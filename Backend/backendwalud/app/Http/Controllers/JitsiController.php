<?php

namespace App\Http\Controllers;

use App\Models\Appointment;
use Illuminate\Http\Request;
use Carbon\Carbon;

/**
 * JitsiController
 *
 * Genera el token JWT para Jitsi Meet (usando Jitsi as a Service - JaaS)
 * y valida que el usuario esté dentro de la ventana de tiempo permitida.
 *
 * Configuración en .env:
 *   JITSI_APP_ID=your_jaas_app_id          # e.g. "vpaas-magic-cookie-xxxxx"
 *   JITSI_API_KEY=your_jaas_api_key_id     # Key ID del dashboard de JaaS
 *   JITSI_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----"
 *
 * Para usar Jitsi Meet gratuito (meet.jit.si) sin autenticación:
 *   - No necesitas JITSI_APP_ID ni claves
 *   - El endpoint devuelve solo room_url y room_name
 *   - En Flutter abre la URL directamente con url_launcher
 */
class JitsiController extends Controller
{
    /**
     * GET /api/appointments/{id}/jitsi-token
     *
     * Responde con:
     * {
     *   "room_name": "walud-cita-42-20260528-0900",
     *   "room_url":  "https://meet.jit.si/walud-cita-42-20260528-0900",
     *   "jwt":       "eyJ...",           // solo si JITSI_APP_ID está configurado
     *   "display_name": "Dr. Sara González",
     *   "is_moderator": true,
     *   "window_status": "open"          // 'not_yet' | 'open' | 'expired'
     * }
     */
    public function getToken(Request $request, int $id)
    {
        $user        = $request->user();
        $appointment = Appointment::with(['patient', 'doctor'])->findOrFail($id);

        // ── 1. Verificar que el usuario pertenece a esta cita
        $isDoctor  = $user->tipo_usuario === 'medico'
            && $appointment->doctor_id === $user->id;
        $isPatient = $user->tipo_usuario === 'paciente'
            && $appointment->patient_id === $user->id;

        if (!$isDoctor && !$isPatient) {
            return response()->json([
                'success' => false,
                'message' => 'No tienes permiso para acceder a esta videollamada.',
            ], 403);
        }

        // ── 2. Verificar que la cita está pendiente
        if ($appointment->status !== 'pendiente') {
            return response()->json([
                'success'        => false,
                'message'        => 'Esta cita ya no está activa.',
                'window_status'  => $appointment->meetingWindowStatus(),
            ], 422);
        }

        // ── 3. Verificar ventana de tiempo
        $windowStatus = $appointment->meetingWindowStatus();

        if ($windowStatus === 'not_yet') {
            $minutesLeft = $appointment->minutesUntilOpen();
            $openTime    = $appointment->dateTime
                ->copy()
                ->subMinutes(Appointment::MINUTES_BEFORE)
                ->format('H:i');

            return response()->json([
                'success'        => false,
                'window_status'  => 'not_yet',
                'minutes_until'  => $minutesLeft,
                'opens_at'       => $openTime,
                'appointment_at' => $appointment->dateTime->format('H:i'),
                'message'        => "La sala aún no está disponible. Podrás ingresar a partir de las {$openTime} (10 minutos antes de tu cita).",
            ], 425); // 425 Too Early
        }

        if ($windowStatus === 'expired') {
            return response()->json([
                'success'       => false,
                'window_status' => 'expired',
                'message'       => 'El tiempo para esta videollamada ha expirado. La consulta debió realizarse a las ' . $appointment->dateTime->format('H:i') . '.',
            ], 410); // 410 Gone
        }

        // ── 4. Generar nombre de sala (determinístico, basado en la cita)
        $roomName = $appointment->jitsi_room;
        if (!$roomName) {
            $dateSlug = $appointment->dateTime->format('Ymd-Hi');
            $roomName = 'walud-cita-' . $appointment->id . '-' . $dateSlug;
            $appointment->update(['jitsi_room' => $roomName]);
        }

        // ── 5. Datos del usuario
        $displayName = $isDoctor
            ? 'Dr. ' . $user->name . ' ' . $user->last_name
            : $user->name . ' ' . $user->last_name;

        $avatarUrl = $user->profile_photo
            ? url('/api/image/profile_photos/' . basename($user->profile_photo))
            : null;

        // ── 6. Construir respuesta base (sin JWT → meet.jit.si gratuito)
        $appId = config('services.jitsi.app_id');
        $host  = $appId ? 'https://8x8.vc' : 'https://meet.jit.si';
        $roomUrl = $appId
            ? "{$host}/{$appId}/{$roomName}"
            : "{$host}/{$roomName}";

        $response = [
            'success'      => true,
            'room_name'    => $roomName,
            'room_url'     => $roomUrl,
            'display_name' => $displayName,
            'avatar_url'   => $avatarUrl,
            'is_moderator' => $isDoctor,
            'window_status'=> 'open',
            'subject'      => 'Consulta ' . $appointment->especialidad . ' — Walud',
        ];

        // ── 7. Generar JWT solo si JaaS está configurado
        if ($appId) {
            $jwt = $this->generateJaasJwt(
                appId:       $appId,
                roomName:    $roomName,
                userId:      (string) $user->id,
                displayName: $displayName,
                email:       $user->email,
                avatarUrl:   $avatarUrl ?? '',
                isModerator: $isDoctor,
            );
            $response['jwt'] = $jwt;
        }

        return response()->json($response);
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  JWT para Jitsi as a Service (JaaS / 8x8.vc)
    //  Documentación: https://developer.8x8.com/jaas/docs/api-keys-jwt
    // ─────────────────────────────────────────────────────────────────────────

    private function generateJaasJwt(
        string $appId,
        string $roomName,
        string $userId,
        string $displayName,
        string $email,
        string $avatarUrl,
        bool   $isModerator,
    ): string {
        $apiKeyId   = config('services.jitsi.api_key');
        $privateKey = config('services.jitsi.private_key');

        $now = time();
        $exp = $now + (60 * 90); // 90 minutos de validez

        // Header
        $header = $this->base64UrlEncode(json_encode([
            'kid' => "{$appId}/{$apiKeyId}",
            'typ' => 'JWT',
            'alg' => 'RS256',
        ]));

        // Payload
        $payload = $this->base64UrlEncode(json_encode([
            'iss'  => 'chat',
            'iat'  => $now,
            'exp'  => $exp,
            'nbf'  => $now,
            'aud'  => 'jitsi',
            'sub'  => $appId,
            'room' => $roomName,
            'context' => [
                'user' => [
                    'id'           => $userId,
                    'name'         => $displayName,
                    'email'        => $email,
                    'avatar'       => $avatarUrl,
                    'moderator'    => $isModerator ? 'true' : 'false',
                ],
                'features' => [
                    'livestreaming' => 'false',
                    'outbound-call' => 'false',
                    'sip-outbound-call' => 'false',
                    'transcription'     => 'false',
                    'recording'         => $isModerator ? 'true' : 'false',
                ],
            ],
        ]));

        // Firma RSA-256
        $data = "{$header}.{$payload}";
        $privateKeyResource = openssl_pkey_get_private($privateKey);
        openssl_sign($data, $signature, $privateKeyResource, OPENSSL_ALGO_SHA256);
        $sig = $this->base64UrlEncode($signature);

        return "{$data}.{$sig}";
    }

    private function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}

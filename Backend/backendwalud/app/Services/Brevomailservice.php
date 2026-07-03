<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Exception;

/**
 * Envía correos transaccionales usando la API HTTP de Brevo en vez de SMTP.
 *
 * Se usa la API en lugar de SMTP porque, en algunas redes/ISP, la conexión
 * SMTP a smtp-relay.brevo.com se enruta a un nodo regional cuyo certificado
 * SSL no coincide con el nombre esperado, lo que rompe el handshake TLS.
 * La API HTTP (HTTPS estándar) no tiene ese problema.
 *
 * Necesita en el .env:
 *   BREVO_API_KEY=xkeysib-...
 *
 * Se obtiene en: https://app.brevo.com/settings/keys/api
 */
class BrevoMailService
{
    private string $apiKey;

    public function __construct()
    {
        $this->apiKey = config('services.brevo.api_key') ?? '';
    }

    public function isConfigured(): bool
    {
        return $this->apiKey !== '';
    }

    /**
     * Envía un correo HTML.
     *
     * @param string $toEmail
     * @param string $toName
     * @param string $subject
     * @param string $htmlContent
     * @return bool true si Brevo aceptó el envío
     * @throws Exception
     */
    public function send(string $toEmail, string $toName, string $subject, string $htmlContent): bool
    {
        if (!$this->isConfigured()) {
            throw new Exception('Brevo no está configurado. Define BREVO_API_KEY en el .env.');
        }

        $fromEmail = config('mail.from.address', 'no-reply@walud.com');
        $fromName  = config('mail.from.name', 'WALUD');

        $response = Http::withHeaders([
            'api-key'      => $this->apiKey,
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json',
        ])->post('https://api.brevo.com/v3/smtp/email', [
            'sender'      => ['name' => $fromName, 'email' => $fromEmail],
            'to'          => [['email' => $toEmail, 'name' => $toName]],
            'subject'     => $subject,
            'htmlContent' => $htmlContent,
        ]);

        if (!$response->successful()) {
            Log::warning('Brevo API mail failed', ['response' => $response->body()]);
            throw new Exception('Error al enviar el correo vía Brevo: ' . ($response->json('message') ?? 'Error desconocido'));
        }

        return true;
    }
}
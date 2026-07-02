<?php

namespace App\Services;

use App\Models\User;
use App\Models\Appointment;
use App\Models\MedicalRecord;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Config;

class AIService
{
    // ======================================================
    // IA PARA PACIENTES (PRECONSULTA)
    // ======================================================
    public function analizarSintomas($mensaje)
    {
        try {

            $especialidadesValidas = [
                'Medicina General',
                'Psicología',
                'Psiquiatría',
                'Dermatología',
                'Nutrición y Dietética',
                'Pediatría',
                'Ginecología',
                'Medicina Interna',
                'Endocrinología',
                'Cardiología',
            ];

            $prompt = "
Eres un asistente médico virtual de WALUD.

Tu función es:
- orientar pacientes
- sugerir especialidad médica
- clasificar prioridad

IMPORTANTE:
- NO diagnostiques enfermedades
- NO recetes medicamentos
- NO reemplaces médicos
- SOLO orientación básica

SOLO puedes recomendar UNA de estas especialidades EXACTAMENTE como aparecen aquí:

- Medicina General
- Psicología
- Psiquiatría
- Dermatología
- Nutrición y Dietética
- Pediatría
- Ginecología
- Medicina Interna
- Endocrinología
- Cardiología

Clasifica prioridad:
- Baja
- Media
- Alta

Si detectas síntomas graves como:
- dificultad respiratoria
- dolor intenso en pecho
- pérdida de conciencia
- sangrado severo

entonces urgente=true.

RESPONDE ÚNICAMENTE EN JSON VÁLIDO.

Formato:

{
  \"especialidad\": \"...\",
  \"prioridad\": \"...\",
  \"urgente\": true,
  \"recomendacion\": \"...\",
  \"resumen\": \"...\"
}

Síntomas del paciente:
$mensaje
";

            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . Config::get('services.openai.key'),
                'Content-Type' => 'application/json',
            ])->post('https://api.openai.com/v1/chat/completions', [

                'model' => 'gpt-4.1-mini',

                'messages' => [
                    [
                        'role' => 'system',
                        'content' => 'Eres un asistente médico virtual de WALUD.'
                    ],
                    [
                        'role' => 'user',
                        'content' => $prompt
                    ]
                ],

                'temperature' => 0.3
            ]);

            if ($response->failed()) {

                Log::error('ERROR OPENAI', [
                    'body' => $response->body()
                ]);

                return [
                    'error' => true,
                    'message' => $response->json()
                ];
            }

            $content = $response['choices'][0]['message']['content'];

            $content = str_replace(['```json', '```'], '', $content);

            $decoded = json_decode(trim($content), true);

            if (!$decoded) {

                Log::error('JSON INVALIDO IA', [
                    'content' => $content
                ]);

                return [
                    'error' => true,
                    'message' => 'La IA devolvió un formato inválido'
                ];
            }

            if (
                !isset($decoded['especialidad']) ||
                !in_array($decoded['especialidad'], $especialidadesValidas)
            ) {
                $decoded['especialidad'] = 'Medicina General';
            }

            if (
                !isset($decoded['prioridad']) ||
                !in_array($decoded['prioridad'], ['Baja', 'Media', 'Alta'])
            ) {
                $decoded['prioridad'] = 'Media';
            }

            if (!isset($decoded['urgente'])) {
                $decoded['urgente'] = false;
            }

            return $decoded;

        } catch (\Exception $e) {

            Log::error('ERROR IA', [
                'error' => $e->getMessage()
            ]);

            return [
                'error' => true,
                'message' => $e->getMessage()
            ];
        }
    }

    // ======================================================
    // IA PARA MÉDICOS (RESUMEN DEL PACIENTE)
    // ======================================================
    public function generarResumenPaciente($documento)
    {
        try {

            $paciente = User::where('document', $documento)->first();

            if (!$paciente) {
                return [
                    'error' => true,
                    'message' => 'Paciente no encontrado'
                ];
            }

            // El historial clínico real del paciente vive en la tabla
            // medical_records (evoluciones registradas por los médicos),
            // no en appointments (que solo son las citas agendadas).
            $registros = MedicalRecord::where('patient_id', $paciente->id)
                ->orderBy('created_at', 'desc')
                ->get();

            if ($registros->isEmpty()) {
                return [
                    'error' => true,
                    'message' => 'El paciente no tiene historial clínico'
                ];
            }

            $historial = "";

            foreach ($registros as $registro) {

                $historial .= "
Fecha: {$registro->created_at}
Especialidad: {$registro->especialidad}
Motivo de consulta: {$registro->motivo_consulta}
Examen físico: {$registro->examen_fisico}
Diagnóstico: {$registro->diagnostico_nombre} ({$registro->diagnostico_cie10})
Descripción del diagnóstico: {$registro->diagnostico_descripcion}
Tratamiento: {$registro->tratamiento}
Observaciones: {$registro->observaciones}

";
            }

            $prompt = "
Eres un asistente médico para WALUD.

Genera un resumen clínico claro y profesional para ayudar al médico.

NO inventes diagnósticos.
NO agregues información inexistente.
Solo resume la información disponible.

Historial del paciente:

$historial
";

            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . Config::get('services.openai.key'),
                'Content-Type' => 'application/json',
            ])->post('https://api.openai.com/v1/chat/completions', [

                'model' => 'gpt-4.1-mini',

                'messages' => [
                    [
                        'role' => 'system',
                        'content' => 'Eres un asistente médico.'
                    ],
                    [
                        'role' => 'user',
                        'content' => $prompt
                    ]
                ],

                'temperature' => 0.2
            ]);

            if ($response->failed()) {

                return [
                    'error' => true,
                    'message' => $response->json()
                ];
            }

            return [
                'paciente' => $paciente->name . ' ' . $paciente->last_name,
                'documento' => $paciente->document,
                'resumen' => $response['choices'][0]['message']['content']
            ];

        } catch (\Exception $e) {

            Log::error('ERROR RESUMEN IA', [
                'error' => $e->getMessage()
            ]);

            return [
                'error' => true,
                'message' => $e->getMessage()
            ];
        }
    }
}
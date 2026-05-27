<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Config;

class AIService
{
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

Formato exacto:

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

            // Limpiar posibles bloques markdown
            $content = str_replace(['```json', '```'], '', $content);

            $decoded = json_decode(trim($content), true);

            // Validar JSON
            if (!$decoded) {

                Log::error('JSON INVALIDO IA', [
                    'content' => $content
                ]);

                return [
                    'error' => true,
                    'message' => 'La IA devolvió un formato inválido'
                ];
            }

            // Validar especialidad
            if (
                !isset($decoded['especialidad']) ||
                !in_array($decoded['especialidad'], $especialidadesValidas)
            ) {
                $decoded['especialidad'] = 'Medicina General';
            }

            // Validar prioridad
            if (
                !isset($decoded['prioridad']) ||
                !in_array($decoded['prioridad'], ['Baja', 'Media', 'Alta'])
            ) {
                $decoded['prioridad'] = 'Media';
            }

            // Validar urgente
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
}
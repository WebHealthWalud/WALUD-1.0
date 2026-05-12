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

            $prompt = "
Eres un asistente médico de orientación clínica para WALUD.

Tu función es:
- orientar pacientes
- sugerir especialidad médica
- clasificar prioridad

IMPORTANTE:
- NO diagnostiques enfermedades
- NO recetes medicamentos
- NO reemplaces médicos
- SOLO orientación básica

Clasifica prioridad:
- Baja
- Media
- Alta

Si detectas síntomas graves:
- dificultad respiratoria
- dolor intenso en pecho
- pérdida de conciencia
- sangrado severo

marca urgente=true.

RESPONDE ÚNICAMENTE EN JSON.

Formato:
{
  \"especialidad\": \"...\",
  \"prioridad\": \"...\",
  \"urgente\": true,
  \"recomendacion\": \"...\",
  \"resumen\": \"...\"
}

Síntomas:
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
                        'content' => 'Eres un asistente médico.'
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

            $decoded = json_decode($content, true);

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
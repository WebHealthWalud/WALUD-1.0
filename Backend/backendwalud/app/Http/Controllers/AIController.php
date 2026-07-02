<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\AIService;

class AIController extends Controller
{
    protected $aiService;

    public function __construct(AIService $aiService)
    {
        $this->aiService = $aiService;
    }

    // ==================================================
    // PACIENTE → PRECONSULTA IA
    // ==================================================
    public function preconsulta(Request $request)
    {
        $request->validate([
            'mensaje' => 'required|string'
        ]);

        $resultado = $this->aiService->analizarSintomas(
            $request->mensaje
        );

        return response()->json($resultado);
    }

    // ==================================================
    // MÉDICO → RESUMEN DEL PACIENTE
    // ==================================================
    public function resumenPaciente(Request $request)
    {
        $request->validate([
            'documento' => 'required|string'
        ]);

        $resultado = $this->aiService->generarResumenPaciente(
            $request->documento
        );

        return response()->json($resultado);
    }
}
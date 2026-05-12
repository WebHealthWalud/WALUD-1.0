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
}
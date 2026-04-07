<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use App\Models\Appointment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PaymentController extends Controller
{
    public function index(Request $request)
    {
        $user  = $request->user();
        $query = Payment::with(['patient:id,name,last_name', 'appointment:id,date,time,especialidad']);

        if ($user->tipo_usuario === 'paciente') {
            $query->where('patient_id', $user->id);
        } elseif ($user->tipo_usuario === 'medico') {
            // Médico no ve pagos directamente
            return response()->json(['message' => 'No autorizado'], 403);
        }
        // Admin ve todos

        if ($request->has('estado_pago')) {
            $query->where('estado_pago', $request->estado_pago);
        }
        if ($request->has('tipo')) {
            $query->where('tipo', $request->tipo);
        }

        $payments = $query->orderBy('created_at', 'desc')->get();

        return response()->json($payments);
    }

    public function store(Request $request)
    {
        $user = $request->user();

        // Solo pacientes o admin crean pagos
        if ($user->tipo_usuario === 'medico') {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $validated = $request->validate([
            'appointment_id'   => 'nullable|exists:appointments,id',
            'concepto'         => 'required|string|max:255',
            'tipo'             => 'required|in:consulta,estudio,seguro,vacuna,psicoterapia,otro',
            'monto'            => 'required|numeric|min:0',
            'estado_pago'      => 'sometimes|in:pendiente,completado,cancelado,reembolsado',
            'fecha_vencimiento'=> 'nullable|date',
            'fecha_pago'       => 'nullable|date',
            'metodo_pago'      => 'nullable|in:tarjeta_credito,tarjeta_debito,transferencia,efectivo,otro',
            'referencia_pago'  => 'nullable|string',
            'notas'            => 'nullable|string',
        ]);

        $payment = Payment::create([
            'patient_id'       => $user->id,
            'appointment_id'   => $validated['appointment_id'] ?? null,
            'concepto'         => $validated['concepto'],
            'tipo'             => $validated['tipo'],
            'monto'            => $validated['monto'],
            'estado_pago'      => $validated['estado_pago'] ?? 'pendiente',
            'fecha_vencimiento'=> $validated['fecha_vencimiento'] ?? null,
            'fecha_pago'       => $validated['fecha_pago'] ?? null,
            'metodo_pago'      => $validated['metodo_pago'] ?? null,
            'referencia_pago'  => $validated['referencia_pago'] ?? null,
            'notas'            => $validated['notas'] ?? null,
        ]);

        return response()->json([
            'message' => 'Pago registrado correctamente',
            'data'    => $payment->load('appointment:id,date,time,especialidad'),
        ], 201);
    }

    public function show($id, Request $request)
    {
        $user    = $request->user();
        $payment = Payment::with(['patient:id,name,last_name,email', 'appointment'])->findOrFail($id);

        // Validar acceso
        if ($user->tipo_usuario === 'paciente' && $payment->patient_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        return response()->json($payment);
    }

    public function update(Request $request, $id)
    {
        $user    = $request->user();
        $payment = Payment::findOrFail($id);

        if ($user->tipo_usuario === 'paciente' && $payment->patient_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }
        if ($user->tipo_usuario === 'medico') {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $validated = $request->validate([
            'concepto'         => 'sometimes|string|max:255',
            'tipo'             => 'sometimes|in:consulta,estudio,seguro,vacuna,psicoterapia,otro',
            'monto'            => 'sometimes|numeric|min:0',
            'estado_pago'      => 'sometimes|in:pendiente,completado,cancelado,reembolsado',
            'fecha_vencimiento'=> 'nullable|date',
            'fecha_pago'       => 'nullable|date',
            'metodo_pago'      => 'nullable|in:tarjeta_credito,tarjeta_debito,transferencia,efectivo,otro',
            'referencia_pago'  => 'nullable|string',
            'notas'            => 'nullable|string',
        ]);

        $payment->update($validated);

        return response()->json([
            'message' => 'Pago actualizado correctamente',
            'data'    => $payment->fresh(),
        ]);
    }

    /**
     * Procesar pago (cambiar a completado)
     */
    public function pay(Request $request, $id)
    {
        $user    = $request->user();
        $payment = Payment::findOrFail($id);

        if ($user->tipo_usuario === 'paciente' && $payment->patient_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $validated = $request->validate([
            'metodo_pago'    => 'required|in:tarjeta_credito,tarjeta_debito,transferencia,efectivo,otro',
            'referencia_pago'=> 'nullable|string',
        ]);

        $payment->update([
            'estado_pago'    => 'completado',
            'fecha_pago'     => now()->toDateString(),
            'metodo_pago'    => $validated['metodo_pago'],
            'referencia_pago'=> $validated['referencia_pago'] ?? null,
        ]);

        return response()->json([
            'message' => 'Pago procesado exitosamente',
            'data'    => $payment->fresh(),
        ]);
    }

    public function destroy($id, Request $request)
    {
        $user    = $request->user();
        $payment = Payment::findOrFail($id);

        if ($user->tipo_usuario === 'paciente' && $payment->patient_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }
        if ($user->tipo_usuario === 'medico') {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $payment->delete();

        return response()->json(['message' => 'Pago eliminado correctamente']);
    }

    /**
     * Resumen/estadísticas de pagos del paciente
     */
    public function summary(Request $request)
    {
        $user = $request->user();

        $query = Payment::where('patient_id', $user->id);

        return response()->json([
            'total_pendiente'  => (clone $query)->where('estado_pago', 'pendiente')->sum('monto'),
            'total_completado' => (clone $query)->where('estado_pago', 'completado')->sum('monto'),
            'count_pendiente'  => (clone $query)->where('estado_pago', 'pendiente')->count(),
            'count_completado' => (clone $query)->where('estado_pago', 'completado')->count(),
        ]);
    }
}

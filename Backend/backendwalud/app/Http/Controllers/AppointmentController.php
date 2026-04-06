<?php

namespace App\Http\Controllers;

use App\Models\Appointment;
use Illuminate\Http\Request;
use App\Models\User;

class AppointmentController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        // Filtrar según tipo de usuario
        if ($user->tipo_usuario === 'paciente') {
            // Paciente: solo ve SUS citas
            $appointments = Appointment::where('patient_id', $user->id)
                ->with(['patient', 'doctor'])
                ->get();
        } else if ($user->tipo_usuario === 'medico') {
            // Médico: solo ve las citas donde es el doctor asignado
            $appointments = Appointment::where('doctor_id', $user->id)
                ->with(['patient', 'doctor'])
                ->get();
        } else {
            // Admin (si existe): ve todas
            $appointments = Appointment::with(['patient', 'doctor'])->get();
        }

        return response()->json($appointments);
    }

    public function store(Request $request)
    {
        $user = $request->user();

        try {
            $validated = $request->validate([
                'doctor_id' => 'required|exists:users,id',
                'patient_document' => 'required|numeric',
                'patient_name' => 'required|string',
                'appointment_type' => 'required|string',
                'date' => 'required|date',
                'time' => 'required',
                'reason' => 'required|string',
                'status' => 'required|in:pendiente,realizada,cancelada',
                'notes' => 'nullable|string'
            ]);

            // Buscar paciente por documento Y tipo_documento
            $patient = User::where('document', $validated['patient_document'])
            ->where('tipo_documento', $request->patient_tipo_documento ?? 'cedula_ciudadania')
            ->where('tipo_usuario', 'paciente')
            ->first();

            if (!$patient) {
                return response()->json([
                    'message' => 'Paciente no encontrado con ese documento y tipo de documento'
                ], 404);
            }

            // Si es médico, forzar que él sea el doctor
            if ($user->tipo_usuario === 'medico') {
                $validated['doctor_id'] = $user->id;
                $validated['patient_id'] = $patient->id;
            }
            // Si es paciente, forzar que él sea el paciente
            else if ($user->tipo_usuario === 'paciente') {
                $validated['patient_id'] = $user->id;
            }

            $appointment = Appointment::create([
                'patient_id' => $validated['patient_id'],
                'doctor_id' => $validated['doctor_id'],
                'patient_document' => $validated['patient_document'],
                'patient_name' => $validated['patient_name'],
                'appointment_type' => $validated['appointment_type'],
                'date' => $validated['date'],
                'time' => $validated['time'],
                'reason' => $validated['reason'],
                'status' => $validated['status'],
                'notes' => $validated['notes'] ?? null,
            ]);

            return response()->json([
                'message' => 'Cita creada correctamente',
                'data' => $appointment
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Error de validación',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al crear la cita',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function show($id)
    {
        $appointment = Appointment::with(['patient', 'doctor'])->findOrFail($id);
        return response()->json($appointment);
    }

    public function update(Request $request, $id)
    {
        $user = $request->user();

        try {
            // Buscar la cita y verificar propiedad
            $appointment = Appointment::findOrFail($id);

            // Validar que solo el dueño pueda editar
            if ($user->tipo_usuario === 'paciente' && $appointment->patient_id !== $user->id) {
                return response()->json([
                    'message' => 'No tienes permiso para editar esta cita'
                ], 403);
            }

            if ($user->tipo_usuario === 'medico' && $appointment->doctor_id !== $user->id) {
                return response()->json([
                    'message' => 'No tienes permiso para editar esta cita'
                ], 403);
            }

            $validated = $request->validate([
                'doctor_id' => 'sometimes|exists:users,id',
                'date' => 'sometimes|date|after_or_equal:today',
                'time' => 'sometimes',
                'reason' => 'sometimes|required|string',
                'status' => 'sometimes|in:pendiente,realizada,cancelada',
                'notes' => 'nullable|string'
            ]);

            $appointment->update($validated);

            return response()->json([
                'message' => 'Cita actualizada correctamente',
                'data' => $appointment
            ], 200);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'message' => 'Cita no encontrada'
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al actualizar la cita',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function destroy($id, Request $request)
    {
        $user = $request->user();

        try {
            // Buscar la cita y verificar propiedad
            $appointment = Appointment::findOrFail($id);

            // Validar que solo el dueño pueda eliminar
            if ($user->tipo_usuario === 'paciente' && $appointment->patient_id !== $user->id) {
                return response()->json([
                    'message' => 'No tienes permiso para eliminar esta cita'
                ], 403);
            }

            if ($user->tipo_usuario === 'medico' && $appointment->doctor_id !== $user->id) {
                return response()->json([
                    'message' => 'No tienes permiso para eliminar esta cita'
                ], 403);
            }

            $appointment->delete();

            return response()->json([
                'message' => 'Cita eliminada correctamente'
            ], 200);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'message' => 'Cita no encontrada'
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al eliminar la cita',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}

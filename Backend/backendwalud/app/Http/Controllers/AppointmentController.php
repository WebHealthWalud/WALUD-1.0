<?php

namespace App\Http\Controllers;

use App\Models\Appointment;
use Illuminate\Http\Request;
class AppointmentController extends Controller
{
    public function index()
    {
        $appointments = Appointment::with(['patient', 'doctor'])->get();
        return response()->json($appointments);
    }

    public function store(Request $request)
    {
        try {
            $request->validate([
                'patient_id' => 'required|exists:users,id',
                'doctor_id' => 'required|exists:users,id',
                'patient_document' => 'required|string',
                'patient_name' => 'required|string',
                'appointment_type' => 'required|string',
                'date' => 'required|date|after_or_equal:today',
                'time' => 'required',
                'status' => 'required|in:pendiente,realizada,cancelada',
                'reason' => 'required|string',
            ]);

            $appointment = Appointment::create([
                'patient_id' => $request->patient_id,
                'doctor_id' => $request->doctor_id,
                'patient_document' => $request->patient_document,
                'patient_name' => $request->patient_name,
                'appointment_type' => $request->appointment_type,
                'date' => $request->date,
                'time' => $request->time,
                'status' => $request->status,
                'notes' => $request->notes,
                'reason' => $request->reason,
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
        try {
            $request->validate([
                'patient_id' => 'required|exists:users,id',
                'doctor_id' => 'required|exists:users,id',
                'patient_document' => 'required|string',
                'patient_name' => 'required|string',
                'appointment_type' => 'required|string',
                'date' => 'required|date|after_or_equal:today',
                'time' => 'required',
                'status' => 'required|in:pendiente,realizada,cancelada'
            ]);

            $appointment = Appointment::findOrFail($id);

            $appointment->update($request->all());

            return response()->json([
                'message' => 'Cita actualizada correctamente',
                'data' => $appointment
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {

            return response()->json([
                'message' => 'Error de validación',
                'errors' => $e->errors()
            ], 422);

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

    public function destroy($id)
    {
        try {
            $appointment = Appointment::findOrFail($id);

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

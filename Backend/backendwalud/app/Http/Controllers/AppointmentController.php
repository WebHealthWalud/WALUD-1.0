<?php

namespace App\Http\Controllers;

use App\Models\Appointment;
use Illuminate\Http\Request;

class AppointmentController extends Controller
{
    public function index()
    {
        return Appointment::all();
    }

    public function store(Request $request)
{
    try {
        $request->validate([
            'patient_id' => 'required|exists:users,id',
            'doctor_id' => 'required|exists:users,id',
            'date' => 'required|date',
            'time' => 'required',
            'status' => 'required|in:pendiente,realizada,cancelada'
        ]);

        $appointment = Appointment::create($request->all());

        return response()->json([
            'message' => 'Cita creada correctamente',
            'data' => $appointment
        ], 201);

    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Error al crear la cita',
            'error' => $e->getMessage()
        ], 500);
    }
}

    public function show($id)
    {
        return Appointment::findOrFail($id);
    }

    public function update(Request $request, $id)
{
    try {
        $request->validate([
            'patient_id' => 'sometimes|exists:users,id',
            'doctor_id' => 'sometimes|exists:users,id',
            'date' => 'sometimes|date',
            'time' => 'sometimes',
            'status' => 'sometimes|in:pendiente,realizada,cancelada'
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
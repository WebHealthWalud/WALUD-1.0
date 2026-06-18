<?php

namespace App\Http\Controllers;

use App\Models\DoctorProfile;
use App\Models\Appointment;
use Illuminate\Http\Request;

class DoctorProfileController extends Controller
{
    // ── Ver perfil del médico autenticado
    public function show(Request $request)
    {
        $user    = $request->user();
        $profile = $user->doctorProfile;

        if (!$profile) {
            $profile = DoctorProfile::create(['user_id' => $user->id]);
        }

        // ✅ Actividad clínica: total consultas últimos 30 días
        $totalConsultas = Appointment::where('doctor_id', $user->id)
            ->where('status', 'realizada')
            ->where('created_at', '>=', now()->subDays(30))
            ->count();

        // ✅ Últimos pacientes atendidos
        $ultimosPacientes = Appointment::with('patient:id,name,last_name')
            ->where('doctor_id', $user->id)
            ->where('status', 'realizada')
            ->orderBy('date', 'desc')
            ->limit(5)
            ->get()
            ->map(fn($a) => [
                'paciente' => $a->patient?->name . ' ' . $a->patient?->last_name,
                'motivo'   => $a->reason,
                'estado'   => $a->status,
                'fecha'    => $a->date,
                'hora'     => $a->time,
            ]);

        return response()->json([
            'success' => true,
            'data'    => array_merge(
                $user->only(['id', 'name', 'last_name', 'email',
                             'especialidad', 'document']),
                $profile->toArray(),
                [
                    'perfil_completo'  => $profile->checkIfComplete(),
                    'total_consultas'  => $totalConsultas,
                    'ultimos_pacientes'=> $ultimosPacientes,
                ]
            ),
        ]);
    }

    // ── Actualizar perfil del médico
    public function update(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'rethus'               => 'nullable|string|max:50',
            'formacion_academica'  => 'nullable|array',
            'formacion_academica.*.titulo'      => 'required|string',
            'formacion_academica.*.institucion' => 'required|string',
            'formacion_academica.*.anio_inicio' => 'nullable|string',
            'formacion_academica.*.anio_fin'    => 'nullable|string',
            'areas_enfoque'        => 'nullable|array',
            'areas_enfoque.*'      => 'string',
            'horarios_atencion'    => 'nullable|array',
            'ubicaciones_consulta' => 'nullable|array',
        ]);

        $profile = $user->doctorProfile ?? DoctorProfile::create(['user_id' => $user->id]);
        $profile->update($validated);
        $profile->update(['perfil_completo' => $profile->checkIfComplete()]);

        return response()->json([
            'success' => true,
            'message' => 'Perfil actualizado correctamente',
            'data'    => $profile->fresh(),
        ]);
    }
}
<?php
namespace App\Http\Controllers;

use App\Models\MedicalRecord;
use App\Models\User;
use Illuminate\Http\Request;

class MedicalRecordController extends Controller
{
    /**
     * Listar registros médicos.
     * - Médico: puede buscar por documento o nombre del paciente.
     * - Paciente: ve solo sus propios registros, puede filtrar por especialidad.
     */
    public function index(Request $request)
    {
        $user  = $request->user();
        $query = MedicalRecord::with([
            'patient:id,name,last_name,document,tipo_documento,birth_date,tipo_sangre,alergias,genero',
            'doctor:id,name,last_name,especialidad,profile_photo_path',
            'appointment:id,date,time',
        ]);

        if ($user->tipo_usuario === 'paciente') {
            // Paciente solo ve sus propios registros
            $query->where('patient_id', $user->id);

            // Filtro por especialidad
            if ($request->filled('especialidad')) {
                $query->where('especialidad', $request->especialidad);
            }

        } elseif ($user->tipo_usuario === 'medico') {
            // Médico puede buscar por documento o nombre del paciente
            if ($request->filled('search')) {
                $s = $request->search;
                $patientIds = User::where('tipo_usuario', 'paciente')
                    ->where(function ($q) use ($s) {
                        $q->where('document',  'like', "%$s%")
                          ->orWhere('name',     'like', "%$s%")
                          ->orWhere('last_name','like', "%$s%")
                          ->orWhereRaw("CONCAT(name, ' ', last_name) LIKE ?", ["%$s%"]);
                    })->pluck('id');

                $query->whereIn('patient_id', $patientIds);
            } else {
                // Sin búsqueda, mostrar los registros creados por este médico
                $query->where('doctor_id', $user->id);
            }

            if ($request->filled('especialidad')) {
                $query->where('especialidad', $request->especialidad);
            }
        }

        return response()->json($query->orderBy('created_at', 'desc')->get());
    }

    /**
     * Ver un registro médico por ID.
     */
    public function show(Request $request, $id)
    {
        $user   = $request->user();
        $record = MedicalRecord::with([
            'patient:id,name,last_name,document,tipo_documento,birth_date,tipo_sangre,alergias,genero,phone,email',
            'doctor:id,name,last_name,especialidad,profile_photo_path,phone,email',
            'appointment:id,date,time,especialidad',
        ])->findOrFail($id);

        // Validar acceso
        if ($user->tipo_usuario === 'paciente' && $record->patient_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        return response()->json($record);
    }

    /**
     * Crear nueva evolución médica.
     * Solo médicos pueden crear registros.
     */
    public function store(Request $request)
    {
        $user = $request->user();

        if ($user->tipo_usuario !== 'medico') {
            return response()->json(['message' => 'Solo los médicos pueden crear evoluciones'], 403);
        }

        $validated = $request->validate([
            'patient_id'               => 'required|exists:users,id',
            'appointment_id'           => 'nullable|exists:appointments,id',
            'motivo_consulta'          => 'required|string',
            'examen_fisico'            => 'nullable|string',
            'diagnostico_cie10'        => 'nullable|string|max:20',
            'diagnostico_nombre'       => 'nullable|string|max:255',
            'diagnostico_descripcion'  => 'nullable|string',
            'tratamiento'              => 'nullable|string',
            'observaciones'            => 'nullable|string',
            'especialidad'             => 'required|string',
            // Signos vitales opcionales
            'presion_sistolica'        => 'nullable|numeric',
            'presion_diastolica'       => 'nullable|numeric',
            'frecuencia_cardiaca'      => 'nullable|numeric',
            'temperatura'              => 'nullable|numeric',
            'peso'                     => 'nullable|numeric',
            'talla'                    => 'nullable|numeric',
            'saturacion_oxigeno'       => 'nullable|numeric',
        ]);

        // Verificar que el patient_id sea realmente un paciente
        $patient = User::where('id', $validated['patient_id'])
            ->where('tipo_usuario', 'paciente')
            ->first();

        if (!$patient) {
            return response()->json(['message' => 'Paciente no válido'], 422);
        }

        $record = MedicalRecord::create([
            ...$validated,
            'doctor_id'   => $user->id,
            'especialidad'=> $validated['especialidad'] ?? $user->especialidad,
            'expediente'  => MedicalRecord::generateExpediente(),
        ]);

        return response()->json([
            'message' => 'Evolución médica guardada correctamente',
            'data'    => $record->load([
                'patient:id,name,last_name,document,tipo_sangre,alergias,birth_date',
                'doctor:id,name,last_name,especialidad',
            ]),
        ], 201);
    }

    /**
     * Actualizar registro médico.
     * Solo el médico que lo creó puede editarlo.
     */
    public function update(Request $request, $id)
    {
        $user   = $request->user();
        $record = MedicalRecord::findOrFail($id);

        if ($user->tipo_usuario !== 'medico' || $record->doctor_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $validated = $request->validate([
            'motivo_consulta'         => 'sometimes|string',
            'examen_fisico'           => 'nullable|string',
            'diagnostico_cie10'       => 'nullable|string|max:20',
            'diagnostico_nombre'      => 'nullable|string|max:255',
            'diagnostico_descripcion' => 'nullable|string',
            'tratamiento'             => 'nullable|string',
            'observaciones'           => 'nullable|string',
            'presion_sistolica'       => 'nullable|numeric',
            'presion_diastolica'      => 'nullable|numeric',
            'frecuencia_cardiaca'     => 'nullable|numeric',
            'temperatura'             => 'nullable|numeric',
            'peso'                    => 'nullable|numeric',
            'talla'                   => 'nullable|numeric',
            'saturacion_oxigeno'      => 'nullable|numeric',
        ]);

        $record->update($validated);

        return response()->json([
            'message' => 'Evolución actualizada correctamente',
            'data'    => $record->fresh([
                'patient:id,name,last_name',
                'doctor:id,name,last_name,especialidad',
            ]),
        ]);
    }

    /**
     * Obtener la línea de tiempo clínica de un paciente.
     * Usado por el médico al crear/ver evoluciones.
     */
    public function timeline(Request $request, $patientId)
    {
        $user = $request->user();

        if ($user->tipo_usuario !== 'medico') {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $records = MedicalRecord::with(['doctor:id,name,last_name,especialidad'])
            ->where('patient_id', $patientId)
            ->orderBy('created_at', 'desc')
            ->get([
                'id', 'doctor_id', 'motivo_consulta',
                'diagnostico_nombre', 'tratamiento',
                'especialidad', 'created_at',
            ]);

        return response()->json($records);
    }

    /**
     * Buscar paciente por documento para el médico.
     */
    public function searchPatient(Request $request)
    {
        $user = $request->user();
        if ($user->tipo_usuario !== 'medico') {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $request->validate(['search' => 'required|string|min:2']);
        $s = $request->search;

        $patients = User::where('tipo_usuario', 'paciente')
            ->where(function ($q) use ($s) {
                $q->where('document',  'like', "%$s%")
                  ->orWhere('name',     'like', "%$s%")
                  ->orWhere('last_name','like', "%$s%")
                  ->orWhereRaw("CONCAT(name, ' ', last_name) LIKE ?", ["%$s%"]);
            })
            ->select('id', 'name', 'last_name', 'document', 'tipo_documento',
                     'birth_date', 'tipo_sangre', 'alergias', 'genero')
            ->limit(10)
            ->get();

        return response()->json(['success' => true, 'patients' => $patients]);
    }
}
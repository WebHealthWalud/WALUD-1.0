<?php

namespace App\Http\Controllers;

use App\Models\Appointment;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Storage;

class AppointmentController extends Controller
{
    public function index(Request $request)
    {
        $user  = $request->user();
        $query = Appointment::with([
            'patient:id,name,last_name,document',
            'doctor:id,name,last_name,especialidad',
        ]);

        if ($user->tipo_usuario === 'paciente') {
            $query->where('patient_id', $user->id);
        } elseif ($user->tipo_usuario === 'medico') {
            $query->where('doctor_id', $user->id);
        }

        if ($request->has('status'))      $query->where('status', $request->status);
        if ($request->has('especialidad')) $query->where('especialidad', $request->especialidad);

        return response()->json($query->orderBy('date', 'asc')->get());
    }

    /**
     * Disponibilidad por especialidad y fecha
     */
    public function availableSlots(Request $request)
    {
        $request->validate([
            'especialidad' => 'required|string',
            'date'         => 'required|date|after_or_equal:today',
        ]);

        $doctors = User::where('tipo_usuario', 'medico')
            ->where('especialidad', $request->especialidad)
            ->select('id', 'name', 'last_name', 'especialidad')
            ->get();

        if ($doctors->isEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'No hay médicos disponibles para esa especialidad',
            ], 404);
        }

        $baseSlots = ['08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00'];

        $result = [];
        foreach ($doctors as $doctor) {
            $booked = Appointment::where('doctor_id', $doctor->id)
                ->whereDate('date', $request->date)
                ->whereIn('status', ['pendiente'])
                ->pluck('time')
                // Normalizar a HH:MM para comparar correctamente
                ->map(fn($t) => substr($t, 0, 5))
                ->toArray();

            $availableSlots = array_values(array_filter(
                $baseSlots,
                fn($s) => !in_array($s, $booked)
            ));

            if (!empty($availableSlots)) {
                $result[] = [
                    'doctor_id'    => $doctor->id,
                    'doctor_name'  => $doctor->name . ' ' . $doctor->last_name,
                    'especialidad' => $doctor->especialidad,
                    'slots'        => $availableSlots,
                ];
            }
        }

        return response()->json([
            'success' => true,
            'date'    => $request->date,
            'doctors' => $result,
        ]);
    }

    /**
     * Crear cita — paciente O médico
     */
    public function store(Request $request)
    {
        $user = $request->user();

        try {
            $validated = $request->validate([
                'doctor_id'        => 'required|exists:users,id',
                'especialidad'     => 'required|string',
                'appointment_type' => 'required|string',
                // Aceptar date como date y time como string HH:MM o HH:MM:SS
                'date'             => 'required|date',
                'time'             => ['required', 'regex:/^\d{2}:\d{2}(:\d{2})?$/'],
                'reason'           => 'required|string',
                'notes'            => 'nullable|string',
                // Solo médico puede especificar patient_id o patient_document
                'patient_id'       => 'nullable|exists:users,id',
                'patient_document' => 'nullable|string',
                'patient_tipo_documento' => 'nullable|string',
            ]);

            // Normalizar time a HH:MM siempre
            $validated['time'] = substr($validated['time'], 0, 5);

            // ── Determinar paciente según tipo de usuario
            if ($user->tipo_usuario === 'paciente') {
                $patientId       = $user->id;
                $patientDocument = (string) $user->document;
                $patientName     = $user->name . ' ' . $user->last_name;

            } elseif ($user->tipo_usuario === 'medico') {
                // Médico puede especificar por patient_id directo o buscar por documento
                if (!empty($validated['patient_id'])) {
                    $patient = User::findOrFail($validated['patient_id']);
                } elseif (!empty($validated['patient_document'])) {
                    $patient = User::where('document', $validated['patient_document'])
                        ->where('tipo_usuario', 'paciente')
                        ->when(
                            !empty($validated['patient_tipo_documento']),
                            fn($q) => $q->where('tipo_documento', $validated['patient_tipo_documento'])
                        )
                        ->first();
                    if (!$patient) {
                        return response()->json([
                            'message' => 'Paciente no encontrado con ese documento',
                        ], 404);
                    }
                } else {
                    return response()->json([
                        'message' => 'Debe especificar el paciente (patient_id o patient_document)',
                    ], 422);
                }
                $patientId       = $patient->id;
                $patientDocument = (string) $patient->document;
                $patientName     = $patient->name . ' ' . $patient->last_name;

                // Médico solo puede asignarse a sí mismo como doctor
                $validated['doctor_id'] = $user->id;
            } else {
                return response()->json(['message' => 'No autorizado'], 403);
            }

            // Verificar que el doctor existe y pertenece a la especialidad
            $doctor = User::where('id', $validated['doctor_id'])
                ->where('tipo_usuario', 'medico')
                ->first();

            if (!$doctor) {
                return response()->json(['message' => 'Médico no válido'], 422);
            }

            // Verificar slot no ocupado
            $exists = Appointment::where('doctor_id', $validated['doctor_id'])
                ->whereDate('date', $validated['date'])
                ->whereRaw("LEFT(time, 5) = ?", [$validated['time']])
                ->where('status', 'pendiente')
                ->exists();

            if ($exists) {
                return response()->json([
                    'message' => 'Ese horario ya fue tomado, por favor selecciona otro',
                ], 409);
            }

            $appointment = Appointment::create([
                'patient_id'       => $patientId,
                'doctor_id'        => $validated['doctor_id'],
                'patient_document' => $patientDocument,
                'patient_name'     => $patientName,
                'especialidad'     => $validated['especialidad'],
                'appointment_type' => $validated['appointment_type'],
                'date'             => $validated['date'],
                'time'             => $validated['time'],
                'reason'           => $validated['reason'],
                'status'           => 'pendiente',
                'notes'            => $validated['notes'] ?? null,
            ]);

            return response()->json([
                'message' => 'Cita creada correctamente',
                'data'    => $appointment->load([
                    'patient:id,name,last_name',
                    'doctor:id,name,last_name,especialidad',
                ]),
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json(['message' => 'Error de validación', 'errors' => $e->errors()], 422);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Error al crear la cita', 'error' => $e->getMessage()], 500);
        }
    }

    public function show($id)
    {
        $appointment = Appointment::with([
            'patient:id,name,last_name,document,email',
            'doctor:id,name,last_name,especialidad,email',
        ])->findOrFail($id);

        return response()->json($appointment);
    }

    public function update(Request $request, $id)
    {
        $user        = $request->user();
        $appointment = Appointment::findOrFail($id);

        // Solo se pueden editar citas PENDIENTES
        if ($appointment->status !== 'pendiente') {
            return response()->json([
                'message' => 'Solo se pueden modificar citas pendientes',
            ], 422);
        }

        if ($user->tipo_usuario === 'paciente' && $appointment->patient_id !== $user->id) {
            return response()->json(['message' => 'No tienes permiso para editar esta cita'], 403);
        }
        if ($user->tipo_usuario === 'medico' && $appointment->doctor_id !== $user->id) {
            return response()->json(['message' => 'No tienes permiso para editar esta cita'], 403);
        }

        try {
            if ($user->tipo_usuario === 'medico') {
                // Médico SOLO cambia estado
                $validated = $request->validate([
                    'status' => 'required|in:pendiente,realizada,cancelada',
                ]);
                $appointment->update(['status' => $validated['status']]);

            } else {
                // Paciente puede cambiar fecha, hora, especialidad, razón, notas
                $validated = $request->validate([
                    'doctor_id'        => 'sometimes|exists:users,id',
                    'especialidad'     => 'sometimes|string',
                    'appointment_type' => 'sometimes|string',
                    'date'             => 'sometimes|date|after_or_equal:today',
                    // Aceptar HH:MM o HH:MM:SS
                    'time'             => ['sometimes', 'regex:/^\d{2}:\d{2}(:\d{2})?$/'],
                    'reason'           => 'sometimes|string',
                    'notes'            => 'nullable|string',
                ]);

                // Normalizar time
                if (isset($validated['time'])) {
                    $validated['time'] = substr($validated['time'], 0, 5);
                }

                $appointment->update($validated);
            }

            return response()->json([
                'message' => 'Cita actualizada correctamente',
                'data'    => $appointment->fresh([
                    'patient:id,name,last_name',
                    'doctor:id,name,last_name,especialidad',
                ]),
            ]);

        } catch (\Exception $e) {
            return response()->json(['message' => 'Error al actualizar', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Subir archivo adjunto — cualquier estado, solo paciente dueño
     */
    public function uploadAttachment(Request $request, $id)
    {
        $user        = $request->user();
        $appointment = Appointment::findOrFail($id);

        if ($user->tipo_usuario !== 'paciente' || $appointment->patient_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $request->validate([
            'attachment' => 'required|file|max:10240|mimes:pdf,jpg,jpeg,png,doc,docx',
        ]);

        if ($appointment->attachment_path) {
            Storage::disk('public')->delete($appointment->attachment_path);
        }

        $file = $request->file('attachment');
        $path = $file->store('appointments/attachments', 'public');

        $appointment->update([
            'attachment_path' => $path,
            'attachment_name' => $file->getClientOriginalName(),
        ]);

        return response()->json([
            'message'         => 'Archivo adjuntado correctamente',
            'attachment_name' => $appointment->attachment_name,
            'attachment_url'  => Storage::url($path),
        ]);
    }

    public function destroy($id, Request $request)
    {
        $user        = $request->user();
        $appointment = Appointment::findOrFail($id);

        if ($user->tipo_usuario === 'paciente' && $appointment->patient_id !== $user->id) {
            return response()->json(['message' => 'No tienes permiso para eliminar esta cita'], 403);
        }
        if ($user->tipo_usuario === 'medico' && $appointment->doctor_id !== $user->id) {
            return response()->json(['message' => 'No tienes permiso para eliminar esta cita'], 403);
        }

        if ($appointment->attachment_path) {
            Storage::disk('public')->delete($appointment->attachment_path);
        }

        $appointment->delete();
        return response()->json(['message' => 'Cita eliminada correctamente']);
    }
}

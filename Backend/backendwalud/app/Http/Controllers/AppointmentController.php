<?php
namespace App\Http\Controllers;

use App\Models\Appointment;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

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

        if ($request->has('status'))       $query->where('status', $request->status);
        if ($request->has('especialidad')) $query->where('especialidad', $request->especialidad);

        return response()->json($query->orderBy('date', 'asc')->get());
    }

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

        $baseSlots = ['08:00','09:00','10:00','11:00','12:00','13:00','14:00','15:00','16:00','17:00'];

        $isToday = Carbon::parse($request->date)->isToday();
        $now     = Carbon::now();

        $result = [];

        foreach ($doctors as $doctor) {
            $booked = Appointment::where('doctor_id', $doctor->id)
                ->whereDate('date', $request->date)
                ->where('status', 'pendiente')
                ->pluck('time')
                ->map(fn($t) => substr($t, 0, 5))
                ->toArray();

            $available = array_values(array_filter($baseSlots, function ($slot) use ($booked, $isToday, $now) {
                if (in_array($slot, $booked)) return false;
                if ($isToday) {
                    [$h, $m]  = explode(':', $slot);
                    $slotTime = Carbon::now()->setHour((int)$h)->setMinute((int)$m)->setSecond(0);
                    // Excluir slots que ya pasaron o con menos de 30 min de anticipación
                    if ($slotTime->lessThanOrEqualTo($now->copy()->addMinutes(30))) return false;
                }
                return true;
            }));

            if (!empty($available)) {
                $result[] = [
                    'doctor_id'    => $doctor->id,
                    'doctor_name'  => $doctor->name . ' ' . $doctor->last_name,
                    'especialidad' => $doctor->especialidad,
                    'slots'        => $available,
                ];
            }
        }

        return response()->json(['success' => true, 'date' => $request->date, 'doctors' => $result]);
    }

    /**
     * Crear cita.
     * Valida que no sea en el pasado.
     * Valida que el doctor no tenga ese slot ocupado.
     * Valida que el paciente no tenga ya una cita en ese mismo horario.
     */
    public function store(Request $request)
    {
        $user = $request->user();

        try {
            $validated = $request->validate([
                'doctor_id'              => 'required|exists:users,id',
                'especialidad'           => 'required|string',
                'appointment_type'       => 'required|string',
                'date'                   => 'required|date',
                'time'                   => ['required', 'regex:/^\d{2}:\d{2}(:\d{2})?$/'],
                'reason'                 => 'required|string',
                'notes'                  => 'nullable|string',
                'patient_id'             => 'nullable|exists:users,id',
                'patient_document'       => 'nullable|string',
                'patient_tipo_documento' => 'nullable|string',
            ]);

            $validated['time'] = substr($validated['time'], 0, 5);

            // Validar que no sea en el pasado
            [$h, $m]  = explode(':', $validated['time']);
            $slotTime = Carbon::parse($validated['date'])->setHour((int)$h)->setMinute((int)$m)->setSecond(0);

            if ($slotTime->lessThanOrEqualTo(Carbon::now()->addMinutes(30))) {
                return response()->json([
                    'message' => 'No puedes agendar una cita en el pasado o con menos de 30 minutos de anticipación.',
                ], 422);
            }

            // Determinar paciente
            if ($user->tipo_usuario === 'paciente') {
                $patientId       = $user->id;
                $patientDocument = (string) $user->document;
                $patientName     = $user->name . ' ' . $user->last_name;

            } elseif ($user->tipo_usuario === 'medico') {
                if (!empty($validated['patient_id'])) {
                    $patient = User::findOrFail($validated['patient_id']);
                } elseif (!empty($validated['patient_document'])) {
                    $patient = User::where('document', $validated['patient_document'])
                        ->where('tipo_usuario', 'paciente')
                        ->when(!empty($validated['patient_tipo_documento']),
                            fn($q) => $q->where('tipo_documento', $validated['patient_tipo_documento']))
                        ->first();
                    if (!$patient) {
                        return response()->json(['message' => 'Paciente no encontrado con ese documento'], 404);
                    }
                } else {
                    return response()->json(['message' => 'Debe especificar el paciente'], 422);
                }

                $patientId       = $patient->id;
                $patientDocument = (string) $patient->document;
                $patientName     = $patient->name . ' ' . $patient->last_name;

                if (empty($validated['doctor_id'])) $validated['doctor_id'] = $user->id;

                $doctorTarget = User::where('id', $validated['doctor_id'])->where('tipo_usuario', 'medico')->first();
                if (!$doctorTarget) return response()->json(['message' => 'El médico seleccionado no es válido'], 422);
            } else {
                return response()->json(['message' => 'No autorizado'], 403);
            }

            $doctor = User::where('id', $validated['doctor_id'])->where('tipo_usuario', 'medico')->first();
            if (!$doctor) return response()->json(['message' => 'Médico no válido'], 422);

            // Verificar que el slot del doctor no esté ocupado
            $doctorConflict = Appointment::where('doctor_id', $validated['doctor_id'])
                ->whereDate('date', $validated['date'])
                ->whereRaw("LEFT(time, 5) = ?", [$validated['time']])
                ->where('status', 'pendiente')
                ->exists();

            if ($doctorConflict) {
                return response()->json(['message' => 'Ese horario ya fue tomado, por favor selecciona otro.'], 409);
            }

            // Verificar que el paciente no tenga ya una cita en ese mismo horario
            $patientConflict = Appointment::where('patient_id', $patientId)
                ->whereDate('date', $validated['date'])
                ->whereRaw("LEFT(time, 5) = ?", [$validated['time']])
                ->where('status', 'pendiente')
                ->exists();

            if ($patientConflict) {
                return response()->json(['message' => 'Ya tienes una cita agendada en ese mismo horario.'], 409);
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
                'data'    => $appointment->load(['patient:id,name,last_name', 'doctor:id,name,last_name,especialidad']),
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

        if ($appointment->status !== 'pendiente') {
            return response()->json(['message' => 'Solo se pueden modificar citas pendientes'], 422);
        }
        if ($user->tipo_usuario === 'paciente' && $appointment->patient_id !== $user->id) {
            return response()->json(['message' => 'No tienes permiso para editar esta cita'], 403);
        }
        if ($user->tipo_usuario === 'medico' && $appointment->doctor_id !== $user->id) {
            return response()->json(['message' => 'No tienes permiso para editar esta cita'], 403);
        }

        try {
            if ($user->tipo_usuario === 'medico') {
                $validated = $request->validate(['status' => 'required|in:realizada']);
                $appointment->update(['status' => $validated['status']]);
            } else {
                $validated = $request->validate([
                    'doctor_id'        => 'sometimes|exists:users,id',
                    'especialidad'     => 'sometimes|string',
                    'appointment_type' => 'sometimes|string',
                    'date'             => 'sometimes|date|after_or_equal:today',
                    'time'             => ['sometimes', 'regex:/^\d{2}:\d{2}(:\d{2})?$/'],
                    'reason'           => 'sometimes|string',
                    'notes'            => 'nullable|string',
                ]);

                if (isset($validated['time'])) {
                    $validated['time'] = substr($validated['time'], 0, 5);
                }

                // Validar que la nueva fecha/hora no sea pasada
                if (isset($validated['date']) || isset($validated['time'])) {
                    $checkDate = $validated['date'] ?? $appointment->date->format('Y-m-d');
                    $checkTime = $validated['time'] ?? substr($appointment->time, 0, 5);
                    [$h, $m]   = explode(':', $checkTime);
                    $newDT     = Carbon::parse($checkDate)->setHour((int)$h)->setMinute((int)$m)->setSecond(0);

                    if ($newDT->lessThanOrEqualTo(Carbon::now()->addMinutes(30))) {
                        return response()->json([
                            'message' => 'No puedes mover la cita a una fecha/hora pasada o con menos de 30 minutos de anticipación.',
                        ], 422);
                    }
                }

                // Verificar conflicto de slot excluyendo la cita actual
                if (isset($validated['date']) || isset($validated['time']) || isset($validated['doctor_id'])) {
                    $checkDate   = $validated['date']      ?? $appointment->date->format('Y-m-d');
                    $checkTime   = $validated['time']      ?? substr($appointment->time, 0, 5);
                    $checkDoctor = $validated['doctor_id'] ?? $appointment->doctor_id;

                    $conflict = Appointment::where('doctor_id', $checkDoctor)
                        ->whereDate('date', $checkDate)
                        ->whereRaw("LEFT(time, 5) = ?", [$checkTime])
                        ->where('status', 'pendiente')
                        ->where('id', '!=', $appointment->id)
                        ->exists();

                    if ($conflict) {
                        return response()->json([
                            'message' => 'Ese horario ya está ocupado. Por favor selecciona otro.',
                        ], 409);
                    }
                }

                $appointment->update($validated);
            }

            return response()->json([
                'message' => 'Cita actualizada correctamente',
                'data'    => $appointment->fresh(['patient:id,name,last_name', 'doctor:id,name,last_name,especialidad']),
            ]);

        } catch (\Exception $e) {
            return response()->json(['message' => 'Error al actualizar', 'error' => $e->getMessage()], 500);
        }
    }

    public function uploadAttachment(Request $request, $id)
    {
        $user        = $request->user();
        $appointment = Appointment::findOrFail($id);

        if ($user->tipo_usuario !== 'paciente' || $appointment->patient_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $request->validate(['attachment' => 'required|file|max:10240|mimes:pdf,jpg,jpeg,png,doc,docx']);

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

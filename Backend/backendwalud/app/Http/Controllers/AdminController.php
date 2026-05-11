<?php
namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Appointment;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AdminController extends Controller
{
    private function checkAdmin(Request $request)
    {
        if (!$request->user() || !$request->user()->hasRole('admin')) {
            return response()->json(['message' => 'Acceso denegado. Solo administradores.'], 403);
        }
        return null;
    }

    public function stats(Request $request)
    {
        if ($deny = $this->checkAdmin($request)) return $deny;

        return response()->json([
            'total_usuarios'        => User::count(),
            'medicos_activos'       => User::whereHas('roles', fn($q) => $q->where('name', 'medico'))->count(),
            'pacientes_registrados' => User::whereHas('roles', fn($q) => $q->where('name', 'paciente'))->count(),
            'cuentas_pendientes'    => User::where('is_active', false)->count(),
            'total_citas'           => Appointment::count(),
            'citas_pendientes'      => Appointment::where('status', 'pendiente')->count(),
            'citas_realizadas'      => Appointment::where('status', 'realizada')->count(),
            'ingresos_totales'      => Payment::where('estado_pago', 'completado')->sum('monto'),
        ]);
    }

    // Listar usuarios — filtro por rol funciona correctamente
    public function indexUsers(Request $request)
    {
        if ($deny = $this->checkAdmin($request)) return $deny;

        $query = User::with('roles');

        if ($request->filled('rol')) {
            $query->whereHas('roles', fn($q) => $q->where('name', $request->rol));
        }
        if ($request->has('is_active')) {
            $query->where('is_active', $request->boolean('is_active'));
        }
        if ($request->filled('search')) {
            $s = $request->search;
            $query->where(function ($q) use ($s) {
                $q->where('name',      'like', "%$s%")
                  ->orWhere('last_name','like', "%$s%")
                  ->orWhere('email',   'like', "%$s%")
                  ->orWhere('document','like', "%$s%");
            });
        }

        return response()->json($query->orderBy('created_at', 'desc')->paginate(15));
    }

    public function showUser(Request $request, $id)
    {
        if ($deny = $this->checkAdmin($request)) return $deny;
        return response()->json(User::with('roles')->findOrFail($id));
    }

    public function createUser(Request $request)
    {
        if ($deny = $this->checkAdmin($request)) return $deny;

        $validated = $request->validate([
            'document'       => 'required|numeric|unique:users',
            'tipo_documento' => 'required|in:cedula_ciudadania,tarjeta_identidad,registro_civil,cedula_extranjeria,carne_diplomatico,pasaporte,permiso_especial_permanencia,permiso_proteccion_temporal',
            'name'           => 'required|string|max:100',
            'last_name'      => 'required|string|max:100',
            'email'          => 'required|email|unique:users',
            'password'       => 'required|min:6',
            'birth_date'     => 'nullable|date',
            'phone'          => 'nullable|string|max:20',
            'genero'         => 'nullable|in:masculino,femenino,otro,prefiero_no_decir',
            'tipo_sangre'    => 'nullable|in:A+,A-,B+,B-,AB+,AB-,O+,O-,desconocido',
            'alergias'       => 'nullable|string',
            'rol'            => 'required|in:paciente,medico,admin',
            'especialidad'   => 'nullable|string',
            'is_active'      => 'nullable|boolean',
        ]);

        $user = User::create([
            'document'       => (int) $validated['document'],
            'tipo_documento' => $validated['tipo_documento'],
            'name'           => $validated['name'],
            'last_name'      => $validated['last_name'],
            'email'          => $validated['email'],
            'password'       => Hash::make($validated['password']),
            'tipo_usuario'   => $validated['rol'],
            'birth_date'     => $validated['birth_date']  ?? null,
            'phone'          => $validated['phone']        ?? null,
            'genero'         => $validated['genero']       ?? null,
            'tipo_sangre'    => $validated['tipo_sangre']  ?? null,
            'alergias'       => $validated['alergias']     ?? null,
            'especialidad'   => $validated['especialidad'] ?? null,
            'is_active'      => $validated['is_active']    ?? true,
        ]);

        $user->assignRole($validated['rol']);

        return response()->json([
            'message' => 'Usuario creado correctamente',
            'user'    => $user->load('roles'),
        ], 201);
    }

    public function updateUser(Request $request, $id)
    {
        if ($deny = $this->checkAdmin($request)) return $deny;

        $user      = User::findOrFail($id);
        $validated = $request->validate([
            'name'         => 'sometimes|string|max:100',
            'last_name'    => 'sometimes|string|max:100',
            'email'        => 'sometimes|email|unique:users,email,' . $id,
            'birth_date'   => 'sometimes|date',
            'phone'        => 'nullable|string|max:20',
            'genero'       => 'nullable|in:masculino,femenino,otro,prefiero_no_decir',
            'tipo_sangre'  => 'nullable|in:A+,A-,B+,B-,AB+,AB-,O+,O-,desconocido',
            'alergias'     => 'nullable|string',
            'especialidad' => 'nullable|string',
            'is_active'    => 'sometimes|boolean',
        ]);

        $user->update($validated);

        return response()->json([
            'message' => 'Usuario actualizado correctamente',
            'user'    => $user->fresh()->load('roles'),
        ]);
    }

    public function assignRole(Request $request, $id)
    {
        if ($deny = $this->checkAdmin($request)) return $deny;

        $request->validate([
            'rol'          => 'required|in:paciente,medico,admin',
            'especialidad' => 'nullable|string',
        ]);

        $user = User::findOrFail($id);
        $user->syncRoles([$request->rol]);
        $user->update([
            'tipo_usuario' => $request->rol,
            'especialidad' => $request->especialidad ?? $user->especialidad,
        ]);

        return response()->json([
            'message' => "Rol '{$request->rol}' asignado correctamente",
            'user'    => $user->fresh()->load('roles'),
        ]);
    }

    public function toggleActive(Request $request, $id)
    {
        if ($deny = $this->checkAdmin($request)) return $deny;

        $user = User::findOrFail($id);
        $user->update(['is_active' => !$user->is_active]);

        return response()->json([
            'message'   => $user->is_active ? 'Cuenta activada' : 'Cuenta desactivada',
            'is_active' => $user->is_active,
        ]);
    }

    public function deleteUser(Request $request, $id)
    {
        if ($deny = $this->checkAdmin($request)) return $deny;

        $user = User::findOrFail($id);
        Appointment::where('patient_id', $id)->orWhere('doctor_id', $id)->delete();
        $user->delete();

        return response()->json(['message' => 'Usuario eliminado correctamente']);
    }

    // Citas con búsqueda por documento del paciente
    public function indexAppointments(Request $request)
    {
        if ($deny = $this->checkAdmin($request)) return $deny;

        $query = Appointment::with([
            'patient:id,name,last_name,document',
            'doctor:id,name,last_name,especialidad',
        ]);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        // Búsqueda por documento o nombre del paciente
        if ($request->filled('search')) {
            $s = $request->search;
            $query->where(function ($q) use ($s) {
                $q->where('patient_document', 'like', "%$s%")
                  ->orWhere('patient_name',   'like', "%$s%");
            });
        }

        return response()->json($query->orderBy('date', 'asc')->paginate(20));
    }

    public function cancelAppointment(Request $request, $id)
    {
        if ($deny = $this->checkAdmin($request)) return $deny;

        $appointment = Appointment::findOrFail($id);
        $appointment->update(['status' => 'cancelada']);

        return response()->json(['message' => 'Cita cancelada por el administrador']);
    }

    public function indexPayments(Request $request)
    {
        if ($deny = $this->checkAdmin($request)) return $deny;

        $query = Payment::with([
            'patient:id,name,last_name',
            'appointment:id,date,time,especialidad',
        ]);

        if ($request->filled('estado_pago')) {
            $query->where('estado_pago', $request->estado_pago);
        }

        return response()->json($query->orderBy('created_at', 'desc')->paginate(20));
    }

    public function paymentStats(Request $request)
    {
        if ($deny = $this->checkAdmin($request)) return $deny;

        return response()->json([
            'total_completado' => Payment::where('estado_pago', 'completado')->sum('monto'),
            'total_pendiente'  => Payment::where('estado_pago', 'pendiente')->sum('monto'),
            'total_cancelado'  => Payment::where('estado_pago', 'cancelado')->sum('monto'),
            'count_completado' => Payment::where('estado_pago', 'completado')->count(),
            'count_pendiente'  => Payment::where('estado_pago', 'pendiente')->count(),
            'count_cancelado'  => Payment::where('estado_pago', 'cancelado')->count(),
        ]);
    }
}

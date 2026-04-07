<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $query = User::query();

        if ($request->has('tipo_usuario')) {
            $query->where('tipo_usuario', $request->tipo_usuario);
        }
        if ($request->has('especialidad')) {
            $query->where('especialidad', $request->especialidad);
        }

        $users = $query->select('id', 'name', 'last_name', 'email', 'tipo_usuario', 'document', 'especialidad')->get();

        return response()->json($users);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name'         => 'required',
            'document'     => 'required|unique:users',
            'last_name'    => 'required',
            'email'        => 'required|email|unique:users',
            'password'     => 'required|min:6',
            'tipo_usuario' => 'required|in:paciente,medico',
            'birth_date'   => 'nullable|date',
            'especialidad' => 'nullable|string',
        ]);

        $user = User::create([
            'document'     => $request->document,
            'name'         => $request->name,
            'last_name'    => $request->last_name,
            'email'        => $request->email,
            'password'     => Hash::make($request->password),
            'tipo_usuario' => $request->tipo_usuario,
            'birth_date'   => $request->birth_date,
            'especialidad' => $request->especialidad,
        ]);

        $user->assignRole($request->tipo_usuario);

        return response()->json($user, 201);
    }

    public function show($id)
    {
        $user = User::select('id', 'name', 'email', 'tipo_usuario', 'document', 'last_name', 'especialidad')
            ->findOrFail($id);

        return response()->json($user);
    }

    public function update(Request $request, $id)
    {
        $user      = User::findOrFail($id);
        $validated = $request->validate([
            'name'         => 'sometimes|required',
            'document'     => 'sometimes|required|unique:users,document,' . $id,
            'last_name'    => 'sometimes|required',
            'email'        => 'sometimes|required|email|unique:users,email,' . $id,
            'tipo_usuario' => 'sometimes|required|in:paciente,medico',
            'birth_date'   => 'nullable|date',
            'especialidad' => 'nullable|string',
        ]);

        $user->update($validated);

        return response()->json($user);
    }

    public function destroy($id)
    {
        User::destroy($id);
        return response()->json(['message' => 'Usuario eliminado']);
    }

    public function searchByDocument(Request $request)
    {
        try {
            $request->validate([
                'document'       => 'required|string',
                'tipo_documento' => 'required|in:cedula_ciudadania,tarjeta_identidad,registro_civil,cedula_extranjeria,carne_diplomatico,pasaporte,permiso_especial_permanencia,permiso_proteccion_temporal',
            ]);

            $patient = User::where('document', $request->document)
                ->where('tipo_documento', $request->tipo_documento)
                ->where('tipo_usuario', 'paciente')
                ->select('id', 'name', 'last_name', 'email', 'document', 'tipo_documento', 'birth_date', 'tipo_usuario')
                ->first();

            if (!$patient) {
                return response()->json(['success' => false, 'message' => 'Paciente no encontrado'], 404);
            }

            return response()->json(['success' => true, 'patient' => $patient]);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Error: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Médicos disponibles por especialidad
     */
    public function doctorsBySpecialty($especialidad)
    {
        $doctors = User::where('tipo_usuario', 'medico')
            ->where('especialidad', $especialidad)
            ->select('id', 'name', 'last_name', 'especialidad')
            ->get();

        return response()->json(['success' => true, 'doctors' => $doctors]);
    }
}

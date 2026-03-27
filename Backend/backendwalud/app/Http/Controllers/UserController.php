<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    // LISTAR
    public function index(Request $request)
{
    $query = User::query();

    // Filtrar por tipo_usuario si se proporciona
    if ($request->has('tipo_usuario')) {
        $query->where('tipo_usuario', $request->tipo_usuario);
    }

    // Ocultar campos sensibles
    $users = $query->select('id', 'name', 'last_name', 'email', 'tipo_usuario', 'document')->get();

    return response()->json($users);
}

    // CREAR
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'document' => 'required|unique:users',
            'last_name' => 'required',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:6',
            'tipo_usuario' => 'required',
            'birth_date' => 'nullable|date'
        ]);

        $user = User::create([
            'document' => $request->document,
            'name' => $request->name,
            'last_name' => $request->last_name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'tipo_usuario' => $request->tipo_usuario,
            'birth_date' => $request->birth_date
        ]);

        $user->assignRole($request->tipo_usuario);
        return response()->json($user, 201);
    }

    // VER UNO
    public function show($id)
    {
        $user = User::select('id', 'name', 'email', 'tipo_usuario', 'document', 'last_name')
            ->findOrFail($id);

        return response()->json($user);
    }

    // ACTUALIZAR
    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);

         $validated = $request->validate([
            'name' => 'sometimes|required',
            'document' => 'sometimes|required|unique:users,document,' . $id,
            'last_name' => 'sometimes|required',
            'email' => 'sometimes|required|email|unique:users,email,' . $id,
            'tipo_usuario' => 'sometimes|required|in:paciente,medico',
            'birth_date' => 'nullable|date'
        ]);

        $user->update($validated);

        return response()->json($user);
    }

    // ELIMINAR
    public function destroy($id)
    {
        User::destroy($id);

        return response()->json([
            'message' => 'Usuario eliminado'
        ]);
    }
}

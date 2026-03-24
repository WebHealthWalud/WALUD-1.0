<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    // LISTAR
    public function index()
    {
        return User::all();
    }

    // CREAR
    public function store(Request $request)
    {
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'tipo_usuario' => $request->tipo_usuario
        ]);
        $user->assignRole($request->tipo_usuario);
        return response()->json($user, 201);
    }

    // VER UNO
    public function show($id)
    {
        return User::findOrFail($id);
    }

    // ACTUALIZAR
    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $user->update($request->all());

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
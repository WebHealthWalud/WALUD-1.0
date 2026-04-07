<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $rules = [
            'document'       => 'required|numeric|unique:users',
            'tipo_documento' => 'required|in:cedula_ciudadania,tarjeta_identidad,registro_civil,cedula_extranjeria,carne_diplomatico,pasaporte,permiso_especial_permanencia,permiso_proteccion_temporal',
            'name'           => 'required|string',
            'last_name'      => 'required|string',
            'email'          => 'required|email|unique:users',
            'password'       => 'required|min:6|confirmed',
            'birth_date'     => 'required|date',
            'tipo_usuario'   => 'required|in:paciente,medico',
        ];

        // Especialidad obligatoria solo para médicos
        if ($request->tipo_usuario === 'medico') {
            $rules['especialidad'] = 'required|in:medicina_general,psicologia,psiquiatria,dermatologia,nutricion_dietetica,pediatria,ginecologia,medicina_interna,endocrinologia,cardiologia';
        }

        $request->validate($rules);

        $user = User::create([
            'document'      => (int) $request->document,
            'tipo_documento'=> $request->tipo_documento,
            'name'          => $request->name,
            'last_name'     => $request->last_name,
            'email'         => $request->email,
            'birth_date'    => $request->birth_date,
            'password'      => Hash::make($request->password),
            'tipo_usuario'  => $request->tipo_usuario,
            'especialidad'  => $request->tipo_usuario === 'medico' ? $request->especialidad : null,
        ]);

        $user->assignRole($request->tipo_usuario);

        $token = $user->createToken('token', ['*'], now()->addDays(7))->plainTextToken;

        return response()->json([
            'message' => 'Usuario registrado exitosamente',
            'user'    => $user,
            'token'   => $token,
        ], 201);
    }

    public function login(Request $request)
    {
        if (!Auth::attempt($request->only('email', 'password'))) {
            return response()->json(['message' => 'Credenciales incorrectas'], 401);
        }

        $user  = Auth::user();
        $token = $user->createToken('token', ['*'], now()->addDays(7))->plainTextToken;

        return response()->json([
            'message' => 'Login exitoso',
            'token'   => $token,
            'user'    => $user,
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->tokens()->delete();
        return response()->json(['message' => 'Logout exitoso']);
    }

    public function me(Request $request)
    {
        return response()->json($request->user());
    }
}

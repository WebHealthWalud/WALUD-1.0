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
            'name'           => 'required|string|max:100',
            'last_name'      => 'required|string|max:100',
            'email'          => 'required|email|unique:users',
            'password'       => [
                'required',
                'confirmed',
                'min:8',
                'regex:/[A-Z]/',      // al menos una mayúscula
                'regex:/[a-z]/',      // al menos una minúscula
                'regex:/[0-9]/',      // al menos un número
                'regex:/[!@#$%^&*(),.?":{}|<>_\-]/', // al menos un especial
            ],
            'birth_date'     => 'required|date',
            'tipo_usuario'   => 'required|in:paciente,medico',
        ];

        // ✅ Especialidad obligatoria para médicos — string simple, no ENUM
        if ($request->tipo_usuario === 'medico') {
            $rules['especialidad'] = 'required|string|in:medicina_general,psicologia,psiquiatria,dermatologia,nutricion_dietetica,pediatria,ginecologia,medicina_interna,endocrinologia,cardiologia';
        }

        $validated = $request->validate($rules, [
            'password.regex' => 'La contraseña debe incluir mayúsculas, minúsculas, números y caracteres especiales.',
        ]);

        // ✅ Solo asignar especialidad si es médico
        $especialidad = ($validated['tipo_usuario'] === 'medico')
            ? $validated['especialidad']
            : null;

        $user = User::create([
            'document'       => (int) $validated['document'],
            'tipo_documento' => $validated['tipo_documento'],
            'name'           => $validated['name'],
            'last_name'      => $validated['last_name'],
            'email'          => $validated['email'],
            'birth_date'     => $validated['birth_date'],
            'password'       => Hash::make($validated['password']),
            'tipo_usuario'   => $validated['tipo_usuario'],
            'especialidad'   => $especialidad,   // ✅ guardado explícitamente
        ]);

        $user->assignRole($validated['tipo_usuario']);

        $token = $user->createToken('token', ['*'], now()->addDays(7))->plainTextToken;

        return response()->json([
            'message' => 'Usuario registrado exitosamente',
            'user'    => $user,
            'token'   => $token,
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required',
        ]);

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
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
                'regex:/[A-Z]/',
                'regex:/[a-z]/',
                'regex:/[0-9]/',
                'regex:/[!@#$%^&*(),.?":{}|<>_\-]/',
            ],
            'birth_date'           => 'required|date',
            'phone'                => 'required|string|max:20',
            'genero'               => 'required|in:masculino,femenino,otro,prefiero_no_decir',
            'tipo_sangre'          => 'nullable|in:A+,A-,B+,B-,AB+,AB-,O+,O-,desconocido',
            'alergias'             => 'nullable|string|max:500',
            'notificaciones_email' => 'nullable|boolean',
            'notificaciones_sms'   => 'nullable|boolean',
        ];

        $validated = $request->validate($rules, [
            'password.regex' => 'La contraseña debe incluir mayúsculas, minúsculas, números y caracteres especiales.',
        ]);

        $user = User::create([
            'document'             => (int) $validated['document'],
            'tipo_documento'       => $validated['tipo_documento'],
            'name'                 => $validated['name'],
            'last_name'            => $validated['last_name'],
            'email'                => $validated['email'],
            'birth_date'           => $validated['birth_date'],
            'password'             => Hash::make($validated['password']),
            'tipo_usuario'         => 'paciente', // default, el admin puede promover
            'phone'                => $validated['phone'],
            'genero'               => $validated['genero'],
            'tipo_sangre'          => $validated['tipo_sangre'] ?? null,
            'alergias'             => $validated['alergias'] ?? null,
            'notificaciones_email' => $validated['notificaciones_email'] ?? true,
            'notificaciones_sms'   => $validated['notificaciones_sms'] ?? false,
            'is_active'            => true,
        ]);

        // Asignar rol 'paciente' por defecto (el admin puede cambiar a 'medico')
        $user->assignRole('paciente');

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

        $user = User::where('email', $request->email)->first();

        // Verificar si la cuenta está activa
        if ($user && !$user->is_active) {
            return response()->json(['message' => 'Tu cuenta está desactivada. Contacta al administrador.'], 403);
        }

        if (!Auth::attempt($request->only('email', 'password'))) {
            return response()->json(['message' => 'Credenciales incorrectas'], 401);
        }

        $user  = Auth::user();
        $token = $user->createToken('token', ['*'], now()->addDays(7))->plainTextToken;

        // Incluir roles en la respuesta
        $userData = $user->toArray();
        $userData['roles'] = $user->getRoleNames();
        $userData['tipo_from_role'] = $user->tipo_from_role;

        return response()->json([
            'message' => 'Login exitoso',
            'token'   => $token,
            'user'    => $userData,
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->tokens()->delete();
        return response()->json(['message' => 'Logout exitoso']);
    }

    public function me(Request $request)
    {
        $user = $request->user();
        $userData = $user->toArray();
        $userData['roles'] = $user->getRoleNames();
        $userData['tipo_from_role'] = $user->tipo_from_role;
        return response()->json($userData);
    }
}

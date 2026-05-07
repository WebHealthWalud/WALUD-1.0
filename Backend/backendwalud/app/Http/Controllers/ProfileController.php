<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    // ── Ver perfil del usuario autenticado
    public function show(Request $request)
    {
        $user = $request->user();
        return response()->json([
            'success' => true,
            'data'    => $this->formatUser($user),
        ]);
    }

    // ── Actualizar datos personales
    public function update(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name'       => 'sometimes|string|max:100',
            'last_name'  => 'sometimes|string|max:100',
            'email'      => 'sometimes|email|unique:users,email,' . $user->id,
            'birth_date' => 'sometimes|date',
            'phone'      => 'nullable|string|max:20',
        ]);

        $user->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Perfil actualizado correctamente',
            'data'    => $this->formatUser($user->fresh()),
        ]);
    }

    // ── Subir foto de perfil
    public function uploadPhoto(Request $request)
{
    $request->validate([
        'photo' => 'required|file|max:5120|mimes:jpg,jpeg,png,webp',
    ]);

    $user = $request->user();

    if ($user->profile_photo_path) {
        Storage::disk('public')->delete($user->profile_photo_path);
    }

    $file = $request->file('photo');
    $path = $file->store('profile_photos', 'public');
    $filename = basename($path);

    $user->update(['profile_photo_path' => $path]);

    // ✅ URL a través de la API, no de storage directo
    $apiUrl = url("api/image/profile_photos/{$filename}");

    return response()->json([
        'success' => true,
        'message' => 'Foto de perfil actualizada',
        'photo_url' => $apiUrl,
    ]);
}

    // ── Cambiar contraseña
    public function changePassword(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'current_password'          => 'required|string',
            'password'                  => [
                'required', 'confirmed', 'min:8',
                'regex:/[A-Z]/',
                'regex:/[a-z]/',
                'regex:/[0-9]/',
                'regex:/[!@#$%^&*(),.?":{}|<>_\-]/',
            ],
        ], [
            'password.regex' => 'La contraseña debe incluir mayúsculas, minúsculas, números y caracteres especiales.',
        ]);

        // Verificar contraseña actual
        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'La contraseña actual es incorrecta',
            ], 422);
        }

        $user->update(['password' => Hash::make($request->password)]);

        return response()->json([
            'success' => true,
            'message' => 'Contraseña actualizada correctamente',
        ]);
    }

    // ── Eliminar foto de perfil
    public function deletePhoto(Request $request)
    {
        $user = $request->user();

        if ($user->profile_photo_path) {
            Storage::disk('public')->delete($user->profile_photo_path);
            $user->update(['profile_photo_path' => null]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Foto de perfil eliminada',
        ]);
    }

    private function formatUser($user): array
{
    $photoUrl = null;
    if ($user->profile_photo_path) {
        $filename = basename($user->profile_photo_path);
        $photoUrl = url("api/image/profile_photos/{$filename}");
    }

    return [
        'id'                 => $user->id,
        'name'               => $user->name,
        'last_name'          => $user->last_name,
        'email'              => $user->email,
        'document'           => $user->document,
        'tipo_documento'     => $user->tipo_documento,
        'birth_date'         => $user->birth_date,
        'phone'              => $user->phone,
        'tipo_usuario'       => $user->tipo_usuario,
        'especialidad'       => $user->especialidad,
        'profile_photo_path' => $user->profile_photo_path,
        'photo_url'          => $photoUrl, // ✅ URL via API
    ];
}
}
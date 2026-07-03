<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use App\Services\CloudinaryService;

class ProfileController extends Controller
{
    protected CloudinaryService $cloudinary;

    public function __construct(CloudinaryService $cloudinary)
    {
        $this->cloudinary = $cloudinary;
    }

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

    // ── Subir foto de perfil (Cloudinary)
    public function uploadPhoto(Request $request)
    {
        $request->validate([
            'photo' => 'required|file|max:5120|mimes:jpg,jpeg,png,webp',
        ]);

        $user = $request->user();

        try {
            $result = $this->cloudinary->upload(
                $request->file('photo'),
                'walud/profile_photos',
                'image'
            );
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }

        // Borrar la foto anterior en Cloudinary, si existía
        if ($user->profile_photo_public_id) {
            $this->cloudinary->destroy($user->profile_photo_public_id, 'image');
        }

        $user->update([
            'profile_photo_path'      => $result['secure_url'],
            'profile_photo_public_id' => $result['public_id'],
        ]);

        return response()->json([
            'success'   => true,
            'message'   => 'Foto de perfil actualizada',
            'photo_url' => $result['secure_url'],
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

    // ── Eliminar foto de perfil (Cloudinary)
    public function deletePhoto(Request $request)
    {
        $user = $request->user();

        if ($user->profile_photo_public_id) {
            $this->cloudinary->destroy($user->profile_photo_public_id, 'image');
        }

        $user->update([
            'profile_photo_path'      => null,
            'profile_photo_public_id' => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Foto de perfil eliminada',
        ]);
    }

    private function formatUser($user): array
    {
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
            // ✅ profile_photo_path ya es la URL completa de Cloudinary
            'photo_url'          => $user->profile_photo_path,
        ];
    }
}
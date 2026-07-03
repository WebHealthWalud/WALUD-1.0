<?php

namespace App\Http\Controllers;

use App\Models\PatientProfile;
use App\Models\PatientDocument;
use Illuminate\Http\Request;
use App\Services\CloudinaryService;

class PatientProfileController extends Controller
{
    protected CloudinaryService $cloudinary;

    public function __construct(CloudinaryService $cloudinary)
    {
        $this->cloudinary = $cloudinary;
    }

    // ── Ver perfil del paciente autenticado
    public function show(Request $request)
    {
        $user    = $request->user();
        $profile = $user->patientProfile;

        if (!$profile) {
            $profile = PatientProfile::create(['user_id' => $user->id]);
        }

        return response()->json([
            'success' => true,
            'data'    => array_merge(
                $user->only(['id', 'name', 'last_name', 'email', 'document',
                             'tipo_documento', 'birth_date', 'phone',
                             'genero', 'tipo_sangre', 'alergias']),
                $profile->toArray(),
                ['perfil_completo' => $profile->checkIfComplete()]
            ),
        ]);
    }

    // ── Completar perfil (peso, talla, dirección, contacto emergencia, datos médicos)
    public function update(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'peso'                          => 'nullable|numeric|min:1|max:500',
            'talla'                         => 'nullable|numeric|min:0.5|max:3',
            'direccion'                     => 'nullable|string|max:255',
            'ciudad'                        => 'nullable|string|max:100',
            'contacto_emergencia_nombre'    => 'nullable|string|max:100',
            'contacto_emergencia_telefono'  => 'nullable|string|max:20',
            'contacto_emergencia_relacion'  => 'nullable|string|max:50',
            'genero'                        => 'nullable|string|max:30',
            'tipo_sangre'                   => 'nullable|string|max:10',
            'alergias'                      => 'nullable|string|max:500',
        ]);

        // Campos que pertenecen al usuario (no al perfil médico)
        $userFields = collect($validated)->only(['genero', 'tipo_sangre', 'alergias'])->toArray();
        if (!empty($userFields)) {
            $user->update($userFields);
        }

        $profileFields = collect($validated)->except(['genero', 'tipo_sangre', 'alergias'])->toArray();

        $profile = $user->patientProfile ?? PatientProfile::create(['user_id' => $user->id]);
        $profile->update($profileFields);

        // ✅ Actualizar perfil_completo automáticamente
        $profile->update(['perfil_completo' => $profile->checkIfComplete()]);

        return response()->json([
            'success' => true,
            'message' => 'Perfil actualizado correctamente',
            'data'    => $profile->fresh(),
            'perfil_completo' => $profile->fresh()->checkIfComplete(),
        ]);
    }

    // ── Subir documento médico (Cloudinary)
    public function uploadDocument(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'documento' => 'required|file|max:10240|mimes:pdf,jpg,jpeg,png,doc,docx',
            'nombre'    => 'required|string|max:255',
            'tipo'      => 'nullable|string|max:50',
        ]);

        $file = $request->file('documento');

        try {
            $result = $this->cloudinary->upload(
                $file,
                'walud/patient_documents/' . $user->id,
                'auto'
            );
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }

        $doc = PatientDocument::create([
            'user_id'              => $user->id,
            'nombre'               => $request->nombre,
            'tipo'                 => $request->tipo ?? 'general',
            'archivo_path'         => $result['secure_url'],
            'cloudinary_public_id' => $result['public_id'],
            'archivo_nombre'       => $file->getClientOriginalName(),
            'mime_type'            => $file->getMimeType(),
            'tamanio'              => $file->getSize(),
        ]);

        return response()->json([
            'success'  => true,
            'message'  => 'Documento subido correctamente',
            'data'     => array_merge($doc->toArray(), [
                'archivo_url' => $doc->archivo_path, // ✅ ya es la URL completa de Cloudinary
            ]),
        ], 201);
    }

    // ── Listar documentos del paciente
    public function listDocuments(Request $request)
    {
        $user = $request->user();
        $docs = PatientDocument::where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(fn($d) => array_merge($d->toArray(), [
                'archivo_url' => $d->archivo_path, // ✅ URL directa de Cloudinary
            ]));

        return response()->json(['success' => true, 'data' => $docs]);
    }

    // ── Eliminar documento
    public function deleteDocument($id, Request $request)
    {
        $user = $request->user();
        $doc  = PatientDocument::where('id', $id)
            ->where('user_id', $user->id)
            ->firstOrFail();

        if ($doc->cloudinary_public_id) {
            $resourceType = str_starts_with($doc->mime_type ?? '', 'image/') ? 'image' : 'raw';
            $this->cloudinary->destroy($doc->cloudinary_public_id, $resourceType);
        }

        $doc->delete();

        return response()->json(['success' => true, 'message' => 'Documento eliminado']);
    }
}
<?php

namespace App\Http\Controllers;

use App\Models\PatientProfile;
use App\Models\PatientDocument;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PatientProfileController extends Controller
{
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

    // ── Completar perfil (peso, talla, dirección, contacto emergencia)
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
        ]);

        $profile = $user->patientProfile ?? PatientProfile::create(['user_id' => $user->id]);
        $profile->update($validated);

        // ✅ Actualizar perfil_completo automáticamente
        $profile->update(['perfil_completo' => $profile->checkIfComplete()]);

        return response()->json([
            'success' => true,
            'message' => 'Perfil actualizado correctamente',
            'data'    => $profile->fresh(),
            'perfil_completo' => $profile->fresh()->checkIfComplete(),
        ]);
    }

    // ── Subir documento médico
    public function uploadDocument(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'documento' => 'required|file|max:10240|mimes:pdf,jpg,jpeg,png,doc,docx',
            'nombre'    => 'required|string|max:255',
            'tipo'      => 'nullable|string|max:50',
        ]);

        $file     = $request->file('documento');
        $path     = $file->store('patient_documents/' . $user->id, 'public');
        $filename = $file->getClientOriginalName();
        $mime     = $file->getMimeType();
        $size     = $file->getSize();

        $doc = PatientDocument::create([
            'user_id'        => $user->id,
            'nombre'         => $request->nombre,
            'tipo'           => $request->tipo ?? 'general',
            'archivo_path'   => $path,
            'archivo_nombre' => $filename,
            'mime_type'      => $mime,
            'tamanio'        => $size,
        ]);

        return response()->json([
            'success'  => true,
            'message'  => 'Documento subido correctamente',
            'data'     => array_merge($doc->toArray(), [
                'archivo_url' => url("api/image/patient_documents/{$user->id}/" . basename($path)),
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
                'archivo_url' => url("api/image/patient_documents/{$user->id}/" . basename($d->archivo_path)),
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

        Storage::disk('public')->delete($doc->archivo_path);
        $doc->delete();

        return response()->json(['success' => true, 'message' => 'Documento eliminado']);
    }
}
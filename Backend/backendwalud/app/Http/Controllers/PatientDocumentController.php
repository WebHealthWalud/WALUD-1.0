<?php

namespace App\Http\Controllers;

use App\Models\PatientDocument;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PatientDocumentController extends Controller
{
    // ── Listar documentos del paciente autenticado
    public function index(Request $request)
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

    // ── Subir documento
    public function store(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'documento' => 'required|file|max:10240|mimes:pdf,jpg,jpeg,png,doc,docx',
            'nombre'    => 'required|string|max:255',
            'tipo'      => 'nullable|in:analisis,radiografia,receta,informe,vacuna,otro',
        ]);

        $file     = $request->file('documento');
        $path     = $file->store("patient_documents/{$user->id}", 'public');
        $filename = $file->getClientOriginalName();
        $mime     = $file->getMimeType();
        $size     = $file->getSize();

        $doc = PatientDocument::create([
            'user_id'        => $user->id,
            'nombre'         => $request->nombre,
            'tipo'           => $request->tipo ?? 'otro',
            'archivo_path'   => $path,
            'archivo_nombre' => $filename,
            'mime_type'      => $mime,
            'tamanio'        => $size,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Documento subido correctamente',
            'data'    => array_merge($doc->toArray(), [
                'archivo_url' => url("api/image/patient_documents/{$user->id}/" . basename($path)),
            ]),
        ], 201);
    }

    // ── Ver un documento específico
    public function show($id, Request $request)
    {
        $user = $request->user();
        $doc  = PatientDocument::where('id', $id)
            ->where('user_id', $user->id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'data'    => array_merge($doc->toArray(), [
                'archivo_url' => url("api/image/patient_documents/{$user->id}/" . basename($doc->archivo_path)),
            ]),
        ]);
    }

    // ── Eliminar documento
    public function destroy($id, Request $request)
    {
        $user = $request->user();
        $doc  = PatientDocument::where('id', $id)
            ->where('user_id', $user->id)
            ->firstOrFail();

        // ✅ Eliminar archivo físico del storage
        Storage::disk('public')->delete($doc->archivo_path);
        $doc->delete();

        return response()->json([
            'success' => true,
            'message' => 'Documento eliminado correctamente',
        ]);
    }
}
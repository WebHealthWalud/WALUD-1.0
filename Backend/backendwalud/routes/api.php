<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\AppointmentController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\ProfileController;

// ── Públicas
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login',    [AuthController::class, 'login']);

// ✅ Servir imágenes con CORS correcto — PÚBLICA, sin autenticación
Route::get('/image/{folder}/{filename}', function ($folder, $filename) {
    $path = storage_path("app/public/{$folder}/{$filename}");

    if (!file_exists($path)) {
        return response()->json(['message' => 'Imagen no encontrada'], 404);
    }

    $mimeType = mime_content_type($path);

    return response()->file($path, [
        'Content-Type'                => $mimeType,
        'Access-Control-Allow-Origin' => '*',
        'Cache-Control'               => 'public, max-age=86400',
    ]);
})->where(['folder' => '[a-zA-Z0-9_]+', 'filename' => '[a-zA-Z0-9_.]+']);

// ── Protegidas
Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/me',      [AuthController::class, 'me']);

    // ── Perfil de usuario
    Route::get('/profile',                  [ProfileController::class, 'show']);
    Route::put('/profile',                  [ProfileController::class, 'update']);
    Route::post('/profile/photo',           [ProfileController::class, 'uploadPhoto']);
    Route::delete('/profile/photo',         [ProfileController::class, 'deletePhoto']);
    Route::post('/profile/change-password', [ProfileController::class, 'changePassword']);

    // Usuarios
    Route::get('/users/doctors/by-specialty/{especialidad}', [UserController::class, 'doctorsBySpecialty']);
    Route::post('/users/search-by-document', [UserController::class, 'searchByDocument']);
    Route::apiResource('users', UserController::class);

    // Citas
    Route::get('/appointments/available-slots',      [AppointmentController::class, 'availableSlots']);
    Route::post('/appointments/{id}/attachment',     [AppointmentController::class, 'uploadAttachment']);
    Route::apiResource('appointments', AppointmentController::class);

    // Pagos
    Route::get('/payments/summary',   [PaymentController::class, 'summary']);
    Route::post('/payments/{id}/pay', [PaymentController::class, 'pay']);
    Route::apiResource('payments', PaymentController::class);
});
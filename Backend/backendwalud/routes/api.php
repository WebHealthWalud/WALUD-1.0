<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\AppointmentController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\PatientProfileController;
use App\Http\Controllers\DoctorProfileController;
use App\Http\Controllers\AIController;

// ── Públicas
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

// ✅ Ruta separada para profile_photos
Route::get('/image/profile_photos/{filename}', function ($filename) {

    $path = storage_path("app/public/profile_photos/{$filename}");

    if (!file_exists($path)) {
        return response()->json([
            'message' => 'Imagen no encontrada'
        ], 404);
    }

    $mimeType = mime_content_type($path);

    return response()->file($path, [
        'Content-Type'                => $mimeType,
        'Access-Control-Allow-Origin' => '*',
        'Cache-Control'               => 'public, max-age=86400',
    ]);

})->where('filename', '[a-zA-Z0-9_.]+');


// ✅ Ruta para documentos de pacientes
Route::get('/image/patient_documents/{userId}/{filename}', function ($userId, $filename) {

    $path = storage_path("app/public/patient_documents/{$userId}/{$filename}");

    if (!file_exists($path)) {
        return response()->json([
            'message' => 'Archivo no encontrado'
        ], 404);
    }

    $mimeType = mime_content_type($path);

    return response()->file($path, [
        'Content-Type'                => $mimeType,
        'Access-Control-Allow-Origin' => '*',
        'Cache-Control'               => 'public, max-age=86400',
    ]);

})->where([
    'userId'   => '[0-9]+',
    'filename' => '[a-zA-Z0-9_.]+'
]);


// ── Protegidas
Route::middleware('auth:sanctum')->group(function () {

    // ── Auth
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/me', [AuthController::class, 'me']);

    // ── Perfil general
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);
    Route::post('/profile/photo', [ProfileController::class, 'uploadPhoto']);
    Route::delete('/profile/photo', [ProfileController::class, 'deletePhoto']);
    Route::post('/profile/change-password', [ProfileController::class, 'changePassword']);

    // ── Perfil Paciente
    Route::get('/patient-profile', [PatientProfileController::class, 'show']);
    Route::put('/patient-profile', [PatientProfileController::class, 'update']);
    Route::get('/patient-profile/documents', [PatientProfileController::class, 'listDocuments']);
    Route::post('/patient-profile/documents', [PatientProfileController::class, 'uploadDocument']);
    Route::delete('/patient-profile/documents/{id}', [PatientProfileController::class, 'deleteDocument']);

    // ── Perfil Médico
    Route::get('/doctor-profile', [DoctorProfileController::class, 'show']);
    Route::put('/doctor-profile', [DoctorProfileController::class, 'update']);

    // ── Usuarios
    Route::get('/users/doctors/by-specialty/{especialidad}', [UserController::class, 'doctorsBySpecialty']);
    Route::post('/users/search-by-document', [UserController::class, 'searchByDocument']);
    Route::apiResource('users', UserController::class);

    // ── Citas
    Route::get('/appointments/available-slots', [AppointmentController::class, 'availableSlots']);
    Route::post('/appointments/{id}/attachment', [AppointmentController::class, 'uploadAttachment']);
    Route::apiResource('appointments', AppointmentController::class);

    // ── Pagos
    Route::get('/payments/summary', [PaymentController::class, 'summary']);
    Route::post('/payments/{id}/pay', [PaymentController::class, 'pay']);
    Route::apiResource('payments', PaymentController::class);

    // ── IA
    Route::post('/ia/preconsulta', [AIController::class, 'preconsulta']);

    // ── Admin
    Route::prefix('admin')->group(function () {

        Route::get('/stats', [AdminController::class, 'stats']);

        Route::get('/users', [AdminController::class, 'indexUsers']);
        Route::get('/users/{id}', [AdminController::class, 'showUser']);
        Route::post('/users', [AdminController::class, 'createUser']);
        Route::put('/users/{id}', [AdminController::class, 'updateUser']);
        Route::delete('/users/{id}', [AdminController::class, 'deleteUser']);

        Route::post('/users/{id}/role', [AdminController::class, 'assignRole']);
        Route::post('/users/{id}/toggle-active', [AdminController::class, 'toggleActive']);

        Route::get('/appointments', [AdminController::class, 'indexAppointments']);
        Route::post('/appointments/{id}/cancel', [AdminController::class, 'cancelAppointment']);

        Route::get('/payments', [AdminController::class, 'indexPayments']);
        Route::get('/payments/stats', [AdminController::class, 'paymentStats']);

    });

});
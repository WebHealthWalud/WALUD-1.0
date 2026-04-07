<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\AppointmentController;
use App\Http\Controllers\PaymentController;

// ── Públicas
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login',    [AuthController::class, 'login']);

// ── Protegidas
Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/me',      [AuthController::class, 'me']);

    // Usuarios — rutas específicas ANTES de apiResource
    Route::get('/users/doctors/by-specialty/{especialidad}', [UserController::class, 'doctorsBySpecialty']);
    Route::post('/users/search-by-document', [UserController::class, 'searchByDocument']);
    Route::apiResource('users', UserController::class);

    // Citas — rutas específicas ANTES de apiResource
    // Sin esto, Laravel interpreta "available-slots" como {id} y devuelve 404
    Route::get('/appointments/available-slots', [AppointmentController::class, 'availableSlots']);
    Route::post('/appointments/{id}/attachment', [AppointmentController::class, 'uploadAttachment']);
    Route::apiResource('appointments', AppointmentController::class);

    // Pagos — rutas específicas ANTES de apiResource
    Route::get('/payments/summary',   [PaymentController::class, 'summary']);
    Route::post('/payments/{id}/pay', [PaymentController::class, 'pay']);
    Route::apiResource('payments', PaymentController::class);
});

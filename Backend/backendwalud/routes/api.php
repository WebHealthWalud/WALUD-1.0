<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\AppointmentController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\AIController;

// ── Públicas
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login',    [AuthController::class, 'login']);

// ── Protegidas
Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/me',      [AuthController::class, 'me']);

    // Perfil de usuario
    Route::get('/profile',                    [ProfileController::class, 'show']);
    Route::put('/profile',                    [ProfileController::class, 'update']);
    Route::post('/profile/photo',             [ProfileController::class, 'uploadPhoto']);
    Route::delete('/profile/photo',           [ProfileController::class, 'deletePhoto']);
    Route::post('/profile/change-password',   [ProfileController::class, 'changePassword']);

    // Usuarios
    Route::get('/users/doctors/by-specialty/{especialidad}', [UserController::class, 'doctorsBySpecialty']);
    Route::post('/users/search-by-document',                 [UserController::class, 'searchByDocument']);
    Route::apiResource('users', UserController::class);

    // Citas
    Route::get('/appointments/available-slots',          [AppointmentController::class, 'availableSlots']);
    Route::post('/appointments/{id}/attachment',         [AppointmentController::class, 'uploadAttachment']);
    Route::apiResource('appointments', AppointmentController::class);

    // Pagos
    Route::get('/payments/summary',    [PaymentController::class, 'summary']);
    Route::post('/payments/{id}/pay',  [PaymentController::class, 'pay']);
    Route::apiResource('payments', PaymentController::class);

      // ── RUTAS IA
    Route::post('/ia/preconsulta', [AIController::class, 'preconsulta']);


    // ── RUTAS ADMIN
    Route::prefix('admin')->middleware('auth:sanctum')->group(function () {

        Route::get('/stats',                     [AdminController::class, 'stats']);
        Route::get('/users',                     [AdminController::class, 'indexUsers']);
        Route::get('/users/{id}',                [AdminController::class, 'showUser']);
        Route::post('/users',                    [AdminController::class, 'createUser']);
        Route::put('/users/{id}',                [AdminController::class, 'updateUser']);
        Route::delete('/users/{id}',             [AdminController::class, 'deleteUser']);
        Route::post('/users/{id}/role',          [AdminController::class, 'assignRole']);
        Route::post('/users/{id}/toggle-active', [AdminController::class, 'toggleActive']);
        Route::get('/appointments',              [AdminController::class, 'indexAppointments']);
        Route::post('/appointments/{id}/cancel', [AdminController::class, 'cancelAppointment']);
        Route::get('/payments',                  [AdminController::class, 'indexPayments']);
        Route::get('/payments/stats',            [AdminController::class, 'paymentStats']);
    });
});


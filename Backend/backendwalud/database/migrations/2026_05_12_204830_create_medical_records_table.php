<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('medical_records', function (Blueprint $table) {
            $table->id();

            // Relaciones
            $table->foreignId('patient_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('doctor_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('appointment_id')->nullable()->constrained('appointments')->onDelete('set null');

            // Número de expediente único por paciente
            $table->string('expediente')->unique();

            // Campos clínicos principales
            $table->text('motivo_consulta');
            $table->text('examen_fisico')->nullable();
            $table->string('diagnostico_cie10')->nullable();   // código CIE-10
            $table->string('diagnostico_nombre')->nullable();  // nombre del diagnóstico
            $table->text('diagnostico_descripcion')->nullable();
            $table->text('tratamiento')->nullable();           // medicamentos e indicaciones
            $table->text('observaciones')->nullable();         // notas adicionales del médico
            $table->string('especialidad');

            // Signos vitales opcionales
            $table->decimal('presion_sistolica',  5, 1)->nullable();
            $table->decimal('presion_diastolica', 5, 1)->nullable();
            $table->decimal('frecuencia_cardiaca',5, 1)->nullable();
            $table->decimal('temperatura',        4, 1)->nullable();
            $table->decimal('peso',               5, 2)->nullable();
            $table->decimal('talla',              5, 2)->nullable();
            $table->decimal('saturacion_oxigeno', 5, 1)->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('medical_records');
    }
};
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
   public function up(): void
{
    Schema::create('medical_records', function (Blueprint $table) {
        $table->id();
        $table->foreignId('patient_id')->constrained('users')->onDelete('cascade');
        $table->foreignId('doctor_id')->constrained('users')->onDelete('cascade');
        $table->foreignId('appointment_id')->nullable()->constrained('appointments')->onDelete('set null');
        $table->string('expediente')->unique();
        $table->string('especialidad');
        $table->text('motivo_consulta');
        $table->text('examen_fisico')->nullable();
        $table->string('diagnostico_cie10', 20)->nullable();
        $table->string('diagnostico_nombre', 255)->nullable();
        $table->text('diagnostico_descripcion')->nullable();
        $table->text('tratamiento')->nullable();
        $table->text('observaciones')->nullable();
        $table->decimal('presion_sistolica', 5, 1)->nullable();
        $table->decimal('presion_diastolica', 5, 1)->nullable();
        $table->decimal('frecuencia_cardiaca', 5, 1)->nullable();
        $table->decimal('temperatura', 4, 1)->nullable();
        $table->decimal('peso', 5, 2)->nullable();
        $table->decimal('talla', 4, 2)->nullable();
        $table->decimal('saturacion_oxigeno', 4, 1)->nullable();
        $table->timestamps();
    });
}

public function down(): void
{
    Schema::dropIfExists('medical_records');
}

    /**
     * Reverse the migrations.
     */
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
{
    Schema::create('doctor_profiles', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->onDelete('cascade');
        $table->string('rethus')->nullable();
        $table->json('formacion_academica')->nullable();
        $table->json('areas_enfoque')->nullable();
        $table->json('horarios_atencion')->nullable();
        $table->json('ubicaciones_consulta')->nullable();
        $table->boolean('perfil_completo')->default(false);
        $table->timestamps();
    });
}

public function down(): void
{
    Schema::dropIfExists('doctor_profiles');
}
};

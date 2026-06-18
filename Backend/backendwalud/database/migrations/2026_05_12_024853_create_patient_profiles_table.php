<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
{
    Schema::create('patient_profiles', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->onDelete('cascade');
        $table->string('tipo_sangre')->nullable();
        $table->decimal('peso', 5, 2)->nullable();
        $table->decimal('talla', 5, 2)->nullable();
        $table->text('alergias')->nullable();
        $table->string('direccion')->nullable();
        $table->string('ciudad')->nullable();
        $table->string('contacto_emergencia_nombre')->nullable();
        $table->string('contacto_emergencia_telefono')->nullable();
        $table->string('contacto_emergencia_relacion')->nullable();
        $table->boolean('perfil_completo')->default(false);
        $table->timestamps();
    });
}

public function down(): void
{
    Schema::dropIfExists('patient_profiles');
}
    
    
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
{
    Schema::create('patient_documents', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->onDelete('cascade');
        $table->string('nombre');
        $table->string('tipo')->nullable();
        $table->string('archivo_path');
        $table->string('archivo_nombre');
        $table->string('mime_type')->nullable();
        $table->unsignedBigInteger('tamanio')->nullable();
        $table->timestamps();
    });
}

public function down(): void
{
    Schema::dropIfExists('patient_documents');
}
};

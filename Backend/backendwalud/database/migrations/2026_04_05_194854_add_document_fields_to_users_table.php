<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Agregar tipo_documento 
            if (!Schema::hasColumn('users', 'tipo_documento')) {
                $table->enum('tipo_documento', [
                    'cedula_ciudadania',
                    'tarjeta_identidad',
                    'registro_civil',
                    'cedula_extranjeria',
                    'carne_diplomatico',
                    'pasaporte',
                    'permiso_especial_permanencia',
                    'permiso_proteccion_temporal'
                ])->default('cedula_ciudadania')->after('document');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'tipo_documento')) {
                $table->dropColumn('tipo_documento');
            }
        });
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Primero hacer la columna nullable temporalmente
            $table->string('document')->nullable()->change();
        });

        // Limpiar datos no numéricos
        DB::statement("UPDATE users SET document = NULL WHERE document NOT REGEXP '^[0-9]+$'");

        // Cambiar a BIGINT UNSIGNED
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedBigInteger('document')->change();
        });

        // Agregar tipo_documento
        if (!Schema::hasColumn('users', 'tipo_documento')) {
            Schema::table('users', function (Blueprint $table) {
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
            });
        }
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('tipo_documento');
            $table->string('document')->change();
        });
    }
};

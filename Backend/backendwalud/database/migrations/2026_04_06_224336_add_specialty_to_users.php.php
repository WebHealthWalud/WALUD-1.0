<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->enum('especialidad', [
                'medicina_general',
                'psicologia',
                'psiquiatria',
                'dermatologia',
                'nutricion_dietetica',
                'pediatria',
                'ginecologia',
                'medicina_interna',
                'endocrinologia',
                'cardiologia',
            ])->nullable()->after('tipo_usuario');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('especialidad');
        });
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    // Actualización de tabla (Faltaban campos)
    public function up()
{
    Schema::table('users', function (Blueprint $table) {
            $table->string('document')->unique()->after('id');
            $table->string('last_name')->after('name');
            $table->date('birth_date')->nullable()->after('email');
            $table->string('tipo_usuario')->default('paciente')->after('birth_date');
        });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['document', 'last_name', 'birth_date', 'tipo_usuario']);
        });
    }
};

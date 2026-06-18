<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {

            $table->enum('genero', ['masculino', 'femenino', 'otro', 'prefiero_no_decir'])
                  ->nullable()
                  ->after('birth_date');

            $table->enum('tipo_sangre', ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'desconocido'])
                  ->nullable()
                  ->after('genero');

            $table->text('alergias')
                  ->nullable()
                  ->after('tipo_sangre');

            // Teléfono ya existe como 'phone', pero si no existe lo añadimos
            if (!Schema::hasColumn('users', 'phone')) {
                $table->string('phone', 20)->nullable()->after('email');
            }

            // Verificación de correo y teléfono para notificaciones
            $table->boolean('notificaciones_email')->default(true)->after('alergias');
            $table->boolean('notificaciones_sms')->default(false)->after('notificaciones_email');
            $table->boolean('is_active')->default(true)->after('notificaciones_sms');
            $table->timestamp('phone_verified_at')->nullable()->after('phone');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'genero',
                'tipo_sangre',
                'alergias',
                'notificaciones_email',
                'notificaciones_sms',
                'is_active',
                'phone_verified_at',
            ]);
        });
    }
};

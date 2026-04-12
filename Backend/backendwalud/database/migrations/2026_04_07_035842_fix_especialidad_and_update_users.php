<?php
// database/migrations/xxxx_fix_especialidad_and_update_users.php
// EJECUTAR: php artisan migrate
// Luego actualizar médicos existentes con el seeder de abajo

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Verificar si la columna ya existe; si no, crearla
        if (!Schema::hasColumn('users', 'especialidad')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('especialidad')->nullable()->after('tipo_usuario');
            });
        }

        // ✅ Asegurar que el campo no tenga restricción ENUM que bloquee NULL
        // Si fue creado como ENUM anteriormente, cambiarlo a VARCHAR
        DB::statement("ALTER TABLE users MODIFY COLUMN especialidad VARCHAR(100) NULL DEFAULT NULL");
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('especialidad');
        });
    }
};
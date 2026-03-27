<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('appointments', function (Blueprint $table) {
            // AGREGAR campo 'reason' que usa el frontend
            if (!Schema::hasColumn('appointments', 'reason')) {
                $table->text('reason')->nullable()->after('time');
            }

            // Hacer campos opcionales si el frontend no los envía
            if (Schema::hasColumn('appointments', 'patient_document')) {
                $table->string('patient_document')->nullable()->change();
            }
            if (Schema::hasColumn('appointments', 'patient_name')) {
                $table->string('patient_name')->nullable()->change();
            }
            if (Schema::hasColumn('appointments', 'appointment_type')) {
                $table->string('appointment_type')->nullable()->change();
            }
        });
    }

    public function down(): void
    {
        Schema::table('appointments', function (Blueprint $table) {
            if (Schema::hasColumn('appointments', 'reason')) {
                $table->dropColumn('reason');
            }
            // Revertir a NOT NULL si lo necesitas después
        });
    }
};

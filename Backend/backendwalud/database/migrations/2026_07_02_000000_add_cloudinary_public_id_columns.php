<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'profile_photo_public_id')) {
                $table->string('profile_photo_public_id')->nullable()->after('profile_photo_path');
            }
        });

        Schema::table('patient_documents', function (Blueprint $table) {
            if (!Schema::hasColumn('patient_documents', 'cloudinary_public_id')) {
                $table->string('cloudinary_public_id')->nullable()->after('archivo_path');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('profile_photo_public_id');
        });

        Schema::table('patient_documents', function (Blueprint $table) {
            $table->dropColumn('cloudinary_public_id');
        });
    }
};

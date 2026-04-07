<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('appointment_id')->nullable()->constrained('appointments')->onDelete('set null');
            $table->string('concepto');
            $table->enum('tipo', ['consulta', 'estudio', 'seguro', 'vacuna', 'psicoterapia', 'otro'])->default('consulta');
            $table->decimal('monto', 10, 2);
            $table->enum('estado_pago', ['pendiente', 'completado', 'cancelado', 'reembolsado'])->default('pendiente');
            $table->date('fecha_vencimiento')->nullable();
            $table->date('fecha_pago')->nullable();
            $table->enum('metodo_pago', ['tarjeta_credito', 'tarjeta_debito', 'transferencia', 'efectivo', 'otro'])->nullable();
            $table->string('referencia_pago')->nullable();
            $table->text('notas')->nullable();
            $table->string('factura_path')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};

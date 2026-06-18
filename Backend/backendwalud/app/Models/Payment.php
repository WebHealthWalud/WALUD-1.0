<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    protected $fillable = [
        'patient_id',
        'appointment_id',
        'concepto',
        'tipo',
        'monto',
        'estado_pago',
        'fecha_vencimiento',
        'fecha_pago',
        'metodo_pago',
        'referencia_pago',
        'notas',
        'factura_path',
    ];

    protected $casts = [
        'monto'             => 'decimal:2',
        'fecha_vencimiento' => 'date',
        'fecha_pago'        => 'date',
        'created_at'        => 'datetime',
        'updated_at'        => 'datetime',
    ];

    public function patient()
    {
        return $this->belongsTo(User::class, 'patient_id');
    }

    public function appointment()
    {
        return $this->belongsTo(Appointment::class);
    }
}

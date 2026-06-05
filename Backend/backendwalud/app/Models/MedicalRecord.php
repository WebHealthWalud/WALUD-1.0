<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MedicalRecord extends Model
{
    protected $fillable = [
        'patient_id',
        'doctor_id',
        'appointment_id',
        'expediente',
        'motivo_consulta',
        'examen_fisico',
        'diagnostico_cie10',
        'diagnostico_nombre',
        'diagnostico_descripcion',
        'tratamiento',
        'observaciones',
        'especialidad',
        'presion_sistolica',
        'presion_diastolica',
        'frecuencia_cardiaca',
        'temperatura',
        'peso',
        'talla',
        'saturacion_oxigeno',
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function patient()
    {
        return $this->belongsTo(User::class, 'patient_id');
    }

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function appointment()
    {
        return $this->belongsTo(Appointment::class);
    }

    // Generar número de expediente único
    public static function generateExpediente(): string
    {
        $year   = date('Y');
        $count  = self::whereYear('created_at', $year)->count() + 1;
        return 'WM-' . $year . '-' . str_pad($count, 4, '0', STR_PAD_LEFT);
    }
}
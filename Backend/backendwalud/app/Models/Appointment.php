<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
class Appointment extends Model
{
    protected $fillable = [
        'patient_id',
        'doctor_id',
        'patient_document',
        'patient_name',
        'appointment_type',
        'date',
        'time',
        'status',
        'notes',
        'reason',
    ];

    protected $casts = [
        'date' => 'date',
        'time' => 'datetime:H:i',
    ];

    public function patient()
    {
        return $this->belongsTo(User::class, 'patient_id');
    }

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Models\User;

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
        'date' => 'date:Y-m-d',
        'time' => 'string',
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

    public function getDateTimeAttribute()
    {
        if ($this->date && $this->time) {
            return \Carbon\Carbon::parse("{$this->date} {$this->time}");
        }
        return null;
    }
}

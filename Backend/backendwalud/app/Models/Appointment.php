<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Appointment extends Model
{
    protected $fillable = [
    'patient_id',
    'doctor_id',
    'date',
    'time',
    'status'
];
}

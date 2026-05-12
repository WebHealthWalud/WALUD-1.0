<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DoctorProfile extends Model
{
    protected $fillable = [
        'user_id',
        'rethus',
        'formacion_academica',
        'areas_enfoque',
        'horarios_atencion',
        'ubicaciones_consulta',
        'perfil_completo',
    ];

    protected $casts = [
        'formacion_academica'  => 'array',
        'areas_enfoque'        => 'array',
        'horarios_atencion'    => 'array',
        'ubicaciones_consulta' => 'array',
        'perfil_completo'      => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function checkIfComplete(): bool
    {
        return !empty($this->rethus) &&
               !empty($this->formacion_academica) &&
               !empty($this->areas_enfoque);
    }
}
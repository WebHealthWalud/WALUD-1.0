<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PatientProfile extends Model
{
    protected $fillable = [
        'user_id',
        'tipo_sangre',
        'peso',
        'talla',
        'alergias',
        'direccion',
        'ciudad',
        'contacto_emergencia_nombre',
        'contacto_emergencia_telefono',
        'contacto_emergencia_relacion',
        'perfil_completo',
    ];

    protected $casts = [
        'peso'            => 'decimal:2',
        'talla'           => 'decimal:2',
        'perfil_completo' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // ✅ Verificar si el perfil está completo
    public function checkIfComplete(): bool
    {
        return !empty($this->peso) &&
               !empty($this->talla) &&
               !empty($this->direccion) &&
               !empty($this->contacto_emergencia_nombre) &&
               !empty($this->contacto_emergencia_telefono);
    }
}

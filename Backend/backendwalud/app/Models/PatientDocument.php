<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PatientDocument extends Model
{
    protected $fillable = [
        'user_id',
        'nombre',
        'tipo',
        'archivo_path',
        'cloudinary_public_id',
        'archivo_nombre',
        'mime_type',
        'tamanio',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
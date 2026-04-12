<?php
// app/Models/User.php — versión con campos de perfil

namespace App\Models;

use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasFactory, Notifiable, HasApiTokens, HasRoles;

    protected $guard_name = 'api';

    protected $fillable = [
        'name',
        'last_name',
        'email',
        'password',
        'tipo_usuario',
        'document',
        'tipo_documento',
        'birth_date',
        'especialidad',
        'profile_photo_path',  // ✅ nuevo
        'phone',               // ✅ nuevo
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password'          => 'hashed',
        ];
    }
}
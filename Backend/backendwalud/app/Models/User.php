<?php
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
        'profile_photo_path',
        'phone',
        'genero',
        'tipo_sangre',
        'alergias',
        'notificaciones_email',
        'notificaciones_sms',
        'is_active',
        'phone_verified_at',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at'     => 'datetime',
            'phone_verified_at'     => 'datetime',
            'password'              => 'hashed',
            'notificaciones_email'  => 'boolean',
            'notificaciones_sms'    => 'boolean',
            'is_active'             => 'boolean',
        ];
    }

    // Helper: determinar tipo desde rol Spatie
    public function getTipoFromRoleAttribute(): string
    {
        if ($this->hasRole('admin'))   return 'admin';
        if ($this->hasRole('medico'))  return 'medico';
        return 'paciente';
    }

    // Agrega estos métodos al modelo User existente

public function patientProfile()
{
    return $this->hasOne(PatientProfile::class);
}

public function doctorProfile()
{
    return $this->hasOne(DoctorProfile::class);
}

public function patientDocuments()
{
    return $this->hasMany(PatientDocument::class);
}
}

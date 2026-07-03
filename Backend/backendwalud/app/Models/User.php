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
        'profile_photo_public_id',
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

    // ✅ FIX ROL: forzar que tipo_from_role se incluya SIEMPRE en toArray()/toJson()
    // Sin esto, el accessor existe pero nunca aparece en la respuesta JSON
    // a menos que se agregue manualmente (como hacíamos en AuthController).
    // Con $appends, se incluye automáticamente en TODAS las respuestas.
    protected $appends = ['tipo_from_role'];

    protected function casts(): array
    {
        return [
            'email_verified_at'    => 'datetime',
            'phone_verified_at'    => 'datetime',
            'password'             => 'hashed',
            'notificaciones_email' => 'boolean',
            'notificaciones_sms'   => 'boolean',
            'is_active'            => 'boolean',
        ];
    }

    // ✅ Determina el rol real desde Spatie (no desde tipo_usuario de la BD)
    // Este accessor ahora se incluye automáticamente gracias a $appends.
    // Flutter debe leer 'tipo_from_role' en lugar de 'tipo_usuario'.
    public function getTipoFromRoleAttribute(): string
    {
        if ($this->hasRole('admin'))  return 'admin';
        if ($this->hasRole('medico')) return 'medico';
        return 'paciente';
    }

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

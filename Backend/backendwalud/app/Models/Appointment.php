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
        'especialidad',
        'appointment_type',
        'date',
        'time',
        'status',
        'notes',
        'reason',
        'attachment_path',
        'attachment_name',
        'jitsi_room',        // ← nuevo
    ];

    protected $casts = [
        'date'       => 'date:Y-m-d',
        'time'       => 'string',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ─────────────────────────────────────────────────────────
    //  Relaciones
    // ─────────────────────────────────────────────────────────

    public function patient()
    {
        return $this->belongsTo(User::class, 'patient_id');
    }

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function payment()
    {
        return $this->hasOne(Payment::class);
    }

    // ─────────────────────────────────────────────────────────
    //  Accessors
    // ─────────────────────────────────────────────────────────

    /**
     * Retorna el DateTime combinado de date + time.
     */
    public function getDateTimeAttribute(): ?\Carbon\Carbon
    {
        if ($this->date && $this->time) {
            return \Carbon\Carbon::parse(
                $this->date->format('Y-m-d') . ' ' . $this->time
            );
        }

        return null;
    }

    // ─────────────────────────────────────────────────────────
    //  Helpers de ventana de tiempo para Jitsi
    //
    //  Regla:
    //    - Se puede entrar desde 10 minutos ANTES de la cita
    //    - Se puede entrar hasta 45 minutos DESPUÉS del inicio
    //    (duración estimada de consulta = 45 min)
    // ─────────────────────────────────────────────────────────

    public const MINUTES_BEFORE = 10;   // margen de entrada anticipada
    public const MEETING_DURATION = 45; // duración de la consulta en minutos

    /**
     * Indica si ahora mismo la sala está dentro de la ventana permitida.
     */
    public function isWithinMeetingWindow(): bool
    {
        $apptTime = $this->dateTime;
        if (!$apptTime) return false;

        $now        = \Carbon\Carbon::now();
        $openFrom   = $apptTime->copy()->subMinutes(self::MINUTES_BEFORE);
        $closedFrom = $apptTime->copy()->addMinutes(self::MEETING_DURATION);

        return $now->between($openFrom, $closedFrom);
    }

    /**
     * Minutos que faltan para que abra la sala (negativo = ya abrió).
     */
    public function minutesUntilOpen(): int
    {
        $apptTime = $this->dateTime;
        if (!$apptTime) return PHP_INT_MAX;

        $openFrom = $apptTime->copy()->subMinutes(self::MINUTES_BEFORE);
        return (int) \Carbon\Carbon::now()->diffInMinutes($openFrom, false);
    }

    /**
     * Estado de la ventana: 'not_yet' | 'open' | 'expired'
     */
    public function meetingWindowStatus(): string
    {
        $apptTime = $this->dateTime;
        if (!$apptTime) return 'not_yet';

        $now        = \Carbon\Carbon::now();
        $openFrom   = $apptTime->copy()->subMinutes(self::MINUTES_BEFORE);
        $closedFrom = $apptTime->copy()->addMinutes(self::MEETING_DURATION);

        if ($now->lt($openFrom))   return 'not_yet';
        if ($now->gt($closedFrom)) return 'expired';
        return 'open';
    }
}
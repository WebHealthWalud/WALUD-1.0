<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Confirmación de cita — WALUD</title>
</head>
<body style="margin:0; padding:0; background-color:#F3F4F6; font-family: Arial, Helvetica, sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding: 24px 0;">
        <tr>
            <td align="center">
                <table role="presentation" width="480" cellpadding="0" cellspacing="0"
                       style="background-color:#ffffff; border-radius:12px; overflow:hidden;">
                    <tr>
                        <td style="background-color:#4F46E5; padding:24px; text-align:center;">
                            <span style="color:#ffffff; font-size:22px; font-weight:bold;">WALUD</span>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:28px;">
                            <h2 style="color:#1A1A7A; margin-top:0;">¡Tu cita fue agendada! ✅</h2>
                            <p style="color:#374151; font-size:14px; line-height:1.6;">
                                Hola {{ $appointment->patient_name }}, te confirmamos los detalles de tu cita médica:
                            </p>

                            <table role="presentation" width="100%" cellpadding="8" cellspacing="0"
                                   style="background-color:#F9FAFB; border-radius:10px; margin:16px 0; font-size:14px; color:#374151;">
                                <tr>
                                    <td><strong>Especialidad:</strong></td>
                                    <td>{{ $appointment->especialidad }}</td>
                                </tr>
                                <tr>
                                    <td><strong>Fecha:</strong></td>
                                    <td>{{ \Carbon\Carbon::parse($appointment->date)->translatedFormat('d \d\e F \d\e Y') }}</td>
                                </tr>
                                <tr>
                                    <td><strong>Hora:</strong></td>
                                    <td>{{ $appointment->time }}</td>
                                </tr>
                                <tr>
                                    <td><strong>Médico:</strong></td>
                                    <td>Dr(a). {{ $appointment->doctor?->name }} {{ $appointment->doctor?->last_name }}</td>
                                </tr>
                                <tr>
                                    <td><strong>Motivo:</strong></td>
                                    <td>{{ $appointment->reason }}</td>
                                </tr>
                            </table>

                            <p style="color:#6B7280; font-size:12px; line-height:1.5;">
                                Recuerda ingresar a la plataforma WALUD unos minutos antes de tu consulta.
                                Si necesitas reprogramar o cancelar, hazlo desde la sección "Mis Citas".
                            </p>
                        </td>
                    </tr>
                    <tr>
                        <td style="background-color:#F9FAFB; padding:16px; text-align:center;">
                            <span style="color:#9CA3AF; font-size:11px;">
                                Este es un correo automático de WALUD, tu plataforma de telemedicina. No respondas a este mensaje.
                            </span>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>

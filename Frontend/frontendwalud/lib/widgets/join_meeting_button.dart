import 'dart:html' as html;  // solo Flutter Web
import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../services/jitsi_service.dart';

/// Widget reutilizable del botón "Unirse a videollamada".
///
/// Uso:
///   JoinMeetingButton(appointment: a, currentUser: _currentUser)
///
/// — Muestra el botón solo si la cita es [pendiente]
/// — Al presionar, consulta al backend si la ventana está abierta
/// — Si no es hora o expiró → muestra un AlertDialog con mensaje personalizado
/// — Si está abierta → abre Jitsi en una pestaña nueva (Flutter Web)
class JoinMeetingButton extends StatefulWidget {
  final Appointment appointment;
  final User?       currentUser;
  final bool        compact;   // true → icono pequeño (para usar en tabla)

  const JoinMeetingButton({
    super.key,
    required this.appointment,
    required this.currentUser,
    this.compact = false,
  });

  @override
  State<JoinMeetingButton> createState() => _JoinMeetingButtonState();
}

class _JoinMeetingButtonState extends State<JoinMeetingButton> {
  bool _loading = false;

  bool get _isDoctor  => widget.currentUser?.isDoctor  == true;
  bool get _isPatient => widget.currentUser?.isPatient == true;

  // Solo mostramos el botón si la cita es pendiente y el usuario pertenece a ella
  bool get _canShow {
    final a = widget.appointment;
    if (a.status != AppointmentStatus.pendiente) return false;
    if (_isDoctor  && a.doctorId  == widget.currentUser?.id) return true;
    if (_isPatient && a.patientId == widget.currentUser?.id) return true;
    return false;
  }

  Future<void> _handleJoin() async {
    if (_loading) return;
    setState(() => _loading = true);

    final result = await JitsiService.getToken(widget.appointment.id!);

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result.windowStatus) {
      case JitsiWindowStatus.open:
        _openRoom(result);
        break;
      case JitsiWindowStatus.notYet:
        _showNotYetAlert(result);
        break;
      case JitsiWindowStatus.expired:
        _showExpiredAlert(result);
        break;
      case JitsiWindowStatus.error:
        _showErrorSnack(result.message ?? 'Error al conectar con la sala');
        break;
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Abrir sala Jitsi
  // ─────────────────────────────────────────────────────────

  void _openRoom(JitsiTokenResult result) {
    if (result.roomUrl == null) return;

    // Si hay JWT (JaaS), agrega el token a la URL
    final url = result.jwt != null
        ? '${result.roomUrl}?jwt=${result.jwt}'
        : result.roomUrl!;

    // Flutter Web → nueva pestaña
    html.window.open(url, '_blank');
  }

  // ─────────────────────────────────────────────────────────
  //  Alerts de tiempo
  // ─────────────────────────────────────────────────────────

  void _showNotYetAlert(JitsiTokenResult result) {
    final opensAt       = result.opensAt       ?? '--:--';
    final appointmentAt = result.appointmentAt ?? '--:--';
    final minutes       = result.minutesUntil  ?? 0;

    final String titulo;
    final String descripcion;
    final String extra;

    if (_isDoctor) {
      titulo      = 'La sala aún no está disponible';
      descripcion = 'La videollamada con tu paciente está programada para las $appointmentAt.';
      extra       = 'Podrás ingresar a partir de las $opensAt (10 minutos antes). '
                    'Faltan aproximadamente $minutes minuto${minutes == 1 ? "" : "s"}.';
    } else {
      titulo      = 'Tu consulta aún no ha comenzado';
      descripcion = 'Tu cita médica está programada para las $appointmentAt.';
      extra       = 'La sala se abrirá a las $opensAt (10 minutos antes de tu cita). '
                    'Faltan aproximadamente $minutes minuto${minutes == 1 ? "" : "s"}.';
    }

    _showTimeAlert(
      icon:   Icons.schedule_outlined,
      color:  const Color(0xFF4F46E5),
      bgColor: const Color(0xFFEDE9FE),
      titulo: titulo,
      descripcion: descripcion,
      extra:  extra,
      btnLabel: 'Entendido',
    );
  }

  void _showExpiredAlert(JitsiTokenResult result) {
    final String titulo;
    final String descripcion;

    if (_isDoctor) {
      titulo      = 'Tiempo de consulta expirado';
      descripcion = 'El tiempo asignado para esta videollamada ya finalizó. '
                    'Si la consulta no se realizó, por favor reagenda la cita con el paciente.';
    } else {
      titulo      = 'La videollamada ya no está disponible';
      descripcion = 'El tiempo asignado para esta consulta ha finalizado. '
                    'Si necesitas atención, puedes agendar una nueva cita.';
    }

    _showTimeAlert(
      icon:   Icons.videocam_off_outlined,
      color:  const Color(0xFFEF4444),
      bgColor: const Color(0xFFFEF2F2),
      titulo: titulo,
      descripcion: descripcion,
      extra:  result.message,
      btnLabel: 'Cerrar',
    );
  }

  void _showTimeAlert({
    required IconData icon,
    required Color    color,
    required Color    bgColor,
    required String   titulo,
    required String   descripcion,
    String?           extra,
    required String   btnLabel,
  }) {
    showDialog(
      context:           context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Icono
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 20),

            // Título
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A7A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Descripción
            Text(
              descripcion,
              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),

            // Extra (hora de apertura, minutos, etc.)
            if (extra != null && extra.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    extra,
                    style: TextStyle(fontSize: 12, color: color, height: 1.5),
                  )),
                ]),
              ),
            ],
            const SizedBox(height: 24),

            // Botón
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  btnLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ─────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_canShow) return const SizedBox.shrink();

    if (widget.compact) {
      // ── Versión compacta para tabla / listado
      return Tooltip(
        message: 'Unirse a videollamada',
        child: InkWell(
          onTap: _handleJoin,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.4)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        color: Color(0xFF06B6D4), strokeWidth: 2))
                : const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.videocam_outlined,
                        color: Color(0xFF06B6D4), size: 15),
                    SizedBox(width: 4),
                    Text('Unirse',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF06B6D4),
                            fontWeight: FontWeight.bold)),
                  ]),
          ),
        ),
      );
    }

    // ── Versión completa para detail / card
    return ElevatedButton.icon(
      onPressed: _loading ? null : _handleJoin,
      icon: _loading
          ? const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.videocam_outlined, size: 18),
      label: Text(
        _loading ? 'Conectando...' : 'Unirse a videollamada',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF06B6D4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
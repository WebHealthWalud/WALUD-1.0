import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../config/api_config.dart';

/// Resultado de la validación de ventana de tiempo
enum JitsiWindowStatus {
  open,      // dentro de la ventana → puede entrar
  notYet,    // aún no es hora
  expired,   // ya pasó el tiempo
  error,     // error de red u otro
}

class JitsiTokenResult {
  final bool              success;
  final JitsiWindowStatus windowStatus;
  final String?           roomUrl;
  final String?           jwt;
  final String?           roomName;
  final String?           displayName;
  final bool              isModerator;
  final String?           subject;

  // Mensajes para los alerts
  final String?  message;
  final String?  opensAt;          // hora desde la que se puede entrar
  final String?  appointmentAt;    // hora de la cita
  final int?     minutesUntil;     // minutos que faltan

  const JitsiTokenResult({
    required this.success,
    required this.windowStatus,
    this.roomUrl,
    this.jwt,
    this.roomName,
    this.displayName,
    this.isModerator = false,
    this.subject,
    this.message,
    this.opensAt,
    this.appointmentAt,
    this.minutesUntil,
  });
}

class JitsiService {
  /// Solicita al backend el token/sala para la cita [appointmentId].
  /// El backend ya valida la ventana de tiempo y devuelve el status.
  static Future<JitsiTokenResult> getToken(int appointmentId) async {
    try {
      final token = await ApiService.getToken();
      final uri   = Uri.parse(
        '${ApiService.baseUrl}appointments/$appointmentId/jitsi-token',
      );

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept':        'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      // ── Sala abierta
      if (response.statusCode == 200 && body['success'] == true) {
        return JitsiTokenResult(
          success:      true,
          windowStatus: JitsiWindowStatus.open,
          roomUrl:      body['room_url'] as String?,
          jwt:          body['jwt']      as String?,
          roomName:     body['room_name'] as String?,
          displayName:  body['display_name'] as String?,
          isModerator:  body['is_moderator'] == true,
          subject:      body['subject'] as String?,
          message:      body['message'] as String?,
        );
      }

      // ── Aún no es hora (425 Too Early)
      if (response.statusCode == 425) {
        return JitsiTokenResult(
          success:       false,
          windowStatus:  JitsiWindowStatus.notYet,
          message:       body['message'] as String?,
          opensAt:       body['opens_at'] as String?,
          appointmentAt: body['appointment_at'] as String?,
          minutesUntil:  body['minutes_until'] as int?,
        );
      }

      // ── Tiempo expirado (410 Gone)
      if (response.statusCode == 410) {
        return JitsiTokenResult(
          success:      false,
          windowStatus: JitsiWindowStatus.expired,
          message:      body['message'] as String?,
        );
      }

      // ── Otro error (403, 422, 500…)
      return JitsiTokenResult(
        success:      false,
        windowStatus: JitsiWindowStatus.error,
        message:      body['message'] as String? ?? 'Error inesperado',
      );
    } catch (e) {
      return JitsiTokenResult(
        success:      false,
        windowStatus: JitsiWindowStatus.error,
        message:      'Error de conexión: $e',
      );
    }
  }
}
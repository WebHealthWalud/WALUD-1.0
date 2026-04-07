import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class AppointmentService {

  /// Slots disponibles
  static Future<Map<String, dynamic>> getAvailableSlots({
    required String especialidad,
    required String date,
  }) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}appointments/available-slots')
          .replace(queryParameters: {'especialidad': especialidad, 'date': date});

      final token = await ApiService.getToken();
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      if (response.statusCode == 404) {
        return {'success': false, 'message': 'No hay médicos disponibles para esa especialidad'};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Error al consultar disponibilidad'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Crear cita — paciente O médico
  /// [patientDocument] y [patientTipoDocumento] solo se envían cuando es médico
  static Future<Map<String, dynamic>> create(
    Appointment appointment, {
    String? patientDocument,
    String? patientTipoDocumento,
  }) async {
    try {
      // ✅ Formato HH:MM — el backend espera exactamente este formato
      final dateStr = DateFormat('yyyy-MM-dd').format(appointment.dateTime);
      final timeStr = DateFormat('HH:mm').format(appointment.dateTime);

      final body = <String, dynamic>{
        'doctor_id':        appointment.doctorId,
        'especialidad':     appointment.especialidad,
        'appointment_type': appointment.appointmentType,
        'date':             dateStr,
        'time':             timeStr,   // ✅ Siempre HH:MM, nunca HH:MM:SS
        'status':           'pendiente',
        'reason':           appointment.reason,
        if (appointment.notes != null) 'notes': appointment.notes,
        // Solo para médico
        if (patientDocument != null)      'patient_document':       patientDocument,
        if (patientTipoDocumento != null) 'patient_tipo_documento': patientTipoDocumento,
      };

      final response = await ApiService.postAuth(ApiConfig.appointmentsEndpoint, body);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success':     true,
          'message':     data['message'] ?? 'Cita creada',
          'appointment': Appointment.fromJson(data['data'] ?? data['appointment'] ?? {}),
        };
      }
      final error = jsonDecode(response.body);
      return {
        'success': false,
        'message': error['message'] ?? 'Error al crear cita',
        'errors':  error['errors'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Listar citas
  static Future<Map<String, dynamic>> getAll({
    String? status,
    String? especialidad,
  }) async {
    try {
      var uri = Uri.parse('${ApiService.baseUrl}${ApiConfig.appointmentsEndpoint}');
      final params = <String, String>{};
      if (status != null)       params['status']       = status;
      if (especialidad != null) params['especialidad'] = especialidad;
      if (params.isNotEmpty)    uri = uri.replace(queryParameters: params);

      final token = await ApiService.getToken();
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {
          'success':      true,
          'appointments': data.map((a) => Appointment.fromJson(a)).toList(),
        };
      }
      return {'success': false, 'message': 'Error al obtener citas'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Paciente actualiza fecha, hora, especialidad, razón, notas
  /// Solo funciona en citas PENDIENTES
  static Future<Map<String, dynamic>> updatePatient(
    int id,
    Appointment appointment,
  ) async {
    try {
      // ✅ Mismo formato HH:MM para la actualización
      final body = <String, dynamic>{
        'doctor_id':        appointment.doctorId,
        'especialidad':     appointment.especialidad,
        'appointment_type': appointment.appointmentType,
        'date':             DateFormat('yyyy-MM-dd').format(appointment.dateTime),
        'time':             DateFormat('HH:mm').format(appointment.dateTime),
        'reason':           appointment.reason,
        if (appointment.notes != null) 'notes': appointment.notes,
      };

      final response = await ApiService.putAuth(
        '${ApiConfig.appointmentsEndpoint}/$id', body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success':     true,
          'message':     data['message'],
          'appointment': Appointment.fromJson(data['data']),
        };
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Error al actualizar'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Médico actualiza solo el estado
  /// Solo funciona en citas PENDIENTES
  static Future<Map<String, dynamic>> updateStatus(
    int id,
    AppointmentStatus status,
  ) async {
    try {
      final response = await ApiService.putAuth(
        '${ApiConfig.appointmentsEndpoint}/$id',
        {'status': status.name},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success':     true,
          'message':     data['message'],
          'appointment': Appointment.fromJson(data['data']),
        };
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Error al actualizar estado'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Subir archivo adjunto
  static Future<Map<String, dynamic>> uploadAttachment(
    int appointmentId,
    File file,
  ) async {
    try {
      final token = await ApiService.getToken();
      final uri   = Uri.parse(
        '${ApiService.baseUrl}${ApiConfig.appointmentsEndpoint}/$appointmentId/attachment',
      );

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept']        = 'application/json'
        ..files.add(await http.MultipartFile.fromPath(
          'attachment', file.path,
          contentType: MediaType('application', 'octet-stream'),
        ));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success':         true,
          'message':         data['message'],
          'attachment_name': data['attachment_name'],
        };
      }
      return {'success': false, 'message': 'Error al subir archivo'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Eliminar cita
  static Future<Map<String, dynamic>> delete(int id) async {
    try {
      final response = await ApiService.deleteAuth(
        '${ApiConfig.appointmentsEndpoint}/$id',
      );
      if (response.statusCode == 200) return {'success': true, 'message': 'Cita eliminada'};
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Error al eliminar'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
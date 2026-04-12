import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import '../models/appointment.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class AppointmentService {

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

  static Future<Map<String, dynamic>> create(
    Appointment appointment, {
    String? patientDocument,
    String? patientTipoDocumento,
  }) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(appointment.dateTime);
      final timeStr = DateFormat('HH:mm').format(appointment.dateTime);

      final body = <String, dynamic>{
        'doctor_id':        appointment.doctorId,
        'especialidad':     appointment.especialidad,
        'appointment_type': appointment.appointmentType,
        'date':             dateStr,
        'time':             timeStr,
        'status':           'pendiente',
        'reason':           appointment.reason,
        if (appointment.notes != null) 'notes': appointment.notes,
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

  static Future<Map<String, dynamic>> updatePatient(
    int id,
    Appointment appointment,
  ) async {
    try {
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

  /// ✅ Upload corregido — compatible con Flutter Web y móvil
  /// [filePath]  ruta del archivo (móvil/desktop)
  /// [fileBytes] bytes del archivo (web)
  /// [fileName]  nombre original del archivo
  static Future<Map<String, dynamic>> uploadAttachment(
    int appointmentId, {
    String?     filePath,
    Uint8List?  fileBytes,
    required String fileName,
  }) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'No autenticado'};
      }

      final uri = Uri.parse(
        '${ApiService.baseUrl}${ApiConfig.appointmentsEndpoint}/$appointmentId/attachment',
      );

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept']        = 'application/json';

      // ✅ Detectar MIME type real del archivo
      final mimeType  = lookupMimeType(fileName) ?? 'application/octet-stream';
      final mimeParts = mimeType.split('/');
      final mediaType = MediaType(mimeParts[0], mimeParts[1]);

      if (kIsWeb) {
        // ── Flutter Web: usar bytes directamente
        if (fileBytes == null) {
          return {'success': false, 'message': 'No se recibieron datos del archivo'};
        }
        request.files.add(http.MultipartFile.fromBytes(
          'attachment',
          fileBytes,
          filename:    fileName,
          contentType: mediaType,
        ));
      } else {
        // ── Móvil / Desktop: usar path
        if (filePath == null) {
          return {'success': false, 'message': 'Ruta del archivo no disponible'};
        }
        request.files.add(await http.MultipartFile.fromPath(
          'attachment',
          filePath,
          filename:    fileName,
          contentType: mediaType,
        ));
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Tiempo de espera agotado al subir el archivo'),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success':         true,
          'message':         data['message'] ?? 'Archivo subido correctamente',
          'attachment_name': data['attachment_name'],
          'attachment_url':  data['attachment_url'],
        };
      }

      // Mostrar el error real del backend
      String errorMsg = 'Error al subir archivo (${response.statusCode})';
      try {
        final errData = jsonDecode(response.body);
        errorMsg = errData['message'] ?? errorMsg;
      } catch (_) {}

      return {'success': false, 'message': errorMsg};
    } catch (e) {
      return {'success': false, 'message': 'Error al subir archivo: $e'};
    }
  }

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
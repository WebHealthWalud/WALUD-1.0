import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/appointment.dart';
import 'api_service.dart';
import '../config/api_config.dart';
import 'package:intl/intl.dart';

class AppointmentService {
  static Future<Map<String, dynamic>> create(Appointment appointment) async {
    try {
      final response =
          await ApiService.postAuth(ApiConfig.appointmentsEndpoint, {
            'patient_id': appointment.patientId,
            'doctor_id': appointment.doctorId,
            'patient_document': appointment.patientDocument,
            'patient_name': appointment.patientName,
            'appointment_type': appointment.appointmentType,
            'date': DateFormat('yyyy-MM-dd').format(appointment.dateTime),
            'time': DateFormat('HH:mm').format(appointment.dateTime),
            'status': appointment.status.name,
            'notes': appointment.notes,
            'reason': appointment.reason,
          });

      // 🔥 DEBUG (CLAVE PARA 422)
      print('STATUS: ${response.statusCode}');
      print('BODY: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Cita creada',
          'appointment': Appointment.fromJson(
            data['data'] ?? data['appointment'],
          ),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error al crear cita',
          'errors': error['errors'], // 👈 IMPORTANTE
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAll({
    int? patientId,
    int? doctorId,
  }) async {
    try {
      String url = ApiConfig.appointmentsEndpoint;
      if (patientId != null) {
        url += '?patient_id=$patientId';
      } else if (doctorId != null) {
        url += '?doctor_id=$doctorId';
      }

      final response = await ApiService.getAuth(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List appointmentsJson = data is List
            ? data
            : (data['data'] ?? data['appointments'] ?? []);

        return {
          'success': true,
          'appointments': appointmentsJson
              .map((a) => Appointment.fromJson(a))
              .toList(),
        };
      } else {
        return {'success': false, 'message': 'Error al obtener citas'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> update(
    int id,
    Appointment appointment,
  ) async {
    try {
      final response = await ApiService.putAuth(
        '${ApiConfig.appointmentsEndpoint}/$id',
        appointment.toJson(), // ✅ consistente con create
      );

      print('UPDATE STATUS: ${response.statusCode}');
      print('UPDATE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Cita actualizada',
          'appointment': Appointment.fromJson(
            data['data'] ?? data['appointment'],
          ),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error al actualizar',
          'errors': error['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> delete(int id) async {
    try {
      final response = await ApiService.deleteAuth(
        '${ApiConfig.appointmentsEndpoint}/$id',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Cita eliminada',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error al eliminar',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateStatus(
    int id,
    AppointmentStatus status,
  ) async {
    try {
      final response = await ApiService.patchAuth(
        '${ApiConfig.appointmentsEndpoint}/$id',
        {'status': status.name},
      );

      print('PATCH STATUS: ${response.statusCode}');
      print('PATCH BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Estado actualizado',
          'appointment': Appointment.fromJson(
            data['data'] ?? data['appointment'],
          ),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error al actualizar estado',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}

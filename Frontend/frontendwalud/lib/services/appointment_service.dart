import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/appointment.dart';
import 'api_service.dart';
import '../config/api_config.dart';
import 'package:intl/intl.dart';

class AppointmentService {

  static Future<Map<String, dynamic>> create(Appointment appointment) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(appointment.dateTime);
      final timeStr = DateFormat('HH:mm').format(appointment.dateTime);

      print('📅 ENVIANDO - Fecha: $dateStr, Hora: $timeStr');
      print('👤 patient_document: ${appointment.patientDocument}');
      print('👤 patient_name: ${appointment.patientName}');

      final response = await ApiService.postAuth(
        ApiConfig.appointmentsEndpoint,
        {
          'patient_id': appointment.patientId,
          'doctor_id': appointment.doctorId,
          'patient_document': appointment.patientDocument,
          'patient_name': appointment.patientName,
          'appointment_type': appointment.appointmentType,
          'date': dateStr,  
          'time': timeStr, 
          'status': appointment.status.name,
          'notes': appointment.notes,
          'reason': appointment.reason,
        },
      );

      print('📡 STATUS: ${response.statusCode}');
      print('📡 BODY: ${response.body}');

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
          'errors': error['errors'],
        };
      }
    } catch (e) {
      print('❌ ERROR: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAll() async {
    try {
      final response = await ApiService.getAuth(ApiConfig.appointmentsEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return {
          'success': true,
          'appointments': data.map((a) => Appointment.fromJson(a)).toList(),
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
      final response =
          await ApiService.putAuth('${ApiConfig.appointmentsEndpoint}/$id', {
            'doctor_id': appointment.doctorId,
            'date': DateFormat('yyyy-MM-dd').format(appointment.dateTime),
            'time': DateFormat('HH:mm').format(appointment.dateTime),
            'reason': appointment.reason,
            'status': appointment.status.name,
            'notes': appointment.notes,
          });

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

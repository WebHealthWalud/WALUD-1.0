// lib/services/medical_record_service.dart
import 'dart:convert';
import '../models/medical_record.dart';
import 'api_service.dart';

class MedicalRecordService {
  static const _ep = 'medical-records';

  static Future<Map<String, dynamic>> getAll({
    String? search, String? especialidad,
  }) async {
    try {
      final params = <String>[];
      if (search?.isNotEmpty == true)
        params.add('search=${Uri.encodeComponent(search!)}');
      if (especialidad?.isNotEmpty == true)
        params.add('especialidad=$especialidad');

      final ep = params.isEmpty ? _ep : '$_ep?${params.join('&')}';
      final r  = await ApiService.getAuth(ep);

      if (r.statusCode == 200) {
        final List data = jsonDecode(r.body);
        return {
          'success': true,
          'records': data.map((e) => MedicalRecord.fromJson(e)).toList(),
        };
      }
      final err = jsonDecode(r.body);
      return {'success': false, 'message': err['message'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> getById(int id) async {
    try {
      final r = await ApiService.getAuth('$_ep/$id');
      if (r.statusCode == 200) {
        return {
          'success': true,
          'record': MedicalRecord.fromJson(jsonDecode(r.body)),
        };
      }
      return {'success': false, 'message': 'Registro no encontrado'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> create(MedicalRecord record) async {
    try {
      final r = await ApiService.postAuth(_ep, record.toJson());
      if (r.statusCode == 201) {
        final data = jsonDecode(r.body);
        return {
          'success': true,
          'record': MedicalRecord.fromJson(data['data']),
        };
      }
      final err = jsonDecode(r.body);
      return {'success': false, 'message': err['message'] ?? 'Error al guardar'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ✅ Actualizar evolución (médico y admin)
  static Future<Map<String, dynamic>> update(
      int id, Map<String, dynamic> body) async {
    try {
      final r = await ApiService.putAuth('$_ep/$id', body);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return {
          'success': true,
          'record':  MedicalRecord.fromJson(data['data']),
        };
      }
      final err = jsonDecode(r.body);
      return {'success': false, 'message': err['message'] ?? 'Error al actualizar'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> getTimeline(int patientId) async {
    try {
      final r = await ApiService.getAuth('$_ep/timeline/$patientId');
      if (r.statusCode == 200) {
        final List data = jsonDecode(r.body);
        return {
          'success': true,
          'timeline': data.map((e) => MedicalRecord.fromJson(e)).toList(),
        };
      }
      return {'success': false, 'message': 'Error al obtener timeline'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> searchPatients(String query) async {
    try {
      final r = await ApiService.getAuth(
          '$_ep/search-patient?search=${Uri.encodeComponent(query)}');
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return {
          'success': true,
          'patients': List<Map<String, dynamic>>.from(data['patients'] ?? []),
        };
      }
      return {'success': false, 'message': 'Error en búsqueda'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
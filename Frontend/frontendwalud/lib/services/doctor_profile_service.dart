import 'dart:convert';
import '../models/doctor_profile.dart';
import 'api_service.dart';

class DoctorProfileService {
  static const _endpoint = 'doctor-profile';

  // ── Obtener perfil
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await ApiService.getAuth(_endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data':    data['data'],
          'profile': DoctorProfile.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': 'Error al obtener perfil'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ── Actualizar perfil
  static Future<Map<String, dynamic>> updateProfile({
    String?                        rethus,
    List<Map<String, dynamic>>?    formacionAcademica,
    List<String>?                  areasEnfoque,
    Map<String, dynamic>?          horariosAtencion,
    List<Map<String, dynamic>>?    ubicacionesConsulta,
  }) async {
    try {
      final body = <String, dynamic>{
        if (rethus != null)              'rethus':               rethus,
        if (formacionAcademica != null)  'formacion_academica':  formacionAcademica,
        if (areasEnfoque != null)        'areas_enfoque':        areasEnfoque,
        if (horariosAtencion != null)    'horarios_atencion':    horariosAtencion,
        if (ubicacionesConsulta != null) 'ubicaciones_consulta': ubicacionesConsulta,
      };
      final response = await ApiService.putAuth(_endpoint, body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'profile': DoctorProfile.fromJson(data['data']),
        };
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Error al actualizar'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
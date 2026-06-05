import 'dart:convert';
import '../models/patient_profile.dart';
import 'api_service.dart';

class PatientProfileService {
  static const _endpoint = 'patient-profile';

  // ── Obtener perfil
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await ApiService.getAuth(_endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data':    data['data'],
          'profile': PatientProfile.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': 'Error al obtener perfil'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ── Actualizar perfil
  static Future<Map<String, dynamic>> updateProfile({
    double? peso,
    double? talla,
    String? direccion,
    String? ciudad,
    String? contactoNombre,
    String? contactoTelefono,
    String? contactoRelacion,
  }) async {
    try {
      final body = <String, dynamic>{
        if (peso != null)             'peso':                         peso,
        if (talla != null)            'talla':                        talla,
        if (direccion != null)        'direccion':                    direccion,
        if (ciudad != null)           'ciudad':                       ciudad,
        if (contactoNombre != null)   'contacto_emergencia_nombre':   contactoNombre,
        if (contactoTelefono != null) 'contacto_emergencia_telefono': contactoTelefono,
        if (contactoRelacion != null) 'contacto_emergencia_relacion': contactoRelacion,
      };

      final response = await ApiService.putAuth(_endpoint, body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success':         true,
          'message':         data['message'],
          'profile':         PatientProfile.fromJson(data['data']),
          'perfil_completo': data['perfil_completo'],
        };
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Error al actualizar'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
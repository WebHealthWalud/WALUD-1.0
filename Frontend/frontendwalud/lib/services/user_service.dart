import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';
import '../config/api_config.dart';
class UserService {

    /// Obtiene todos los médicos registrados (tipo_usuario = 'medico')
    static Future<Map<String, dynamic>> getDoctors() async {
      try {
        final response = await ApiService.getAuth(ApiConfig.usersEndpoint);
        
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          
          final doctors = data
              .where((u) => u['tipo_usuario'] == 'medico')
              .map((u) => User.fromJson(u))
              .where((u) => u.id != null)
              .toList();
          
          return {'success': true, 'doctors': doctors};
        } else {
          return {'success': false, 'message': 'Error al obtener médicos'};
        }
      } catch (e) {
        return {'success': false, 'message': 'Error de conexión: $e'};
      }
    }

    /// Buscar paciente por documento y tipo de documento
    static Future<Map<String, dynamic>> searchPatientByDocument(
      String document,
      String tipoDocumento,
    ) async {
      try {
        final response = await ApiService.postAuth(
          '${ApiConfig.usersEndpoint}/search-by-document',
          {
            'document': document,
            'tipo_documento': tipoDocumento,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'patient': User.fromJson(data['patient']),
          };
        } else if (response.statusCode == 404) {
          final data = jsonDecode(response.body);
          return {
            'success': false,
            'message': data['message'] ?? 'Paciente no encontrado',
          };
        } else {
          return {'success': false, 'message': 'Error al buscar paciente'};
        }
      } catch (e) {
        return {'success': false, 'message': 'Error de conexión: $e'};
      }
    }
  }

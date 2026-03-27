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

        // ✅ Filtrar solo usuarios con tipo_usuario = 'medico'
        final doctors = data
            .where((u) => u['tipo_usuario'] == 'medico')
            .map((u) => User.fromJson(u))
            .where((u) => u.id != null) // Solo usuarios con ID válido
            .toList();

        return {'success': true, 'doctors': doctors};
      } else {
        return {'success': false, 'message': 'Error al obtener médicos'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}

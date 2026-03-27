import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await ApiService.post(ApiConfig.loginEndpoint, {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Guardar token con verificación
        if (data['token'] != null) {
          await ApiService.saveToken(data['token']);
          // Guardar también el usuario para recuperación rápida
          await _saveUserData(data['user']);
        }

        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'token': data['token'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error al iniciar sesión',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String document,
    required String name,
    required String lastName,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String birthDate,
    required String userType,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.registerEndpoint, {
        'document': document,
        'name': name,
        'last_name': lastName,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'birth_date': birthDate,
        'tipo_usuario': userType,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // NO guardar token en registro (el usuario debe loguearse)
        // if (data['token'] != null) {
        //   await ApiService.saveToken(data['token']);
        // }

        return {
          'success': true,
          'message': data['message'] ?? 'Registro exitoso',
          'user': User.fromJson(data['user']),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error al registrar',
          'errors': error['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // NUEVO: Guardar datos del usuario en SharedPreferences
  static Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
  }

  // NUEVO: Recuperar usuario guardado
  static Future<User?> getSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        return User.fromJson(jsonDecode(userData));
      }
    } catch (e) {
      // Ignorar errores
    }
    return null;
  }

  // NUEVO: Verificar si hay sesión activa válida
  static Future<bool> hasValidSession() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) return false;

    // Opcional: Verificar con el backend que el token sigue válido
    try {
      final response = await ApiService.getAuth(ApiConfig.meEndpoint);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final token = await ApiService.getToken();
      if (token != null) {
        await ApiService.postAuth(ApiConfig.logoutEndpoint, {});
      }
    } catch (e) {
      // Ignorar errores en logout
    } finally {
      // Limpiar token Y datos de usuario
      await ApiService.clearToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    }
    return {'success': true, 'message': 'Sesión cerrada'};
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await ApiService.getAuth(ApiConfig.meEndpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Actualizar datos guardados
        await _saveUserData(data);
        return {'success': true, 'user': User.fromJson(data)};
      } else {
        // Si falla, intentar recuperar usuario guardado
        final savedUser = await getSavedUser();
        if (savedUser != null) {
          return {'success': true, 'user': savedUser, 'cached': true};
        }
        return {'success': false, 'message': 'No se pudo obtener el usuario'};
      }
    } catch (e) {
      // Fallback a usuario guardado
      final savedUser = await getSavedUser();
      if (savedUser != null) {
        return {'success': true, 'user': savedUser, 'cached': true};
      }
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}

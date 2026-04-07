import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await ApiService.post(ApiConfig.loginEndpoint, {'email': email, 'password': password});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await ApiService.saveToken(data['token']);
          await _saveUserData(data['user']);
        }
        return {'success': true, 'user': User.fromJson(data['user']), 'token': data['token']};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Error al iniciar sesión'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String       document,
    required DocumentType documentType,
    required String       name,
    required String       lastName,
    required String       email,
    required String       password,
    required String       passwordConfirmation,
    required String       birthDate,
    required String       userType,
    String?               especialidad,
  }) async {
    try {
      final body = {
        'document':              document,
        'tipo_documento':        documentType.value,
        'name':                  name,
        'last_name':             lastName,
        'email':                 email,
        'password':              password,
        'password_confirmation': passwordConfirmation,
        'birth_date':            birthDate,
        'tipo_usuario':          userType,
        if (especialidad != null && especialidad.isNotEmpty) 'especialidad': especialidad,
      };

      final response = await ApiService.post(ApiConfig.registerEndpoint, body);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'] ?? 'Registro exitoso', 'user': User.fromJson(data['user'])};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Error al registrar', 'errors': error['errors']};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<void> _saveUserData(Map<String, dynamic> userData) async =>
    (await SharedPreferences.getInstance()).setString('user_data', jsonEncode(userData));

  static Future<User?> getSavedUser() async {
    try {
      final prefs    = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) return User.fromJson(jsonDecode(userData));
    } catch (_) {}
    return null;
  }

  static Future<bool> hasValidSession() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) return false;
    try {
      final response = await ApiService.getAuth(ApiConfig.meEndpoint);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await ApiService.getAuth(ApiConfig.meEndpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveUserData(data);
        return {'success': true, 'user': User.fromJson(data)};
      }
      final saved = await getSavedUser();
      if (saved != null) return {'success': true, 'user': saved, 'cached': true};
      return {'success': false, 'message': 'No se pudo obtener el usuario'};
    } catch (e) {
      final saved = await getSavedUser();
      if (saved != null) return {'success': true, 'user': saved, 'cached': true};
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final token = await ApiService.getToken();
      if (token != null) await ApiService.postAuth(ApiConfig.logoutEndpoint, {});
    } catch (_) {}
    await ApiService.clearToken();
    (await SharedPreferences.getInstance()).remove('user_data');
    return {'success': true};
  }
}
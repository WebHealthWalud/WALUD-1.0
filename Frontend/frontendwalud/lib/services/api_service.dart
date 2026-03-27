import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Future<Map<String, String>> get _authHeaders async {
    final token = await getToken();
    return {
      ..._headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // POST sin autenticación
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return await http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );
  }

  // POST con autenticación
  static Future<http.Response> postAuth(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return await http.post(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _authHeaders,
      body: jsonEncode(data),
    );
  }

  // GET sin autenticación
  static Future<http.Response> get(String endpoint) async {
    return await http.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: _headers,
    );
  }

  // GET con autenticación
  static Future<http.Response> getAuth(String endpoint) async {
    return await http.get(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _authHeaders,
    );
  }

  // PUT con autenticación
  static Future<http.Response> putAuth(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return await http.put(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _authHeaders,
      body: jsonEncode(data),
    );
  }

  // PATCH con autenticación
  static Future<http.Response> patchAuth(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return await http.patch(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _authHeaders,
      body: jsonEncode(data),
    );
  }

  // DELETE con autenticación
  static Future<http.Response> deleteAuth(String endpoint) async {
    return await http.delete(
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      headers: await _authHeaders,
    );
  }

  // Gestión de Token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
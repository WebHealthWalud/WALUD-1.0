import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
  };

  static Future<Map<String, String>> get _authHeaders async {
    final token = await getToken();
    return {
      ..._headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async =>
    http.post(Uri.parse('$baseUrl$endpoint'), headers: _headers, body: jsonEncode(data));

  static Future<http.Response> postAuth(String endpoint, Map<String, dynamic> data) async =>
    http.post(Uri.parse('$baseUrl$endpoint'), headers: await _authHeaders, body: jsonEncode(data));

  static Future<http.Response> get(String endpoint) async =>
    http.get(Uri.parse('$baseUrl$endpoint'), headers: _headers);

  static Future<http.Response> getAuth(String endpoint) async =>
    http.get(Uri.parse('$baseUrl$endpoint'), headers: await _authHeaders);

  static Future<http.Response> putAuth(String endpoint, Map<String, dynamic> data) async =>
    http.put(Uri.parse('$baseUrl$endpoint'), headers: await _authHeaders, body: jsonEncode(data));

  static Future<http.Response> patchAuth(String endpoint, Map<String, dynamic> data) async =>
    http.patch(Uri.parse('$baseUrl$endpoint'), headers: await _authHeaders, body: jsonEncode(data));

  static Future<http.Response> deleteAuth(String endpoint) async =>
    http.delete(Uri.parse('$baseUrl$endpoint'), headers: await _authHeaders);

  // Token management
  static Future<void>    saveToken(String token) async => (await SharedPreferences.getInstance()).setString('auth_token', token);
  static Future<String?> getToken()               async => (await SharedPreferences.getInstance()).getString('auth_token');
  static Future<void>    clearToken()             async => (await SharedPreferences.getInstance()).remove('auth_token');
  static Future<bool>    isLoggedIn()             async { final t = await getToken(); return t != null && t.isNotEmpty; }
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../models/user.dart';
import 'api_service.dart';

class ProfileService {
  static const _endpoint = 'profile';

  // ── Obtener perfil
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await ApiService.getAuth(_endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user':    User.fromJson(data['data']),
        };
      }
      return {'success': false, 'message': 'Error al obtener perfil'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ── Actualizar datos personales
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? lastName,
    String? email,
    String? birthDate,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{
        if (name != null)      'name':       name,
        if (lastName != null)  'last_name':  lastName,
        if (email != null)     'email':      email,
        if (birthDate != null) 'birth_date': birthDate,
        if (phone != null)     'phone':      phone,
      };

      final response = await ApiService.putAuth(_endpoint, body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'user':    User.fromJson(data['data']),
        };
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Error al actualizar'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ── Subir foto de perfil (Web + Móvil)
  static Future<Map<String, dynamic>> uploadPhoto({
    required String fileName,
    String?     filePath,
    Uint8List?  fileBytes,
  }) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return {'success': false, 'message': 'No autenticado'};

      final uri    = Uri.parse('${ApiService.baseUrl}$_endpoint/photo');
      final mimeType  = lookupMimeType(fileName) ?? 'image/jpeg';
      final mimeParts = mimeType.split('/');
      final mediaType = MediaType(mimeParts[0], mimeParts.length > 1 ? mimeParts[1] : 'jpeg');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept']        = 'application/json';

      if (kIsWeb) {
        if (fileBytes == null || fileBytes.isEmpty) {
          return {'success': false, 'message': 'No se obtuvieron datos de la imagen'};
        }
        request.files.add(http.MultipartFile.fromBytes(
          'photo', fileBytes, filename: fileName, contentType: mediaType,
        ));
      } else {
        if (filePath == null || filePath.isEmpty) {
          return {'success': false, 'message': 'Ruta de imagen no disponible'};
        }
        request.files.add(await http.MultipartFile.fromPath(
          'photo', filePath, filename: fileName, contentType: mediaType,
        ));
      }

      final streamed  = await request.send().timeout(const Duration(seconds: 30));
      final response  = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success':   true,
          'message':   data['message'],
          'photo_url': data['photo_url'],
        };
      }
      final err = jsonDecode(response.body);
      return {'success': false, 'message': err['message'] ?? 'Error al subir foto'};
    } catch (e) {
      return {'success': false, 'message': 'Error al subir foto: $e'};
    }
  }

  // ── Eliminar foto de perfil
  static Future<Map<String, dynamic>> deletePhoto() async {
    try {
      final token = await ApiService.getToken();
      final uri   = Uri.parse('${ApiService.baseUrl}$_endpoint/photo');
      final response = await http.delete(uri, headers: {
        'Accept':        'application/json',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Foto eliminada'};
      }
      return {'success': false, 'message': 'Error al eliminar foto'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ── Cambiar contraseña
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    try {
      final response = await ApiService.postAuth('$_endpoint/change-password', {
        'current_password':          currentPassword,
        'password':                  newPassword,
        'password_confirmation':     confirmation,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Error al cambiar contraseña'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
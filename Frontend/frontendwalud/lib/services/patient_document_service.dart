import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../models/patient_document.dart';
import 'api_service.dart';

class PatientDocumentService {
  static const _endpoint = 'patient-profile/documents';

  // ── Listar documentos del paciente autenticado
  static Future<Map<String, dynamic>> getAll() async {
    try {
      final response = await ApiService.getAuth(_endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final docs = (data['data'] as List)
            .map((d) => PatientDocument.fromJson(d))
            .toList();
        return {'success': true, 'documents': docs};
      }
      return {'success': false, 'message': 'Error al obtener documentos'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ── Subir documento
  static Future<Map<String, dynamic>> upload({
    required String    nombre,
    required String    tipo,
    required String    fileName,
    String?            filePath,
    Uint8List?         fileBytes,
  }) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return {'success': false, 'message': 'No autenticado'};

      final uri      = Uri.parse('${ApiService.baseUrl}$_endpoint');
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
      final parts    = mimeType.split('/');
      final media    = MediaType(parts[0], parts.length > 1 ? parts[1] : 'octet-stream');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept']        = 'application/json'
        ..fields['nombre']         = nombre
        ..fields['tipo']           = tipo;

      if (kIsWeb) {
        if (fileBytes == null) {
          return {'success': false, 'message': 'Sin datos del archivo'};
        }
        request.files.add(http.MultipartFile.fromBytes(
          'documento',
          fileBytes,
          filename:    fileName,
          contentType: media,
        ));
      } else {
        if (filePath == null) {
          return {'success': false, 'message': 'Sin ruta del archivo'};
        }
        request.files.add(await http.MultipartFile.fromPath(
          'documento',
          filePath,
          filename:    fileName,
          contentType: media,
        ));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success':  true,
          'message':  data['message'],
          'document': PatientDocument.fromJson(data['data']),
        };
      }

      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Error al subir documento'};
    } catch (e) {
      return {'success': false, 'message': 'Error al subir: $e'};
    }
  }

  // ── Eliminar documento
  static Future<Map<String, dynamic>> delete(int id) async {
    try {
      final response = await ApiService.deleteAuth('$_endpoint/$id');
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Documento eliminado correctamente'};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Error al eliminar'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
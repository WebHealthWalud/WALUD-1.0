import 'dart:convert';
import '../models/payment.dart';
import 'api_service.dart';

class PaymentService {
  static const _endpoint = 'payments';

  static Future<Map<String, dynamic>> getAll({String? estadoPago, String? tipo}) async {
    try {
      var endpoint = _endpoint;
      final params = <String>[];
      if (estadoPago != null) params.add('estado_pago=$estadoPago');
      if (tipo != null)       params.add('tipo=$tipo');
      if (params.isNotEmpty)  endpoint += '?${params.join('&')}';

      final response = await ApiService.getAuth(endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {'success': true, 'payments': data.map((p) => Payment.fromJson(p)).toList()};
      }
      return {'success': false, 'message': 'Error al obtener pagos'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSummary() async {
    try {
      final response = await ApiService.getAuth('$_endpoint/summary');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Error al obtener resumen'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> create({
  required String concepto,
  required String tipo,
  required double monto,
  String?  estadoPago,
  String?  fechaPago,
  String?  metodoPago,
  String?  referenciaPago,
  int?     appointmentId,
  String?  fechaVencimiento,
  String?  notas,
}) async {
  try {
    final body = <String, dynamic>{
      'concepto':          concepto,
      'tipo':              tipo,
      'monto':             monto,
      if (estadoPago != null)       'estado_pago':       estadoPago,
      if (fechaPago != null)        'fecha_pago':        fechaPago,
      if (metodoPago != null)       'metodo_pago':       metodoPago,
      if (referenciaPago != null)   'referencia_pago':   referenciaPago,
      if (appointmentId != null)    'appointment_id':    appointmentId,
      if (fechaVencimiento != null) 'fecha_vencimiento': fechaVencimiento,
      if (notas != null)            'notas':             notas,
    };

    final response = await ApiService.postAuth(_endpoint, body);
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': data['message'],
        'payment': Payment.fromJson(data['data']),
      };
    }
    final error = jsonDecode(response.body);
    return {'success': false, 'message': error['message'] ?? 'Error al crear pago'};
  } catch (e) {
    return {'success': false, 'message': 'Error de conexión: $e'};
  }
}

  static Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    try {
      final response = await ApiService.putAuth('$_endpoint/$id', data);
      if (response.statusCode == 200) {
        final resp = jsonDecode(response.body);
        return {'success': true, 'message': resp['message'], 'payment': Payment.fromJson(resp['data'])};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Error al actualizar'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Procesar pago (marcar como completado)
  static Future<Map<String, dynamic>> pay(int id, String metodoPago, {String? referencia}) async {
    try {
      final response = await ApiService.postAuth('$_endpoint/$id/pay', {
        'metodo_pago':     metodoPago,
        'referencia_pago': referencia,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'], 'payment': Payment.fromJson(data['data'])};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Error al procesar pago'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> delete(int id) async {
    try {
      final response = await ApiService.deleteAuth('$_endpoint/$id');
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Pago eliminado'};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Error al eliminar'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
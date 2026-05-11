import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';

class AdminService {
  static const _base = 'admin';

  // ── Stats
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final r = await ApiService.getAuth('$_base/stats');
      if (r.statusCode == 200)
        return {'success': true, 'data': jsonDecode(r.body)};
      return {'success': false, 'message': 'Error al obtener estadísticas'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Usuarios — filtro por rol correcto
  static Future<Map<String, dynamic>> getUsers({
    String? rol,
    bool? isActive,
    String? search,
    int page = 1,
  }) async {
    try {
      var ep = '$_base/users?page=$page';
      if (rol != null && rol.isNotEmpty) ep += '&rol=$rol';
      if (isActive != null) ep += '&is_active=${isActive ? 1 : 0}';
      if (search != null && search.isNotEmpty)
        ep += '&search=${Uri.encodeComponent(search)}';

      final r = await ApiService.getAuth(ep);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final List items = data['data'] ?? [];
        return {
          'success': true,
          'users': items.map((u) => User.fromJson(u)).toList(),
          'total': data['total'] ?? items.length,
          'last_page': data['last_page'] ?? 1,
        };
      }
      return {'success': false, 'message': 'Error al obtener usuarios'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Crear usuario
  static Future<Map<String, dynamic>> createUser(
    Map<String, dynamic> body,
  ) async {
    try {
      final r = await ApiService.postAuth('$_base/users', body);
      if (r.statusCode == 201) {
        final data = jsonDecode(r.body);
        return {'success': true, 'user': User.fromJson(data['user'])};
      }
      final err = jsonDecode(r.body);
      return {
        'success': false,
        'message': err['message'] ?? 'Error al crear usuario',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Actualizar usuario
  static Future<Map<String, dynamic>> updateUser(
    int id,
    Map<String, dynamic> body,
  ) async {
    try {
      final r = await ApiService.putAuth('$_base/users/$id', body);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return {'success': true, 'user': User.fromJson(data['user'])};
      }
      final err = jsonDecode(r.body);
      return {
        'success': false,
        'message': err['message'] ?? 'Error al actualizar',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Asignar rol
  static Future<Map<String, dynamic>> assignRole(
    int id,
    String rol, {
    String? especialidad,
  }) async {
    try {
      final body = <String, dynamic>{'rol': rol};
      if (especialidad != null) body['especialidad'] = especialidad;
      final r = await ApiService.postAuth('$_base/users/$id/role', body);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return {'success': true, 'user': User.fromJson(data['user'])};
      }
      final err = jsonDecode(r.body);
      return {
        'success': false,
        'message': err['message'] ?? 'Error al asignar rol',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Activar / desactivar
  static Future<Map<String, dynamic>> toggleActive(int id) async {
    try {
      final r = await ApiService.postAuth('$_base/users/$id/toggle-active', {});
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return {
          'success': true,
          'is_active': data['is_active'],
          'message': data['message'],
        };
      }
      return {'success': false, 'message': 'Error al cambiar estado'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Eliminar usuario
  static Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      final r = await ApiService.deleteAuth('$_base/users/$id');
      if (r.statusCode == 200) return {'success': true};
      final err = jsonDecode(r.body);
      return {
        'success': false,
        'message': err['message'] ?? 'Error al eliminar',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Citas con búsqueda por documento
  static Future<Map<String, dynamic>> getAppointments({
    String? status,
    String? search,
    int page = 1,
  }) async {
    try {
      var ep = '$_base/appointments?page=$page';
      if (status != null && status.isNotEmpty && status != 'todas')
        ep += '&status=$status';
      if (search != null && search.isNotEmpty)
        ep += '&search=${Uri.encodeComponent(search)}';
      final r = await ApiService.getAuth(ep);
      if (r.statusCode == 200)
        return {'success': true, 'data': jsonDecode(r.body)};
      return {'success': false, 'message': 'Error al obtener citas'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Cancelar cita
  static Future<Map<String, dynamic>> cancelAppointment(int id) async {
    try {
      final r = await ApiService.postAuth('$_base/appointments/$id/cancel', {});
      if (r.statusCode == 200) return {'success': true};
      return {'success': false, 'message': 'Error al cancelar cita'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Pagos
  static Future<Map<String, dynamic>> getPayments({
    String? estadoPago,
    int page = 1,
  }) async {
    try {
      var ep = '$_base/payments?page=$page';
      if (estadoPago != null) ep += '&estado_pago=$estadoPago';
      final r = await ApiService.getAuth(ep);
      if (r.statusCode == 200)
        return {'success': true, 'data': jsonDecode(r.body)};
      return {'success': false, 'message': 'Error al obtener pagos'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPaymentStats() async {
    try {
      final r = await ApiService.getAuth('$_base/payments/stats');
      if (r.statusCode == 200)
        return {'success': true, 'data': jsonDecode(r.body)};
      return {'success': false, 'message': 'Error al obtener stats'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}

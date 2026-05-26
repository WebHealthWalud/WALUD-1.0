import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/appointment.dart';
import '../../models/payment.dart';
import '../../models/user.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import 'create_appointment_screen.dart';

class AppointmentsListScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const AppointmentsListScreen({super.key, this.onNavigate});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  List<Appointment> _all      = [];
  List<Payment>     _payments = [];
  bool   _isLoading = true;
  String _filter    = 'Todas';
  User?  _currentUser;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
  final r = await AuthService.getCurrentUser();
  if (r['success'] && mounted) {
    setState(() => _currentUser = r['user']);
  }
  // ✅ Solo cargar citas DESPUÉS de tener el usuario
  await _loadAppointments();
}

Future<void> _loadAppointments() async {
  setState(() => _isLoading = true);
  final r = await AppointmentService.getAll();

  // ✅ Verificar rol ANTES de llamar pagos
  List<Payment> payments = [];
  final esP = _currentUser?.isPatient == true;
  
  if (esP) {
    final pagosR = await PaymentService.getAll(estadoPago: 'pendiente');
    if (pagosR['success'] == true) {
      payments = List<Payment>.from(pagosR['payments']);
    }
  }

  if (mounted) {
    setState(() {
      _isLoading = false;
      _all       = r['success'] == true
          ? List<Appointment>.from(r['appointments']) : [];
      _payments  = esP ? payments : [];
    });
  }
}

  // ✅ Verificar si una cita tiene pago pendiente
  bool _tienePagoPendiente(Appointment a) {
    return _payments.any((p) => p.appointmentId == a.id);
  }

  List<Appointment> get _filtered {
    switch (_filter) {
      case 'Pendientes':
        return _all.where((a) =>
            a.status == AppointmentStatus.pendiente).toList();
      case 'Realizadas':
        return _all.where((a) =>
            a.status == AppointmentStatus.realizada).toList();
      case 'Canceladas':
        return _all.where((a) =>
            a.status == AppointmentStatus.cancelada).toList();
      default:
        return _all;
    }
  }

  Appointment? get _nextAppointment {
    final now     = DateTime.now();
    final pending = _all.where((a) =>
        a.status == AppointmentStatus.pendiente &&
        a.dateTime.isAfter(now)).toList();
    if (pending.isEmpty) return null;
    pending.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return pending.first;
  }

  void _openEdit(Appointment a) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CreateAppointmentScreen(
        appointmentToEdit: a,
        onCreated: _loadAppointments,
      ),
    ));
  }

  void _irAPagos() {
    if (widget.onNavigate != null) {
      widget.onNavigate!(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: const Color(0xFF4F46E5),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mis Citas', style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A7A))),
              const SizedBox(height: 4),
              Text('Gestiona y consulta el historial de tus consultas médicas.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ])),
            if (_currentUser?.isPatient == true ||
                _currentUser?.isDoctor == true)
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CreateAppointmentScreen(
                    onCreated: _loadAppointments,
                  ),
                )),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agendar Nueva Cita',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
          ]),
          const SizedBox(height: 24),

          // ✅ Banner pagos pendientes — solo pacientes
          if (_currentUser?.isPatient == true && _payments.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFF59E0B), size: 24),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _payments.length == 1
                        ? 'Tienes 1 cita con pago pendiente'
                        : 'Tienes ${_payments.length} citas con pago pendiente',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E), fontSize: 14,
                    )),
                  const Text('Realiza el pago para confirmar tu cita.',
                    style: TextStyle(color: Color(0xFF92400E), fontSize: 12)),
                ])),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _irAPagos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Pagar ahora',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
            const SizedBox(height: 24),
          ],

          // Próxima cita
          if (_nextAppointment != null) ...[
            _buildNextCard(_nextAppointment!),
            const SizedBox(height: 24),
          ],

          // Tabla
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10, offset: const Offset(0, 4),
              )],
            ),
            child: Column(children: [
              // Filtros
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: ['Todas', 'Pendientes', 'Realizadas', 'Canceladas']
                      .map((f) {
                    final active = _filter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF1A237E) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(f, style: TextStyle(
                          color: active ? Colors.white : Colors.grey[500],
                          fontWeight: active
                              ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        )),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade100),

              // Cabecera tabla
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(children: [
                  Expanded(flex: 3, child: _th(
                    _currentUser?.isDoctor == true ? 'PACIENTE' : 'MÉDICO')),
                  Expanded(flex: 2, child: _th('ESPECIALIDAD')),
                  Expanded(flex: 2, child: _th('FECHA')),
                  Expanded(flex: 1, child: _th('HORA')),
                  Expanded(flex: 2, child: _th('ESTADO')),
                  // ✅ Columna pago solo para pacientes
                  if (_currentUser?.isPatient == true)
                    Expanded(flex: 2, child: _th('PAGO')),
                  const SizedBox(width: 40),
                ]),
              ),
              Divider(height: 1, color: Colors.grey.shade100),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(
                      color: Color(0xFF4F46E5))),
                )
              else if (_filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(child: Column(children: [
                    Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'No hay citas ${_filter == "Todas" ? "" : _filter.toLowerCase()}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                  ])),
                )
              else
                ..._filtered.asMap().entries.map((e) =>
                    _buildRow(e.value, e.key.isOdd)),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Mostrando ${_filtered.length} de ${_all.length} citas',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildNextCard(Appointment a) {
    final now       = DateTime.now();
    final diff      = a.dateTime.difference(now);
    final isToday   = a.dateTime.day == now.day &&
        a.dateTime.month == now.month;
    final isTomorrow = a.dateTime.day ==
        now.add(const Duration(days: 1)).day;
    final cuando = isToday ? 'Hoy'
        : isTomorrow ? 'Mañana'
        : DateFormat('d MMM', 'es').format(a.dateTime);

    final tienePago = _tienePagoPendiente(a);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: const Color(0xFF4F46E5).withOpacity(0.3),
          blurRadius: 16, offset: const Offset(0, 6),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.notifications_active,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text('Siguiente Consulta',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            Text(
              _currentUser?.isDoctor == true
                  ? 'Tu próxima consulta con ${a.patientName}${diff.inHours < 24 ? " es en menos de 24 horas." : "."}'
                  : 'Tu próxima cita es con ${a.doctorName}${diff.inHours < 24 ? " en menos de 24 horas." : "."}',
              style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('FECHA', style: TextStyle(
                    color: Colors.white38, fontSize: 9, letterSpacing: 1)),
                  Text(cuando, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold,
                    fontSize: 16)),
                ]),
                const SizedBox(width: 20),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('HORA', style: TextStyle(
                    color: Colors.white38, fontSize: 9, letterSpacing: 1)),
                  Text(DateFormat('hh:mm a').format(a.dateTime),
                    style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold,
                      fontSize: 16)),
                ]),
              ]),
            ),
          ])),
          const SizedBox(width: 16),
          Column(children: [
            if (a.status == AppointmentStatus.pendiente)
              ElevatedButton(
                onPressed: () => _openEdit(a),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Ver / Editar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ]),
        ]),

        // ✅ Banner pago pendiente en la próxima cita
        if (tienePago && _currentUser?.isPatient == true) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.5)),
            ),
            child: Row(children: [
              const Icon(Icons.payment_outlined,
                  color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 10),
              const Expanded(child: Text(
                'Esta cita tiene un pago pendiente',
                style: TextStyle(
                  color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w500))),
              GestureDetector(
                onTap: _irAPagos,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Pagar',
                    style: TextStyle(
                      color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildRow(Appointment a, bool shaded) {
    final statusColor   = Color(int.parse('0x${a.statusColor}'));
    final tienePago     = _tienePagoPendiente(a);

    return InkWell(
      onTap: () => _showMenu(a),
      child: Container(
        color: shaded ? const Color(0xFFFAFAFC) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Expanded(flex: 3, child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
              child: const Icon(Icons.person,
                  color: Color(0xFF4F46E5), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _currentUser?.isDoctor == true
                    ? a.patientName : a.doctorName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13,
                  color: Color(0xFF4F46E5))),
              Text('ID: #${a.id ?? "-"}',
                style: TextStyle(fontSize: 10, color: Colors.grey[400])),
            ])),
          ])),
          Expanded(flex: 2, child: Text(
            especialidadLabel(a.especialidad),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 2, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(
            DateFormat('d MMM,\nyyyy').format(a.dateTime),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
          Expanded(flex: 1, child: Text(
            DateFormat('hh:mm a').format(a.dateTime),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
          Expanded(flex: 2, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                decoration: BoxDecoration(
                    color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(a.statusLabel, style: TextStyle(
                color: statusColor, fontSize: 11,
                fontWeight: FontWeight.bold)),
            ]),
          )),

          // ✅ Botón pagar en la fila — solo pacientes
          if (_currentUser?.isPatient == true)
            Expanded(flex: 2, child: tienePago
                ? GestureDetector(
                    onTap: _irAPagos,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.5)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.payment_outlined,
                            color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 4),
                        const Text('Pagar',
                          style: TextStyle(
                            color: Color(0xFFF59E0B), fontSize: 11,
                            fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  )
                : const SizedBox()),

          SizedBox(width: 40, child: IconButton(
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            onPressed: () => _showMenu(a),
          )),
        ]),
      ),
    );
  }

  void _showMenu(Appointment a) {
    final tienePago = _tienePagoPendiente(a);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),

          // ✅ Opción pagar en el menú — solo pacientes con pago pendiente
          if (tienePago && _currentUser?.isPatient == true)
            ListTile(
              leading: const Icon(Icons.payment_outlined,
                  color: Color(0xFFF59E0B)),
              title: const Text('Pagar cita',
                style: TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _irAPagos();
              },
            ),

          if (a.status == AppointmentStatus.pendiente &&
              (_currentUser?.isPatient == true ||
                  _currentUser?.isDoctor == true))
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.orange),
              title: const Text('Editar cita'),
              onTap: () {
                Navigator.pop(context);
                _openEdit(a);
              },
            ),
          if (_currentUser?.isPatient == true)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar cita',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(a);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _confirmDelete(Appointment a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar cita'),
        content: const Text(
            '¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final r = await AppointmentService.delete(a.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(r['message']),
                  backgroundColor:
                      r['success'] ? Colors.green : Colors.red,
                ));
                if (r['success'] == true) _loadAppointments();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _th(String t) => Text(t, style: const TextStyle(
    fontSize: 11, fontWeight: FontWeight.bold,
    color: Color(0xFF4F46E5), letterSpacing: 0.5));
}
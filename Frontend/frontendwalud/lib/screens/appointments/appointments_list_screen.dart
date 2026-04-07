import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import 'appointment_detail_screen.dart';
import 'create_appointment_screen.dart';

class AppointmentsListScreen extends StatefulWidget {
  const AppointmentsListScreen({super.key});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  List<Appointment> _all = [];
  bool   _isLoading = true;
  String _filter    = 'todas';
  User?  _currentUser;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final r = await AuthService.getCurrentUser();
    if (r['success'] && mounted) setState(() => _currentUser = r['user']);
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    final r = await AppointmentService.getAll();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _all = r['success'] ? List<Appointment>.from(r['appointments']) : [];
      });
    }
  }

  List<Appointment> get _filtered {
    if (_filter == 'todas') return _all;
    return _all.where((a) => a.status.name == _filter).toList();
  }

  // Próxima cita pendiente
  Appointment? get _nextAppointment {
    final now = DateTime.now();
    final pending = _all.where((a) => a.status == AppointmentStatus.pendiente && a.dateTime.isAfter(now)).toList();
    if (pending.isEmpty) return null;
    pending.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return pending.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        color: const Color(0xFF4F46E5),
        child: CustomScrollView(
          slivers: [
            // ── Header
            SliverToBoxAdapter(child: _buildHeader()),
            // ── Próxima cita
            if (_nextAppointment != null)
              SliverToBoxAdapter(child: _buildNextAppointmentCard()),
            // ── Filtros
            SliverToBoxAdapter(child: _buildFilters()),
            // ── Lista
            if (_isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))))
            else if (_filtered.isEmpty)
              SliverFillRemaining(child: _buildEmpty())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildAppointmentRow(_filtered[i]),
                  childCount: _filtered.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: _currentUser?.isPatient == true
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => CreateAppointmentScreen(onCreated: _loadAppointments))),
              backgroundColor: const Color(0xFF4F46E5),
              icon: const Icon(Icons.add),
              label: const Text('Nueva Cita', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mis Citas',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
              Text('Gestiona y consulta el historial de tus consultas médicas.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${_all.length}',
              style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildNextAppointmentCard() {
    final next = _nextAppointment!;
    final now  = DateTime.now();
    final diff = next.dateTime.difference(now);
    final isToday    = diff.inHours < 24 && next.dateTime.day == now.day;
    final isTomorrow = next.dateTime.day == now.add(const Duration(days: 1)).day;
    String cuando = isToday ? 'Hoy' : (isTomorrow ? 'Mañana' : DateFormat('d MMM', 'es').format(next.dateTime));

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF4F46E5)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.notifications_active, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          const Text('Siguiente Consulta', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
        const SizedBox(height: 10),
        Text('Tu próxima cita es con ${next.doctorName} ${diff.inHours < 24 ? "en menos de 24 horas." : "."}',
          style: const TextStyle(color: Colors.white, fontSize: 14)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('FECHA', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
              Text(cuando, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ])),
            Container(width: 1, height: 36, color: Colors.white24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('HORA', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                  Text(DateFormat('hh:mm a').format(next.dateTime),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: next, onChanged: _loadAppointments))),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ver Preparación', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  Widget _buildFilters() {
    final filters = [
      {'key': 'todas',    'label': 'Todas'},
      {'key': 'pendiente','label': 'Pendientes'},
      {'key': 'realizada','label': 'Realizadas'},
      {'key': 'cancelada','label': 'Canceladas'},
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Tabla de citas header
          Expanded(child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final active = _filter == f['key'];
                return GestureDetector(
                  onTap: () => setState(() => _filter = f['key']!),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8, bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF4F46E5) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? const Color(0xFF4F46E5) : Colors.grey.shade300),
                    ),
                    child: Text(f['label']!,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.grey[600],
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      )),
                  ),
                );
              }).toList(),
            ),
          )),
        ]),
        // Columnas de tabla
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(flex: 3, child: _colHeader('MÉDICO')),
            Expanded(flex: 2, child: _colHeader('ESPECIALIDAD')),
            Expanded(flex: 2, child: _colHeader('FECHA')),
            Expanded(flex: 2, child: _colHeader('ESTADO')),
            const SizedBox(width: 32),
          ]),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ]),
    );
  }

  Widget _colHeader(String text) =>
    Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), letterSpacing: 0.5));

  Widget _buildAppointmentRow(Appointment a) {
    final statusColor = Color(int.parse('0x${a.statusColor}'));
    return Container(
      color: Colors.white,
      child: Column(children: [
        InkWell(
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: a, onChanged: _loadAppointments))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(children: [
              // Doctor
              Expanded(flex: 3, child: Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                  child: const Icon(Icons.person, color: Color(0xFF4F46E5), size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4F46E5))),
                  Text('ID: #${a.id ?? '-'}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ])),
              ])),
              // Especialidad
              Expanded(flex: 2, child: Text(
                especialidadLabel(a.especialidad),
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              )),
              // Fecha
              Expanded(flex: 2, child: Text(
                DateFormat('d MMM,\nyyyy').format(a.dateTime),
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              )),
              // Estado
              Expanded(flex: 2, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(a.statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
              )),
              // Acciones
              IconButton(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                onPressed: () => _showOptions(a),
              ),
            ]),
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade100, indent: 20, endIndent: 20),
      ]),
    );
  }

  void _showOptions(Appointment a) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.visibility, color: Color(0xFF4F46E5)),
            title: const Text('Ver detalle'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: a, onChanged: _loadAppointments)));
            },
          ),
          if (a.status == AppointmentStatus.pendiente && _currentUser?.isPatient == true)
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Editar cita'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: a, onChanged: _loadAppointments, editMode: true)));
              },
            ),
          if (_currentUser?.isPatient == true)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar cita', style: TextStyle(color: Colors.red)),
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
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Eliminar cita'),
      content: const Text('¿Estás seguro de que deseas eliminar esta cita? Esta acción no se puede deshacer.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final r = await AppointmentService.delete(a.id!);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(r['message']),
                backgroundColor: r['success'] ? Colors.green : Colors.red,
              ));
              if (r['success']) _loadAppointments();
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Eliminar'),
        ),
      ],
    ));
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('No hay citas ${_filter == "todas" ? "" : _filter + "s"}',
          style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        if (_currentUser?.isPatient == true && _filter == 'todas') ...[
          const SizedBox(height: 8),
          Text('Agenda tu primera cita', style: TextStyle(color: Colors.grey[400])),
        ],
      ]),
    );
  }
}
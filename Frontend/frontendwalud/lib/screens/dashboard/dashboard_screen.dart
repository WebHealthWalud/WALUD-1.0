import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../auth/login_screen.dart';
import '../appointments/appointments_list_screen.dart';
import '../appointments/create_appointment_screen.dart';
import '../profile/patient_profile_screen.dart';
import '../profile/doctor_profile_screen.dart';
import '../payments/payments_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int   _selectedIndex = 0;
  User? _currentUser;
  bool  _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final r = await AuthService.getCurrentUser();
    if (mounted) setState(() {
      _isLoading   = false;
      _currentUser = r['success'] ? r['user'] : null;
    });
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  List<_NavItem> get _navItems {
  final items = <_NavItem>[
    _NavItem(icon: Icons.grid_view_rounded,       label: 'Inicio'),
    _NavItem(icon: Icons.calendar_today_outlined,  label: 'Citas'),
    _NavItem(icon: Icons.history_outlined,         label: 'Historial'),
  ];
  if (_currentUser?.isPatient == true) {
    items.add(_NavItem(icon: Icons.payment_outlined, label: 'Pagos'));
    items.add(_NavItem(icon: Icons.headset_mic_outlined, label: 'Soporte'));
  }
  items.add(_NavItem(icon: Icons.person_outline, label: 'Perfil'));
  return items;
}

  int get _perfilIndex  => _navItems.length - 1;
  int get _pagosIndex   => _currentUser?.isPatient == true ? 3 : -1;
  int get _soporteIndex => _currentUser?.isPatient == true ? 4 : -1;

  Widget _buildScreen(int idx) {
  if (idx == 0) {
    return _HomeTab(
      user:       _currentUser,
      onNavigate: (i) => setState(() => _selectedIndex = i),
    );
  }
  if (idx == 1) return const AppointmentsListScreen();
  if (idx == 2) return _HistorialTab();
  if (idx == _pagosIndex)   return const PaymentsScreen();
  if (idx == _soporteIndex) return _SoporteTab();
  if (idx == _perfilIndex)  {
    if (_currentUser?.isDoctor == true) {
      return const DoctorProfileScreen();
    } else {
      return const PatientProfileScreen();
    }
  }
  return const SizedBox();
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Row(children: [
        _buildSidebar(),
        Expanded(child: _buildScreen(_selectedIndex)),
      ]),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                const Text('Walud', style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A7A),
                )),
              ]),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Text('SALUD DIGITAL', style: TextStyle(
                  fontSize: 9, letterSpacing: 1.5,
                  color: Colors.grey[400], fontWeight: FontWeight.w600,
                )),
              ),
            ]),
          ),
          const SizedBox(height: 32),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final item   = _navItems[i];
                final active = _selectedIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF4F46E5) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      gradient: active
                          ? const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                    ),
                    child: Row(children: [
                      Icon(item.icon,
                        color: active ? Colors.white : Colors.grey[500],
                        size: 20),
                      const SizedBox(width: 12),
                      Text(item.label, style: TextStyle(
                        color: active ? Colors.white : Colors.grey[600],
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      )),
                    ]),
                  ),
                );
              },
            ),
          ),

          // Nueva Cita
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const CreateAppointmentScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add, color: Color(0xFF4F46E5), size: 18),
                  SizedBox(width: 6),
                  Text('Nueva Cita', style: TextStyle(
                    color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13,
                  )),
                ]),
              ),
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade100),

          // Mini perfil sidebar
          InkWell(
            onTap: () => setState(() => _selectedIndex = _perfilIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _currentUser?.hasPhoto != true
                        ? const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)])
                        : null,
                    border: Border.all(
                      color: const Color(0xFF4F46E5).withOpacity(0.3), width: 2),
                  ),
                  child: _currentUser?.hasPhoto == true
                      ? ClipOval(child: Image.network(
                          '${_currentUser!.fullPhotoUrl!}?t=${DateTime.now().millisecondsSinceEpoch}',
                          key: ValueKey(_currentUser!.fullPhotoUrl),
                          fit: BoxFit.cover,
                          width: 36, height: 36,
                          errorBuilder: (_, __, ___) => Center(child: Text(
                            _currentUser?.name.isNotEmpty == true
                                ? _currentUser!.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          )),
                        ))
                      : Center(child: Text(
                          _currentUser?.name.isNotEmpty == true
                              ? _currentUser!.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        )),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_currentUser?.fullName ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A)),
                    overflow: TextOverflow.ellipsis),
                  Text(_currentUser?.isDoctor == true ? 'Médico' : 'Paciente',
                    style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                ])),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ]),
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade100),
          _sidebarFooterItem(Icons.help_outline,  'Ayuda', () {}),
          _sidebarFooterItem(Icons.logout, 'Cerrar Sesión', _handleLogout, isRed: true),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sidebarFooterItem(IconData icon, String label, VoidCallback onTap,
      {bool isRed = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
        child: Row(children: [
          Icon(icon, size: 18, color: isRed ? Colors.red.shade400 : Colors.grey[400]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(
            color: isRed ? Colors.red.shade400 : Colors.grey[500],
            fontSize: 13,
          )),
        ]),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String   label;
  const _NavItem({required this.icon, required this.label});
}

// ── HOME TAB
class _HomeTab extends StatefulWidget {
  final User?       user;
  final Function(int) onNavigate;
  const _HomeTab({this.user, required this.onNavigate});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Appointment? _nextAppointment;

  @override
  void initState() {
    super.initState();
    _loadNext();
  }

  Future<void> _loadNext() async {
    final r = await AppointmentService.getAll(status: 'pendiente');
    if (r['success'] == true && mounted) {
      final list     = List<Appointment>.from(r['appointments']);
      final now      = DateTime.now();
      final upcoming = list.where((a) => a.dateTime.isAfter(now)).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      setState(() => _nextAppointment = upcoming.isNotEmpty ? upcoming.first : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Hola, ${user?.name ?? 'Usuario'}',
            style: const TextStyle(
              fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF1A1A7A)))),
          if (_nextAppointment != null)
            _NextAppointmentCard(appointment: _nextAppointment!),
        ]),
        const SizedBox(height: 36),
        Row(children: [
          Expanded(child: _QuickCard(
            icon: Icons.calendar_month_outlined,
            iconColor: const Color(0xFF4F46E5),
            iconBg: const Color(0xFFEDE9FE),
            title: 'Agendar Cita',
            subtitle: 'Encuentra especialistas disponibles en tu zona hoy mismo para tu próxima revisión.',
            actionLabel: 'Comenzar',
            onTap: () => widget.onNavigate(1),
          )),
          const SizedBox(width: 20),
          Expanded(child: _QuickCard(
            icon: Icons.receipt_long_outlined,
            iconColor: const Color(0xFF0D9488),
            iconBg: const Color(0xFFCCFBF1),
            title: 'Ver Historial',
            subtitle: 'Accede a tus resultados, recetas y diagnósticos anteriores de forma segura.',
            actionLabel: 'Consultar',
            onTap: () => widget.onNavigate(2),
          )),
          if (user?.isPatient == true) ...[
            const SizedBox(width: 20),
            Expanded(child: _QuickCard(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFF7C3AED),
              iconBg: const Color(0xFFEDE9FE),
              title: 'Realizar Pago',
              subtitle: 'Gestiona tus facturas pendientes y métodos de pago seguros vinculados a tu cuenta.',
              actionLabel: 'Pagar ahora',
              onTap: () => widget.onNavigate(3),
            )),
          ],
        ]),
      ]),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _NextAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: const Color(0xFF4F46E5).withOpacity(0.3),
          blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('PRÓXIMA CITA', style: TextStyle(
              color: Colors.white, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          const Icon(Icons.calendar_today, color: Colors.white54, size: 16),
        ]),
        const SizedBox(height: 14),
        Text(appointment.doctorName, style: const TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${appointment.especialidad} • Clínica Walud',
          style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('FECHA', style: TextStyle(
                color: Colors.white38, fontSize: 9, letterSpacing: 1)),
              Text(DateFormat('d MMM', 'es').format(appointment.dateTime),
                style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(width: 24),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('HORA', style: TextStyle(
                color: Colors.white38, fontSize: 9, letterSpacing: 1)),
              Text(DateFormat('hh:mm a').format(appointment.dateTime),
                style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor, iconBg;
  final String   title, subtitle, actionLabel;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,       required this.iconColor,
    required this.iconBg,     required this.title,
    required this.subtitle,   required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 20),
        Text(title, style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.5)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onTap,
          child: Row(children: [
            Text(actionLabel, style: const TextStyle(
              color: Color(0xFF1A1A7A), fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF1A1A7A)),
          ]),
        ),
      ]),
    );
  }
}

class _HistorialTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.history, size: 80, color: Color(0xFF4F46E5)),
      SizedBox(height: 16),
      Text('Historial Médico', style: TextStyle(
        fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
      SizedBox(height: 8),
      Text('Próximamente disponible', style: TextStyle(color: Colors.grey)),
    ]),
  );
}

class _SoporteTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.headset_mic, size: 80, color: Color(0xFF4F46E5)),
      SizedBox(height: 16),
      Text('Soporte', style: TextStyle(
        fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
      SizedBox(height: 8),
      Text('Próximamente disponible', style: TextStyle(color: Colors.grey)),
    ]),
  );
}
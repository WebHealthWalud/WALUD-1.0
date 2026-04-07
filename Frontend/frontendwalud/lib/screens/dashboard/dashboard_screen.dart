import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../appointments/appointments_list_screen.dart';
import '../payments/payments_screens.dart';
import '../../models/user.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int   _selectedIndex = 0;
  User? _currentUser;
  bool  _isLoading     = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final result = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _isLoading   = false;
        _currentUser = result['success'] ? result['user'] : null;
      });
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))));

    // Definir pantallas según rol
    final screens = [
      _buildHomeTab(),
      const AppointmentsListScreen(),
      if (_currentUser?.isPatient == true) const PaymentsScreen(),
      _buildSupportTab(),
    ];

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
      const BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Citas'),
      if (_currentUser?.isPatient == true)
        const BottomNavigationBarItem(icon: Icon(Icons.payment_outlined), activeIcon: Icon(Icons.payment), label: 'Pagos'),
      const BottomNavigationBarItem(icon: Icon(Icons.headset_mic_outlined), activeIcon: Icon(Icons.headset_mic), label: 'Soporte'),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor:   const Color(0xFF4F46E5),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        items: items,
      ),
    );
  }

  // ── Pantalla HOME
  Widget _buildHomeTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('WALUD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _handleLogout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Saludo
          Text(
            'Hola, ${_currentUser?.name ?? 'Usuario'} 👋',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A)),
          ),
          Text(
            _currentUser?.isDoctor == true
                ? 'Dr. ${_currentUser?.lastName ?? ''} • ${_currentUser?.especialidad?.replaceAll('_', ' ') ?? ''}'
                : 'Bienvenido a tu portal de salud digital',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Tarjetas de acceso rápido
          const Text('Acceso rápido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A7A))),
          const SizedBox(height: 12),
          Row(children: [
            _quickCard(
              icon: Icons.calendar_today,
              color: const Color(0xFF4F46E5),
              title: 'Agendar Cita',
              subtitle: 'Reserva tu consulta',
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            const SizedBox(width: 12),
            _quickCard(
              icon: Icons.history,
              color: const Color(0xFF0EA5E9),
              title: 'Ver Historial',
              subtitle: 'Consultas anteriores',
              onTap: () => setState(() => _selectedIndex = 1),
            ),
          ]),
          if (_currentUser?.isPatient == true) ...[
            const SizedBox(height: 12),
            Row(children: [
              _quickCard(
                icon: Icons.payment,
                color: const Color(0xFF06B6D4),
                title: 'Realizar Pago',
                subtitle: 'Gestiona tus facturas',
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              const SizedBox(width: 12),
              _quickCard(
                icon: Icons.headset_mic,
                color: const Color(0xFF8B5CF6),
                title: 'Soporte',
                subtitle: 'Resuelve tus dudas',
                onTap: () => setState(() => _selectedIndex = _currentUser?.isPatient == true ? 3 : 2),
              ),
            ]),
          ],
          const SizedBox(height: 24),

          // Info del perfil
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF4F46E5).withOpacity(0.12),
                child: Text(
                  (_currentUser?.name ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_currentUser?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A7A))),
                Text(_currentUser?.email ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _currentUser?.isDoctor == true ? 'Médico' : 'Paciente',
                    style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _quickCard({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A7A))),
            Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            const SizedBox(height: 8),
            Row(children: [
              Text('Comenzar', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              Icon(Icons.chevron_right, size: 14, color: color),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildSupportTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Soporte', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4F46E5),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.headset_mic, size: 80, color: Color(0xFF4F46E5)),
          SizedBox(height: 16),
          Text('Chat de Soporte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
          SizedBox(height: 8),
          Text('Próximamente disponible', style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../config/constants.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ADMIN DASHBOARD
// ══════════════════════════════════════════════════════════════════════════════
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final r = await AuthService.getCurrentUser();
    if (mounted && r['success']) setState(() => _currentUser = r['user']);
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
  }

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, label: 'Panel Principal'),
    _NavItem(icon: Icons.people_alt_outlined, label: 'Gestión Usuarios'),
    _NavItem(icon: Icons.medical_services_outlined, label: 'Médicos'),
    _NavItem(icon: Icons.calendar_month_outlined, label: 'Citas'),
    _NavItem(icon: Icons.payment_outlined, label: 'Reportes de Pago'),
  ];

  Widget _buildScreen(int idx) {
    switch (idx) {
      case 0:
        return const _AdminHomeTab();
      case 1:
        return const AdminUsersScreen(filterRol: null);
      case 2:
        return const AdminUsersScreen(filterRol: 'medico');
      case 3:
        return const AdminAppointmentsScreen();
      case 4:
        return const AdminPaymentsScreen();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildScreen(_selectedIndex)),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Walud',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A7A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(left: 34),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'GESTIÓN ADMINISTRATIVA',
                    style: TextStyle(
                      fontSize: 7,
                      letterSpacing: 1,
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final item = _navItems[i];
                final active = _selectedIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: active
                          ? const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: active ? null : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          color: active ? Colors.white : Colors.grey[500],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: active ? Colors.white : Colors.grey[600],
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                      ),
                      border: Border.all(
                        color: const Color(0xFF4F46E5).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _currentUser?.name.isNotEmpty == true
                            ? _currentUser!.name[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser?.fullName ?? 'Administrador',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A7A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'ADMINISTRADOR',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF4F46E5),
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _footerItem(Icons.help_outline, 'Ayuda', () {}),
          _footerItem(
            Icons.logout,
            'Cerrar Sesión',
            _handleLogout,
            isRed: true,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _footerItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isRed = false,
  }) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isRed ? Colors.red.shade400 : Colors.grey[400],
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isRed ? Colors.red.shade400 : Colors.grey[500],
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ══════════════════════════════════════════════════════════════════════════════
// HOME TAB
// ══════════════════════════════════════════════════════════════════════════════
class _AdminHomeTab extends StatefulWidget {
  const _AdminHomeTab();
  @override
  State<_AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<_AdminHomeTab> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await AdminService.getStats();
    if (mounted)
      setState(() {
        _loading = false;
        if (r['success']) _stats = r['data'];
      });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF4F46E5),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Panel Principal',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A7A),
                      ),
                    ),
                    Text(
                      'Resumen general del sistema Walud',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        color: Color(0xFF10B981),
                        size: 8,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('d MMM yyyy').format(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              )
            else
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(
                    icon: Icons.people_alt_outlined,
                    iconBg: const Color(0xFFEDE9FE),
                    iconColor: const Color(0xFF4F46E5),
                    label: 'Total Usuarios',
                    value: '${_stats['total_usuarios'] ?? 0}',
                    trend: '+12%',
                    trendUp: true,
                  ),
                  _StatCard(
                    icon: Icons.medical_services_outlined,
                    iconBg: const Color(0xFFE0F2FE),
                    iconColor: const Color(0xFF0EA5E9),
                    label: 'Médicos Activos',
                    value: '${_stats['medicos_activos'] ?? 0}',
                    trend: '+4%',
                    trendUp: true,
                  ),
                  _StatCard(
                    icon: Icons.person_outline,
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF10B981),
                    label: 'Pacientes',
                    value: '${_stats['pacientes_registrados'] ?? 0}',
                    trend: '+18%',
                    trendUp: true,
                  ),
                  _StatCard(
                    icon: Icons.hourglass_empty_outlined,
                    iconBg: const Color(0xFFFEE2E2),
                    iconColor: const Color(0xFFEF4444),
                    label: 'Cuentas Inactivas',
                    value: '${_stats['cuentas_pendientes'] ?? 0}',
                    trend: '-2%',
                    trendUp: false,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label, value, trend;
  final bool trendUp;
  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: trendUp
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                trend,
                style: TextStyle(
                  color: trendUp ? const Color(0xFF10B981) : Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A7A),
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// GESTIÓN DE USUARIOS
// ══════════════════════════════════════════════════════════════════════════════
class AdminUsersScreen extends StatefulWidget {
  final String? filterRol;
  const AdminUsersScreen({super.key, this.filterRol});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<User> _users = [];
  bool _loading = true;
  String _filterTab = 'Todos';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? search}) async {
    setState(() => _loading = true);
    // Si filterRol está fijo (ej. 'medico'), siempre usarlo
    String? rol = widget.filterRol;
    if (rol == null) {
      if (_filterTab == 'Médicos') rol = 'medico';
      if (_filterTab == 'Pacientes') rol = 'paciente';
      if (_filterTab == 'Admin') rol = 'admin';
    }
    final r = await AdminService.getUsers(rol: rol, search: search);
    if (mounted)
      setState(() {
        _loading = false;
        _users = r['success'] == true ? List<User>.from(r['users']) : [];
      });
  }

  @override
  Widget build(BuildContext context) {
    final isMedicoTab = widget.filterRol == 'medico';
    final title = isMedicoTab ? 'Gestión de Médicos' : 'Gestión de Usuarios';

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF4F46E5),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A7A),
                        ),
                      ),
                      Text(
                        isMedicoTab
                            ? 'Administra los médicos registrados y sus especialidades.'
                            : 'Administra el acceso, roles y estados de todos los colaboradores y pacientes de la plataforma.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Botón crear usuario FUNCIONAL
                ElevatedButton.icon(
                  onPressed: () => _showUserFormDialog(null),
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: Text(
                    isMedicoTab ? 'Nuevo Médico' : 'Crear Nuevo Usuario',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Búsqueda
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => _load(search: v),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, correo o documento...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[400],
                          size: 18,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),

                  // Tabs (solo si no está fijo en médicos)
                  if (!isMedicoTab)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: ['Todos', 'Médicos', 'Pacientes', 'Admin']
                            .map((f) {
                              final active = _filterTab == f;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _filterTab = f);
                                  _load();
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? const Color(0xFF1A237E)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    f,
                                    style: TextStyle(
                                      color: active
                                          ? Colors.white
                                          : Colors.grey[500],
                                      fontWeight: active
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey.shade100),

                  // Cabecera tabla — con columna especialidad en vista médicos
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Expanded(flex: 3, child: _TH('NOMBRE')),
                        const Expanded(flex: 2, child: _TH('ROL')),
                        if (isMedicoTab)
                          const Expanded(flex: 2, child: _TH('ESPECIALIDAD')),
                        const Expanded(flex: 3, child: _TH('CORREO')),
                        const Expanded(flex: 2, child: _TH('ESTADO')),
                        const SizedBox(width: 130, child: _TH('ACCIONES')),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),

                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    )
                  else if (_users.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No hay usuarios',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._users.asMap().entries.map(
                      (e) => _UserRow(
                        user: e.value,
                        shaded: e.key.isOdd,
                        showEspecialidad: isMedicoTab,
                        onEdit: () => _showUserFormDialog(e.value),
                        onRol: () => _showRolDialog(e.value),
                        onToggleActive: () => _toggleActive(e.value),
                        onDelete: () => _confirmDelete(e.value),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Mostrando ${_users.length} usuarios',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FORMULARIO CREAR / EDITAR
  void _showUserFormDialog(User? userToEdit) {
    final isEdit = userToEdit != null;

    final nameCtrl = TextEditingController(text: userToEdit?.name ?? '');
    final lastNameCtrl = TextEditingController(
      text: userToEdit?.lastName ?? '',
    );
    final emailCtrl = TextEditingController(text: userToEdit?.email ?? '');
    final phoneCtrl = TextEditingController(text: userToEdit?.phone ?? '');
    final docCtrl = TextEditingController(
      text: userToEdit?.document?.toString() ?? '',
    );
    final passCtrl = TextEditingController();
    final birthCtrl = TextEditingController(text: userToEdit?.birthDate ?? '');

    String selectedRol = userToEdit?.isDoctor == true
        ? 'medico'
        : userToEdit?.isAdmin == true
        ? 'admin'
        : 'paciente';
    String? selectedEspecialidad = userToEdit?.especialidad;
    DocumentType docType =
        userToEdit?.documentType ?? DocumentType.cedulaCiudadania;
    bool obscurePass = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEdit ? Icons.edit_outlined : Icons.person_add_outlined,
                  color: const Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? 'Editar Usuario' : 'Crear Nuevo Usuario',
                style: const TextStyle(fontSize: 18, color: Color(0xFF1A1A7A)),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo de usuario
                  _fLabel('Tipo de usuario *'),
                  const SizedBox(height: 8),
                  Row(
                    children: ['paciente', 'medico', 'admin'].map((r) {
                      final sel = selectedRol == r;
                      final labels = {
                        'paciente': 'Paciente',
                        'medico': 'Médico',
                        'admin': 'Admin',
                      };
                      final icons = {
                        'paciente': Icons.person_outline,
                        'medico': Icons.medical_services_outlined,
                        'admin': Icons.admin_panel_settings_outlined,
                      };
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setS(() {
                            selectedRol = r;
                            if (r != 'medico') selectedEspecialidad = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFF4F46E5).withOpacity(0.08)
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel
                                    ? const Color(0xFF4F46E5)
                                    : Colors.grey.shade200,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  icons[r]!,
                                  size: 20,
                                  color: sel
                                      ? const Color(0xFF4F46E5)
                                      : Colors.grey,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  labels[r]!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: sel
                                        ? const Color(0xFF4F46E5)
                                        : Colors.grey[600],
                                    fontWeight: sel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Especialidad (solo médico)
                  if (selectedRol == 'medico') ...[
                    _fLabel('Especialidad *'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedEspecialidad,
                      decoration: _fDeco(
                        'Selecciona especialidad',
                        Icons.medical_services_outlined,
                      ),
                      items: kEspecialidades
                          .map(
                            (e) => DropdownMenuItem(
                              value: e['value'],
                              child: Text(
                                e['label']!,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setS(() => selectedEspecialidad = v),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Nombre y apellido
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _fField(
                          'Nombre *',
                          nameCtrl,
                          Icons.person_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _fField(
                          'Apellido *',
                          lastNameCtrl,
                          Icons.person_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tipo documento
                  _fLabel('Tipo de Documento'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<DocumentType>(
                    value: docType,
                    decoration: _fDeco('', Icons.badge_outlined),
                    items: DocumentType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              t.label,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setS(() => docType = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  _fField(
                    'Número de documento *',
                    docCtrl,
                    Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _fField(
                    'Correo electrónico *',
                    emailCtrl,
                    Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _fField(
                    'Teléfono',
                    phoneCtrl,
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),

                  // Fecha nacimiento
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime(1990),
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now().subtract(
                          const Duration(days: 365 * 5),
                        ),
                      );
                      if (d != null)
                        setS(
                          () => birthCtrl.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(d),
                        );
                    },
                    child: AbsorbPointer(
                      child: _fField(
                        'Fecha de nacimiento',
                        birthCtrl,
                        Icons.cake_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Contraseña solo en creación
                  if (!isEdit)
                    StatefulBuilder(
                      builder: (__, setSP) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fLabel('Contraseña *'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: passCtrl,
                            obscureText: obscurePass,
                            decoration: _fDeco('••••••••', Icons.lock_outline)
                                .copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePass
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        setSP(() => obscurePass = !obscurePass),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    emailCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nombre y correo son obligatorios'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (selectedRol == 'medico' && selectedEspecialidad == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selecciona la especialidad del médico'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (!isEdit && passCtrl.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'La contraseña debe tener al menos 6 caracteres',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);

                Map<String, dynamic> result;
                if (isEdit) {
                  result = await AdminService.updateUser(userToEdit!.id!, {
                    'name': nameCtrl.text.trim(),
                    'last_name': lastNameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'birth_date': birthCtrl.text.trim(),
                    'especialidad': selectedEspecialidad,
                  });
                  // Si cambió el rol, asignarlo
                  final currentRol = userToEdit.isDoctor
                      ? 'medico'
                      : userToEdit.isAdmin
                      ? 'admin'
                      : 'paciente';
                  if (selectedRol != currentRol) {
                    await AdminService.assignRole(
                      userToEdit.id!,
                      selectedRol,
                      especialidad: selectedEspecialidad,
                    );
                  }
                } else {
                  result = await AdminService.createUser({
                    'name': nameCtrl.text.trim(),
                    'last_name': lastNameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'password': passCtrl.text,
                    'phone': phoneCtrl.text.trim(),
                    'document': docCtrl.text.trim(),
                    'tipo_documento': docType.value,
                    'birth_date': birthCtrl.text.trim(),
                    'rol': selectedRol,
                    'especialidad': selectedEspecialidad,
                    'is_active': true,
                  });
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['success'] == true
                            ? (isEdit
                                  ? '✅ Usuario actualizado correctamente'
                                  : '✅ Usuario creado correctamente')
                            : (result['message'] ?? 'Error'),
                      ),
                      backgroundColor: result['success'] == true
                          ? const Color(0xFF10B981)
                          : Colors.red,
                    ),
                  );
                  if (result['success'] == true) _load();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(isEdit ? 'Guardar Cambios' : 'Crear Usuario'),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers del formulario
  Widget _fField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType? keyboardType,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _fLabel(label),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: _fDeco('', icon),
      ),
    ],
  );

  Widget _fLabel(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFF374151),
    ),
  );

  InputDecoration _fDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
    prefixIcon: Icon(icon, color: Colors.grey[400], size: 18),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
  );

  Future<void> _toggleActive(User user) async {
    final r = await AdminService.toggleActive(user.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            r['message'] ?? (r['success'] ? 'Actualizado' : 'Error'),
          ),
          backgroundColor: r['success'] == true
              ? const Color(0xFF10B981)
              : Colors.red,
        ),
      );
      if (r['success'] == true) _load();
    }
  }

  Future<void> _confirmDelete(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Eliminar a ${user.fullName}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final r = await AdminService.deleteUser(user.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              r['success'] == true ? 'Usuario eliminado' : 'Error al eliminar',
            ),
            backgroundColor: r['success'] == true
                ? const Color(0xFF10B981)
                : Colors.red,
          ),
        );
        if (r['success'] == true) _load();
      }
    }
  }

  void _showRolDialog(User user) {
    String selectedRol = user.isDoctor
        ? 'medico'
        : (user.isAdmin ? 'admin' : 'paciente');
    String? selectedEspecialidad;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cambiar Rol — ${user.fullName}'),
        content: StatefulBuilder(
          builder: (ctx, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...['paciente', 'medico', 'admin'].map(
                (r) => RadioListTile<String>(
                  value: r,
                  groupValue: selectedRol,
                  activeColor: const Color(0xFF4F46E5),
                  onChanged: (v) => setS(() => selectedRol = v!),
                  title: Text(
                    r == 'paciente'
                        ? 'Paciente'
                        : r == 'medico'
                        ? 'Médico'
                        : 'Administrador',
                  ),
                ),
              ),
              if (selectedRol == 'medico') ...[
                const Divider(),
                DropdownButtonFormField<String>(
                  value: selectedEspecialidad,
                  hint: const Text(
                    'Especialidad médica',
                    style: TextStyle(fontSize: 13),
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: kEspecialidades
                      .map(
                        (e) => DropdownMenuItem(
                          value: e['value'],
                          child: Text(
                            e['label']!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setS(() => selectedEspecialidad = v),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final r = await AdminService.assignRole(
                user.id!,
                selectedRol,
                especialidad: selectedEspecialidad,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      r['success'] == true
                          ? 'Rol asignado correctamente'
                          : (r['message'] ?? 'Error'),
                    ),
                    backgroundColor: r['success'] == true
                        ? const Color(0xFF10B981)
                        : Colors.red,
                  ),
                );
                if (r['success'] == true) _load();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

// ── Fila de usuario en tabla
class _UserRow extends StatelessWidget {
  final User user;
  final bool shaded, showEspecialidad;
  final VoidCallback onEdit, onRol, onToggleActive, onDelete;
  const _UserRow({
    required this.user,
    required this.shaded,
    this.showEspecialidad = false,
    required this.onEdit,
    required this.onRol,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rolColor = user.isAdmin
        ? const Color(0xFF7C3AED)
        : user.isDoctor
        ? const Color(0xFF0EA5E9)
        : const Color(0xFF10B981);

    return Container(
      color: shaded ? const Color(0xFFFAFAFC) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1A1A7A),
                        ),
                      ),
                      Text(
                        'ID: WAL-${user.id?.toString().padLeft(4, '0') ?? '0000'}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: rolColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.rolLabel,
                style: TextStyle(
                  color: rolColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // Especialidad visible en pestaña médicos
          if (showEspecialidad)
            Expanded(
              flex: 2,
              child: Text(
                user.especialidad != null
                    ? especialidadLabel(user.especialidad!)
                    : '—',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            flex: 3,
            child: Text(
              user.email,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Switch(
                  value: user.isActive,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (_) => onToggleActive(),
                ),
                Text(
                  user.isActive ? 'ACTIVO' : 'INACTIVO',
                  style: TextStyle(
                    color: user.isActive
                        ? const Color(0xFF10B981)
                        : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 130,
            child: Row(
              children: [
                _ActionBtn(
                  icon: Icons.edit_outlined,
                  color: Colors.orange,
                  onTap: onEdit,
                  tooltip: 'Editar',
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.manage_accounts_outlined,
                  color: const Color(0xFF4F46E5),
                  onTap: onRol,
                  tooltip: 'Cambiar rol',
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  onTap: onDelete,
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip ?? '',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    ),
  );
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Color(0xFF4F46E5),
      letterSpacing: 0.5,
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// SUPERVISIÓN DE CITAS
// ══════════════════════════════════════════════════════════════════════════════
class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});
  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  String _filter = 'todas';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? search}) async {
    setState(() => _loading = true);
    final r = await AdminService.getAppointments(
      status: _filter == 'todas' ? null : _filter,
      search: search,
    );
    if (mounted)
      setState(() {
        _loading = false;
        if (r['success']) _data = r['data'];
      });
  }

  @override
  Widget build(BuildContext context) {
    final appointments = (_data['data'] as List? ?? []);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Supervisión de Citas',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A7A),
            ),
          ),
          Text(
            'Revisa, supervisa y cancela citas si es necesario.',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Búsqueda por documento del paciente
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => _load(search: v),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText:
                          'Buscar por cédula, TI u otro documento del paciente...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[400],
                        size: 18,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                // Filtros estado
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      ...['todas', 'pendiente', 'realizada', 'cancelada'].map((
                        f,
                      ) {
                        final active = _filter == f;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _filter = f);
                            _load();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF1A237E)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              f[0].toUpperCase() + f.substring(1),
                              style: TextStyle(
                                color: active ? Colors.white : Colors.grey[500],
                                fontWeight: active
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade100),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: const [
                      Expanded(flex: 2, child: _TH('PACIENTE')),
                      Expanded(flex: 2, child: _TH('MÉDICO')),
                      Expanded(flex: 2, child: _TH('ESPECIALIDAD')),
                      Expanded(flex: 2, child: _TH('FECHA')),
                      Expanded(flex: 2, child: _TH('ESTADO')),
                      SizedBox(width: 90, child: _TH('ACCIÓN')),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade100),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  )
                else if (appointments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay citas',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...appointments.asMap().entries.map((e) {
                    final a = e.value as Map<String, dynamic>;
                    final stat = a['status'] ?? 'pendiente';
                    final stColor = stat == 'pendiente'
                        ? const Color(0xFFD97706)
                        : stat == 'realizada'
                        ? const Color(0xFF10B981)
                        : Colors.grey;
                    return Container(
                      color: e.key.isOdd
                          ? const Color(0xFFFAFAFC)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a['patient_name'] ?? '—',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF1A1A7A),
                                  ),
                                ),
                                Text(
                                  'Doc: ${a['patient_document'] ?? '—'}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${a['doctor']?['name'] ?? '—'} ${a['doctor']?['last_name'] ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              a['especialidad'] ?? '—',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              a['date'] != null
                                  ? a['date'].toString().substring(0, 10)
                                  : '—',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: stColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: stColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    stat[0].toUpperCase() + stat.substring(1),
                                    style: TextStyle(
                                      color: stColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: stat == 'pendiente'
                                ? TextButton(
                                    onPressed: () async {
                                      final r =
                                          await AdminService.cancelAppointment(
                                            a['id'],
                                          );
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              r['success'] == true
                                                  ? 'Cita cancelada'
                                                  : 'Error',
                                            ),
                                            backgroundColor:
                                                r['success'] == true
                                                ? const Color(0xFF10B981)
                                                : Colors.red,
                                          ),
                                        );
                                        if (r['success'] == true) _load();
                                      }
                                    },
                                    child: const Text(
                                      'Cancelar',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    );
                  }),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${appointments.length} citas encontradas',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REPORTES DE PAGO
// ══════════════════════════════════════════════════════════════════════════════
class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});
  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final statsR = await AdminService.getPaymentStats();
    final dataR = await AdminService.getPayments();
    if (mounted)
      setState(() {
        _loading = false;
        if (statsR['success']) _stats = statsR['data'];
        if (dataR['success']) _data = dataR['data'];
      });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final payments = (_data['data'] as List? ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reportes de Pago',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A7A),
            ),
          ),
          Text(
            'Monitorea pagos, detecta fallos y verifica estados de transacciones.',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 24),

          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _PayStatCard(
                    label: 'Total completado',
                    value: '\$${fmt.format(_stats['total_completado'] ?? 0)}',
                    color: const Color(0xFF10B981),
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PayStatCard(
                    label: 'Pendiente',
                    value: '\$${fmt.format(_stats['total_pendiente'] ?? 0)}',
                    color: const Color(0xFFD97706),
                    icon: Icons.hourglass_empty_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PayStatCard(
                    label: 'Cancelado',
                    value: '\$${fmt.format(_stats['total_cancelado'] ?? 0)}',
                    color: Colors.red,
                    icon: Icons.cancel_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: const [
                        Expanded(flex: 3, child: _TH('PACIENTE')),
                        Expanded(flex: 3, child: _TH('CONCEPTO')),
                        Expanded(flex: 1, child: _TH('TIPO')),
                        Expanded(flex: 2, child: _TH('MONTO')),
                        Expanded(flex: 2, child: _TH('ESTADO')),
                        Expanded(flex: 2, child: _TH('FECHA')),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade100),
                  if (payments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No hay pagos',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    )
                  else
                    ...payments.asMap().entries.map((e) {
                      final p = e.value as Map<String, dynamic>;
                      final stat = p['estado_pago'] ?? 'pendiente';
                      final stColor = stat == 'completado'
                          ? const Color(0xFF10B981)
                          : stat == 'pendiente'
                          ? const Color(0xFFD97706)
                          : Colors.red;
                      return Container(
                        color: e.key.isOdd
                            ? const Color(0xFFFAFAFC)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${p['patient']?['name'] ?? '—'} ${p['patient']?['last_name'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF1A1A7A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                p['concepto'] ?? '—',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                p['tipo'] ?? '—',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '\$${fmt.format(double.tryParse(p['monto']?.toString() ?? '0') ?? 0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A7A),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: stColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  stat[0].toUpperCase() + stat.substring(1),
                                  style: TextStyle(
                                    color: stColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                p['created_at'] != null
                                    ? p['created_at'].toString().substring(
                                        0,
                                        10,
                                      )
                                    : '—',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${payments.length} transacciones',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PayStatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _PayStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

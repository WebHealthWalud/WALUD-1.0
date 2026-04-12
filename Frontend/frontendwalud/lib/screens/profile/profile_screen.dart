// lib/screens/profile/profile_screen.dart
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User?  _user;
  bool   _isLoading   = true;
  bool   _isSaving    = false;
  bool   _isUploadingPhoto = false;

  // ── Controladores edición de datos
  late TextEditingController _nameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _birthDateCtrl;

  // ── Controladores cambio de contraseña
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureCurrent   = true;
  bool _obscureNew       = true;
  bool _obscureConfirm   = true;
  bool _isChangingPass   = false;

  // ── Indicadores de fortaleza
  bool get _hasLength  => _newPassCtrl.text.length >= 8;
  bool get _hasUpper   => _newPassCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLower   => _newPassCtrl.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber  => _newPassCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _newPassCtrl.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
  int  get _strength   => [_hasLength, _hasUpper, _hasLower, _hasNumber, _hasSpecial].where((b) => b).length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _nameCtrl      = TextEditingController();
    _lastNameCtrl  = TextEditingController();
    _emailCtrl     = TextEditingController();
    _phoneCtrl     = TextEditingController();
    _birthDateCtrl = TextEditingController();
    _newPassCtrl.addListener(() => setState(() {}));
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final r = await ProfileService.getProfile();
    if (r['success'] == true && mounted) {
      final user = r['user'] as User;
      setState(() {
        _user          = user;
        _isLoading     = false;
        _nameCtrl.text     = user.name;
        _lastNameCtrl.text = user.lastName ?? '';
        _emailCtrl.text    = user.email;
        _phoneCtrl.text    = user.phone ?? '';
        _birthDateCtrl.text = user.birthDate ?? '';
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // ── Seleccionar y subir foto
  Future<void> _pickAndUploadPhoto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    String?    filePath;
    Uint8List? fileBytes;

    if (kIsWeb) {
      if (file.bytes == null) return;
      fileBytes = file.bytes;
    } else {
      if (file.path == null) return;
      filePath = file.path;
    }

    setState(() => _isUploadingPhoto = true);

    final r = await ProfileService.uploadPhoto(
      fileName:  file.name,
      filePath:  filePath,
      fileBytes: fileBytes,
    );

    setState(() => _isUploadingPhoto = false);

    if (mounted) {
      if (r['success'] == true) {
        // ✅ Recargar perfil completo desde el servidor para obtener URL actualizada
        await _loadProfile();
        _showSnack('✅ Foto de perfil actualizada', Colors.green);
        widget.onProfileUpdated?.call(); // ✅ notificar al dashboard
      } else {
        _showSnack(r['message'] ?? 'Error', Colors.red);
      }
    }
  }

  // ── Eliminar foto
  Future<void> _deletePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar foto'),
        content: const Text('¿Estás seguro de que deseas eliminar tu foto de perfil?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final r = await ProfileService.deletePhoto();
    if (mounted) {
      if (r['success'] == true) {
        setState(() => _user = User(
          id: _user!.id, name: _user!.name, email: _user!.email,
          document: _user!.document, documentType: _user!.documentType,
          lastName: _user!.lastName, birthDate: _user!.birthDate,
          userType: _user!.userType, especialidad: _user!.especialidad,
          phone: _user!.phone, profilePhotoPath: null, photoUrl: null,
        ));
        _showSnack('Foto eliminada', Colors.grey);
      } else {
        _showSnack(r['message'] ?? 'Error', Colors.red);
      }
    }
  }

  // ── Guardar datos personales
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final r = await ProfileService.updateProfile(
      name:      _nameCtrl.text.trim(),
      lastName:  _lastNameCtrl.text.trim(),
      email:     _emailCtrl.text.trim(),
      birthDate: _birthDateCtrl.text.trim(),
      phone:     _phoneCtrl.text.trim(),
    );
    setState(() => _isSaving = false);

    if (mounted) {
      if (r['success'] == true) {
        setState(() => _user = r['user'] as User);
        _showSnack('✅ Perfil actualizado correctamente', Colors.green);
        widget.onProfileUpdated?.call(); // ✅ notificar al dashboard
      } else {
        _showSnack(r['message'] ?? 'Error al guardar', Colors.red);
      }
    }
  }

  // ── Cambiar contraseña
  Future<void> _changePassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      _showSnack('Las contraseñas no coinciden', Colors.red);
      return;
    }
    if (_strength < 5) {
      _showSnack('La contraseña no cumple los requisitos de seguridad', Colors.orange);
      return;
    }
    setState(() => _isChangingPass = true);

    final r = await ProfileService.changePassword(
      currentPassword: _currentPassCtrl.text,
      newPassword:     _newPassCtrl.text,
      confirmation:    _confirmPassCtrl.text,
    );

    setState(() => _isChangingPass = false);

    if (mounted) {
      if (r['success'] == true) {
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        _showSnack('✅ Contraseña actualizada correctamente', Colors.green);
      } else {
        _showSnack(r['message'] ?? 'Error', Colors.red);
      }
    }
  }

  Future<void> _selectBirthDate() async {
    DateTime initial = DateTime(1990);
    try {
      if (_birthDateCtrl.text.isNotEmpty) {
        initial = DateTime.parse(_birthDateCtrl.text);
      }
    } catch (_) {}

    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
    );
    if (d != null && mounted) {
      setState(() => _birthDateCtrl.text = DateFormat('yyyy-MM-dd').format(d));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Mi Perfil', style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A7A),
            )),
            Text('Administra tu información personal y configuración de cuenta.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ])),
        ]),
        const SizedBox(height: 24),

        // ── Avatar + info básica
        _buildAvatarCard(),
        const SizedBox(height: 20),

        // ── Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            // Tab bar
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF4F46E5),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Datos'),
                  Tab(icon: Icon(Icons.lock_outline, size: 18), text: 'Contraseña'),
                  Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Cuenta'),
                ],
              ),
            ),
            // Tab content
            SizedBox(
              height: 480,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDatosTab(),
                  _buildPasswordTab(),
                  _buildCuentaTab(),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Avatar card
  Widget _buildAvatarCard() {
    final photoUrl = _user?.fullPhotoUrl;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        // Avatar
        Stack(children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: photoUrl == null
                  ? const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)])
                  : null,
              border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3), width: 3),
            ),
            child: photoUrl != null
                ? ClipOval(child: _buildNetworkImage(photoUrl!))
                : _avatarFallback(),
          ),
          // Botón cámara
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: _isUploadingPhoto
                    ? const Padding(
                        padding: EdgeInsets.all(5),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
              ),
            ),
          ),
        ]),
        const SizedBox(width: 20),

        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_user?.fullName ?? '', style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A),
          )),
          const SizedBox(height: 4),
          Text(_user?.email ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            _badge(
              _user?.isDoctor == true ? 'Médico' : 'Paciente',
              _user?.isDoctor == true ? const Color(0xFF4F46E5) : const Color(0xFF06B6D4),
            ),
            if (_user?.especialidad != null) ...[
              const SizedBox(width: 8),
              _badge(especialidadLabel(_user!.especialidad!), Colors.grey),
            ],
          ]),
        ])),

        // Eliminar foto
        if (_user?.hasPhoto == true)
          IconButton(
            onPressed: _deletePhoto,
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            tooltip: 'Eliminar foto',
          ),
      ]),
    );
  }

  // ✅ Widget de imagen que maneja errores de CORS en Flutter Web
  Widget _buildNetworkImage(String url) {
    // Agregar timestamp para evitar cache cuando se cambia la foto
    final urlWithCache = url.contains('?')
        ? '$url&t=${DateTime.now().millisecondsSinceEpoch}'
        : '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    return Image.network(
      urlWithCache,
      fit: BoxFit.cover,
      width: 90,
      height: 90,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Center(child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: const Color(0xFF4F46E5),
            )),
      errorBuilder: (_, error, __) {
        debugPrint('Error cargando foto: $error — URL: $urlWithCache');
        return _avatarFallback();
      },
    );
  }

  Widget _avatarFallback() => Center(
    child: Text(
      _user?.name.isNotEmpty == true ? _user!.name[0].toUpperCase() : '?',
      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
    ),
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
  );

  // ── Tab 1: Datos personales
  Widget _buildDatosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _field('Nombre', _nameCtrl, Icons.person_outline)),
          const SizedBox(width: 16),
          Expanded(child: _field('Apellido', _lastNameCtrl, Icons.person_outline)),
        ]),
        const SizedBox(height: 16),
        _field('Correo electrónico', _emailCtrl, Icons.alternate_email,
          keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _field('Teléfono', _phoneCtrl, Icons.phone_outlined,
            keyboardType: TextInputType.phone)),
          const SizedBox(width: 16),
          Expanded(child: InkWell(
            onTap: _selectBirthDate,
            child: AbsorbPointer(
              child: _field('Fecha de Nacimiento', _birthDateCtrl, Icons.cake_outlined),
            ),
          )),
        ]),

        // Documento (solo lectura)
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(children: [
            Icon(Icons.badge_outlined, color: Colors.grey[400], size: 18),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Documento (no editable)', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              Text('${_user?.documentType?.label ?? "CC"} — ${_user?.document ?? "—"}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            ]),
          ]),
        ),

        if (_user?.isDoctor == true && _user?.especialidad != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.medical_services_outlined, color: Color(0xFF4F46E5), size: 18),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Especialidad médica', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 11)),
                Text(especialidadLabel(_user!.especialidad!),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
              ]),
            ]),
          ),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Guardar Cambios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ]),
    );
  }

  // ── Tab 2: Cambiar contraseña
  Widget _buildPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _passField('Contraseña actual', _currentPassCtrl, _obscureCurrent,
          () => setState(() => _obscureCurrent = !_obscureCurrent)),
        const SizedBox(height: 16),
        _passField('Nueva contraseña', _newPassCtrl, _obscureNew,
          () => setState(() => _obscureNew = !_obscureNew)),

        // Indicador de fortaleza
        if (_newPassCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildStrengthIndicator(),
        ],
        const SizedBox(height: 16),
        _passField('Confirmar nueva contraseña', _confirmPassCtrl, _obscureConfirm,
          () => setState(() => _obscureConfirm = !_obscureConfirm)),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isChangingPass ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isChangingPass
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Cambiar Contraseña', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ]),
    );
  }

  Widget _buildStrengthIndicator() {
    final color = _strength <= 2 ? Colors.red
        : _strength <= 3 ? Colors.orange
        : _strength <= 4 ? Colors.yellow.shade700
        : Colors.green;
    final label = _strength <= 2 ? 'Débil' : _strength <= 3 ? 'Regular' : _strength <= 4 ? 'Buena' : 'Fuerte';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _strength / 5,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        )),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 4, children: [
        _reqBadge('8+ chars', _hasLength),
        _reqBadge('Mayúscula', _hasUpper),
        _reqBadge('Minúscula', _hasLower),
        _reqBadge('Número', _hasNumber),
        _reqBadge('Especial', _hasSpecial),
      ]),
    ]);
  }

  Widget _reqBadge(String label, bool met) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: met ? Colors.green.withOpacity(0.1) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: met ? Colors.green.shade300 : Colors.grey.shade300),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(met ? Icons.check : Icons.close, size: 11, color: met ? Colors.green : Colors.grey),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 10, color: met ? Colors.green : Colors.grey, fontWeight: FontWeight.w500)),
    ]),
  );

  // ── Tab 3: Info de cuenta
  Widget _buildCuentaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _infoTile(Icons.perm_identity, 'ID de usuario', '#${_user?.id ?? "—"}'),
        _infoTile(Icons.calendar_today_outlined, 'Fecha de nacimiento',
          _user?.birthDate != null
              ? DateFormat('d MMMM yyyy', 'es').format(DateTime.tryParse(_user!.birthDate!) ?? DateTime.now())
              : 'No registrada'),
        _infoTile(Icons.phone_outlined, 'Teléfono', _user?.phone?.isNotEmpty == true ? _user!.phone! : 'No registrado'),
        _infoTile(Icons.work_outline, 'Tipo de usuario',
          _user?.isDoctor == true ? 'Médico' : 'Paciente'),
        if (_user?.especialidad != null)
          _infoTile(Icons.medical_services_outlined, 'Especialidad',
            especialidadLabel(_user!.especialidad!)),
        const Divider(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.warning_amber_outlined, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('Zona de peligro', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            const Text('Una vez que elimines tu cuenta, no podrás recuperar tu información.',
              style: TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _showSnack('Contacta al soporte para eliminar tu cuenta', Colors.orange),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Solicitar eliminación de cuenta'),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF4F46E5).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF4F46E5), size: 18),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A7A), fontSize: 14)),
      ]),
    ]),
  );

  // ── Helpers
  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18, color: Colors.grey[400]),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);

  Widget _passField(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock_outline, size: 18, color: Colors.grey[400]),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey, size: 18),
            onPressed: toggle,
          ),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose(); _lastNameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _birthDateCtrl.dispose();
    _currentPassCtrl.dispose(); _newPassCtrl.dispose(); _confirmPassCtrl.dispose();
    super.dispose();
  }
}
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/patient_profile.dart';
import '../../models/patient_document.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/patient_profile_service.dart';
import '../../services/patient_document_service.dart';
import '../../services/profile_service.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  User?                 _user;
  PatientProfile?       _profile;
  List<PatientDocument> _documents      = [];
  bool _isLoading         = true;
  bool _isSaving          = false;
  bool _isUploading       = false;
  bool _isUploadingPhoto  = false;
  bool _showCompleteForm  = false;

  // Controladores perfil
  final _pesoCtrl             = TextEditingController();
  final _tallaCtrl            = TextEditingController();
  final _direccionCtrl        = TextEditingController();
  final _ciudadCtrl           = TextEditingController();
  final _contactoNombreCtrl   = TextEditingController();
  final _contactoTelefonoCtrl = TextEditingController();
  final _contactoRelacionCtrl = TextEditingController();

  // ✅ Seguridad
  bool _isChangingPass   = false;
  bool _showSecurityForm = false;
  bool _obscureCurrent   = true;
  bool _obscureNew       = true;
  bool _obscureConfirm   = true;
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool get _hasLength  => _newPassCtrl.text.length >= 8;
  bool get _hasUpper   => _newPassCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLower   => _newPassCtrl.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber  => _newPassCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _newPassCtrl.text.contains(
      RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
  int get _strength => [
    _hasLength, _hasUpper, _hasLower, _hasNumber, _hasSpecial
  ].where((b) => b).length;

  @override
  void initState() {
    super.initState();
    _loadData();
    _newPassCtrl.addListener(() => setState(() {}));
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userR    = await AuthService.getCurrentUser();
    final profileR = await PatientProfileService.getProfile();
    final docsR    = await PatientDocumentService.getAll();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (userR['success'])    _user    = userR['user'];
        if (profileR['success']) {
          _profile = profileR['profile'];
          if (_profile?.peso != null)
            _pesoCtrl.text = _profile!.peso.toString();
          if (_profile?.talla != null)
            _tallaCtrl.text = _profile!.talla.toString();
          if (_profile?.direccion != null)
            _direccionCtrl.text = _profile!.direccion!;
          if (_profile?.ciudad != null)
            _ciudadCtrl.text = _profile!.ciudad!;
          if (_profile?.contactoEmergenciaNombre != null)
            _contactoNombreCtrl.text = _profile!.contactoEmergenciaNombre!;
          if (_profile?.contactoEmergenciaTelefono != null)
            _contactoTelefonoCtrl.text = _profile!.contactoEmergenciaTelefono!;
          if (_profile?.contactoEmergenciaRelacion != null)
            _contactoRelacionCtrl.text = _profile!.contactoEmergenciaRelacion!;
        }
        if (docsR['success'])
          _documents = List<PatientDocument>.from(docsR['documents']);
      });
    }
  }

  int _calcularEdad(String? birthDate) {
    if (birthDate == null) return 0;
    final birth = DateTime.tryParse(birthDate);
    if (birth == null) return 0;
    final now = DateTime.now();
    int age   = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) age--;
    return age;
  }

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
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Foto actualizada correctamente'),
          backgroundColor: Color(0xFF10B981),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r['message'] ?? 'Error al subir foto'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final r = await PatientProfileService.updateProfile(
      peso:             double.tryParse(_pesoCtrl.text),
      talla:            double.tryParse(_tallaCtrl.text),
      direccion:        _direccionCtrl.text.trim().isNotEmpty ? _direccionCtrl.text.trim() : null,
      ciudad:           _ciudadCtrl.text.trim().isNotEmpty ? _ciudadCtrl.text.trim() : null,
      contactoNombre:   _contactoNombreCtrl.text.trim().isNotEmpty ? _contactoNombreCtrl.text.trim() : null,
      contactoTelefono: _contactoTelefonoCtrl.text.trim().isNotEmpty ? _contactoTelefonoCtrl.text.trim() : null,
      contactoRelacion: _contactoRelacionCtrl.text.trim().isNotEmpty ? _contactoRelacionCtrl.text.trim() : null,
    );
    setState(() => _isSaving = false);

    if (mounted) {
      if (r['success'] == true) {
        setState(() {
          _profile          = r['profile'];
          _showCompleteForm = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Perfil actualizado correctamente'),
          backgroundColor: Color(0xFF10B981),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r['message'] ?? 'Error'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ✅ Cambiar contraseña
  Future<void> _changePassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Las contraseñas no coinciden'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_strength < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('La contraseña no cumple los requisitos de seguridad'),
        backgroundColor: Colors.orange,
      ));
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
        setState(() => _showSecurityForm = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Contraseña actualizada correctamente'),
          backgroundColor: Color(0xFF10B981),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r['message'] ?? 'Error'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _pickAndUploadDocument() async {
    String? tipoSeleccionado = await _showTipoDocumentoDialog();
    if (tipoSeleccionado == null) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    final nombreCtrl = TextEditingController(text: file.name.split('.').first);
    final nombre = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nombre del documento'),
        content: TextField(
          controller: nombreCtrl,
          decoration: const InputDecoration(hintText: 'Ej: Análisis de sangre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nombreCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            child: const Text('Subir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (nombre == null || nombre.isEmpty) return;

    setState(() => _isUploading = true);
    final r = await PatientDocumentService.upload(
      nombre:    nombre,
      tipo:      tipoSeleccionado,
      fileName:  file.name,
      filePath:  kIsWeb ? null : file.path,
      fileBytes: kIsWeb ? file.bytes : null,
    );
    setState(() => _isUploading = false);

    if (mounted) {
      if (r['success'] == true) {
        setState(() => _documents.insert(0, r['document']));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Documento subido correctamente'),
          backgroundColor: Color(0xFF10B981),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r['message'] ?? 'Error'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<String?> _showTipoDocumentoDialog() {
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tipo de documento'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _tipoOption('analisis',    'Análisis',    Icons.science_outlined),
          _tipoOption('radiografia', 'Radiografía', Icons.image_outlined),
          _tipoOption('receta',      'Receta',      Icons.medication_outlined),
          _tipoOption('informe',     'Informe',     Icons.description_outlined),
          _tipoOption('vacuna',      'Vacuna',      Icons.vaccines_outlined),
          _tipoOption('otro',        'Otro',        Icons.folder_outlined),
        ]),
      ),
    );
  }

  Widget _tipoOption(String value, String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4F46E5)),
      title: Text(label),
      onTap: () => Navigator.pop(context, value),
    );
  }

  Future<void> _deleteDocument(PatientDocument doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar documento'),
        content: Text('¿Eliminar "${doc.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final r = await PatientDocumentService.delete(doc.id!);
    if (mounted && r['success'] == true) {
      setState(() => _documents.removeWhere((d) => d.id == doc.id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Documento eliminado'),
        backgroundColor: Colors.grey,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_profile?.isComplete == false) _buildIncompleteBanner(),
        _buildHeader(),
        const SizedBox(height: 24),
        if (_showCompleteForm) ...[
          _buildCompleteProfileForm(),
          const SizedBox(height: 24),
        ],
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: [
            _buildFichaMedica(),
            const SizedBox(height: 20),
            _buildContactoEmergencia(),
          ])),
          const SizedBox(width: 20),
          Expanded(child: Column(children: [
            _buildHistorialCitas(),
            const SizedBox(height: 20),
            _buildDocumentosMedicos(),
          ])),
        ]),
        // ✅ Sección seguridad
        const SizedBox(height: 20),
        _buildSecurityCard(),
      ]),
    );
  }

  Widget _buildIncompleteBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Perfil incompleto', style: TextStyle(
            fontWeight: FontWeight.bold, color: Color(0xFF92400E), fontSize: 14,
          )),
          const SizedBox(height: 2),
          const Text(
            'Completa tu perfil con peso, talla, dirección y contacto de emergencia.',
            style: TextStyle(color: Color(0xFF92400E), fontSize: 12)),
        ])),
        TextButton(
          onPressed: () => setState(() => _showCompleteForm = true),
          child: const Text('Completar', style: TextStyle(
            color: Color(0xFFF59E0B), fontWeight: FontWeight.bold,
          )),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    final edad = _calcularEdad(_user?.birthDate);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Stack(children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              gradient: _user?.hasPhoto != true
                  ? const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)])
                  : null,
            ),
            child: _user?.hasPhoto == true
                ? ClipOval(child: Image.network(
                    '${_user!.fullPhotoUrl!}?t=${DateTime.now().millisecondsSinceEpoch}',
                    key: ValueKey(_user!.fullPhotoUrl),
                    fit: BoxFit.cover,
                    width: 80, height: 80,
                    errorBuilder: (_, __, ___) => _avatarFallback(),
                  ))
                : _avatarFallback(),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: _isUploadingPhoto
                    ? const Padding(
                        padding: EdgeInsets.all(4),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.camera_alt,
                        color: Colors.white, size: 14),
              ),
            ),
          ),
        ]),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_user?.fullName ?? '', style: const TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.cake_outlined, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text('$edad años',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(width: 16),
            if (_profile?.ciudad != null) ...[
              const Icon(Icons.location_on_outlined,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(_profile!.ciudad!,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.fingerprint, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              'ID: WL-${_user?.id?.toString().padLeft(5, '0') ?? '00000'}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ])),
        ElevatedButton.icon(
          onPressed: () =>
              setState(() => _showCompleteForm = !_showCompleteForm),
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Editar Perfil'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1A237E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ]),
    );
  }

  Widget _buildCompleteProfileForm() {
    return _card(
      title: 'Completar Perfil',
      icon:  Icons.edit_outlined,
      child: Column(children: [
        Row(children: [
          Expanded(child: _field('Peso (kg)', _pesoCtrl,
            icon: Icons.monitor_weight_outlined,
            keyboardType: TextInputType.number,
          )),
          const SizedBox(width: 16),
          Expanded(child: _field('Talla (m)', _tallaCtrl,
            icon: Icons.height,
            keyboardType: TextInputType.number,
          )),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _field('Dirección', _direccionCtrl,
            icon: Icons.home_outlined)),
          const SizedBox(width: 16),
          Expanded(child: _field('Ciudad', _ciudadCtrl,
            icon: Icons.location_city_outlined)),
        ]),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Contacto de Emergencia', style: TextStyle(
            fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A),
          )),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field('Nombre', _contactoNombreCtrl,
            icon: Icons.person_outline)),
          const SizedBox(width: 16),
          Expanded(child: _field('Teléfono', _contactoTelefonoCtrl,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          )),
        ]),
        const SizedBox(height: 16),
        _field('Relación (Ej: Madre, Esposo)', _contactoRelacionCtrl,
          icon: Icons.people_outline),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => setState(() => _showCompleteForm = false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4F46E5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF4F46E5))),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                : const Text('Guardar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          )),
        ]),
      ]),
    );
  }

  Widget _buildFichaMedica() {
    return _card(
      title: 'Ficha Médica',
      icon:  Icons.medical_information_outlined,
      child: Column(children: [
        Row(children: [
          Expanded(child: _fichaItem(
            'TIPO DE SANGRE',
            _user?.tipoSangre ?? '—',
            const Color(0xFFEF4444),
            Icons.water_drop_outlined,
          )),
          const SizedBox(width: 12),
          Expanded(child: _fichaItem(
            'PESO',
            _profile?.peso != null ? '${_profile!.peso} kg' : '—',
            const Color(0xFF4F46E5),
            Icons.monitor_weight_outlined,
          )),
          const SizedBox(width: 12),
          Expanded(child: _fichaItem(
            'TALLA',
            _profile?.talla != null ? '${_profile!.talla} m' : '—',
            const Color(0xFF06B6D4),
            Icons.height,
          )),
        ]),
        if (_user?.alergias != null && _user!.alergias!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('ALERGIAS', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold,
              color: Colors.grey, letterSpacing: 1,
            )),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8, runSpacing: 6,
              children: _user!.alergias!.split(',').map((a) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(a.trim(), style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 12, fontWeight: FontWeight.w500,
                )),
              )).toList(),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _fichaItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(
          fontSize: 9, color: Colors.grey,
          letterSpacing: 1, fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: color,
        )),
      ]),
    );
  }

  Widget _buildContactoEmergencia() {
    final tieneContacto = _profile?.contactoEmergenciaNombre != null;
    return _card(
      title: 'Contacto de Emergencia',
      icon:  Icons.emergency_outlined,
      child: tieneContacto
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_profile!.contactoEmergenciaNombre!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 16,
                      )),
                    if (_profile?.contactoEmergenciaRelacion != null)
                      Text(_profile!.contactoEmergenciaRelacion!,
                        style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  ]),
                ]),
                if (_profile?.contactoEmergenciaTelefono != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.phone_outlined,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Text(_profile!.contactoEmergenciaTelefono!,
                        style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ],
              ]),
            )
          : Center(child: Column(children: [
              const SizedBox(height: 8),
              Icon(Icons.emergency_outlined,
                  size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text('Sin contacto de emergencia',
                  style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _showCompleteForm = true),
                child: const Text('Agregar ahora'),
              ),
            ])),
    );
  }

  Widget _buildHistorialCitas() {
    return _card(
      title: 'Historial de Citas',
      icon:  Icons.calendar_month_outlined,
      trailing: TextButton(
        onPressed: () {},
        child: const Text('Ver todo',
            style: TextStyle(color: Color(0xFF4F46E5))),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Próximamente disponible',
              style: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildDocumentosMedicos() {
    return _card(
      title: 'Documentos Médicos',
      icon:  Icons.folder_outlined,
      trailing: ElevatedButton.icon(
        onPressed: _isUploading ? null : _pickAndUploadDocument,
        icon: _isUploading
            ? const SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.upload_outlined, size: 16),
        label: const Text('Subir Nuevo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
      ),
      child: _documents.isEmpty
          ? Center(child: Column(children: [
              const SizedBox(height: 16),
              Icon(Icons.folder_open_outlined,
                  size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text('Sin documentos médicos',
                  style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 16),
            ]))
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2,
              ),
              itemCount: _documents.length,
              itemBuilder: (_, i) => _documentCard(_documents[i]),
            ),
    );
  }

  Widget _documentCard(PatientDocument doc) {
    final isImage = doc.mimeType?.startsWith('image') == true;
    final color   = isImage ? const Color(0xFF06B6D4) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
            color: color, size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(doc.nombre, style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A7A),
            ), overflow: TextOverflow.ellipsis),
            Text('${doc.tipoLabel} • ${doc.tamanioLegible}',
              style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        )),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
          onPressed: () => _deleteDocument(doc),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }

  // ✅ Seguridad
  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.lock_outline,
              color: Color(0xFF1A1A7A), size: 20),
          const SizedBox(width: 8),
          const Text('Seguridad', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A7A),
          )),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(
                () => _showSecurityForm = !_showSecurityForm),
            icon: Icon(
              _showSecurityForm
                  ? Icons.expand_less : Icons.expand_more,
              size: 18,
            ),
            label: Text(
                _showSecurityForm ? 'Cerrar' : 'Cambiar contraseña'),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5)),
          ),
        ]),
        if (_showSecurityForm) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _passField('Contraseña actual', _currentPassCtrl,
              _obscureCurrent,
              () => setState(
                  () => _obscureCurrent = !_obscureCurrent)),
          const SizedBox(height: 16),
          _passField('Nueva contraseña', _newPassCtrl,
              _obscureNew,
              () => setState(() => _obscureNew = !_obscureNew)),
          if (_newPassCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildStrengthIndicator(),
          ],
          const SizedBox(height: 16),
          _passField('Confirmar nueva contraseña', _confirmPassCtrl,
              _obscureConfirm,
              () => setState(
                  () => _obscureConfirm = !_obscureConfirm)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isChangingPass ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isChangingPass
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Cambiar Contraseña',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _passField(String label, TextEditingController ctrl,
      bool obscure, VoidCallback toggle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      )),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock_outline,
              size: 18, color: Colors.grey[400]),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey, size: 18,
            ),
            onPressed: toggle,
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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: Color(0xFF4F46E5), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
        ),
      ),
    ]);
  }

  Widget _buildStrengthIndicator() {
    final color = _strength <= 2
        ? Colors.red
        : _strength <= 3
            ? Colors.orange
            : _strength <= 4
                ? Colors.yellow.shade700
                : Colors.green;
    final label = _strength <= 2
        ? 'Débil'
        : _strength <= 3
            ? 'Regular'
            : _strength <= 4
                ? 'Buena'
                : 'Fuerte';

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
        Text(label, style: TextStyle(
          color: color, fontSize: 12, fontWeight: FontWeight.bold,
        )),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 4, children: [
        _reqBadge('8+ chars', _hasLength),
        _reqBadge('Mayúscula', _hasUpper),
        _reqBadge('Minúscula', _hasLower),
        _reqBadge('Número',    _hasNumber),
        _reqBadge('Especial',  _hasSpecial),
      ]),
    ]);
  }

  Widget _reqBadge(String label, bool met) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: met ? Colors.green.withOpacity(0.1) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color: met ? Colors.green.shade300 : Colors.grey.shade300),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(met ? Icons.check : Icons.close,
          size: 11, color: met ? Colors.green : Colors.grey),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(
        fontSize: 10,
        color: met ? Colors.green : Colors.grey,
        fontWeight: FontWeight.w500,
      )),
    ]),
  );

  Widget _card({
    required String   title,
    required IconData icon,
    required Widget   child,
    Widget?           trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: const Color(0xFF1A1A7A), size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A7A),
          )),
          if (trailing != null) ...[const Spacer(), trailing],
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {
    IconData?      icon,
    TextInputType? keyboardType,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151),
      )),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: icon != null
              ? Icon(icon, size: 18, color: Colors.grey[400]) : null,
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
            borderSide: const BorderSide(
                color: Color(0xFF4F46E5), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
        ),
      ),
    ]);
  }

  Widget _avatarFallback() => Center(
    child: Text(
      _user?.name.isNotEmpty == true ? _user!.name[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
    ),
  );

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _tallaCtrl.dispose();
    _direccionCtrl.dispose();
    _ciudadCtrl.dispose();
    _contactoNombreCtrl.dispose();
    _contactoTelefonoCtrl.dispose();
    _contactoRelacionCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }
}
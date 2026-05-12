import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/doctor_profile.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/doctor_profile_service.dart';
import '../../services/profile_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  User?          _user;
  DoctorProfile? _profile;
  bool _isLoading        = true;
  bool _isSaving         = false;
  bool _isUploadingPhoto = false;
  bool _showEditForm     = false;

  // Controladores perfil
  final _rethusCtrl = TextEditingController();
  final _areaCtrl   = TextEditingController();

  // Datos del perfil
  List<Map<String, dynamic>> _formacion   = [];
  List<String>               _areas       = [];
  List<Map<String, dynamic>> _ubicaciones = [];

  // Horarios
  final Map<String, Map<String, String>> _horarios = {
    'Lun - Vie': {'inicio': '08:00', 'fin': '18:00', 'activo': 'true'},
    'Sábados':   {'inicio': '09:00', 'fin': '13:00', 'activo': 'true'},
    'Domingos':  {'inicio': '',      'fin': '',       'activo': 'false'},
  };

  // Seguridad
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
    final profileR = await DoctorProfileService.getProfile();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (userR['success'])    _user    = userR['user'];
        if (profileR['success']) {
          _profile     = profileR['profile'];
          _formacion   = List<Map<String, dynamic>>.from(
              _profile!.formacionAcademica);
          _areas       = List<String>.from(_profile!.areasEnfoque);
          _ubicaciones = List<Map<String, dynamic>>.from(
              _profile!.ubicacionesConsulta);
          if (_profile?.rethus != null)
            _rethusCtrl.text = _profile!.rethus!;

          if (_profile?.horariosAtencion != null) {
            _profile!.horariosAtencion!.forEach((key, value) {
              if (_horarios.containsKey(key)) {
                _horarios[key] = Map<String, String>.from(value);
              }
            });
          }
        }
      });
    }
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
    final r = await DoctorProfileService.updateProfile(
      rethus:              _rethusCtrl.text.trim().isNotEmpty
                               ? _rethusCtrl.text.trim() : null,
      formacionAcademica:  _formacion,
      areasEnfoque:        _areas,
      horariosAtencion:    _horarios.map((k, v) => MapEntry(k, v)),
      ubicacionesConsulta: _ubicaciones,
    );
    setState(() => _isSaving = false);

    if (mounted) {
      if (r['success'] == true) {
        setState(() {
          _profile      = r['profile'];
          _showEditForm = false;
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

  void _showAddFormacionDialog() {
    final tituloCtrl      = TextEditingController();
    final institucionCtrl = TextEditingController();
    final inicioCtrl      = TextEditingController();
    final finCtrl         = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Agregar Formación'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogField('Título', tituloCtrl),
          const SizedBox(height: 12),
          _dialogField('Institución', institucionCtrl),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _dialogField('Año inicio', inicioCtrl,
                keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _dialogField('Año fin', finCtrl,
                keyboardType: TextInputType.number)),
          ]),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tituloCtrl.text.isNotEmpty &&
                  institucionCtrl.text.isNotEmpty) {
                setState(() => _formacion.add({
                  'titulo':      tituloCtrl.text.trim(),
                  'institucion': institucionCtrl.text.trim(),
                  'anio_inicio': inicioCtrl.text.trim(),
                  'anio_fin':    finCtrl.text.trim(),
                }));
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5)),
            child: const Text('Agregar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddUbicacionDialog() {
    final nombreCtrl    = TextEditingController();
    final direccionCtrl = TextEditingController();
    bool esPrincipal    = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Agregar Ubicación'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _dialogField('Nombre del consultorio', nombreCtrl),
            const SizedBox(height: 12),
            _dialogField('Dirección', direccionCtrl),
            const SizedBox(height: 12),
            Row(children: [
              Checkbox(
                value: esPrincipal,
                onChanged: (v) => setS(() => esPrincipal = v ?? false),
                activeColor: const Color(0xFF4F46E5),
              ),
              const Text('Sede principal'),
            ]),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nombreCtrl.text.isNotEmpty) {
                  setState(() => _ubicaciones.add({
                    'nombre':       nombreCtrl.text.trim(),
                    'direccion':    direccionCtrl.text.trim(),
                    'es_principal': esPrincipal,
                  }));
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5)),
              child: const Text('Agregar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
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
        if (_profile?.perfilCompleto == false) _buildIncompleteBanner(),
        _buildHeader(),
        const SizedBox(height: 24),
        if (_showEditForm) ...[
          _buildEditForm(),
          const SizedBox(height: 24),
        ],
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: [
            _buildFormacionAcademica(),
            const SizedBox(height: 20),
            _buildAreasEnfoque(),
          ])),
          const SizedBox(width: 20),
          Expanded(child: Column(children: [
            _buildActividadClinica(),
            const SizedBox(height: 20),
            _buildHorarios(),
            const SizedBox(height: 20),
            _buildUbicaciones(),
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
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Perfil incompleto', style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF92400E), fontSize: 14,
          )),
          const Text(
            'Completa tu RETHUS, formación académica y áreas de enfoque.',
            style: TextStyle(color: Color(0xFF92400E), fontSize: 12)),
        ])),
        TextButton(
          onPressed: () => setState(() => _showEditForm = true),
          child: const Text('Completar', style: TextStyle(
            color: Color(0xFFF59E0B), fontWeight: FontWeight.bold,
          )),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 4),
        )],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF4F46E5).withOpacity(0.3), width: 3),
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
                    width: 100, height: 100,
                    errorBuilder: (_, __, ___) => _avatarFallback(),
                  ))
                : _avatarFallback(),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: _isUploadingPhoto
                    ? const Padding(
                        padding: EdgeInsets.all(5),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.camera_alt,
                        color: Colors.white, size: 16),
              ),
            ),
          ),
        ]),
        const SizedBox(width: 20),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dr. ${_user?.fullName ?? ''}', style: const TextStyle(
            fontSize: 24, fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A7A),
          )),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.medical_services_outlined,
                color: Color(0xFF4F46E5), size: 16),
            const SizedBox(width: 6),
            Text(_user?.especialidad ?? '—', style: const TextStyle(
              color: Color(0xFF4F46E5), fontSize: 14,
              fontWeight: FontWeight.w500,
            )),
          ]),
          if (_profile?.rethus != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('RETHUS: ${_profile!.rethus}',
                style: TextStyle(
                  fontSize: 12, color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                )),
            ),
          ],
        ])),
        ElevatedButton.icon(
          onPressed: () =>
              setState(() => _showEditForm = !_showEditForm),
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Editar Perfil'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ]),
    );
  }

  Widget _buildEditForm() {
    return _card(
      title: 'Editar Perfil Profesional',
      icon:  Icons.edit_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _formField('Número RETHUS', _rethusCtrl,
            icon: Icons.badge_outlined),
        const SizedBox(height: 20),
        const Text('Áreas de Enfoque', style: TextStyle(
          fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A),
        )),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextFormField(
            controller: _areaCtrl,
            decoration: InputDecoration(
              hintText: 'Ej: Hipertensión Arterial',
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
                  horizontal: 12, vertical: 12),
            ),
          )),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              if (_areaCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _areas.add(_areaCtrl.text.trim());
                  _areaCtrl.clear();
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Agregar'),
          ),
        ]),
        if (_areas.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8,
            children: _areas.asMap().entries.map((e) => Chip(
              label: Text(e.value,
                  style: const TextStyle(fontSize: 12)),
              backgroundColor:
                  const Color(0xFF4F46E5).withOpacity(0.1),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () =>
                  setState(() => _areas.removeAt(e.key)),
            )).toList()),
        ],
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Formación Académica', style: TextStyle(
            fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A),
          )),
          TextButton.icon(
            onPressed: _showAddFormacionDialog,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Agregar'),
          ),
        ]),
        ..._formacion.asMap().entries.map((e) =>
            _formacionItem(e.value, e.key)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Ubicaciones de Consulta', style: TextStyle(
            fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A),
          )),
          TextButton.icon(
            onPressed: _showAddUbicacionDialog,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Agregar'),
          ),
        ]),
        ..._ubicaciones.asMap().entries.map((e) =>
            _ubicacionItem(e.value, e.key)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => setState(() => _showEditForm = false),
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
                : const Text('Guardar Cambios',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          )),
        ]),
      ]),
    );
  }

  Widget _buildFormacionAcademica() {
    return _card(
      title: 'Formación Académica',
      icon:  Icons.school_outlined,
      child: _formacion.isEmpty
          ? Center(child: Column(children: [
              const SizedBox(height: 8),
              Icon(Icons.school_outlined,
                  size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text('Sin formación registrada',
                  style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 8),
            ]))
          : Column(children: _formacion.map((f) =>
              _formacionItem(f, _formacion.indexOf(f),
                  showDelete: false)).toList()),
    );
  }

  Widget _formacionItem(Map<String, dynamic> f, int index,
      {bool showDelete = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 10, height: 10,
          margin: const EdgeInsets.only(top: 5),
          decoration: const BoxDecoration(
              color: Color(0xFF4F46E5), shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f['titulo'] ?? '', style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 13,
            color: Color(0xFF1A1A7A),
          )),
          Text(f['institucion'] ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          if (f['anio_inicio'] != null &&
              f['anio_inicio'].toString().isNotEmpty)
            Text(
              '${f['anio_inicio']} - ${f['anio_fin'] ?? 'Presente'}',
              style: const TextStyle(
                fontSize: 11, color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w500,
              )),
        ])),
        if (showDelete)
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.red),
            onPressed: () =>
                setState(() => _formacion.removeAt(index)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ]),
    );
  }

  Widget _buildAreasEnfoque() {
    return _card(
      title: 'Áreas de Enfoque',
      icon:  Icons.psychology_outlined,
      child: _areas.isEmpty
          ? Center(child: Column(children: [
              const SizedBox(height: 8),
              Icon(Icons.psychology_outlined,
                  size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text('Sin áreas registradas',
                  style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 8),
            ]))
          : Wrap(spacing: 8, runSpacing: 8,
              children: _areas.map((a) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF4F46E5).withOpacity(0.2)),
                ),
                child: Text(a, style: const TextStyle(
                  color: Color(0xFF4F46E5), fontSize: 12,
                  fontWeight: FontWeight.w500,
                )),
              )).toList()),
    );
  }

  Widget _buildActividadClinica() {
    return _card(
      title: 'Actividad Clínica Reciente',
      icon:  Icons.bar_chart_outlined,
      trailing: Text('ÚLTIMOS 30 DÍAS', style: TextStyle(
        fontSize: 10, color: Colors.grey[400], letterSpacing: 1,
      )),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            const Icon(Icons.people_outlined,
                color: Color(0xFF4F46E5), size: 32),
            const SizedBox(height: 8),
            Text('${_profile?.totalConsultas ?? 0}',
              style: const TextStyle(
                fontSize: 36, fontWeight: FontWeight.w900,
                color: Color(0xFF4F46E5),
              )),
            const Text('CONSULTAS TOTALES', style: TextStyle(
              fontSize: 10, color: Colors.grey, letterSpacing: 1,
            )),
          ]),
        ),
        if (_profile?.ultimosPacientes.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('ÚLTIMOS PACIENTES ATENDIDOS', style: TextStyle(
              fontSize: 10, color: Colors.grey,
              letterSpacing: 1, fontWeight: FontWeight.bold,
            )),
          ),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade50),
                children: ['Paciente', 'Motivo', 'Fecha'].map((h) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    child: Text(h, style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    )),
                  )).toList(),
              ),
              ..._profile!.ultimosPacientes.map((p) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    child: Text(p['paciente'] ?? '—',
                      style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    child: Text(p['motivo'] ?? '—',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600])),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    child: Text(
                      p['fecha']?.toString().substring(0, 10) ?? '—',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500])),
                  ),
                ],
              )).toList(),
            ],
          ),
        ],
      ]),
    );
  }

  Widget _buildHorarios() {
    return _card(
      title: 'Horarios de Atención',
      icon:  Icons.access_time_outlined,
      child: Column(children: _horarios.entries.map((e) {
        final activo = e.value['activo'] == 'true';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            SizedBox(width: 80, child: Text(e.key, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A7A),
            ))),
            const Spacer(),
            activo
                ? Text('${e.value['inicio']} - ${e.value['fin']}',
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A7A),
                    ))
                : const Text('Cerrado',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
        );
      }).toList()),
    );
  }

  Widget _buildUbicaciones() {
    return _card(
      title: 'Ubicaciones de Consulta',
      icon:  Icons.location_on_outlined,
      child: _ubicaciones.isEmpty
          ? Center(child: Column(children: [
              const SizedBox(height: 8),
              Icon(Icons.location_off_outlined,
                  size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text('Sin ubicaciones registradas',
                  style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 8),
            ]))
          : Column(children: _ubicaciones.asMap().entries.map((e) =>
              _ubicacionItem(e.value, e.key,
                  showDelete: false)).toList()),
    );
  }

  Widget _ubicacionItem(Map<String, dynamic> u, int index,
      {bool showDelete = true}) {
    final esPrincipal = u['es_principal'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.local_hospital_outlined,
              color: Color(0xFF4F46E5), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(u['nombre'] ?? '', style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13,
              color: Color(0xFF1A1A7A),
            )),
            if (esPrincipal) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Sede Principal', style: TextStyle(
                  color: Color(0xFF10B981), fontSize: 10,
                  fontWeight: FontWeight.bold,
                )),
              ),
            ],
          ]),
          if (u['direccion'] != null &&
              u['direccion'].toString().isNotEmpty)
            Text(u['direccion'],
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ])),
        if (showDelete)
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.red),
            onPressed: () =>
                setState(() => _ubicaciones.removeAt(index)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ]),
    );
  }

  // ── Seguridad
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
      margin: const EdgeInsets.only(bottom: 4),
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

  Widget _formField(String label, TextEditingController ctrl,
      {IconData? icon}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      )),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
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

  Widget _dialogField(String hint, TextEditingController ctrl,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _avatarFallback() => Center(
    child: Text(
      _user?.name.isNotEmpty == true
          ? _user!.name[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white, fontSize: 32,
        fontWeight: FontWeight.bold),
    ),
  );

  @override
  void dispose() {
    _rethusCtrl.dispose();
    _areaCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey          = GlobalKey<FormState>();
  final _docController    = TextEditingController();
  final _nameController   = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController  = TextEditingController();
  final _phoneController  = TextEditingController();
  final _passController   = TextEditingController();
  final _confirmController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _alergiasController  = TextEditingController();

  DocumentType _docType   = DocumentType.cedulaCiudadania;
  String? _genero;
  String? _tipoSangre;
  bool _notifEmail = true;
  bool _notifSms   = false;
  bool _isLoading  = false;
  bool _obscurePass   = true;
  bool _obscureConf   = true;
  int  _currentStep   = 0; // 0: Datos personales | 1: Salud | 2: Seguridad

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  // Fortaleza contraseña
  bool get _hasLength  => _passController.text.length >= 8;
  bool get _hasUpper   => _passController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLower   => _passController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber  => _passController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _passController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
  int  get _strengthScore => [_hasLength, _hasUpper, _hasLower, _hasNumber, _hasSpecial]
      .where((b) => b).length;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _passController.addListener(() => setState(() {}));
  }

  Future<void> _selectDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
    );
    if (d != null && mounted) {
      setState(() => _birthDateController.text = DateFormat('yyyy-MM-dd').format(d));
    }
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa una contraseña';
    if (!_hasLength)  return 'Mínimo 8 caracteres';
    if (!_hasUpper)   return 'Debe incluir al menos una mayúscula';
    if (!_hasLower)   return 'Debe incluir al menos una minúscula';
    if (!_hasNumber)  return 'Debe incluir al menos un número';
    if (!_hasSpecial) return 'Debe incluir al menos un carácter especial (!@#\$...)';
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_genero == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu género'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.register(
      document:              _docController.text.trim(),
      documentType:          _docType,
      name:                  _nameController.text.trim(),
      lastName:              _lastNameController.text.trim(),
      email:                 _emailController.text.trim(),
      password:              _passController.text,
      passwordConfirmation:  _confirmController.text,
      birthDate:             _birthDateController.text,
      phone:                 _phoneController.text.trim(),
      genero:                _genero!,
      tipoSangre:            _tipoSangre,
      alergias:              _alergiasController.text.trim().isNotEmpty
                               ? _alergiasController.text.trim()
                               : null,
      notificacionesEmail:   _notifEmail,
      notificacionesSms:     _notifSms,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cuenta creada. Inicia sesión.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        });
      } else {
        String msg = result['message'] ?? 'Error al registrar';
        if (result['errors'] != null) {
          final errors = result['errors'] as Map<String, dynamic>;
          msg = errors.values.firstWhere((e) => e is List, orElse: () => [msg])[0];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        if (MediaQuery.of(context).size.width > 700)
          Expanded(flex: 4, child: _buildLeftPanel()),
        Expanded(flex: 6, child: _buildFormPanel()),
      ]),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A7A), Color(0xFF4F46E5), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        Positioned(bottom: -60, left: -60, child: _circle(250, Colors.white, 0.05)),
        Positioned(top: 40,  right: -40,  child: _circle(150, Colors.white, 0.06)),
        Padding(
          padding: const EdgeInsets.all(48),
          child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Tu salud, digital y segura.', style: TextStyle(
              fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2,
            )),
            const SizedBox(height: 32),
            _featureItem(Icons.shield_outlined,      'Privacidad de datos garantizada'),
            const SizedBox(height: 16),
            _featureItem(Icons.history_edu_outlined, 'Historial clínico integrado'),
            const SizedBox(height: 16),
            _featureItem(Icons.notifications_active_outlined, 'Notificaciones en tiempo real'),
            const SizedBox(height: 32),
            Text('© 2026 Salud Web Walud', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _featureItem(IconData icon, String text) => Row(children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
    const SizedBox(width: 12),
    Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
  ]);

  Widget _buildFormPanel() {
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Crear Cuenta', style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5),
                  )),
                  const SizedBox(height: 4),
                  Text('Completa tus datos para acceder a la plataforma clínica.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  const SizedBox(height: 20),

                  // ── PASO STEPPER visual
                  _buildStepper(),
                  const SizedBox(height: 24),

                  // ── PASO 0: Datos personales
                  if (_currentStep == 0) ..._buildStep0(),
                  // ── PASO 1: Información de salud
                  if (_currentStep == 1) ..._buildStep1(),
                  // ── PASO 2: Seguridad y notificaciones
                  if (_currentStep == 2) ..._buildStep2(),

                  const SizedBox(height: 24),

                  // Navegación entre pasos
                  Row(children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep--),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF4F46E5)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Anterior', style: TextStyle(color: Color(0xFF4F46E5))),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {
                          if (_currentStep < 2) {
                            setState(() => _currentStep++);
                          } else {
                            _handleRegister();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A7A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(_currentStep < 2 ? 'Siguiente' : 'Crear Cuenta',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Icon(_currentStep < 2 ? Icons.arrow_forward : Icons.check, size: 18),
                            ]),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),
                  Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('¿Ya tienes cuenta? ', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                          context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: const Text('Iniciar Sesión', style: TextStyle(
                        color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13,
                      )),
                    ),
                  ])),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    final steps = ['Datos', 'Salud', 'Seguridad'];
    return Row(children: List.generate(steps.length, (i) {
      final done    = i < _currentStep;
      final current = i == _currentStep;
      return Expanded(child: Row(children: [
        if (i > 0) Expanded(child: Container(
          height: 2,
          color: done ? const Color(0xFF4F46E5) : Colors.grey.shade200,
        )),
        Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done || current ? const Color(0xFF4F46E5) : Colors.grey.shade200,
            ),
            child: Center(child: done
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text('${i + 1}', style: TextStyle(
                  color: current ? Colors.white : Colors.grey[500],
                  fontWeight: FontWeight.bold, fontSize: 13,
                )),
            ),
          ),
          const SizedBox(height: 4),
          Text(steps[i], style: TextStyle(
            fontSize: 10,
            color: current ? const Color(0xFF4F46E5) : Colors.grey[400],
            fontWeight: current ? FontWeight.bold : FontWeight.normal,
          )),
        ]),
        if (i == steps.length - 1) const Expanded(child: SizedBox()),
      ]));
    }));
  }

  // ── Paso 0: Datos personales
  List<Widget> _buildStep0() => [
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Documento'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _docController,
          keyboardType: TextInputType.number,
          decoration: _deco('CC / TI No.', Icons.badge_outlined),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Requerido';
            if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) return 'Solo números';
            return null;
          },
        ),
      ])),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Fecha de Nacimiento'),
        const SizedBox(height: 6),
        InkWell(
          onTap: _selectDate,
          child: AbsorbPointer(
            child: TextFormField(
              controller: _birthDateController,
              decoration: _deco('dd/mm/aaaa', Icons.calendar_today_outlined),
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
          ),
        ),
      ])),
    ]),
    const SizedBox(height: 14),
    _label('Tipo de Documento'),
    const SizedBox(height: 6),
    DropdownButtonFormField<DocumentType>(
      value: _docType,
      decoration: _deco('', Icons.badge_outlined),
      items: DocumentType.values.map((t) => DropdownMenuItem(
        value: t, child: Text(t.label, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: (v) { if (v != null) setState(() => _docType = v); },
    ),
    const SizedBox(height: 14),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Nombre'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nameController,
          decoration: _deco('Tus nombres', Icons.person_outline),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
      ])),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Apellido'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _lastNameController,
          decoration: _deco('Tus apellidos', Icons.person_outline),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
      ])),
    ]),
    const SizedBox(height: 14),
    _label('Correo Electrónico'),
    const SizedBox(height: 6),
    TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _deco('ejemplo@correo.com', Icons.alternate_email),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Requerido';
        if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(v.trim())) return 'Correo no válido';
        return null;
      },
    ),
    const SizedBox(height: 14),
    _label('Teléfono (para notificaciones)'),
    const SizedBox(height: 6),
    TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: _deco('+57 300 000 0000', Icons.phone_outlined),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Requerido para notificaciones';
        return null;
      },
    ),
  ];

  // ── Paso 1: Información de salud
  List<Widget> _buildStep1() => [
    _label('Género *'),
    const SizedBox(height: 8),
    Wrap(spacing: 8, runSpacing: 8, children: kGeneros.map((g) {
      final sel = _genero == g['value'];
      return GestureDetector(
        onTap: () => setState(() => _genero = g['value']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF4F46E5).withOpacity(0.1) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: sel ? const Color(0xFF4F46E5) : Colors.grey.shade200,
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Text(g['label']!, style: TextStyle(
            color: sel ? const Color(0xFF4F46E5) : Colors.grey[600],
            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          )),
        ),
      );
    }).toList()),
    const SizedBox(height: 20),
    _label('Tipo de Sangre'),
    const SizedBox(height: 8),
    Wrap(spacing: 8, runSpacing: 8, children: kTiposSangre.map((s) {
      final sel = _tipoSangre == s;
      return GestureDetector(
        onTap: () => setState(() => _tipoSangre = s),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 64, height: 40,
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF4F46E5) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: sel ? const Color(0xFF4F46E5) : Colors.grey.shade200,
            ),
          ),
          child: Center(child: Text(s, style: TextStyle(
            color: sel ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold, fontSize: 13,
          ))),
        ),
      );
    }).toList()),
    const SizedBox(height: 20),
    _label('Alergias conocidas (opcional)'),
    const SizedBox(height: 6),
    TextFormField(
      controller: _alergiasController,
      maxLines: 3,
      decoration: _deco('Ej: penicilina, mariscos, látex...', Icons.warning_amber_outlined).copyWith(
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
    ),
    const SizedBox(height: 14),
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, color: Color(0xFF0EA5E9), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(
          'Esta información es estrictamente confidencial y solo será visible para tus médicos tratantes.',
          style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.4),
        )),
      ]),
    ),
  ];

  // ── Paso 2: Seguridad y notificaciones
  List<Widget> _buildStep2() => [
    _label('Contraseña'),
    const SizedBox(height: 6),
    TextFormField(
      controller: _passController,
      obscureText: _obscurePass,
      decoration: _deco('••••••••', Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey, size: 20),
          onPressed: () => setState(() => _obscurePass = !_obscurePass),
        ),
      ),
      validator: _validatePassword,
    ),
    if (_passController.text.isNotEmpty) ...[
      const SizedBox(height: 8),
      _buildStrengthIndicator(),
    ],
    const SizedBox(height: 14),
    _label('Confirmar Contraseña'),
    const SizedBox(height: 6),
    TextFormField(
      controller: _confirmController,
      obscureText: _obscureConf,
      decoration: _deco('••••••••', Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscureConf ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey, size: 20),
          onPressed: () => setState(() => _obscureConf = !_obscureConf),
        ),
      ),
      validator: (v) => v != _passController.text ? 'Las contraseñas no coinciden' : null,
    ),
    const SizedBox(height: 20),
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Preferencias de notificaciones', style: TextStyle(
          fontWeight: FontWeight.bold, color: Color(0xFF374151), fontSize: 13,
        )),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.email_outlined, size: 18, color: Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            const Text('Notificaciones por correo', style: TextStyle(fontSize: 13)),
          ]),
          Switch(
            value: _notifEmail,
            activeColor: const Color(0xFF4F46E5),
            onChanged: (v) => setState(() => _notifEmail = v),
          ),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.sms_outlined, size: 18, color: Color(0xFF06B6D4)),
            const SizedBox(width: 8),
            const Text('Notificaciones por SMS', style: TextStyle(fontSize: 13)),
          ]),
          Switch(
            value: _notifSms,
            activeColor: const Color(0xFF06B6D4),
            onChanged: (v) => setState(() => _notifSms = v),
          ),
        ]),
        if (_notifSms) Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Se enviará un código de verificación al número ${_phoneController.text.isNotEmpty ? _phoneController.text : "que registraste"} para activar el SMS.',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ),
      ]),
    ),
  ];

  Widget _buildStrengthIndicator() {
    final color = _strengthScore <= 2 ? Colors.red
        : _strengthScore <= 3 ? Colors.orange
        : _strengthScore <= 4 ? Colors.yellow.shade700
        : Colors.green;
    final label = _strengthScore <= 2 ? 'Débil'
        : _strengthScore <= 3 ? 'Regular'
        : _strengthScore <= 4 ? 'Buena'
        : 'Fuerte';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _strengthScore / 5,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        )),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 4, children: [
        _reqBadge('8+ chars', _hasLength),
        _reqBadge('Mayúscula', _hasUpper),
        _reqBadge('Minúscula', _hasLower),
        _reqBadge('Número',   _hasNumber),
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
      Icon(met ? Icons.check : Icons.close, size: 11,
          color: met ? Colors.green : Colors.grey),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(
          fontSize: 10, color: met ? Colors.green : Colors.grey,
          fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _label(String t) => Text(t, style: const TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151),
  ));

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
    prefixIcon: Icon(icon, color: Colors.grey[400], size: 18),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  Widget _circle(double size, Color color, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(opacity)),
  );

  @override
  void dispose() {
    _docController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    _birthDateController.dispose();
    _alergiasController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }
}
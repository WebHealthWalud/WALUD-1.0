import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../models/medical_record.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/medical_record_service.dart';

const double _kEvolBreak = 900;

class CreateEvolutionScreen extends StatefulWidget {
  final int? preselectedPatientId;
  final String? preselectedPatientName;
  final Map<String, dynamic>? preselectedPatientData;

  const CreateEvolutionScreen({
    super.key,
    this.preselectedPatientId,
    this.preselectedPatientName,
    this.preselectedPatientData,
  });

  @override
  State<CreateEvolutionScreen> createState() => _CreateEvolutionScreenState();
}

class _CreateEvolutionScreenState extends State<CreateEvolutionScreen> {
  User? _currentUser;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Paciente seleccionado
  int? _patientId;
  String? _patientName;
  Map<String, dynamic>? _patientData;

  // Búsqueda
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _searchingPatient = false;

  // Formulario
  final _motivoCtrl = TextEditingController();
  final _examenCtrl = TextEditingController();
  final _cie10Ctrl = TextEditingController();
  final _diagNombreCtrl = TextEditingController();
  final _diagDescCtrl = TextEditingController();
  final _tratamientoCtrl = TextEditingController();
  final _observCtrl = TextEditingController();

  // Signos vitales
  final _pSisCtrl = TextEditingController();
  final _pDiaCtrl = TextEditingController();
  final _fcCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _tallaCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  bool _showSignos = false;

  String? _selectedEspecialidad;

  // Timeline
  List<MedicalRecord> _timeline = [];
  bool _loadingTime = false;

  // ID de evolución (referencia visual)
  final int _evolId = DateTime.now().millisecondsSinceEpoch % 9999;

  @override
  void initState() {
    super.initState();
    _loadUser();
    if (widget.preselectedPatientId != null) {
      _patientId = widget.preselectedPatientId;
      _patientName = widget.preselectedPatientName;
      _patientData = widget.preselectedPatientData;
      _searchCtrl.text = widget.preselectedPatientName ?? '';
      _loadTimeline(widget.preselectedPatientId!);
    }
  }

  Future<void> _loadUser() async {
    final r = await AuthService.getCurrentUser();
    if (mounted)
      setState(() {
        _isLoading = false;
        _currentUser = r['success'] ? r['user'] : null;
        _selectedEspecialidad = _currentUser?.especialidad;
      });
  }

  Future<void> _loadTimeline(int patientId) async {
    setState(() => _loadingTime = true);
    final r = await MedicalRecordService.getTimeline(patientId);
    if (mounted)
      setState(() {
        _loadingTime = false;
        _timeline = r['success'] == true
            ? List<MedicalRecord>.from(r['timeline'])
            : [];
      });
  }

  Future<void> _searchPatients(String value) async {
    if (value.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _searchingPatient = true);
    final r = await MedicalRecordService.searchPatients(value);
    if (mounted)
      setState(() {
        _searchingPatient = false;
        _suggestions = r['success'] == true
            ? List<Map<String, dynamic>>.from(r['patients'])
            : [];
      });
  }

  void _selectPatient(Map<String, dynamic> p) {
    final name = '${p['name']} ${p['last_name']}'.trim();
    setState(() {
      _patientId = p['id'];
      _patientName = name;
      _patientData = p;
      _searchCtrl.text = name;
      _suggestions = [];
    });
    _loadTimeline(p['id']);
  }

  Future<void> _submit() async {
    if (_patientId == null) {
      _snack('Selecciona un paciente', Colors.red);
      return;
    }
    if (_motivoCtrl.text.trim().isEmpty) {
      _snack('El motivo de consulta es obligatorio', Colors.red);
      return;
    }
    if (_selectedEspecialidad == null) {
      _snack('Selecciona la especialidad', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    final record = MedicalRecord(
      patientId: _patientId!,
      doctorId: _currentUser!.id!,
      expediente: '',
      motivoConsulta: _motivoCtrl.text.trim(),
      examenFisico: _v(_examenCtrl),
      diagnosticoCie10: _v(_cie10Ctrl),
      diagnosticoNombre: _v(_diagNombreCtrl),
      diagnosticoDescripcion: _v(_diagDescCtrl),
      tratamiento: _v(_tratamientoCtrl),
      observaciones: _v(_observCtrl),
      especialidad: _selectedEspecialidad!,
      presionSistolica: double.tryParse(_pSisCtrl.text),
      presionDiastolica: double.tryParse(_pDiaCtrl.text),
      frecuenciaCardiaca: double.tryParse(_fcCtrl.text),
      temperatura: double.tryParse(_tempCtrl.text),
      peso: double.tryParse(_pesoCtrl.text),
      talla: double.tryParse(_tallaCtrl.text),
      saturacionOxigeno: double.tryParse(_spo2Ctrl.text),
    );

    final r = await MedicalRecordService.create(record);
    setState(() => _isSubmitting = false);

    if (mounted) {
      if (r['success'] == true) {
        _snack('✅ Evolución guardada correctamente', const Color(0xFF10B981));
        Navigator.pop(context, true);
      } else {
        _snack(r['message'] ?? 'Error al guardar', Colors.red);
      }
    }
  }

  String? _v(TextEditingController c) =>
      c.text.trim().isNotEmpty ? c.text.trim() : null;

  void _snack(String msg, Color color) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
      );

    final isNarrow = MediaQuery.of(context).size.width < _kEvolBreak;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          'Nueva Evolución Médica',
          style: TextStyle(
            color: Color(0xFF1A1A7A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A7A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: isNarrow ? _buildNarrow() : _buildWide(),
    );
  }

  // ── Layout wide: formulario + timeline lateral
  Widget _buildWide() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 6, child: _buildForm()),
      // Línea de tiempo lateral
      Container(
        width: 300,
        margin: const EdgeInsets.fromLTRB(0, 20, 20, 20),
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
        child: _buildTimeline(),
      ),
    ],
  );

  // ── Layout narrow: formulario + timeline colapsado abajo
  Widget _buildNarrow() => SingleChildScrollView(
    child: Column(
      children: [
        _buildForm(narrow: true),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Row(
                children: const [
                  Icon(Icons.timeline, color: Color(0xFF4F46E5), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Línea de Tiempo Clínica',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A7A),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: _buildTimeline(),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildForm({bool narrow = false}) {
    final pad = narrow ? 16.0 : 20.0;
    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      physics: narrow ? const NeverScrollableScrollPhysics() : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── BARRA BÚSQUEDA PACIENTE
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nueva Evolución Médica',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A7A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ID: #$_evolId',
                        style: const TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Busque al paciente para iniciar el registro.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 14),
                // Buscador del paciente
                TextField(
                  controller: _searchCtrl,
                  onChanged: _searchPatients,
                  decoration: InputDecoration(
                    hintText: 'Buscar paciente por CC, TI, nombre...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    prefixIcon: const Icon(
                      Icons.badge_outlined,
                      color: Color(0xFF4F46E5),
                      size: 18,
                    ),
                    suffixIcon: _searchingPatient
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          )
                        : null,
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
                        color: Color(0xFF4F46E5),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildSuggestions(),
                ],
              ],
            ),
          ),

          // ── TARJETA DEL PACIENTE (fiel al diseño imagen 2)
          if (_patientData != null) ...[
            const SizedBox(height: 14),
            _buildPatientHeader(_patientData!),
          ],

          const SizedBox(height: 14),

          // ── Especialidad

          // ── Motivo de consulta
          _section(
            icon: Icons.chat_bubble_outline,
            title: 'Motivo de Consulta',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Escriba el motivo principal de la visita *'),
                const SizedBox(height: 8),
                _tf(
                  _motivoCtrl,
                  'Escriba el motivo principal de la visita...',
                  4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Examen Físico
          _section(
            icon: Icons.health_and_safety_outlined,
            title: 'Examen Físico',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Hallazgos relevantes del examen físico'),
                const SizedBox(height: 8),
                _tf(
                  _examenCtrl,
                  'Hallazgos relevantes del examen físico...',
                  4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Diagnóstico
          _section(
            icon: Icons.biotech_outlined,
            title: 'Diagnóstico (CIE-10)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                narrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Código CIE-10'),
                          const SizedBox(height: 6),
                          _tf(_cie10Ctrl, 'Ej: J06.9', 1),
                          const SizedBox(height: 10),
                          _label('Nombre del diagnóstico'),
                          const SizedBox(height: 6),
                          _tf(
                            _diagNombreCtrl,
                            'Ej: Infección respiratoria aguda',
                            1,
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Código CIE-10'),
                                const SizedBox(height: 6),
                                _tf(_cie10Ctrl, 'Ej: J06.9', 1),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Nombre del diagnóstico'),
                                const SizedBox(height: 6),
                                _tf(
                                  _diagNombreCtrl,
                                  'Ej: Infección respiratoria aguda',
                                  1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 10),
                _label('Descripción del diagnóstico'),
                const SizedBox(height: 6),
                _tf(
                  _diagDescCtrl,
                  'Describe el diagnóstico con más detalle...',
                  3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Tratamiento y Receta
          _section(
            icon: Icons.medication_outlined,
            title: 'Tratamiento y Receta',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(
                  'Medicamentos e indicaciones (una línea por medicamento)',
                ),
                const SizedBox(height: 6),
                _tf(
                  _tratamientoCtrl,
                  'Ej: Amoxicilina 500mg cada 8 horas por 7 días\n'
                  'Ibuprofeno 400mg cada 6 horas si hay dolor...',
                  5,
                ),
                const SizedBox(height: 12),
                _label('Nota del profesional (visible para el paciente)'),
                const SizedBox(height: 6),
                _tf(
                  _observCtrl,
                  'Recomendaciones, seguimiento, próxima cita...',
                  3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Signos Vitales (colapsable)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _showSignos = !_showSignos),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monitor_heart_outlined,
                        color: Color(0xFF1A1A7A),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Signos Vitales (opcional)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A7A),
                          ),
                        ),
                      ),
                      Icon(
                        _showSignos ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
                if (_showSignos) ...[
                  const SizedBox(height: 14),
                  narrow
                      ? Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _vital(
                                    _pSisCtrl,
                                    'Presión Sistólica',
                                    'mmHg',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _vital(
                                    _pDiaCtrl,
                                    'Presión Diastólica',
                                    'mmHg',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _vital(
                                    _fcCtrl,
                                    'Frec. Cardíaca',
                                    'lpm',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _vital(_tempCtrl, 'Temperatura', '°C'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _vital(_pesoCtrl, 'Peso', 'kg'),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _vital(_tallaCtrl, 'Talla', 'cm'),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: _vital(_spo2Ctrl, 'SpO₂', '%')),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _vital(
                                    _pSisCtrl,
                                    'Presión Sistólica',
                                    'mmHg',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _vital(
                                    _pDiaCtrl,
                                    'Presión Diastólica',
                                    'mmHg',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _vital(
                                    _fcCtrl,
                                    'Frec. Cardíaca',
                                    'lpm',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _vital(_tempCtrl, 'Temperatura', '°C'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _vital(_pesoCtrl, 'Peso', 'kg'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _vital(_tallaCtrl, 'Talla', 'cm'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: _vital(_spo2Ctrl, 'SpO₂', '%')),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ],
                        ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Guardar Evolución',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ✅ Tarjeta del paciente fiel al diseño imagen 2
  Widget _buildPatientHeader(Map<String, dynamic> p) {
    final name = '${p['name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
    final expNum =
        'WM-${DateTime.now().year}-${(p['id'] ?? 0).toString().padLeft(4, '0')}';
    final sangre = p['tipo_sangre']?.toString() ?? '—';
    final alergias = p['alergias']?.toString() ?? '';
    final doc = p['document']?.toString() ?? '—';

    String age = '—';
    if (p['birth_date'] != null) {
      try {
        final bd = DateTime.parse(p['birth_date'].toString());
        age = '${DateTime.now().difference(bd).inDays ~/ 365} años';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera: foto + datos principales
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar del paciente
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  border: Border.all(
                    color: const Color(0xFF4F46E5).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A7A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Expediente: #$expNum',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 8),
                    // Chips de info clínica rápida
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _infoChip(Icons.cake_outlined, 'EDAD', age),
                        _infoChip(
                          Icons.water_drop_outlined,
                          'SANGRE',
                          sangre,
                          color: alergias.isNotEmpty ? null : null,
                        ),
                        if (alergias.isNotEmpty)
                          _infoChipAlert(
                            Icons.warning_amber_outlined,
                            'ALERGIAS',
                            alergias,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Botones de acción (igual al diseño)
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, {Color? color}) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (color ?? const Color(0xFF4F46E5)).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color ?? const Color(0xFF4F46E5),
              size: 14,
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1A1A7A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _infoChipAlert(IconData icon, String label, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.red.shade600, size: 14),
      ),
      const SizedBox(width: 6),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.red[300],
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ],
  );

  // ── Línea de tiempo lateral
  Widget _buildTimeline() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: [
            const Icon(Icons.timeline, color: Color(0xFF4F46E5), size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Línea de Tiempo Clínica',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A7A),
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.filter_list, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
      Divider(height: 24, color: Colors.grey.shade100),

      if (_patientId == null)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.person_search, size: 44, color: Colors.grey[200]),
                const SizedBox(height: 8),
                Text(
                  'Selecciona un paciente\npara ver su historial.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        )
      else if (_loadingTime)
        const Padding(
          padding: EdgeInsets.all(28),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
          ),
        )
      else if (_timeline.isEmpty)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 44, color: Colors.grey[200]),
                const SizedBox(height: 8),
                Text(
                  'Sin consultas previas registradas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        )
      else
        Flexible(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _timeline.length,
            itemBuilder: (_, i) =>
                _TimelineItem(record: _timeline[i], isFirst: i == 0),
          ),
        ),

      if (_timeline.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'CARGAR CONSULTAS ANTERIORES',
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _buildSuggestions() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12),
      ],
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      children: _suggestions.map((p) {
        final name = '${p['name']} ${p['last_name']}'.trim();
        final doc = p['document']?.toString() ?? '';
        return InkWell(
          onTap: () => _selectPatient(p),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF1A1A7A),
                        ),
                      ),
                      Text(
                        'Doc: $doc',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );

  // ── UI Helpers
  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _cardDeco(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF1A1A7A), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A7A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFF374151),
    ),
  );

  Widget _tf(TextEditingController ctrl, String hint, int lines) =>
      TextFormField(controller: ctrl, maxLines: lines, decoration: _deco(hint));

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  Widget _vital(TextEditingController ctrl, String label, String unit) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixText: unit,
              suffixStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4F46E5)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
          ),
        ],
      );

  @override
  void dispose() {
    _searchCtrl.dispose();
    _motivoCtrl.dispose();
    _examenCtrl.dispose();
    _cie10Ctrl.dispose();
    _diagNombreCtrl.dispose();
    _diagDescCtrl.dispose();
    _tratamientoCtrl.dispose();
    _observCtrl.dispose();
    _pSisCtrl.dispose();
    _pDiaCtrl.dispose();
    _fcCtrl.dispose();
    _tempCtrl.dispose();
    _pesoCtrl.dispose();
    _tallaCtrl.dispose();
    _spo2Ctrl.dispose();
    super.dispose();
  }
}

// ── Item de línea de tiempo
class _TimelineItem extends StatelessWidget {
  final MedicalRecord record;
  final bool isFirst;
  const _TimelineItem({required this.record, required this.isFirst});

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFirst ? const Color(0xFF4F46E5) : Colors.grey.shade300,
              ),
            ),
            Expanded(child: Container(width: 2, color: Colors.grey.shade200)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.formattedDate,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isFirst ? const Color(0xFF4F46E5) : Colors.grey[500],
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  record.diagnosticoNombre ?? record.motivoConsulta,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1A1A7A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Dr. ${record.doctorFullName}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    '"${record.motivoConsulta.length > 80 ? '${record.motivoConsulta.substring(0, 80)}...' : record.motivoConsulta}"',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../models/medical_record.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/medical_record_service.dart';
import 'create_evolution_screen.dart';
import 'medical_record_detail_screen.dart';

const double _kHistBreak = 700;

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});
  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  User?                _currentUser;
  List<MedicalRecord>  _records          = [];
  bool                 _isLoading        = true;

  // ── Paciente: busca en SUS registros por texto libre
  final _infoSearchCtrl = TextEditingController();

  // ── Médico: busca pacientes por documento/nombre
  final _patientSearchCtrl              = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _searchingPatient                = false;
  int? _selectedPatientId;

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    final r = await AuthService.getCurrentUser();
    if (r['success'] && mounted) setState(() => _currentUser = r['user']);
    await _loadRecords();
  }

  Future<void> _loadRecords({String? search, int? patientId}) async {
    setState(() => _isLoading = true);
    final r = await MedicalRecordService.getAll(search: search);
    if (mounted) setState(() {
      _isLoading = false;
      _records   = r['success'] == true
          ? List<MedicalRecord>.from(r['records']) : [];
    });
  }

  // Médico busca paciente
  Future<void> _searchPatients(String value) async {
    if (value.length < 2) { setState(() => _suggestions = []); return; }
    setState(() => _searchingPatient = true);
    final r = await MedicalRecordService.searchPatients(value);
    if (mounted) setState(() {
      _searchingPatient = false;
      _suggestions = r['success'] == true
          ? List<Map<String, dynamic>>.from(r['patients']) : [];
    });
  }

  void _selectPatient(Map<String, dynamic> p) {
    final name = '${p['name']} ${p['last_name']}'.trim();
    setState(() {
      _selectedPatientId = p['id'];
      _patientSearchCtrl.text = name;
      _suggestions = [];
    });
    _loadRecords(search: p['document']?.toString());
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor  = _currentUser?.isDoctor  == true;
    final isPatient = _currentUser?.isPatient == true;
    final isNarrow  = MediaQuery.of(context).size.width < _kHistBreak;

    return RefreshIndicator(
      onRefresh: _loadRecords,
      color: const Color(0xFF4F46E5),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── HEADER AZUL CON BORDES REDONDEADOS (fiel al diseño imagen 3)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                  isNarrow ? 20 : 28, 28, isNarrow ? 20 : 28, 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20), // ✅ bordes redondeados
                boxShadow: [BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.25),
                    blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: isNarrow
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Historial Médico', style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900,
                          color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(
                        isDoctor
                            ? 'Busca un paciente para ver o registrar sus evoluciones médicas.'
                            : 'Consulta el registro detallado de tus atenciones, diagnósticos, evoluciones, tratamientos y recomendaciones profesionales en un solo lugar.',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12, height: 1.5)),
                      if (isDoctor) ...[
                        const SizedBox(height: 16),
                        SizedBox(width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _goToNewEvolution(null),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Nueva Evolución',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1A237E),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          )),
                      ],
                    ])
                  : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Historial Médico', style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w900,
                            color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(
                          isDoctor
                              ? 'Busca un paciente por documento o nombre para ver o registrar sus evoluciones médicas.'
                              : 'Consulta el registro detallado de tus atenciones, diagnósticos, evoluciones, tratamientos y recomendaciones profesionales en un solo lugar.',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13, height: 1.5)),
                      ])),
                      if (isDoctor) ...[
                        const SizedBox(width: 20),
                        ElevatedButton.icon(
                          onPressed: () => _goToNewEvolution(null),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nueva Evolución',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1A237E),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ]),
            ),
          ),

          // ── BARRAS DE BÚSQUEDA (dentro de una card blanca)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: isDoctor
                  // ── MÉDICO: solo barra para buscar PACIENTE
                  ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.person_search_outlined,
                            color: Color(0xFF4F46E5), size: 16),
                        const SizedBox(width: 6),
                        Text('Buscar paciente',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: Colors.grey[600])),
                      ]),
                      const SizedBox(height: 8),
                      _searchField(
                        controller: _patientSearchCtrl,
                        hint: 'Buscar por cédula (CC), TI, pasaporte o nombre...',
                        icon: Icons.badge_outlined,
                        loading: _searchingPatient,
                        onChanged: _searchPatients,
                      ),
                      if (_suggestions.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildSuggestions(),
                      ],
                    ])
                  // ── PACIENTE: solo barra para buscar EN SU historial
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.search,
                            color: Color(0xFF4F46E5), size: 16),
                        const SizedBox(width: 6),
                        Text('Buscar en tu historial',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: Colors.grey[600])),
                      ]),
                      const SizedBox(height: 8),
                      _searchField(
                        controller: _infoSearchCtrl,
                        hint: 'Buscar consultas, diagnósticos o médicos...',
                        icon: Icons.search,
                        loading: false,
                        onChanged: (v) => _loadRecords(search: v),
                      ),
                    ]),
            ),
          ),

          // ── TABLA / LISTA
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(children: [
                // Cabecera de columnas
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  child: Row(children: [
                    const SizedBox(width: 90, child: _TH('FECHA')),
                    if (isDoctor)
                      const Expanded(flex: 2, child: _TH('PACIENTE')),
                    if (isPatient)
                      const Expanded(flex: 2, child: _TH('MÉDICO')),
                    const Expanded(flex: 2, child: _TH('ESPECIALIDAD')),
                    const Expanded(flex: 3,
                        child: _TH('DIAGNÓSTICO PRINCIPAL')),
                    const SizedBox(width: 100, child: _TH('ACCIÓN')),
                  ]),
                ),
                Divider(height: 1, color: Colors.grey.shade100),

                if (_isLoading)
                  const Padding(padding: EdgeInsets.all(56),
                      child: Center(child: CircularProgressIndicator(
                          color: Color(0xFF4F46E5))))
                else if (_records.isEmpty)
                  _emptyState(isDoctor)
                else
                  ..._records.asMap().entries.map((e) => _RecordRow(
                    record:    e.value,
                    shaded:    e.key.isOdd,
                    isDoctor:  isDoctor,
                    isPatient: isPatient,
                    onView:    () => _goToDetail(e.value),
                    onNewEvol: isDoctor
                        ? () => _goToNewEvolution(e.value) : null,
                  )),

                // Footer con contador
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    Text(
                      'Mostrando ${_records.length} de ${_records.length} consultas registradas',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    // Paginación visual
                    Row(children: [
                      _PageBtn(icon: Icons.chevron_left, onTap: null),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: const Color(0xFF1A237E),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('1', style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold,
                            fontSize: 13)),
                      ),
                      _PageBtn(icon: Icons.chevron_right, onTap: null),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _goToDetail(MedicalRecord r) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => MedicalRecordDetailScreen(recordId: r.id!)));
  }

  void _goToNewEvolution(MedicalRecord? r) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => CreateEvolutionScreen(
          preselectedPatientId:   r?.patientId,
          preselectedPatientName: r?.patientFullName,
          preselectedPatientData: r?.patient,
        ))).then((_) => _loadRecords());
  }

  Widget _searchField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool loading,
    required ValueChanged<String> onChanged,
  }) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.grey[400], size: 18),
      suffixIcon: loading
          ? const Padding(padding: EdgeInsets.all(12),
              child: SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF4F46E5))))
          : null,
      filled: true, fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    ),
  );

  Widget _buildSuggestions() => Container(
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.08), blurRadius: 12)],
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(children: _suggestions.map((p) {
      final name = '${p['name']} ${p['last_name']}'.trim();
      final doc  = p['document']?.toString() ?? '';
      return InkWell(
        onTap: () => _selectPatient(p),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            _Avatar(name: name, size: 32),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13,
                  color: Color(0xFF1A1A7A))),
              Text('Doc: $doc', style: TextStyle(
                  fontSize: 11, color: Colors.grey[500])),
            ])),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
          ]),
        ),
      );
    }).toList()),
  );

  Widget _emptyState(bool isDoctor) => Padding(
    padding: const EdgeInsets.all(56),
    child: Center(child: Column(children: [
      Icon(Icons.folder_open_outlined, size: 72, color: Colors.grey[200]),
      const SizedBox(height: 16),
      Text(
        isDoctor
            ? 'Busca un paciente para ver su historial'
            : 'Aún no tienes registros médicos',
        style: TextStyle(color: Colors.grey[400], fontSize: 15)),
      if (isDoctor) ...[
        const SizedBox(height: 6),
        Text('Ingresa el documento o nombre en el buscador',
            style: TextStyle(color: Colors.grey[300], fontSize: 12)),
      ],
    ])),
  );

  @override
  void dispose() {
    _infoSearchCtrl.dispose();
    _patientSearchCtrl.dispose();
    super.dispose();
  }
}

// ── Fila de la tabla
class _RecordRow extends StatelessWidget {
  final MedicalRecord record;
  final bool shaded, isDoctor, isPatient;
  final VoidCallback onView;
  final VoidCallback? onNewEvol;
  const _RecordRow({
    required this.record, required this.shaded,
    required this.isDoctor, required this.isPatient,
    required this.onView, this.onNewEvol,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onView,
      child: Container(
        color: shaded ? const Color(0xFFF9FAFB) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          // Fecha
          SizedBox(width: 90, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(record.formattedDate, style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 12,
                color: Color(0xFF1A1A7A))),
            Text(record.formattedTime, style: TextStyle(
                fontSize: 10, color: Colors.grey[400])),
          ])),

          // Paciente (médico) / Médico (paciente)
          if (isDoctor)
            Expanded(flex: 2, child: Row(children: [
              _Avatar(name: record.patientFullName, size: 32),
              const SizedBox(width: 8),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(record.patientFullName, style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12,
                    color: Color(0xFF1A1A7A))),
                Text('ID: #${record.id ?? '—'}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ])),
            ])),

          if (isPatient)
            Expanded(flex: 2, child: Row(children: [
              _Avatar(name: 'Dr. ${record.doctorFullName}', size: 32),
              const SizedBox(width: 8),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dr. ${record.doctorFullName}', style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12,
                    color: Color(0xFF1A1A7A))),
                Text(record.doctorEspecialidad,
                    style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ])),
            ])),

          // Especialidad
          Expanded(flex: 2, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20)),
            child: Text(especialidadLabel(record.especialidad),
                style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          )),

          // Diagnóstico
          Expanded(flex: 3, child: Text(
            record.diagnosticoNombre ?? 'Sin diagnóstico registrado',
            style: TextStyle(
              fontSize: 12,
              color: record.diagnosticoNombre != null
                  ? Colors.grey[700] : Colors.grey[400],
              fontStyle: record.diagnosticoNombre != null
                  ? FontStyle.normal : FontStyle.italic,
            ),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          )),

          // Acciones
          SizedBox(width: 100, child: Row(
              mainAxisAlignment: MainAxisAlignment.end, children: [
            _ActionBtn(
                icon: Icons.remove_red_eye_outlined,
                label: 'Ver',
                color: const Color(0xFF4F46E5),
                onTap: onView),
          ])),
        ]),
      ),
    );
  }
}

// ── Widgets auxiliares
class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  const _Avatar({required this.name, this.size = 36});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withOpacity(0.1), shape: BoxShape.circle),
    child: Center(child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
    )),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon; final Color color;
  final String label; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color,
      required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12,
            fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _PageBtn extends StatelessWidget {
  final IconData icon; final VoidCallback? onTap;
  const _PageBtn({required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, size: 16, color: Colors.grey[500]),
    ),
  );
}

class _TH extends StatelessWidget {
  final String text; const _TH(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.bold,
      color: Color(0xFF4F46E5), letterSpacing: 0.5));
}
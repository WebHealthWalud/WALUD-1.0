import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:frontendwalud/screens/history/create_evolution_screen.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/medical_record.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/medical_record_service.dart';

const double _kDetBreak = 800;

class MedicalRecordDetailScreen extends StatefulWidget {
  final int recordId;
  const MedicalRecordDetailScreen({super.key, required this.recordId});
  @override
  State<MedicalRecordDetailScreen> createState() =>
      _MedicalRecordDetailScreenState();
}

class _MedicalRecordDetailScreenState extends State<MedicalRecordDetailScreen> {
  MedicalRecord? _record;
  bool _isLoading = true;
  User? _currentUser;
  bool _isEditing = false;

  final _motivoCtrl = TextEditingController();
  final _examenCtrl = TextEditingController();
  final _diagDescCtrl = TextEditingController();
  final _tratamientoCtrl = TextEditingController();
  final _observCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final userR = await AuthService.getCurrentUser();
    if (userR['success'] && mounted) {
      setState(() => _currentUser = userR['user']);
    }
    await _load();
  }

  Future<void> _load() async {
    final r = await MedicalRecordService.getById(widget.recordId);
    if (mounted)
      setState(() {
        _isLoading = false;
        if (r['success'] == true) {
          _record = r['record'];
          _fillControllers(_record!);
        }
      });
  }

  void _fillControllers(MedicalRecord r) {
    _motivoCtrl.text = r.motivoConsulta;
    _examenCtrl.text = r.examenFisico ?? '';
    _diagDescCtrl.text = r.diagnosticoDescripcion ?? '';
    _tratamientoCtrl.text = r.tratamiento ?? '';
    _observCtrl.text = r.observaciones ?? '';
  }

  Future<void> _saveEdits() async {
    if (_record == null) return;
    setState(() => _isSaving = true);
    final r = await MedicalRecordService.update(widget.recordId, {
      'motivo_consulta': _motivoCtrl.text.trim(),
      'examen_fisico': _examenCtrl.text.trim().isNotEmpty
          ? _examenCtrl.text.trim()
          : null,
      'diagnostico_descripcion': _diagDescCtrl.text.trim().isNotEmpty
          ? _diagDescCtrl.text.trim()
          : null,
      'tratamiento': _tratamientoCtrl.text.trim().isNotEmpty
          ? _tratamientoCtrl.text.trim()
          : null,
      'observaciones': _observCtrl.text.trim().isNotEmpty
          ? _observCtrl.text.trim()
          : null,
    });
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });
    if (mounted) {
      if (r['success'] == true) {
        _snack(
          '✅ Evolución actualizada correctamente',
          const Color(0xFF10B981),
        );
        await _load();
      } else {
        _snack(r['message'] ?? 'Error al guardar', Colors.red);
      }
    }
  }

  // ✅ Genera y descarga un resumen PDF en texto enriquecido usando la API de impresión del navegador
  void _downloadPdf() {
    if (_record == null) return;
    final r = _record!;
    final p = r.patient;
    final patientName = p != null
        ? '${p['name'] ?? ''} ${p['last_name'] ?? ''}'.trim()
        : '—';
    final sangre = p?['tipo_sangre']?.toString() ?? '—';
    final alergias = p?['alergias']?.toString() ?? 'Ninguna';

    final html_content =
        '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Resumen de Consulta — ${r.expediente}</title>
  <style>
    body { font-family: Arial, sans-serif; color: #1A1A7A; padding: 32px; max-width: 800px; margin: 0 auto; }
    h1 { color: #1A237E; font-size: 22px; margin-bottom: 4px; }
    h2 { color: #4F46E5; font-size: 15px; margin: 20px 0 8px; border-bottom: 2px solid #EDE9FE; padding-bottom: 4px; }
    .header-bar { background: linear-gradient(135deg,#1A237E,#3949AB); color: white; padding: 20px 24px; border-radius: 12px; margin-bottom: 24px; }
    .header-bar p { margin: 4px 0; font-size: 13px; opacity: 0.85; }
    .row { display: flex; gap: 16px; margin-bottom: 8px; }
    .label { font-weight: bold; min-width: 140px; font-size: 12px; color: #6B7280; }
    .value { font-size: 13px; }
    .badge { background: #EDE9FE; color: #4F46E5; padding: 2px 10px; border-radius: 20px; font-size: 11px; font-weight: bold; display: inline-block; }
    .box { background: #F9FAFB; border: 1px solid #E5E7EB; border-radius: 8px; padding: 14px; margin-bottom: 12px; font-size: 13px; line-height: 1.6; }
    .vital { display: inline-block; background: #EDE9FE; border-radius: 8px; padding: 8px 14px; margin: 4px; text-align: center; }
    .vital .val { font-size: 18px; font-weight: 900; color: #4F46E5; }
    .vital .lbl { font-size: 9px; color: #6B7280; display: block; }
    .patient-box { background: #F0F9FF; border: 1px solid #BAE6FD; border-radius: 8px; padding: 14px; margin-bottom: 20px; }
    footer { margin-top: 32px; font-size: 11px; color: #9CA3AF; text-align: center; border-top: 1px solid #E5E7EB; padding-top: 12px; }
    @media print { body { padding: 16px; } }
  </style>
</head>
<body>
  <div class="header-bar">
    <h1 style="color:white;margin:0 0 8px">Walud — Resumen de Consulta</h1>
    <p><strong>Expediente:</strong> ${r.expediente}</p>
    <p><strong>Fecha:</strong> ${r.formattedDateLong} — ${r.formattedTime}</p>
    <p><strong>Especialidad:</strong> ${especialidadLabel(r.especialidad)}</p>
    <p><strong>Médico:</strong> Dr. ${r.doctorFullName}</p>
  </div>

  <div class="patient-box">
    <h2 style="margin-top:0;border:none">Datos del Paciente</h2>
    <div class="row"><span class="label">Nombre</span><span class="value">${patientName}</span></div>
    <div class="row"><span class="label">Tipo de Sangre</span><span class="value">${sangre}</span></div>
    <div class="row"><span class="label">Alergias</span><span class="value">${alergias}</span></div>
    <div class="row"><span class="label">Edad</span><span class="value">${r.patientAge}</span></div>
  </div>

  <h2>Motivo de Consulta</h2>
  <div class="box">${r.motivoConsulta}</div>

  ${r.diagnosticoNombre != null ? '''
  <h2>Diagnóstico</h2>
  <div class="box">
    ${r.diagnosticoCie10 != null ? '<span class="badge">${r.diagnosticoCie10}</span><br><br>' : ''}
    <strong>${r.diagnosticoNombre}</strong>
    ${r.diagnosticoDescripcion != null ? '<br><br>${r.diagnosticoDescripcion}' : ''}
  </div>
  ''' : ''}

  ${r.examenFisico != null ? '''
  <h2>Evolución y Examen Físico</h2>
  <div class="box">${r.examenFisico}</div>
  ''' : ''}

  ${r.hasSignosVitales ? '''
  <h2>Signos Vitales</h2>
  <div>
    ${r.presionSistolica != null ? '<div class="vital"><span class="val">${r.presionSistolica!.toInt()}</span><span class="lbl">PRESIÓN SIS. mmHg</span></div>' : ''}
    ${r.presionDiastolica != null ? '<div class="vital"><span class="val">${r.presionDiastolica!.toInt()}</span><span class="lbl">PRESIÓN DIA. mmHg</span></div>' : ''}
    ${r.frecuenciaCardiaca != null ? '<div class="vital"><span class="val">${r.frecuenciaCardiaca!.toInt()}</span><span class="lbl">FREC. CARD. lpm</span></div>' : ''}
    ${r.temperatura != null ? '<div class="vital"><span class="val">${r.temperatura}</span><span class="lbl">TEMPERATURA °C</span></div>' : ''}
    ${r.peso != null ? '<div class="vital"><span class="val">${r.peso}</span><span class="lbl">PESO kg</span></div>' : ''}
    ${r.talla != null ? '<div class="vital"><span class="val">${r.talla}</span><span class="lbl">TALLA m</span></div>' : ''}
    ${r.saturacionOxigeno != null ? '<div class="vital"><span class="val">${r.saturacionOxigeno}</span><span class="lbl">SpO₂ %</span></div>' : ''}
  </div>
  ''' : ''}

  ${r.tratamiento != null ? '''
  <h2>Tratamiento y Receta</h2>
  <div class="box">${r.tratamiento!.replaceAll('\n', '<br>')}</div>
  ''' : ''}

  ${r.observaciones != null ? '''
  <h2>Nota del Profesional</h2>
  <div class="box">${r.observaciones}</div>
  ''' : ''}

  <footer>Generado por Walud Salud Digital • ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}</footer>
  <script>window.onload = function(){ window.print(); }</script>
</body>
</html>
''';

    if (kIsWeb) {
      final blob = html.Blob([html_content], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final win = html.window.open(url, '_blank');
      if (win == null) {
        // fallback: descarga directa como .html
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'consulta_${r.expediente}.html')
          ..click();
      }
      Future.delayed(
        const Duration(seconds: 5),
        () => html.Url.revokeObjectUrl(url),
      );
    } else {
      _snack(
        'La descarga de PDF está disponible solo en el navegador web.',
        Colors.grey,
      );
    }
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

  bool get _isDoctor => _currentUser?.isDoctor == true;
  bool get _isPatient => _currentUser?.isPatient == true;

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
      );
    if (_record == null)
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: const Center(child: Text('Registro no encontrado')),
      );

    final r = _record!;
    final isNarrow = MediaQuery.of(context).size.width < _kDetBreak;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A7A)),
        title: const Text(
          'Detalle de la Consulta',
          style: TextStyle(
            color: Color(0xFF1A1A7A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          // Botón Editar para médico
          if (_isDoctor && !_isEditing) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Color(0xFF4F46E5),
                ),
                label: const Text(
                  'Editar',
                  style: TextStyle(color: Color(0xFF4F46E5), fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4F46E5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
          if (_isDoctor && _isEditing) ...[
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton(
                onPressed: () => setState(() {
                  _isEditing = false;
                  _fillControllers(r);
                }),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveEdits,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Guardar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ],
          // ✅ Botón PDF funcional — visible para todos en pantallas anchas
          if (!isNarrow && !_isEditing) ...[
            OutlinedButton.icon(
              onPressed: _downloadPdf,
              icon: const Icon(
                Icons.download_outlined,
                size: 16,
                color: Color(0xFF4F46E5),
              ),
              label: const Text(
                'Descargar PDF',
                style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4F46E5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            // ✅ Botón seguimiento — solo para médico, redirige a nueva evolución
            if (_isDoctor) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  // Redirige al módulo de nueva evolución con el mismo paciente
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateEvolutionScreen(
                        preselectedPatientId: _record!.patient?['id'],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text(
                  'Nueva Evolución',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  elevation: 0,
                ),
              ),
            ],
            const SizedBox(width: 12),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isNarrow ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Consultas',
                    style: TextStyle(color: Color(0xFF4F46E5), fontSize: 13),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                const Text(
                  'Resumen de Consulta',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Detalle de la Consulta',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A7A),
              ),
            ),
            Text(
              'Revisa las indicaciones y el resumen clínico de tu última atención.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 20),

            // ✅ Botones en mobile — PDF siempre, seguimiento solo médico
            if (isNarrow && !_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _downloadPdf,
                      icon: const Icon(Icons.download_outlined, size: 14),
                      label: const Text(
                        'Descargar PDF',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4F46E5),
                        side: const BorderSide(color: Color(0xFF4F46E5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  // ✅ Seguimiento solo para médico en mobile
                  if (_isDoctor) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/nueva-evolucion',
                            arguments: {'patient_id': _record!.patient?['id']},
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 14),
                        label: const Text(
                          'Nueva Evolución',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06B6D4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ✅ Info del paciente ARRIBA (antes de todo el contenido clínico)
            if (r.patient != null) ...[
              _patientSummary(r),
              const SizedBox(height: 20),
            ],

            // Fila superior: Especialista + Diagnóstico
            isNarrow
                ? Column(
                    children: [
                      _doctorCard(r),
                      const SizedBox(height: 16),
                      _diagCard(r),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _doctorCard(r)),
                      const SizedBox(width: 20),
                      Expanded(flex: 4, child: _diagCard(r)),
                    ],
                  ),
            const SizedBox(height: 20),

            // Fila inferior: Evolución + Tratamiento
            isNarrow
                ? Column(
                    children: [
                      _evolucionColumn(r),
                      const SizedBox(height: 16),
                      _tratamientoColumn(r),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: _evolucionColumn(r)),
                      const SizedBox(width: 20),
                      Expanded(flex: 3, child: _tratamientoColumn(r)),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // ── Info del paciente — ahora arriba
  Widget _patientSummary(MedicalRecord r) {
    final p = r.patient!;
    final name = '${p['name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
    final sangre = p['tipo_sangre']?.toString() ?? '—';
    final alergias = p['alergias']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _DoctorAvatar(name: name, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PACIENTE',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  r.patientAge,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chipWhite(Icons.water_drop_outlined, 'Sangre: $sangre'),
              if (alergias != null && alergias.isNotEmpty)
                _chipWhite(Icons.warning_amber_outlined, 'Alergia'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipWhite(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  // ── Tarjeta del especialista
  Widget _doctorCard(MedicalRecord r) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ESPECIALISTA',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.5,
            color: const Color(0xFF4F46E5),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _DoctorAvatar(name: r.doctorFullName, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${r.doctorFullName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A1A7A),
                    ),
                  ),
                  Text(
                    especialidadLabel(r.especialidad),
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Divider(height: 1, color: Colors.grey.shade100),
        const SizedBox(height: 12),
        _infoRow(
          Icons.calendar_today_outlined,
          'Fecha de Consulta',
          r.formattedDateLong,
        ),
        const SizedBox(height: 8),
        _infoRow(Icons.access_time_outlined, 'Hora', r.formattedTime),
        const SizedBox(height: 8),
        _infoRow(Icons.numbers_outlined, 'Expediente', r.expediente),
      ],
    ),
  );

  // ── Tarjeta del diagnóstico
  Widget _diagCard(MedicalRecord r) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.biotech_outlined,
                color: Color(0xFF4F46E5),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Diagnóstico Principal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A7A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (r.diagnosticoNombre != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: const Color(0xFF4F46E5), width: 4),
              ),
              color: const Color(0xFF4F46E5).withOpacity(0.03),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r.diagnosticoCie10 != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      r.diagnosticoCie10!,
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  r.diagnosticoNombre!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _editField(
                      _diagDescCtrl,
                      'Descripción del diagnóstico...',
                      3,
                    ),
                  )
                else if (r.diagnosticoDescripcion != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    r.diagnosticoDescripcion!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No se registró un diagnóstico.',
              style: TextStyle(
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    ),
  );

  // ── Columna Izquierda: Evolución
  Widget _evolucionColumn(MedicalRecord r) => Column(
    children: [
      _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(Icons.chat_bubble_outline, 'Motivo de Consulta'),
            const SizedBox(height: 12),
            _isEditing
                ? _editField(_motivoCtrl, 'Motivo de la consulta...', 4)
                : Text(
                    r.motivoConsulta,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
          ],
        ),
      ),
      if (r.examenFisico != null || _isEditing) ...[
        const SizedBox(height: 16),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardHeader(
                Icons.health_and_safety_outlined,
                'Evolución y Observaciones',
              ),
              const SizedBox(height: 12),
              _isEditing
                  ? _editField(_examenCtrl, 'Hallazgos del examen físico...', 5)
                  : Text(
                      r.examenFisico ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
              if (r.hasSignosVitales && !_isEditing) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (r.presionSistolica != null)
                      _vitalChip(
                        'PRESIÓN SISTÓLICA',
                        '${r.presionSistolica!.toInt()}',
                        'mmHg',
                        const Color(0xFF4F46E5),
                      ),
                    if (r.presionDiastolica != null)
                      _vitalChip(
                        'PRESIÓN DIASTÓLICA',
                        '${r.presionDiastolica!.toInt()}',
                        'mmHg',
                        const Color(0xFF06B6D4),
                      ),
                    if (r.frecuenciaCardiaca != null)
                      _vitalChip(
                        'FREC. CARDÍACA',
                        '${r.frecuenciaCardiaca!.toInt()}',
                        'lpm',
                        const Color(0xFFEF4444),
                      ),
                    if (r.temperatura != null)
                      _vitalChip(
                        'TEMPERATURA',
                        '${r.temperatura}',
                        '°C',
                        const Color(0xFFD97706),
                      ),
                    if (r.peso != null)
                      _vitalChip(
                        'PESO',
                        '${r.peso}',
                        'kg',
                        const Color(0xFF10B981),
                      ),
                    if (r.talla != null)
                      _vitalChip(
                        'TALLA',
                        '${r.talla}',
                        'm',
                        const Color(0xFF7C3AED),
                      ),
                    if (r.saturacionOxigeno != null)
                      _vitalChip(
                        'SpO₂',
                        '${r.saturacionOxigeno}',
                        '%',
                        const Color(0xFF0EA5E9),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    ],
  );

  // ── Columna Derecha: Tratamiento + Nota profesional
  // ✅ Info del paciente se quitó de aquí (ahora está arriba)
  Widget _tratamientoColumn(MedicalRecord r) => Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medication_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Tratamiento y Receta',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditing)
              TextFormField(
                controller: _tratamientoCtrl,
                maxLines: 6,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Medicamentos e indicaciones...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              )
            else if (r.tratamiento != null)
              ..._parseTratamiento(r.tratamiento!).map(_treatItem)
            else
              Text(
                'Sin tratamiento registrado.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),

      if (r.observaciones != null || _isEditing) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF06B6D4), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Nota del Profesional',
                    style: TextStyle(
                      color: Color(0xFF0369A1),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _isEditing
                  ? _editField(_observCtrl, 'Nota para el paciente...', 3)
                  : Text(
                      r.observaciones ?? '',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
            ],
          ),
        ),
      ],
    ],
  );

  // ── Helpers UI
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
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
    child: child,
  );

  Widget _cardHeader(IconData icon, String title) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4F46E5).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF4F46E5), size: 18),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A7A),
        ),
      ),
    ],
  );

  Widget _infoRow(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: Colors.grey[400]),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A7A),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _vitalChip(String label, String value, String unit, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  List<String> _parseTratamiento(String t) =>
      t.split('\n').where((l) => l.trim().isNotEmpty).toList();

  Widget _treatItem(String item) {
    final parts = item.split(' - ');
    final title = parts[0].trim();
    final detail = parts.length > 1 ? parts[1].trim() : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, String hint, int lines) =>
      TextFormField(
        controller: ctrl,
        maxLines: lines,
        decoration: InputDecoration(
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      );

  Widget _chip(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    _motivoCtrl.dispose();
    _examenCtrl.dispose();
    _diagDescCtrl.dispose();
    _tratamientoCtrl.dispose();
    _observCtrl.dispose();
    super.dispose();
  }
}

class _DoctorAvatar extends StatelessWidget {
  final String name;
  final double size;
  const _DoctorAvatar({required this.name, this.size = 52});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
      ),
    ),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'M',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.40,
        ),
      ),
    ),
  );
}

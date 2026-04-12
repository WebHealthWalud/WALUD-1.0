import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';

// ── Helper inline de selección de archivos (Web + Móvil)
class _PickedFile {
  final String     name;
  final String?    path;
  final Uint8List? bytes;
  final bool       isValid;
  const _PickedFile({required this.name, this.path, this.bytes, this.isValid = true});
  static const _PickedFile empty = _PickedFile(name: '', isValid: false);
}

Future<_PickedFile> _pickFile() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    withData: kIsWeb,
    withReadStream: false,
  );
  if (result == null || result.files.isEmpty) return _PickedFile.empty;
  final file = result.files.first;
  if (kIsWeb) {
    if (file.bytes == null) return _PickedFile.empty;
    return _PickedFile(name: file.name, bytes: file.bytes);
  } else {
    if (file.path == null) return _PickedFile.empty;
    return _PickedFile(name: file.name, path: file.path);
  }
}

class AppointmentDetailScreen extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback? onChanged;
  final bool editMode;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
    this.onChanged,
    this.editMode = false,
  });

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late Appointment _appt;
  User? _currentUser;
  bool  _isEditing   = false;
  bool  _isSaving    = false;
  bool  _isUploading = false;

  // Edición paciente
  late TextEditingController _reasonController;
  late TextEditingController _notesController;
  DateTime?  _editDate;
  TimeOfDay? _editTime;
  String?    _editEspecialidad;

  // ✅ Médico solo puede marcar como 'realizada'
  AppointmentStatus? _editStatus;

  bool get _isPending => _appt.status == AppointmentStatus.pendiente;
  bool get _isDoc     => _currentUser?.isDoctor == true;
  bool get _isPatient => _currentUser?.isPatient == true;

  // ✅ Verificar si el paciente aún puede editar (máximo 12 horas desde creación)
  bool get _canPatientEdit {
    if (!_isPending) return false;
    if (_appt.createdAt == null) return true;
    final hoursElapsed = DateTime.now().difference(_appt.createdAt!).inHours;
    return hoursElapsed < 12;
  }

  @override
  void initState() {
    super.initState();
    _appt         = widget.appointment;
    _isEditing    = widget.editMode && (_isPending);
    _reasonController = TextEditingController(text: _appt.reason);
    _notesController  = TextEditingController(text: _appt.notes ?? '');
    _editDate         = _appt.dateTime;
    _editTime         = TimeOfDay.fromDateTime(_appt.dateTime);
    _editEspecialidad = _appt.especialidad;
    _editStatus       = AppointmentStatus.realizada; // médico solo puede poner realizada
    _loadUser();
  }

  Future<void> _loadUser() async {
    final r = await AuthService.getCurrentUser();
    if (r['success'] && mounted) setState(() => _currentUser = r['user']);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    Map<String, dynamic> result;

    if (_isDoc) {
      // ✅ Médico solo puede marcar como realizada
      result = await AppointmentService.updateStatus(_appt.id!, AppointmentStatus.realizada);
    } else {
      final dt = DateTime(
        _editDate!.year, _editDate!.month, _editDate!.day,
        _editTime!.hour, _editTime!.minute,
      );
      final updated = Appointment(
        id:              _appt.id,
        patientId:       _appt.patientId,
        doctorId:        _appt.doctorId,
        patientDocument: _appt.patientDocument,
        patientName:     _appt.patientName,
        doctorName:      _appt.doctorName,
        especialidad:    _editEspecialidad ?? _appt.especialidad,
        appointmentType: _appt.appointmentType,
        dateTime:        dt,
        reason:          _reasonController.text.trim(),
        notes:           _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      result = await AppointmentService.updatePatient(_appt.id!, updated);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (result['success'] == true) {
        if (result['appointment'] != null) setState(() => _appt = result['appointment']);
        setState(() => _isEditing = false);
        widget.onChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Cita actualizada'), backgroundColor: Color(0xFF10B981)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    final picked = await _pickFile();
    if (!picked.isValid) return;

    setState(() => _isUploading = true);
    final r = await AppointmentService.uploadAttachment(
      _appt.id!,
      fileName:  picked.name,
      filePath:  picked.path,
      fileBytes: picked.bytes,
    );
    setState(() => _isUploading = false);

    if (mounted) {
      if (r['success'] == true) {
        setState(() => _appt = Appointment(
          id:              _appt.id,
          patientId:       _appt.patientId,
          doctorId:        _appt.doctorId,
          patientDocument: _appt.patientDocument,
          patientName:     _appt.patientName,
          doctorName:      _appt.doctorName,
          especialidad:    _appt.especialidad,
          appointmentType: _appt.appointmentType,
          dateTime:        _appt.dateTime,
          reason:          _appt.reason,
          status:          _appt.status,
          notes:           _appt.notes,
          attachmentName:  r['attachment_name'],
          attachmentPath:  r['attachment_url'],
          createdAt:       _appt.createdAt,
        ));
        widget.onChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Archivo adjuntado correctamente'), backgroundColor: Color(0xFF10B981)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r['message'] ?? 'Error al subir'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ✅ Abrir/descargar el archivo adjunto
  Future<void> _viewAttachment() async {
    if (_appt.attachmentPath == null && _appt.attachmentName == null) return;

    // ✅ Base del servidor Laravel — ajusta si cambias de servidor
    const serverBase = 'http://127.0.0.1:8000';

    String url = _appt.attachmentPath ?? '';

    // Casos posibles que devuelve Laravel:
    // 1. Ya es URL completa:  "http://127.0.0.1:8000/storage/appointments/..."
    // 2. Ruta con /storage:   "/storage/appointments/attachments/archivo.pdf"
    // 3. Ruta interna:        "appointments/attachments/archivo.pdf"
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // Ya es URL completa — usar tal cual
    } else if (url.startsWith('/storage/')) {
      url = '$serverBase$url';
    } else if (url.startsWith('storage/')) {
      url = '$serverBase/$url';
    } else {
      // Ruta interna del disco public: "appointments/attachments/archivo.pdf"
      url = '$serverBase/storage/$url';
    }

    final uri = Uri.parse(url);

    try {
      if (kIsWeb) {
        // ✅ En Flutter Web usar dart:html directamente — evita restricciones de url_launcher
        html.window.open(url, '_blank');
      } else {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('No se puede abrir la URL');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el archivo. URL: $url'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(int.parse('0x${_appt.statusColor}'));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar Cita' : 'Detalle de Cita',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4F46E5),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // ✅ Médico: solo si pendiente, botón para marcar realizada
          if (!_isEditing && _isPending && _isDoc)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text('Marcar Realizada',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          // ✅ Paciente: solo si pendiente Y dentro de las 12 horas
          if (!_isEditing && _canPatientEdit && _isPatient)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text('Editar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          if (_isEditing)
            TextButton(
              onPressed: () => setState(() { _isEditing = false; }),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Estado badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(_appt.statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
            ),
          ),

          // ── Banner informativo según estado
          if (!_isPending) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Esta cita está ${_appt.statusLabel.toLowerCase()} y no puede modificarse.',
                  style: const TextStyle(color: Colors.amber, fontSize: 13),
                )),
              ]),
            ),
          ],

          // ── Paciente: aviso límite 12 horas
          if (_isPending && _isPatient && !_canPatientEdit) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.timer_off_outlined, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                const Expanded(child: Text(
                  'Han pasado más de 12 horas desde que agendaste esta cita. Ya no puedes modificarla.',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                )),
              ]),
            ),
          ],
          const SizedBox(height: 20),

          // ── Información Médica
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('Información Médica'),
            const SizedBox(height: 12),
            _infoRow(Icons.person, 'Médico', _appt.doctorName, isBlue: true),
            const SizedBox(height: 10),
            if (_isEditing && _isPatient)
              _especialidadDropdown()
            else
              _infoRow(Icons.medical_services, 'Especialidad', especialidadLabel(_appt.especialidad)),
            if (_isDoc) ...[
              const SizedBox(height: 10),
              _infoRow(Icons.person_outline, 'Paciente', _appt.patientName),
            ],
          ])),

          // ── Fecha y hora
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('Fecha y Hora'),
            const SizedBox(height: 12),
            _infoRow(Icons.access_time_outlined, 'Creado el',
              _appt.createdAt != null
                  ? DateFormat('d MMM yyyy, hh:mm a', 'es').format(_appt.createdAt!)
                  : 'N/A'),
            const Divider(height: 20),
            if (_isEditing && _isPatient) ...[
              _editableDateRow(),
              const SizedBox(height: 10),
              _editableTimeRow(),
            ] else ...[
              _infoRow(Icons.calendar_today, 'Fecha programada',
                DateFormat('EEEE, d MMMM yyyy', 'es').format(_appt.dateTime)),
              const SizedBox(height: 10),
              _infoRow(Icons.schedule, 'Hora', DateFormat('hh:mm a').format(_appt.dateTime)),
            ],
          ])),

          // ── Detalles
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('Detalles de la Consulta'),
            const SizedBox(height: 12),
            _infoRow(Icons.category_outlined, 'Tipo', _appt.appointmentType),
            const Divider(height: 20),
            if (_isEditing && _isPatient) ...[
              const Text('Motivo *', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ] else
              _infoRow(Icons.note_alt_outlined, 'Motivo', _appt.reason),
            const Divider(height: 20),
            if (_isEditing && _isPatient) ...[
              const Text('Notas adicionales', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Alergias, medicamentos, etc.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ] else if (_appt.notes != null && _appt.notes!.isNotEmpty)
              _infoRow(Icons.edit_note, 'Notas', _appt.notes!),
          ])),

          // ── Médico: confirmar realizada (card simple)
          if (_isEditing && _isDoc)
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sectionTitle('Confirmar Consulta'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Marcar como Realizada', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    Text('Confirma que la consulta fue completada exitosamente.',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ])),
                ]),
              ),
            ])),

          // ── Archivo adjunto
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('Archivo Adjunto'),
            const SizedBox(height: 12),

            if (_appt.attachmentName != null) ...[
              // ✅ Tarjeta del archivo con botón VER
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description_outlined, color: Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_appt.attachmentName!,
                      style: const TextStyle(color: Color(0xFF1A1A7A), fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                    const Text('Archivo adjunto por el paciente',
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ])),
                  // ✅ Botón VER — disponible para médico Y paciente
                  TextButton.icon(
                    onPressed: _viewAttachment,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Ver', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF4F46E5)),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
            ],

            // ✅ Botón adjuntar: SOLO paciente
            if (_isPatient) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickAndUploadFile,
                  icon: _isUploading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_appt.attachmentName != null ? Icons.refresh : Icons.upload_file),
                  label: Text(_isUploading
                      ? 'Subiendo...'
                      : (_appt.attachmentName != null ? 'Reemplazar archivo' : 'Adjuntar archivo')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    side: const BorderSide(color: Color(0xFF4F46E5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('PDF, JPG, PNG, DOC — máx. 10 MB',
                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],

            if (_isDoc && _appt.attachmentName == null)
              const Text('El paciente no ha adjuntado archivos.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ])),

          // ── Términos y condiciones (solo paciente en citas pendientes)
          if (_isPatient && _isPending)
            _buildTermsCard(),

          // ── Guardar
          if (_isEditing) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _isDoc ? 'Confirmar Consulta Realizada' : 'Guardar cambios',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  // ── Tarjeta de Términos y Condiciones
  Widget _buildTermsCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.policy_outlined, color: Colors.amber.shade700, size: 20),
          ),
          const SizedBox(width: 10),
          Text('Política de Modificación',
            style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade800,
            )),
        ]),
        const SizedBox(height: 12),
        _termRow(Icons.timer_outlined,
          'Ventana de modificación',
          'Tienes hasta 12 horas después de agendar tu cita para modificarla o cancelarla sin penalización.'),
        const SizedBox(height: 10),
        _termRow(Icons.edit_calendar_outlined,
          'Cambios permitidos',
          'Puedes modificar la fecha, hora, especialidad, motivo y notas de tu cita mientras esté en estado Pendiente.'),
        const SizedBox(height: 10),
        _termRow(Icons.attach_file_outlined,
          'Archivos adjuntos',
          'Puedes adjuntar o reemplazar archivos en cualquier momento, incluso después de las 12 horas.'),
        const SizedBox(height: 10),
        _termRow(Icons.cancel_outlined,
          'Cancelaciones',
          'Las cancelaciones realizadas con menos de 2 horas de anticipación pueden estar sujetas a cargo según la política del médico.'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, size: 14, color: Colors.amber.shade700),
            const SizedBox(width: 6),
            Expanded(child: Text(
              'Al agendar una cita aceptas estos términos y las políticas de privacidad de Walud.',
              style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _termRow(IconData icon, String title, String desc) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: Colors.grey[400]),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF374151))),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4)),
      ])),
    ],
  );

  // ── Helpers UI
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );

  Widget _sectionTitle(String t) => Text(t,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), letterSpacing: 0.5));

  Widget _infoRow(IconData icon, String label, String value, {bool isBlue = false}) =>
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: Colors.grey[400]),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        Text(value, style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isBlue ? const Color(0xFF4F46E5) : const Color(0xFF1A1A7A),
          fontSize: 14,
        )),
      ])),
    ]);

  Widget _especialidadDropdown() => DropdownButtonFormField<String>(
    value: _editEspecialidad,
    decoration: InputDecoration(
      labelText: 'Especialidad',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    items: kEspecialidades.map((e) =>
      DropdownMenuItem(value: e['value'], child: Text(e['label']!))).toList(),
    onChanged: (v) => setState(() => _editEspecialidad = v),
  );

  Widget _editableDateRow() => InkWell(
    onTap: () async {
      final d = await showDatePicker(
        context: context, initialDate: _editDate!,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 60)),
      );
      if (d != null) setState(() => _editDate = d);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'Fecha',
        prefixIcon: const Icon(Icons.calendar_today, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: Text(DateFormat('d MMM yyyy', 'es').format(_editDate!),
        style: const TextStyle(fontWeight: FontWeight.w500)),
    ),
  );

  Widget _editableTimeRow() => InkWell(
    onTap: () async {
      final t = await showTimePicker(context: context, initialTime: _editTime!);
      if (t != null) setState(() => _editTime = t);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'Hora',
        prefixIcon: const Icon(Icons.schedule, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: Text(_editTime!.format(context), style: const TextStyle(fontWeight: FontWeight.w500)),
    ),
  );

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
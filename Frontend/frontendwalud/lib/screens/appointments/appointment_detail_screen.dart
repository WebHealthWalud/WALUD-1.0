import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';

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
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late Appointment _appt;
  User? _currentUser;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploading = false;

  // Edición paciente
  late TextEditingController _reasonController;
  late TextEditingController _notesController;
  DateTime? _editDate;
  TimeOfDay? _editTime;
  String? _editEspecialidad;

  // Edición médico
  AppointmentStatus? _editStatus;

  // ✅ Solo se puede editar si está pendiente
  bool get _isPending => _appt.status == AppointmentStatus.pendiente;
  bool get _isDoc => _currentUser?.isDoctor == true;
  bool get _isPatient => _currentUser?.isPatient == true;

  @override
  void initState() {
    super.initState();
    _appt = widget.appointment;
    // Solo abrir en edición si la cita está pendiente
    _isEditing = widget.editMode && _isPending;
    _reasonController = TextEditingController(text: _appt.reason);
    _notesController = TextEditingController(text: _appt.notes ?? '');
    _editDate = _appt.dateTime;
    _editTime = TimeOfDay.fromDateTime(_appt.dateTime);
    _editEspecialidad = _appt.especialidad;
    _editStatus = _appt.status;
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
      result = await AppointmentService.updateStatus(_appt.id!, _editStatus!);
    } else {
      final dt = DateTime(
        _editDate!.year,
        _editDate!.month,
        _editDate!.day,
        _editTime!.hour,
        _editTime!.minute,
      );
      final updated = Appointment(
        id: _appt.id,
        patientId: _appt.patientId,
        doctorId: _appt.doctorId,
        patientDocument: _appt.patientDocument,
        patientName: _appt.patientName,
        doctorName: _appt.doctorName,
        especialidad: _editEspecialidad ?? _appt.especialidad,
        appointmentType: _appt.appointmentType,
        dateTime: dt,
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      result = await AppointmentService.updatePatient(_appt.id!, updated);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (result['success'] == true) {
        if (result['appointment'] != null)
          setState(() => _appt = result['appointment']);
        setState(() => _isEditing = false);
        widget.onChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cita actualizada'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    // ✅ Adjuntar archivo disponible en cualquier estado (solo paciente dueño)
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result == null ||
        result.files.isEmpty ||
        result.files.first.path == null)
      return;

    setState(() => _isUploading = true);
    final r = await AppointmentService.uploadAttachment(
      _appt.id!,
      File(result.files.first.path!),
    );
    setState(() => _isUploading = false);

    if (mounted) {
      if (r['success'] == true) {
        setState(
          () => _appt = Appointment(
            id: _appt.id,
            patientId: _appt.patientId,
            doctorId: _appt.doctorId,
            patientDocument: _appt.patientDocument,
            patientName: _appt.patientName,
            doctorName: _appt.doctorName,
            especialidad: _appt.especialidad,
            appointmentType: _appt.appointmentType,
            dateTime: _appt.dateTime,
            reason: _appt.reason,
            status: _appt.status,
            notes: _appt.notes,
            attachmentName: r['attachment_name'],
            createdAt: _appt.createdAt,
          ),
        );
        widget.onChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Archivo adjuntado'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(r['message'] ?? 'Error'),
            backgroundColor: Colors.red,
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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF4F46E5),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // ✅ Solo mostrar botón editar si la cita está PENDIENTE
          if (!_isEditing && _isPending)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: Text(
                _isDoc ? 'Cambiar estado' : 'Editar',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_isEditing)
            TextButton(
              onPressed: () => setState(() {
                _isEditing = false;
                _editStatus = _appt.status;
              }),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Badge estado
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _appt.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Banner cuando NO es pendiente — informa que no se puede editar
            if (!_isPending) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta cita está ${_appt.statusLabel.toLowerCase()} y no puede modificarse.',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ── Médico / Especialidad
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Información Médica'),
                  const SizedBox(height: 12),
                  _infoRow(
                    Icons.person,
                    'Médico',
                    _appt.doctorName,
                    isBlue: true,
                  ),
                  const SizedBox(height: 10),
                  if (_isEditing && _isPatient)
                    _especialidadDropdown()
                  else
                    _infoRow(
                      Icons.medical_services,
                      'Especialidad',
                      especialidadLabel(_appt.especialidad),
                    ),
                ],
              ),
            ),

            // ── Fecha y hora
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Fecha y Hora'),
                  const SizedBox(height: 12),
                  _infoRow(
                    Icons.access_time_outlined,
                    'Creado el',
                    _appt.createdAt != null
                        ? DateFormat(
                            'd MMM yyyy, hh:mm a',
                            'es',
                          ).format(_appt.createdAt!)
                        : 'N/A',
                  ),
                  const Divider(height: 20),
                  if (_isEditing && _isPatient) ...[
                    _editableDateRow(),
                    const SizedBox(height: 10),
                    _editableTimeRow(),
                  ] else ...[
                    _infoRow(
                      Icons.calendar_today,
                      'Fecha programada',
                      DateFormat(
                        'EEEE, d MMMM yyyy',
                        'es',
                      ).format(_appt.dateTime),
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      Icons.schedule,
                      'Hora',
                      DateFormat('hh:mm a').format(_appt.dateTime),
                    ),
                  ],
                ],
              ),
            ),

            // ── Detalles
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Detalles de la Consulta'),
                  const SizedBox(height: 12),
                  _infoRow(
                    Icons.category_outlined,
                    'Tipo',
                    _appt.appointmentType,
                  ),
                  const Divider(height: 20),
                  if (_isEditing && _isPatient) ...[
                    const Text(
                      'Motivo *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ] else
                    _infoRow(Icons.note_alt_outlined, 'Motivo', _appt.reason),
                  const Divider(height: 20),
                  if (_isEditing && _isPatient) ...[
                    const Text(
                      'Notas adicionales',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Alergias, medicamentos, etc.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ] else if (_appt.notes != null && _appt.notes!.isNotEmpty)
                    _infoRow(Icons.edit_note, 'Notas', _appt.notes!),
                ],
              ),
            ),

            // ── Cambio de estado (médico, solo pendiente)
            if (_isEditing && _isDoc)
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Actualizar Estado'),
                    const SizedBox(height: 12),
                    ...AppointmentStatus.values.map((s) {
                      final tempAppt = Appointment(
                        patientId: 0,
                        doctorId: 0,
                        patientDocument: '',
                        patientName: '',
                        doctorName: '',
                        especialidad: '',
                        appointmentType: '',
                        dateTime: DateTime.now(),
                        reason: '',
                        status: s,
                      );
                      final sc = Color(int.parse('0x${tempAppt.statusColor}'));
                      return RadioListTile<AppointmentStatus>(
                        value: s,
                        groupValue: _editStatus,
                        onChanged: (v) => setState(() => _editStatus = v),
                        title: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: sc,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(tempAppt.statusLabel),
                          ],
                        ),
                        activeColor: const Color(0xFF4F46E5),
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  ],
                ),
              ),

            // ── Archivo adjunto
            // ✅ Botón adjuntar activo SOLO si es paciente dueño
            // Médico solo VE el archivo, nunca puede adjuntar ni modificar
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Archivo Adjunto'),
                  const SizedBox(height: 12),
                  if (_appt.attachmentName != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4F46E5).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_file,
                            color: Color(0xFF4F46E5),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _appt.attachmentName!,
                              style: const TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF10B981),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  // ✅ Botón adjuntar: SOLO para paciente dueño — sin restricción de estado
                  if (_isPatient) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _pickAndUploadFile,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _appt.attachmentName != null
                                    ? Icons.refresh
                                    : Icons.upload_file,
                              ),
                        label: Text(
                          _isUploading
                              ? 'Subiendo...'
                              : (_appt.attachmentName != null
                                    ? 'Reemplazar archivo'
                                    : 'Adjuntar archivo'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                          side: const BorderSide(color: Color(0xFF4F46E5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF, JPG, PNG, DOC — máx. 10 MB',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                  // Médico: solo mensaje informativo
                  if (_isDoc && _appt.attachmentName == null)
                    const Text(
                      'El paciente no ha adjuntado archivos.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                ],
              ),
            ),

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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Guardar cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Helpers UI
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
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
    child: child,
  );

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Color(0xFF4F46E5),
      letterSpacing: 0.5,
    ),
  );

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool isBlue = false,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: Colors.grey[400]),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isBlue
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF1A1A7A),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _especialidadDropdown() => DropdownButtonFormField<String>(
    value: _editEspecialidad,
    decoration: InputDecoration(
      labelText: 'Especialidad',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    items: kEspecialidades
        .map(
          (e) => DropdownMenuItem(value: e['value'], child: Text(e['label']!)),
        )
        .toList(),
    onChanged: (v) => setState(() => _editEspecialidad = v),
  );

  Widget _editableDateRow() => InkWell(
    onTap: () async {
      final d = await showDatePicker(
        context: context,
        initialDate: _editDate!,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      child: Text(
        DateFormat('d MMM yyyy', 'es').format(_editDate!),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      child: Text(
        _editTime!.format(context),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),
  );

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

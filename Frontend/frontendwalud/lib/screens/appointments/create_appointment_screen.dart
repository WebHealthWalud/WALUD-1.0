import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/file_picker_helper.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final VoidCallback? onCreated;
  final Appointment? appointmentToEdit;

  const CreateAppointmentScreen({
    super.key,
    this.onCreated,
    this.appointmentToEdit,
  });

  bool get isEditing => appointmentToEdit != null;

  @override
  State<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  User? _currentUser;
  bool _isLoading = true;
  bool _isSubmitting = false;

  String? _selectedEspecialidad;
  int? _selectedDoctorId;
  String? _selectedDoctorName;
  String? _selectedSlot;
  DateTime _focusedDate = DateTime.now().add(const Duration(days: 1));

  List<Map<String, dynamic>> _availableDoctors = [];
  bool _loadingSlots = false;

  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  String _appointmentType = 'Consulta general';

  // Solo médico creando cita
  final _patientDocCtrl = TextEditingController();
  String _patientTipoDoc = 'cedula_ciudadania';
  User? _foundPatient;
  bool _isSearching = false;

  PickedFileResult? _pickedFile;
  String? _attachmentName;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final r = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _currentUser = r['success'] ? r['user'] : null;
    });

    // Si estamos editando, prellenar todos los campos
    if (widget.isEditing) {
      final a = widget.appointmentToEdit!;
      setState(() {
        _selectedEspecialidad = a.especialidad;
        _selectedDoctorId = a.doctorId;
        _selectedDoctorName = a.doctorName;
        _focusedDate = a.dateTime;
        _selectedSlot = DateFormat('HH:mm').format(a.dateTime);
        _appointmentType = a.appointmentType;
        _reasonController.text = a.reason;
        _notesController.text = a.notes ?? '';
      });
      await _loadSlots(keepSelection: true);
    }
  }

  Future<void> _loadSlots({bool keepSelection = false}) async {
    if (_selectedEspecialidad == null) return;
    setState(() {
      _loadingSlots = true;
      _availableDoctors = [];
      if (!keepSelection) {
        _selectedDoctorId = null;
        _selectedDoctorName = null;
        _selectedSlot = null;
      }
    });

    final r = await AppointmentService.getAvailableSlots(
      especialidad: _selectedEspecialidad!,
      date: DateFormat('yyyy-MM-dd').format(_focusedDate),
    );

    if (!mounted) return;
    setState(() {
      _loadingSlots = false;
      if (r['success'] == true) {
        final data = r['data'] as Map<String, dynamic>;
        _availableDoctors = List<Map<String, dynamic>>.from(
          data['doctors'] ?? [],
        );

        // En edición: si el médico original ya no tiene ese slot libre, limpiar slot
        if (keepSelection && _selectedDoctorId != null) {
          final doctorEntry = _availableDoctors.firstWhere(
            (d) => d['doctor_id'] == _selectedDoctorId,
            orElse: () => {},
          );
          if (doctorEntry.isEmpty) {
            _selectedSlot = null;
          } else {
            final slots = List<String>.from(doctorEntry['slots'] ?? []);
            if (_selectedSlot != null && !slots.contains(_selectedSlot)) {
              _selectedSlot = null;
            }
          }
        }
      }
    });
  }

  Future<void> _searchPatient() async {
    if (_patientDocCtrl.text.trim().isEmpty) return;
    setState(() => _isSearching = true);
    final r = await UserService.searchPatientByDocument(
      _patientDocCtrl.text.trim(),
      _patientTipoDoc,
    );
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _foundPatient = r['success'] == true ? r['patient'] as User : null;
    });
    if (r['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(r['message'] ?? 'Paciente no encontrado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onPickFile() async {
    final picked = await pickAttachmentFile();
    if (picked.isValid && mounted) {
      setState(() {
        _pickedFile = picked;
        _attachmentName = picked.name;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedEspecialidad == null ||
        _selectedDoctorId == null ||
        _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona especialidad, médico y horario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el motivo de la consulta'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_currentUser?.isDoctor == true &&
        _foundPatient == null &&
        !widget.isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Busca y selecciona un paciente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final parts = _selectedSlot!.split(':');
    final dt = DateTime(
      _focusedDate.year,
      _focusedDate.month,
      _focusedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    Map<String, dynamic> result;

    if (widget.isEditing) {
      final updated = Appointment(
        id: widget.appointmentToEdit!.id,
        patientId: widget.appointmentToEdit!.patientId,
        doctorId: _selectedDoctorId!,
        patientDocument: widget.appointmentToEdit!.patientDocument,
        patientName: widget.appointmentToEdit!.patientName,
        doctorName: _selectedDoctorName ?? widget.appointmentToEdit!.doctorName,
        especialidad: _selectedEspecialidad!,
        appointmentType: _appointmentType,
        dateTime: dt,
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      result = await AppointmentService.updatePatient(
        widget.appointmentToEdit!.id!,
        updated,
      );
    } else {
      final appt = Appointment(
        patientId: _currentUser!.isDoctor
            ? _foundPatient!.id!
            : _currentUser!.id!,
        doctorId: _selectedDoctorId!,
        patientDocument: _currentUser!.isDoctor
            ? (_foundPatient!.document?.toString() ?? '')
            : (_currentUser!.document?.toString() ?? ''),
        patientName: _currentUser!.isDoctor
            ? _foundPatient!.fullName
            : _currentUser!.fullName,
        doctorName: _selectedDoctorName ?? '',
        especialidad: _selectedEspecialidad!,
        appointmentType: _appointmentType,
        dateTime: dt,
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      result = await AppointmentService.create(
        appt,
        patientDocument: _currentUser!.isDoctor
            ? _foundPatient!.document?.toString()
            : null,
        patientTipoDocumento: _currentUser!.isDoctor ? _patientTipoDoc : null,
      );

      if (result['success'] == true && _pickedFile != null) {
        final id = result['appointment']?.id;
        if (id != null) {
          await AppointmentService.uploadAttachment(
            id,
            fileName: _pickedFile!.name,
            filePath: _pickedFile!.path,
            fileBytes: _pickedFile!.bytes,
          );
        }
      }
    }

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? '✅ Cita actualizada exitosamente'
                : '✅ Cita agendada exitosamente',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      widget.onCreated?.call();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Editar Cita' : 'Agendar Cita',
          style: const TextStyle(
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
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEditing ? 'Editar Cita' : 'Agendar Cita',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A7A),
                    ),
                  ),
                  Text(
                    widget.isEditing
                        ? 'Modifica los datos de tu cita médica.'
                        : 'Encuentra al especialista adecuado y reserva tu espacio en segundos.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // ── Información médica
                  _section(
                    icon: Icons.medical_services_outlined,
                    title: 'Información Médica',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Especialidad — al cambiar resetea médico y slots
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Especialidad'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedEspecialidad,
                                    decoration: _deco(
                                      'Selecciona especialidad',
                                    ),
                                    hint: const Text(
                                      'Selecciona especialidad',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    items: kEspecialidades
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e['value'],
                                            child: Text(
                                              e['label']!,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        _selectedEspecialidad = v;
                                        // Siempre resetear médico y slot al cambiar especialidad
                                        _selectedDoctorId = null;
                                        _selectedDoctorName = null;
                                        _selectedSlot = null;
                                        _availableDoctors = [];
                                      });
                                      if (v != null) _loadSlots();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // ✅ Médico — se actualiza según especialidad seleccionada
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Médico'),
                                  const SizedBox(height: 8),
                                  _loadingSlots
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(14),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                        )
                                      : DropdownButtonFormField<int>(
                                          value: _selectedDoctorId,
                                          decoration: _deco(
                                            'Selecciona médico',
                                          ),
                                          hint: const Text(
                                            'Selecciona médico',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                          items: _availableDoctors
                                              .map(
                                                (d) => DropdownMenuItem<int>(
                                                  value: d['doctor_id'] as int,
                                                  child: Text(
                                                    d['doctor_name'] as String,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: _availableDoctors.isEmpty
                                              ? null
                                              : (v) => setState(() {
                                                  _selectedDoctorId = v;
                                                  _selectedDoctorName =
                                                      _availableDoctors.firstWhere(
                                                            (d) =>
                                                                d['doctor_id'] ==
                                                                v,
                                                          )['doctor_name']
                                                          as String;
                                                  _selectedSlot =
                                                      null; // Limpiar slot al cambiar médico
                                                }),
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Buscar paciente (solo médico, solo en creación)
                        if (_currentUser?.isDoctor == true &&
                            !widget.isEditing) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          _label('Buscar Paciente'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: _patientTipoDoc,
                                  decoration: _deco('Tipo Doc.'),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'cedula_ciudadania',
                                      child: Text(
                                        'CC',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'tarjeta_identidad',
                                      child: Text(
                                        'TI',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'cedula_extranjeria',
                                      child: Text(
                                        'CE',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'pasaporte',
                                      child: Text(
                                        'PA',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _patientTipoDoc = v!),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 4,
                                child: TextFormField(
                                  controller: _patientDocCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _deco('Número de documento'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: _isSearching ? null : _searchPatient,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isSearching
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.search, size: 18),
                              ),
                            ],
                          ),
                          if (_foundPatient != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Paciente: ${_foundPatient!.fullName}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Fecha y Hora
                  _section(
                    icon: Icons.calendar_month_outlined,
                    title: 'Fecha y Hora',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildCalendar()),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Horarios Disponibles',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_selectedDoctorId == null)
                                Text(
                                  'Selecciona especialidad y médico primero',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                )
                              else
                                ..._buildSlotGrid(),
                              if (_selectedDoctorId != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 13,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Duración estimada: 45 minutos.',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Detalles
                  _section(
                    icon: Icons.edit_note_outlined,
                    title: 'Detalles de la Consulta',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Tipo de cita'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _appointmentType,
                          decoration: _deco(''),
                          items:
                              [
                                    'Consulta general',
                                    'Control',
                                    'Urgencia',
                                    'Seguimiento',
                                    'Primera vez',
                                  ]
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        t,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) =>
                              setState(() => _appointmentType = v!),
                        ),
                        const SizedBox(height: 16),
                        _label('Motivo de la consulta *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _reasonController,
                          maxLines: 3,
                          decoration: _deco('Describe el motivo de tu cita...'),
                        ),
                        const SizedBox(height: 16),
                        _label('Notas adicionales (opcional)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: _deco(
                            'Alergias, medicamentos actuales, etc.',
                          ),
                        ),
                        if (!widget.isEditing) ...[
                          const SizedBox(height: 16),
                          _label('Archivo adjunto (opcional)'),
                          const SizedBox(height: 8),
                          if (_attachmentName != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF4F46E5,
                                ).withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xFF4F46E5,
                                  ).withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.attach_file,
                                    color: Color(0xFF4F46E5),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _attachmentName!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF4F46E5),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _pickedFile = null;
                                      _attachmentName = null;
                                    }),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          OutlinedButton.icon(
                            onPressed: _onPickFile,
                            icon: Icon(
                              _attachmentName != null
                                  ? Icons.refresh
                                  : Icons.upload_file,
                              size: 16,
                            ),
                            label: Text(
                              _attachmentName != null
                                  ? 'Cambiar archivo'
                                  : 'Adjuntar archivo',
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4F46E5),
                              side: const BorderSide(color: Color(0xFF4F46E5)),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Panel derecho resumen
          if (MediaQuery.of(context).size.width > 800)
            SizedBox(
              width: 280,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 28, 24, 28),
                child: _buildSummaryCard(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final minDate = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final daysInMonth = DateTime(
      _focusedDate.year,
      _focusedDate.month + 1,
      0,
    ).day;
    final startWeekday = firstDay.weekday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _capitalizeFirst(
                DateFormat('MMMM yyyy', 'es').format(_focusedDate),
              ),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1A1A7A),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: () {
                final prev = DateTime(
                  _focusedDate.year,
                  _focusedDate.month - 1,
                  1,
                );
                if (!prev.isBefore(DateTime(now.year, now.month, 1))) {
                  setState(() => _focusedDate = prev);
                  _loadSlots(keepSelection: false);
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: () {
                setState(
                  () => _focusedDate = DateTime(
                    _focusedDate.year,
                    _focusedDate.month + 1,
                    1,
                  ),
                );
                _loadSlots(keepSelection: false);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: ['LU', 'MA', 'MI', 'JU', 'VI', 'SA', 'DO']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: (startWeekday - 1) + daysInMonth,
          itemBuilder: (_, i) {
            if (i < startWeekday - 1) return const SizedBox();
            final day = i - (startWeekday - 1) + 1;
            final date = DateTime(_focusedDate.year, _focusedDate.month, day);
            // No permitir fechas pasadas
            final isPast = date.isBefore(minDate);
            final isToday =
                date.day == now.day &&
                date.month == now.month &&
                date.year == now.year;
            final isSelected =
                date.day == _focusedDate.day &&
                date.month == _focusedDate.month &&
                date.year == _focusedDate.year;

            return GestureDetector(
              onTap: isPast
                  ? null
                  : () {
                      setState(() => _focusedDate = date);
                      _loadSlots(keepSelection: false);
                    },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1A237E)
                      : isToday
                      ? const Color(0xFF06B6D4).withOpacity(0.15)
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: (isSelected || isToday)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : isPast
                          ? Colors.grey[300]
                          : isToday
                          ? const Color(0xFF06B6D4)
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildSlotGrid() {
    final doctor = _availableDoctors.firstWhere(
      (d) => d['doctor_id'] == _selectedDoctorId,
      orElse: () => {},
    );
    final slots = doctor.isEmpty
        ? <String>[]
        : List<String>.from(doctor['slots'] ?? []);

    if (slots.isEmpty) {
      return [
        Text(
          'No hay horarios disponibles para esta fecha.',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ];
    }

    final rows = <Widget>[];
    for (var i = 0; i < slots.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _slotBtn(slots[i])),
            const SizedBox(width: 8),
            i + 1 < slots.length
                ? Expanded(child: _slotBtn(slots[i + 1]))
                : const Expanded(child: SizedBox()),
          ],
        ),
      );
      if (i + 2 < slots.length) rows.add(const SizedBox(height: 8));
    }
    return rows;
  }

  Widget _slotBtn(String slot) {
    final parts = slot.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final label = '${h12.toString().padLeft(2, '0')}:$m $ampm';
    final isSel = _selectedSlot == slot;

    return GestureDetector(
      onTap: () => setState(() => _selectedSlot = slot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1A237E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSel ? const Color(0xFF1A237E) : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSel ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isEditing ? 'Resumen de Edición' : 'Resumen de Cita',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _summaryRow(
            Icons.person_outline,
            'ESPECIALISTA',
            _selectedDoctorName ?? '—',
            subtitle: _selectedEspecialidad != null
                ? especialidadLabel(_selectedEspecialidad!)
                : null,
          ),
          const Divider(color: Colors.white12, height: 24),
          _summaryRow(
            Icons.access_time_outlined,
            'FECHA Y HORA',
            _selectedSlot != null
                ? '${_capitalizeFirst(DateFormat('EEEE, d MMMM', 'es').format(_focusedDate))}\n$_selectedSlot'
                : '—',
          ),
          const Divider(color: Colors.white12, height: 24),
          _summaryRow(
            Icons.location_on_outlined,
            'UBICACIÓN',
            'Clínica Walud Norte\nTorre A, Piso 4',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isSubmitting || _selectedSlot == null)
                  ? null
                  : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.isEditing ? 'Guardar Cambios' : 'Confirmar Cita',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Al confirmar, aceptas nuestras políticas de cancelación y privacidad.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    IconData icon,
    String label,
    String value, {
    String? subtitle,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white70, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) => Container(
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
        Row(
          children: [
            Icon(icon, color: const Color(0xFF1A1A7A), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A7A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFF6B7280),
    ),
  );

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
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    _patientDocCtrl.dispose();
    super.dispose();
  }
}

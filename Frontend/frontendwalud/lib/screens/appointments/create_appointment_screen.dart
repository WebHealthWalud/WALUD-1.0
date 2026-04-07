import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final VoidCallback? onCreated;
  const CreateAppointmentScreen({super.key, this.onCreated});

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  int   _step = 0; // 0=especialidad, 1=fecha/slots, 2=detalles
  User? _currentUser;

  // Step 0
  String? _selectedEspecialidad;

  // Step 1
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  List<Map<String, dynamic>> _availableDoctors = [];
  bool _loadingSlots = false;

  // Step 1 — selección
  int?    _selectedDoctorId;
  String? _selectedDoctorName;
  String? _selectedSlot;

  // Step 2 — detalles
  final _reasonController = TextEditingController();
  final _notesController  = TextEditingController();
  String _appointmentType = 'Consulta general';
  bool   _isSubmitting    = false;

  // Médico — buscar paciente
  final _patientDocController  = TextEditingController();
  String _patientTipoDocumento = 'cedula_ciudadania';
  User?  _foundPatient;
  bool   _isSearchingPatient   = false;

  // Adjunto
  File?  _attachmentFile;
  String? _attachmentName;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final r = await AuthService.getCurrentUser();
    if (r['success'] && mounted) setState(() => _currentUser = r['user']);
  }

  // ── Cargar slots disponibles
  Future<void> _loadSlots() async {
    if (_selectedEspecialidad == null) return;
    setState(() {
      _loadingSlots = true;
      _availableDoctors = [];
      _selectedDoctorId = null;
      _selectedSlot     = null;
    });

    final r = await AppointmentService.getAvailableSlots(
      especialidad: _selectedEspecialidad!,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );

    if (mounted) {
      setState(() {
        _loadingSlots = false;
        if (r['success'] == true) {
          final data = r['data'] as Map<String, dynamic>;
          _availableDoctors = List<Map<String, dynamic>>.from(data['doctors'] ?? []);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(r['message'] ?? 'Sin disponibilidad'), backgroundColor: Colors.orange),
          );
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (d != null && mounted) {
      setState(() => _selectedDate = d);
      _loadSlots();
    }
  }

  // ── Buscar paciente por documento (solo médico)
  Future<void> _searchPatient() async {
    if (_patientDocController.text.trim().isEmpty) return;
    setState(() => _isSearchingPatient = true);

    final r = await UserService.searchPatientByDocument(
      _patientDocController.text.trim(),
      _patientTipoDocumento,
    );

    if (mounted) {
      setState(() {
        _isSearchingPatient = false;
        _foundPatient = r['success'] == true ? r['patient'] as User : null;
      });
      if (r['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r['message'] ?? 'Paciente no encontrado'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Seleccionar archivo adjunto
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
      setState(() {
        _attachmentFile = File(result.files.first.path!);
        _attachmentName = result.files.first.name;
      });
    }
  }

  // ── Enviar
  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el motivo de la consulta'), backgroundColor: Colors.red),
      );
      return;
    }

    // Médico debe tener paciente seleccionado
    if (_currentUser?.isDoctor == true && _foundPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe buscar y seleccionar un paciente'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final timeParts = _selectedSlot!.split(':');
    final dt = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      int.parse(timeParts[0]), int.parse(timeParts[1]),
    );

    // ✅ Formato de hora HH:MM — compatible con backend
    final appointment = Appointment(
      patientId:       _currentUser!.isDoctor ? _foundPatient!.id! : _currentUser!.id!,
      doctorId:        _selectedDoctorId!,
      patientDocument: _currentUser!.isDoctor
          ? (_foundPatient!.document?.toString() ?? '')
          : (_currentUser!.document?.toString() ?? ''),
      patientName:     _currentUser!.isDoctor ? _foundPatient!.fullName : _currentUser!.fullName,
      doctorName:      _selectedDoctorName ?? '',
      especialidad:    _selectedEspecialidad!,
      appointmentType: _appointmentType,
      dateTime:        dt,
      reason:          _reasonController.text.trim(),
      notes:           _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    final r = await AppointmentService.create(
      appointment,
      patientDocument: _currentUser!.isDoctor ? _foundPatient!.document?.toString() : null,
      patientTipoDocumento: _currentUser!.isDoctor ? _patientTipoDocumento : null,
    );

    // Subir adjunto si existe
    if (r['success'] == true && _attachmentFile != null) {
      final apptId = r['appointment']?.id;
      if (apptId != null) {
        await AppointmentService.uploadAttachment(apptId, _attachmentFile!);
      }
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (r['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Cita agendada exitosamente'), backgroundColor: Color(0xFF10B981)),
        );
        widget.onCreated?.call();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r['message'] ?? 'Error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Agendar Cita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4F46E5),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStepContent(),
            ),
          ),
          _buildNavButtons(),
        ],
      ),
    );
  }

  // ── Stepper
  Widget _buildStepper() {
    final steps = ['Especialidad', 'Disponibilidad', 'Confirmar'];
    return Container(
      color: const Color(0xFF4F46E5),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(height: 2, color: _step > i ~/ 2 ? Colors.white : Colors.white30),
            );
          }
          final idx    = i ~/ 2;
          final done   = _step > idx;
          final active = _step == idx;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? Colors.white : (active ? Colors.white : Colors.white24),
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, size: 18, color: Color(0xFF4F46E5))
                    : Text('${idx + 1}', style: TextStyle(
                        color: active ? const Color(0xFF4F46E5) : Colors.white70,
                        fontWeight: FontWeight.bold, fontSize: 13,
                      )),
              ),
            ),
            const SizedBox(height: 4),
            Text(steps[idx], style: TextStyle(
              color: (active || done) ? Colors.white : Colors.white54,
              fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal,
            )),
          ]);
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0: return _buildStep0();
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      default: return const SizedBox();
    }
  }

  // ── STEP 0: Especialidad
  Widget _buildStep0() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('¿Qué especialidad necesitas?',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
      const SizedBox(height: 8),
      Text('Selecciona la especialidad médica para la consulta',
        style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      const SizedBox(height: 24),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
        ),
        itemCount: kEspecialidades.length,
        itemBuilder: (_, i) {
          final e   = kEspecialidades[i];
          final val = e['value']!;
          final sel = _selectedEspecialidad == val;
          return GestureDetector(
            onTap: () => setState(() => _selectedEspecialidad = val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF4F46E5) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel ? const Color(0xFF4F46E5) : Colors.grey.shade200, width: 2),
                boxShadow: sel ? [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_especialidadIcon(val), color: sel ? Colors.white : const Color(0xFF4F46E5), size: 28),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(e['label']!, textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sel ? Colors.white : const Color(0xFF1A1A7A),
                      fontSize: 12, fontWeight: FontWeight.w600,
                    )),
                ),
              ]),
            ),
          );
        },
      ),
    ]);
  }

  // ── STEP 1: Fecha y disponibilidad
  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Selecciona fecha y horario',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
      const SizedBox(height: 20),

      // Fecha
      GestureDetector(
        onTap: _selectDate,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200)),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.calendar_today, color: Color(0xFF4F46E5), size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Fecha de la cita', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(DateFormat('EEEE, d MMMM yyyy', 'es').format(_selectedDate),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A), fontSize: 15)),
            ]),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ]),
        ),
      ),
      const SizedBox(height: 16),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _loadSlots,
          icon: const Icon(Icons.search),
          label: const Text('Ver disponibilidad'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0EA5E9), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      const SizedBox(height: 24),

      if (_loadingSlots)
        const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
      else if (_availableDoctors.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(child: Text('Presiona "Ver disponibilidad" para ver los horarios',
              style: TextStyle(color: Colors.orange))),
          ]),
        )
      else ...[
        const Text('Médicos disponibles',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A7A))),
        const SizedBox(height: 12),
        ..._availableDoctors.map((d) => _buildDoctorSlots(d)),
      ],
    ]);
  }

  Widget _buildDoctorSlots(Map<String, dynamic> doctor) {
    final slots     = List<String>.from(doctor['slots']);
    final doctorId  = doctor['doctor_id'] as int;
    final doctorName= doctor['doctor_name'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
            child: const Icon(Icons.person, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
            Text(especialidadLabel(doctor['especialidad'] ?? ''),
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 12),
        const Text('Horarios disponibles:', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: slots.map((slot) {
          final sel = _selectedDoctorId == doctorId && _selectedSlot == slot;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedDoctorId   = doctorId;
              _selectedDoctorName = doctorName;
              _selectedSlot       = slot;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF4F46E5) : const Color(0xFF4F46E5).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(slot, style: TextStyle(
                color: sel ? Colors.white : const Color(0xFF4F46E5),
                fontWeight: FontWeight.w600, fontSize: 13,
              )),
            ),
          );
        }).toList()),
      ]),
    );
  }

  // ── STEP 2: Detalles + búsqueda paciente (médico) + adjunto
  Widget _buildStep2() {
    final isDoc = _currentUser?.isDoctor == true;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Resumen
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Resumen de la cita', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text(especialidadLabel(_selectedEspecialidad ?? ''),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Dr/a. $_selectedDoctorName', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(DateFormat('d MMM yyyy', 'es').format(_selectedDate),
              style: const TextStyle(color: Colors.white)),
            const SizedBox(width: 16),
            const Icon(Icons.access_time, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(_selectedSlot ?? '', style: const TextStyle(color: Colors.white)),
          ]),
        ]),
      ),
      const SizedBox(height: 20),

      // ── Búsqueda paciente (solo médico)
      if (isDoc) ...[
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Buscar Paciente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4F46E5))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _patientTipoDocumento,
            decoration: InputDecoration(
              labelText: 'Tipo de Documento',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: const [
              DropdownMenuItem(value: 'cedula_ciudadania',           child: Text('CC - Cédula Ciudadanía')),
              DropdownMenuItem(value: 'tarjeta_identidad',           child: Text('TI - Tarjeta Identidad')),
              DropdownMenuItem(value: 'cedula_extranjeria',          child: Text('CE - Cédula Extranjería')),
              DropdownMenuItem(value: 'pasaporte',                   child: Text('PA - Pasaporte')),
              DropdownMenuItem(value: 'registro_civil',              child: Text('RC - Registro Civil')),
              DropdownMenuItem(value: 'permiso_especial_permanencia',child: Text('PEP - Permiso Especial')),
              DropdownMenuItem(value: 'permiso_proteccion_temporal', child: Text('PPT - Protección Temporal')),
            ],
            onChanged: (v) => setState(() => _patientTipoDocumento = v!),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _patientDocController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Número de documento',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isSearchingPatient ? null : _searchPatient,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSearchingPatient
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.search),
            ),
          ]),
          if (_foundPatient != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text('Paciente: ${_foundPatient!.fullName}',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ]),
            ),
          ],
        ])),
        const SizedBox(height: 4),
      ],

      // Tipo de cita
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Tipo de cita'),
        DropdownButtonFormField<String>(
          value: _appointmentType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: ['Consulta general', 'Control', 'Urgencia', 'Seguimiento', 'Primera vez']
              .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _appointmentType = v!),
        ),
      ])),

      // Motivo
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Motivo de la consulta *'),
        TextFormField(
          controller: _reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe el motivo de la cita...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ])),

      // Notas
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Notas adicionales (opcional)'),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Alergias, medicamentos actuales, etc.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ])),

      // Adjunto
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Archivo adjunto (opcional)'),
        if (_attachmentName != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.attach_file, color: Color(0xFF4F46E5), size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_attachmentName!, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w500, fontSize: 13))),
              GestureDetector(
                onTap: () => setState(() { _attachmentFile = null; _attachmentName = null; }),
                child: const Icon(Icons.close, size: 16, color: Colors.grey),
              ),
            ]),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickFile,
            icon: Icon(_attachmentName != null ? Icons.refresh : Icons.upload_file),
            label: Text(_attachmentName != null ? 'Cambiar archivo' : 'Adjuntar archivo'),
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
      ])),

      const SizedBox(height: 8),

      // Confirmar
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Confirmar Cita', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 20),
    ]);
  }

  // ── Nav buttons
  Widget _buildNavButtons() {
    if (_step == 2) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _step--),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFF4F46E5)),
              ),
              child: const Text('Atrás', style: TextStyle(color: Color(0xFF4F46E5))),
            ),
          ),
        if (_step > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _canGoNext() ? () {
              if (_step == 1) _loadSlots();
              setState(() => _step++);
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_step == 0 ? 'Siguiente' : 'Ver resumen',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  bool _canGoNext() {
    switch (_step) {
      case 0: return _selectedEspecialidad != null;
      case 1: return _selectedDoctorId != null && _selectedSlot != null;
      default: return true;
    }
  }

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

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151), fontSize: 13)),
  );

  IconData _especialidadIcon(String val) {
    const map = {
      'medicina_general':    Icons.medical_services,
      'psicologia':          Icons.psychology,
      'psiquiatria':         Icons.self_improvement,
      'dermatologia':        Icons.face,
      'nutricion_dietetica': Icons.restaurant,
      'pediatria':           Icons.child_care,
      'ginecologia':         Icons.pregnant_woman,
      'medicina_interna':    Icons.monitor_heart,
      'endocrinologia':      Icons.science,
      'cardiologia':         Icons.favorite,
    };
    return map[val] ?? Icons.local_hospital;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    _patientDocController.dispose();
    super.dispose();
  }
}
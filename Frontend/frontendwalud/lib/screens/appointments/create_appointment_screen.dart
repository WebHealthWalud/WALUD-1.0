// lib/screens/appointments/create_appointment_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final VoidCallback? onCreated;

  const CreateAppointmentScreen({super.key, this.onCreated});

  @override
  State<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _appointmentTypeController = TextEditingController();

  // Para búsqueda de paciente (cuando es médico)
  final _patientDocumentController = TextEditingController();
  final _patientNameController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  int? _selectedDoctorId;
  List<User> _doctors = [];
  bool _isLoadingDoctors = true;
  bool _isSubmitting = false;

  // Buscar paciente por documento
  bool _isSearchingPatient = false;
  User? _foundPatient;

  // Usar valores completos que coincidan con el backend ENUM
  String _patientDocumentType = 'cedula_ciudadania';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadDoctors();
  }

  /// Carga el usuario actual para saber si es médico o paciente
  Future<void> _loadCurrentUser() async {
    final currentUser = await AuthService.getCurrentUser();
    if (mounted && currentUser['success']) {
      final user = currentUser['user'] as User;

      if (user.isDoctor) {
        setState(() {
          _patientDocumentController.text = '';
          _patientNameController.text = '';
          _patientDocumentType = 'cedula_ciudadania';
        });
      }
    }
  }

  /// Carga médicos desde el backend
  Future<void> _loadDoctors() async {
    if (!mounted) return;
    setState(() => _isLoadingDoctors = true);

    try {
      final result = await UserService.getDoctors();

      if (mounted) {
        if (result['success']) {
          setState(() {
            _doctors = result['doctors'] as List<User>;
            if (_doctors.isNotEmpty) {
              _selectedDoctorId = _doctors.first.id;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDoctors = false);
      }
    }
  }

  /// Buscar paciente por documento (solo médicos)
  Future<void> _searchPatient() async {
    if (_patientDocumentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese el documento del paciente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSearchingPatient = true);

    try {
      final result = await UserService.searchPatientByDocument(
        _patientDocumentController.text.trim(),
        _patientDocumentType,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _foundPatient = result['patient'] as User;
            _patientNameController.text = _foundPatient!.fullName;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paciente encontrado'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() => _foundPatient = null);
          _patientNameController.text = '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _foundPatient = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearchingPatient = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null && mounted) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = await AuthService.getCurrentUser();
    final user = currentUser['user'] as User;

    if (user.isDoctor && _foundPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe buscar y seleccionar un paciente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un médico'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Crear DateTime en zona horaria local
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final selectedDoctor = _doctors.firstWhere(
        (d) => d.id == _selectedDoctorId,
        orElse: () => User(name: 'Médico', email: 'medico@walud.com'),
      );

      // Determinar patientId según tipo de usuario
      final int patientId;
      if (user.isDoctor) {
        patientId = _foundPatient!.id!;
      } else {
        patientId = user.id!;
      }

      final appointment = Appointment(
        patientId: patientId,
        doctorId: _selectedDoctorId!,
        patientDocument: user.isDoctor
            ? (_foundPatient!.document?.toString() ?? '')
            : (user.document?.toString() ?? ''),

        patientName: user.isDoctor ? _foundPatient!.fullName : user.fullName,

        doctorName: selectedDoctor.name,
        dateTime: dateTime,
        reason: _reasonController.text,
        appointmentType: _appointmentTypeController.text,
        status: AppointmentStatus.pendiente,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final result = await AppointmentService.create(appointment);

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita agendada'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onCreated?.call();
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Cita'),
        backgroundColor: const Color(0xFF4F46E5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CAMPO PARA BUSCAR PACIENTE (Solo médicos)
              FutureBuilder(
                future: AuthService.getCurrentUser(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final currentUser = snapshot.data as Map<String, dynamic>;
                  if (!currentUser['success'] || currentUser['user'] == null) {
                    return const SizedBox.shrink();
                  }
                  final user = currentUser['user'] as User;

                  if (!user.isDoctor) return const SizedBox.shrink();

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buscar Paciente',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: _patientDocumentType,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Tipo de Documento',
                                    prefixIcon: Icon(Icons.badge),
                                  ),
                                  // Valores que coinciden con backend ENUM
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'cedula_ciudadania',
                                      child: Text('CC - Cédula Ciudadanía'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'tarjeta_identidad',
                                      child: Text('TI - Tarjeta Identidad'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'cedula_extranjeria',
                                      child: Text('CE - Cédula Extranjería'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'pasaporte',
                                      child: Text('PA - Pasaporte'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'registro_civil',
                                      child: Text('RC - Registro Civil'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'carne_diplomatico',
                                      child: Text('CD - Carné Diplomático'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'permiso_especial_permanencia',
                                      child: Text('PEP - Permiso Especial'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'permiso_proteccion_temporal',
                                      child: Text('PPT - Protección Temporal'),
                                    ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _patientDocumentType = value!,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _patientDocumentController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Número de Documento',
                                    prefixIcon: Icon(Icons.person_search),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _isSearchingPatient
                                  ? null
                                  : _searchPatient,
                              icon: _isSearchingPatient
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.search),
                              label: const Text('Buscar Paciente'),
                            ),
                          ),
                          if (_foundPatient != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Paciente: ${_foundPatient!.fullName}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Médico
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seleccionar Médico',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _isLoadingDoctors
                          ? const Center(child: CircularProgressIndicator())
                          : _doctors.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No hay médicos registrados',
                                style: TextStyle(color: Colors.red),
                              ),
                            )
                          : DropdownButtonFormField<int>(
                              value: _selectedDoctorId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              items: _doctors
                                  .where((d) => d.id != null)
                                  .map(
                                    (doctor) => DropdownMenuItem<int>(
                                      value: doctor.id!,
                                      child: Text(doctor.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedDoctorId = value),
                              validator: (value) =>
                                  value == null ? 'Seleccione un médico' : null,
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fecha y Hora
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fecha y Hora',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                  labelText: 'Fecha',
                                ),
                                child: Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(_selectedDate),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _selectTime,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.access_time),
                                  labelText: 'Hora',
                                ),
                                child: Text(_selectedTime.format(context)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tipo de Cita
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tipo de Cita',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _appointmentTypeController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                          hintText: 'Ej: Consulta general, control...',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el tipo de cita';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Motivo
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Motivo de la Consulta',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note_alt),
                          hintText: 'Ej: Dolor de cabeza, chequeo...',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el motivo de la consulta';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notas (opcional)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notas Adicionales (Opcional)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit),
                          hintText: 'Información adicional...',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Agendar
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Agendar Cita',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    _appointmentTypeController.dispose();
    _patientDocumentController.dispose();
    _patientNameController.dispose();
    super.dispose();
  }
}

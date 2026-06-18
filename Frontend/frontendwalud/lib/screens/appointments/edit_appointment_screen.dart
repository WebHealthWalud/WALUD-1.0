import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback? onUpdated;

  const EditAppointmentScreen({
    super.key,
    required this.appointment,
    this.onUpdated,
  });

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _reasonController;
  late TextEditingController _notesController;
  late DateTime  _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ✅ reason nunca es null en el modelo actualizado
    _reasonController = TextEditingController(text: widget.appointment.reason);
    _notesController  = TextEditingController(text: widget.appointment.notes ?? '');
    _selectedDate     = widget.appointment.dateTime;
    _selectedTime     = TimeOfDay.fromDateTime(widget.appointment.dateTime);
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context:     context,
      initialDate: _selectedDate,
      firstDate:   DateTime.now(),
      lastDate:    DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(context: context, initialTime: _selectedTime);
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final dateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    final updatedAppointment = Appointment(
      id:              widget.appointment.id,
      patientId:       widget.appointment.patientId,
      doctorId:        widget.appointment.doctorId,
      patientDocument: widget.appointment.patientDocument,
      patientName:     widget.appointment.patientName,
      doctorName:      widget.appointment.doctorName,
      especialidad:    widget.appointment.especialidad,
      appointmentType: widget.appointment.appointmentType,
      dateTime:        dateTime,
      reason:          _reasonController.text,
      status:          widget.appointment.status,
      notes:           _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    // ✅ El servicio tiene métodos static, no se instancia con ()
    final result = await AppointmentService.updatePatient(
      widget.appointment.id!,
      updatedAppointment,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita actualizada'), backgroundColor: Colors.green),
        );
        widget.onUpdated?.call();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ statusColor y statusLabel vienen directo del modelo (enum), no de métodos locales
    final statusColor = Color(int.parse('0x${widget.appointment.statusColor}'));
    final statusLabel = widget.appointment.statusLabel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Cita', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4F46E5),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Estado (solo visualización)
              Card(
                color: statusColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Médico (solo visualización)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Médico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.person, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 8),
                        Text(widget.appointment.doctorName, style: const TextStyle(fontSize: 16)),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Fecha y Hora
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fecha y Hora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                                labelText: 'Fecha',
                              ),
                              child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
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
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Motivo
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Motivo de la Consulta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note_alt),
                        ),
                        maxLines: 3,
                        validator: (v) => (v == null || v.isEmpty) ? 'Ingrese el motivo' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Notas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notas adicionales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit),
                          hintText: 'Opcional',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Botón guardar
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Actualizar Cita', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    super.dispose();
  }
}
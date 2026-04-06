import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import '../../widgets/appointment_card.dart';
import 'create_appointment_screen.dart';
import 'edit_appointment_screen.dart';

class AppointmentsListScreen extends StatefulWidget {
  final int? patientId;
  final int? doctorId;

  const AppointmentsListScreen({super.key, this.patientId, this.doctorId});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  String _filter = 'todos'; // todos, pendiente, cancelada, realizada

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    final result = await AppointmentService.getAll();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _appointments = List<Appointment>.from(result['appointments']);
        }
      });

      if (!result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Appointment> get _filteredAppointments {
    if (_filter == 'todos') return _appointments;
    return _appointments.where((a) => a.status.name == _filter).toList();
  }

  Future<void> _deleteAppointment(int id) async {
    final result = await AppointmentService.delete(id);

    if (mounted) {
      if (result['success']) {
        setState(() {
          _appointments.removeWhere((a) => a.id == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita eliminada'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(int id, AppointmentStatus status) async {
    final result = await AppointmentService.updateStatus(id, status);

    if (mounted) {
      if (result['success']) {
        setState(() {
          final index = _appointments.indexWhere((a) => a.id == id);
          if (index != -1) {
            // ✅ CORRECCIÓN AQUÍ
            _appointments[index] = result['appointment'];
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estado actualizado'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas'),
        backgroundColor: const Color(0xFF4F46E5),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', 'todos'),
                  _buildFilterChip('Pendientes', 'pendiente'),
                  _buildFilterChip('Realizadas', 'realizada'),
                  _buildFilterChip('Canceladas', 'cancelada'),
                ],
              ),
            ),
          ),

          // Lista de citas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAppointments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay citas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAppointments,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _filteredAppointments.length,
                      itemBuilder: (context, index) {
                        final appointment = _filteredAppointments[index];
                        return AppointmentCard(
                          appointment: appointment,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditAppointmentScreen(
                                  appointment: appointment,
                                  onUpdated: _loadAppointments,
                                ),
                              ),
                            );
                          },
                          onDelete: () => _deleteAppointment(appointment.id!),
                          onStatusChange: (status) =>
                              _updateStatus(appointment.id!, status),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CreateAppointmentScreen(onCreated: _loadAppointments),
            ),
          );
        },
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cita'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filter = value);
        },
        selectedColor: const Color(0xFF4F46E5).withOpacity(0.2),
        checkmarkColor: const Color(0xFF4F46E5),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

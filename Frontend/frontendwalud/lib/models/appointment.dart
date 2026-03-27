import 'package:intl/intl.dart';
enum AppointmentStatus { pendiente, cancelada, realizada }

class Appointment {
  final int? id;
  final int patientId;
  final int doctorId;
  final String patientDocument;
  final String patientName;
  final String doctorName;
  final String appointmentType;
  final DateTime dateTime;
  final String reason;
  final AppointmentStatus status;
  final String? notes;
  final DateTime? createdAt;

  Appointment({
    this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientDocument,
    required this.patientName,
    required this.doctorName,
    required this.appointmentType,
    required this.dateTime,
    required this.reason,
    this.status = AppointmentStatus.pendiente,
    this.notes,
    this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
  return Appointment(
    id: json['id'],
    patientId: json['patient_id'],
    doctorId: json['doctor_id'],
    patientName: json['patient_name'] ?? '',
    doctorName: json['doctor_name'] ?? '',
    
    
    dateTime: DateTime.parse(
  "${json['date'].toString().split('T')[0]} ${json['time']}"
    ),

    reason: json['reason'] ?? '',
    appointmentType: json['appointment_type'] ?? '',
    patientDocument: json['patient_document'] ?? '',
    status: AppointmentStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => AppointmentStatus.pendiente,
    ),
    notes: json['notes'],
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'patient_document': patientDocument,
      'patient_name': patientName,
      'doctor_name': doctorName,
      'appointment_type': appointmentType,
      'date': DateFormat('yyyy-MM-dd').format(dateTime),
      'time': DateFormat('HH:mm:ss').format(dateTime),
      'status': status.name,
      'notes': notes,
      'reason': reason, 
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String getStatusColor() {
    switch (status) {
      case AppointmentStatus.pendiente:
        return 'FFD93D';
      case AppointmentStatus.cancelada:
        return 'EF4444';
      case AppointmentStatus.realizada:
        return '10B981';
    }
  }

  String getStatusText() {
    switch (status) {
      case AppointmentStatus.pendiente:
        return 'Pendiente';
      case AppointmentStatus.cancelada:
        return 'Cancelada';
      case AppointmentStatus.realizada:
        return 'Realizada';
    }
  }
}

import 'package:intl/intl.dart';

enum AppointmentStatus { pendiente, cancelada, realizada }

class Appointment {
  final int? id;
  final int patientId;
  final int doctorId;
  final String patientDocument;
  final String patientName;
  final String doctorName;
  final String? doctorEspecialidad;
  final String especialidad;
  final String appointmentType;
  final DateTime dateTime;
  final String reason;
  final AppointmentStatus status;
  final String? notes;
  final String? attachmentPath;
  final String? attachmentName;
  final DateTime? createdAt;
  final String? jitsiRoom; // ← nuevo

  Appointment({
    this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientDocument,
    required this.patientName,
    required this.doctorName,
    this.doctorEspecialidad,
    required this.especialidad,
    required this.appointmentType,
    required this.dateTime,
    required this.reason,
    this.status = AppointmentStatus.pendiente,
    this.notes,
    this.attachmentPath,
    this.attachmentName,
    this.createdAt,
    this.jitsiRoom, // ← nuevo
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime() {
      try {
        if (json['date'] != null && json['time'] != null) {
          final dateStr = json['date'].toString().split('T')[0];
          final timeStr = json['time'].toString();
          return DateTime.parse('$dateStr $timeStr');
        }
        return DateTime.now();
      } catch (_) {
        return DateTime.now();
      }
    }

    final doctor = json['doctor'] as Map<String, dynamic>?;

    return Appointment(
      id: json['id'],
      patientId: json['patient_id'] ?? 0,
      doctorId: json['doctor_id'] ?? 0,
      patientName: json['patient_name'] ?? '',
      doctorName: doctor != null
          ? '${doctor['name'] ?? ''} ${doctor['last_name'] ?? ''}'.trim()
          : (json['doctor_name'] ?? ''),
      doctorEspecialidad: doctor?['especialidad'],
      especialidad: json['especialidad'] ?? '',
      dateTime: parseDateTime(),
      reason: json['reason'] ?? '',
      appointmentType: json['appointment_type'] ?? '',
      patientDocument: json['patient_document'] ?? '',
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AppointmentStatus.pendiente,
      ),
      notes: json['notes'],
      attachmentPath: json['attachment_path'],
      attachmentName: json['attachment_name'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      jitsiRoom: json['jitsi_room'], // ← nuevo
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'doctor_id': doctorId,
    'patient_document': patientDocument,
    'patient_name': patientName,
    'especialidad': especialidad,
    'appointment_type': appointmentType,
    'date': DateFormat('yyyy-MM-dd').format(dateTime),
    'time': DateFormat('HH:mm:ss').format(dateTime),
    'status': status.name,
    'notes': notes,
    'reason': reason,
  };

  // ─────────────────────────────────────────────────────────
  //  Helpers de UI
  // ─────────────────────────────────────────────────────────

  String get statusColor {
    switch (status) {
      case AppointmentStatus.pendiente:
        return 'FFD97D0C';
      case AppointmentStatus.cancelada:
        return 'FFEF4444';
      case AppointmentStatus.realizada:
        return 'FF10B981';
    }
  }

  String get statusLabel {
    switch (status) {
      case AppointmentStatus.pendiente:
        return 'Pendiente';
      case AppointmentStatus.cancelada:
        return 'Cancelada';
      case AppointmentStatus.realizada:
        return 'Realizada';
    }
  }

  /// Indica si la cita es hoy (para mostrar indicador visual)
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }
}

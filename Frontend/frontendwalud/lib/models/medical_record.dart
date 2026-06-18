import 'package:intl/intl.dart';

class MedicalRecord {
  final int?    id;
  final int     patientId;
  final int     doctorId;
  final int?    appointmentId;
  final String  expediente;
  final String  motivoConsulta;
  final String? examenFisico;
  final String? diagnosticoCie10;
  final String? diagnosticoNombre;
  final String? diagnosticoDescripcion;
  final String? tratamiento;
  final String? observaciones;
  final String  especialidad;

  // Signos vitales opcionales
  final double? presionSistolica;
  final double? presionDiastolica;
  final double? frecuenciaCardiaca;
  final double? temperatura;
  final double? peso;
  final double? talla;
  final double? saturacionOxigeno;

  // Relaciones anidadas
  final Map<String, dynamic>? patient;
  final Map<String, dynamic>? doctor;
  final Map<String, dynamic>? appointment;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicalRecord({
    this.id,
    required this.patientId,
    required this.doctorId,
    this.appointmentId,
    required this.expediente,
    required this.motivoConsulta,
    this.examenFisico,
    this.diagnosticoCie10,
    this.diagnosticoNombre,
    this.diagnosticoDescripcion,
    this.tratamiento,
    this.observaciones,
    required this.especialidad,
    this.presionSistolica,
    this.presionDiastolica,
    this.frecuenciaCardiaca,
    this.temperatura,
    this.peso,
    this.talla,
    this.saturacionOxigeno,
    this.patient,
    this.doctor,
    this.appointment,
    this.createdAt,
    this.updatedAt,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id:                      json['id'],
      patientId:               json['patient_id'] ?? 0,
      doctorId:                json['doctor_id']  ?? 0,
      appointmentId:           json['appointment_id'],
      expediente:              json['expediente'] ?? '',
      motivoConsulta:          json['motivo_consulta'] ?? '',
      examenFisico:            json['examen_fisico'],
      diagnosticoCie10:        json['diagnostico_cie10'],
      diagnosticoNombre:       json['diagnostico_nombre'],
      diagnosticoDescripcion:  json['diagnostico_descripcion'],
      tratamiento:             json['tratamiento'],
      observaciones:           json['observaciones'],
      especialidad:            json['especialidad'] ?? '',
      presionSistolica:        _d(json['presion_sistolica']),
      presionDiastolica:       _d(json['presion_diastolica']),
      frecuenciaCardiaca:      _d(json['frecuencia_cardiaca']),
      temperatura:             _d(json['temperatura']),
      peso:                    _d(json['peso']),
      talla:                   _d(json['talla']),
      saturacionOxigeno:       _d(json['saturacion_oxigeno']),
      patient:    json['patient']    as Map<String, dynamic>?,
      doctor:     json['doctor']     as Map<String, dynamic>?,
      appointment:json['appointment'] as Map<String, dynamic>?,
      createdAt:  json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt:  json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  static double? _d(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  Map<String, dynamic> toJson() => {
    'patient_id':              patientId,
    'doctor_id':               doctorId,
    if (appointmentId != null) 'appointment_id': appointmentId,
    'motivo_consulta':         motivoConsulta,
    if (examenFisico != null)          'examen_fisico': examenFisico,
    if (diagnosticoCie10 != null)      'diagnostico_cie10': diagnosticoCie10,
    if (diagnosticoNombre != null)     'diagnostico_nombre': diagnosticoNombre,
    if (diagnosticoDescripcion != null)'diagnostico_descripcion': diagnosticoDescripcion,
    if (tratamiento != null)           'tratamiento': tratamiento,
    if (observaciones != null)         'observaciones': observaciones,
    'especialidad':            especialidad,
    if (presionSistolica != null)   'presion_sistolica': presionSistolica,
    if (presionDiastolica != null)  'presion_diastolica': presionDiastolica,
    if (frecuenciaCardiaca != null) 'frecuencia_cardiaca': frecuenciaCardiaca,
    if (temperatura != null)        'temperatura': temperatura,
    if (peso != null)               'peso': peso,
    if (talla != null)              'talla': talla,
    if (saturacionOxigeno != null)  'saturacion_oxigeno': saturacionOxigeno,
  };

  // ── Helpers de presentación
  String get patientFullName {
    if (patient == null) return '—';
    return '${patient!['name'] ?? ''} ${patient!['last_name'] ?? ''}'.trim();
  }

  String get doctorFullName {
    if (doctor == null) return '—';
    return '${doctor!['name'] ?? ''} ${doctor!['last_name'] ?? ''}'.trim();
  }

  String get doctorEspecialidad =>
      doctor?['especialidad']?.toString() ?? especialidad;

  String get formattedDate => createdAt != null
      ? DateFormat('d MMM yyyy', 'es').format(createdAt!)
      : '—';

  String get formattedDateLong => createdAt != null
      ? DateFormat("d 'de' MMMM, yyyy", 'es').format(createdAt!)
      : '—';

  String get formattedTime => createdAt != null
      ? DateFormat('hh:mm a').format(createdAt!)
      : '—';

  String get patientAge {
    final birth = patient?['birth_date']?.toString();
    if (birth == null) return '—';
    try {
      final bd  = DateTime.parse(birth);
      final age = DateTime.now().difference(bd).inDays ~/ 365;
      return '$age años';
    } catch (_) { return '—'; }
  }

  bool get hasSignosVitales =>
      presionSistolica != null ||
      presionDiastolica != null ||
      frecuenciaCardiaca != null ||
      temperatura != null;
}
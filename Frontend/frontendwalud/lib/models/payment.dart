enum PaymentStatus { pendiente, completado, cancelado, reembolsado }
enum PaymentTipo   { consulta, estudio, seguro, vacuna, psicoterapia, otro }
enum PaymentMethod { tarjeta_credito, tarjeta_debito, transferencia, efectivo, otro }

extension PaymentStatusExt on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pendiente:   return 'Pendiente';
      case PaymentStatus.completado:  return 'Completado';
      case PaymentStatus.cancelado:   return 'Cancelado';
      case PaymentStatus.reembolsado: return 'Reembolsado';
    }
  }

  String get color {
    switch (this) {
      case PaymentStatus.pendiente:   return 'FFEF4444'; // rojo
      case PaymentStatus.completado:  return 'FF10B981'; // verde
      case PaymentStatus.cancelado:   return 'FF6B7280'; // gris
      case PaymentStatus.reembolsado: return 'FFF59E0B'; // amarillo
    }
  }
}

extension PaymentTipoExt on PaymentTipo {
  String get label {
    switch (this) {
      case PaymentTipo.consulta:      return 'Consulta';
      case PaymentTipo.estudio:       return 'Estudio';
      case PaymentTipo.seguro:        return 'Seguro Médico';
      case PaymentTipo.vacuna:        return 'Vacuna';
      case PaymentTipo.psicoterapia:  return 'Psicoterapia';
      case PaymentTipo.otro:          return 'Otro';
    }
  }
}

class Payment {
  final int?          id;
  final int           patientId;
  final int?          appointmentId;
  final String        concepto;
  final PaymentTipo   tipo;
  final double        monto;
  final PaymentStatus estadoPago;
  final DateTime?     fechaVencimiento;
  final DateTime?     fechaPago;
  final PaymentMethod? metodoPago;
  final String?       referenciaPago;
  final String?       notas;
  final DateTime?     createdAt;

  Payment({
    this.id,
    required this.patientId,
    this.appointmentId,
    required this.concepto,
    required this.tipo,
    required this.monto,
    this.estadoPago = PaymentStatus.pendiente,
    this.fechaVencimiento,
    this.fechaPago,
    this.metodoPago,
    this.referenciaPago,
    this.notas,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id:            json['id'],
      patientId:     json['patient_id'] ?? 0,
      appointmentId: json['appointment_id'],
      concepto:      json['concepto'] ?? '',
      tipo: PaymentTipo.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => PaymentTipo.consulta,
      ),
      monto: double.tryParse(json['monto']?.toString() ?? '0') ?? 0.0,
      estadoPago: PaymentStatus.values.firstWhere(
        (e) => e.name == json['estado_pago'],
        orElse: () => PaymentStatus.pendiente,
      ),
      fechaVencimiento: json['fecha_vencimiento'] != null
          ? DateTime.tryParse(json['fecha_vencimiento'])
          : null,
      fechaPago: json['fecha_pago'] != null
          ? DateTime.tryParse(json['fecha_pago'])
          : null,
      metodoPago: json['metodo_pago'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == json['metodo_pago'],
              orElse: () => PaymentMethod.otro,
            )
          : null,
      referenciaPago: json['referencia_pago'],
      notas:          json['notas'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'patient_id':       patientId,
    'appointment_id':   appointmentId,
    'concepto':         concepto,
    'tipo':             tipo.name,
    'monto':            monto,
    'estado_pago':      estadoPago.name,
    'fecha_vencimiento':fechaVencimiento?.toIso8601String().split('T')[0],
    'fecha_pago':       fechaPago?.toIso8601String().split('T')[0],
    'metodo_pago':      metodoPago?.name,
    'referencia_pago':  referenciaPago,
    'notas':            notas,
  };
}
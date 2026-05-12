class PatientProfile {
  final int?    id;
  final int?    userId;
  final double? peso;
  final double? talla;
  final String? direccion;
  final String? ciudad;
  final String? contactoEmergenciaNombre;
  final String? contactoEmergenciaTelefono;
  final String? contactoEmergenciaRelacion;
  final bool    perfilCompleto;

  PatientProfile({
    this.id,
    this.userId,
    this.peso,
    this.talla,
    this.direccion,
    this.ciudad,
    this.contactoEmergenciaNombre,
    this.contactoEmergenciaTelefono,
    this.contactoEmergenciaRelacion,
    this.perfilCompleto = false,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id:                          json['id'],
      userId:                      json['user_id'],
      peso:                        double.tryParse(json['peso']?.toString() ?? ''),
      talla:                       double.tryParse(json['talla']?.toString() ?? ''),
      direccion:                   json['direccion'],
      ciudad:                      json['ciudad'],
      contactoEmergenciaNombre:    json['contacto_emergencia_nombre'],
      contactoEmergenciaTelefono:  json['contacto_emergencia_telefono'],
      contactoEmergenciaRelacion:  json['contacto_emergencia_relacion'],
      perfilCompleto:              json['perfil_completo'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'peso':                         peso,
    'talla':                        talla,
    'direccion':                    direccion,
    'ciudad':                       ciudad,
    'contacto_emergencia_nombre':   contactoEmergenciaNombre,
    'contacto_emergencia_telefono': contactoEmergenciaTelefono,
    'contacto_emergencia_relacion': contactoEmergenciaRelacion,
  };

  bool get isComplete =>
      peso != null &&
      talla != null &&
      direccion != null &&
      contactoEmergenciaNombre != null &&
      contactoEmergenciaTelefono != null;
}
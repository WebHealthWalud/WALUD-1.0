class DoctorProfile {
  final int?         id;
  final int?         userId;
  final String?      rethus;
  final List<Map<String, dynamic>> formacionAcademica;
  final List<String> areasEnfoque;
  final Map<String, dynamic>?      horariosAtencion;
  final List<Map<String, dynamic>> ubicacionesConsulta;
  final bool         perfilCompleto;
  final int          totalConsultas;
  final List<Map<String, dynamic>> ultimosPacientes;

  DoctorProfile({
    this.id,
    this.userId,
    this.rethus,
    this.formacionAcademica = const [],
    this.areasEnfoque       = const [],
    this.horariosAtencion,
    this.ubicacionesConsulta = const [],
    this.perfilCompleto      = false,
    this.totalConsultas      = 0,
    this.ultimosPacientes    = const [],
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id:                  json['id'],
      userId:              json['user_id'],
      rethus:              json['rethus'],
      formacionAcademica:  List<Map<String, dynamic>>.from(json['formacion_academica'] ?? []),
      areasEnfoque:        List<String>.from(json['areas_enfoque'] ?? []),
      horariosAtencion:    json['horarios_atencion'] != null
                               ? Map<String, dynamic>.from(json['horarios_atencion'])
                               : null,
      ubicacionesConsulta: List<Map<String, dynamic>>.from(json['ubicaciones_consulta'] ?? []),
      perfilCompleto:      json['perfil_completo'] == true,
      totalConsultas:      json['total_consultas'] ?? 0,
      ultimosPacientes:    List<Map<String, dynamic>>.from(json['ultimos_pacientes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'rethus':               rethus,
    'formacion_academica':  formacionAcademica,
    'areas_enfoque':        areasEnfoque,
    'horarios_atencion':    horariosAtencion,
    'ubicaciones_consulta': ubicacionesConsulta,
  };
}
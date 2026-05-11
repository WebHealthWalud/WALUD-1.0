enum DocumentType {
  cedulaCiudadania, tarjetaIdentidad, registroCivil, cedulaExtranjeria,
  carneDiplomatico, pasaporte, permisoEspecialPermanencia, permisoProteccionTemporal,
}

extension DocumentTypeExtension on DocumentType {
  String get value {
    const map = {
      DocumentType.cedulaCiudadania:           'cedula_ciudadania',
      DocumentType.tarjetaIdentidad:           'tarjeta_identidad',
      DocumentType.registroCivil:              'registro_civil',
      DocumentType.cedulaExtranjeria:          'cedula_extranjeria',
      DocumentType.carneDiplomatico:           'carne_diplomatico',
      DocumentType.pasaporte:                  'pasaporte',
      DocumentType.permisoEspecialPermanencia: 'permiso_especial_permanencia',
      DocumentType.permisoProteccionTemporal:  'permiso_proteccion_temporal',
    };
    return map[this]!;
  }

  String get label {
    const map = {
      DocumentType.cedulaCiudadania:           'Cédula de Ciudadanía',
      DocumentType.tarjetaIdentidad:           'Tarjeta de Identidad',
      DocumentType.registroCivil:              'Registro Civil',
      DocumentType.cedulaExtranjeria:          'Cédula de Extranjería',
      DocumentType.carneDiplomatico:           'Carné Diplomático',
      DocumentType.pasaporte:                  'Pasaporte',
      DocumentType.permisoEspecialPermanencia: 'Permiso Especial de Permanencia',
      DocumentType.permisoProteccionTemporal:  'Permiso por Protección Temporal',
    };
    return map[this]!;
  }

  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DocumentType.cedulaCiudadania,
    );
  }
}

const List<String> kTiposSangre = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'desconocido'];

const List<Map<String, String>> kGeneros = [
  {'value': 'masculino',         'label': 'Masculino'},
  {'value': 'femenino',          'label': 'Femenino'},
  {'value': 'otro',              'label': 'Otro'},
  {'value': 'prefiero_no_decir', 'label': 'Prefiero no decir'},
];

class User {
  final int? id;
  final String name;
  final String email;
  final int? document;
  final DocumentType? documentType;
  final String? lastName;
  final String? birthDate;
  final String? userType;       // mantenido para retrocompatibilidad
  final String? especialidad;
  final String? token;
  final String? profilePhotoPath;
  final String? photoUrl;
  final String? phone;
  // Nuevos campos
  final String? genero;
  final String? tipoSangre;
  final String? alergias;
  final bool notificacionesEmail;
  final bool notificacionesSms;
  final bool isActive;
  final List<String> roles; // roles Spatie

  User({
    this.id,
    required this.name,
    required this.email,
    this.document,
    this.documentType,
    this.lastName,
    this.birthDate,
    this.userType,
    this.especialidad,
    this.token,
    this.profilePhotoPath,
    this.photoUrl,
    this.phone,
    this.genero,
    this.tipoSangre,
    this.alergias,
    this.notificacionesEmail = true,
    this.notificacionesSms   = false,
    this.isActive            = true,
    this.roles               = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<String> roleList = [];
    if (json['roles'] != null) {
      final r = json['roles'];
      if (r is List) {
        roleList = r.map((e) {
          if (e is String) return e;
          if (e is Map)    return e['name']?.toString() ?? '';
          return '';
        }).where((e) => e.isNotEmpty).toList();
      }
    }

    return User(
      id:                  json['id'],
      name:                json['name'] ?? '',
      email:               json['email'] ?? '',
      document:            int.tryParse(json['document']?.toString() ?? ''),
      documentType:        json['tipo_documento'] != null
                             ? DocumentTypeExtension.fromString(json['tipo_documento'])
                             : null,
      lastName:            json['last_name'] ?? json['apellido'],
      birthDate:           json['birth_date'],
      userType:            json['tipo_usuario'] ?? json['user_type'],
      especialidad:        json['especialidad'],
      token:               json['token'],
      profilePhotoPath:    json['profile_photo_path'],
      photoUrl:            json['photo_url'],
      phone:               json['phone'],
      genero:              json['genero'],
      tipoSangre:          json['tipo_sangre'],
      alergias:            json['alergias'],
      notificacionesEmail: json['notificaciones_email'] == true || json['notificaciones_email'] == 1,
      notificacionesSms:   json['notificaciones_sms'] == true || json['notificaciones_sms'] == 1,
      isActive:            json['is_active'] != false && json['is_active'] != 0,
      roles:               roleList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':            id,
    'name':          name,
    'email':         email,
    'document':      document,
    'tipo_documento': documentType?.value,
    'last_name':     lastName,
    'birth_date':    birthDate,
    'tipo_usuario':  userType,
    'especialidad':  especialidad,
    'phone':         phone,
    'genero':        genero,
    'tipo_sangre':   tipoSangre,
    'alergias':      alergias,
    'notificaciones_email': notificacionesEmail,
    'notificaciones_sms':   notificacionesSms,
    'is_active':     isActive,
  };

  String get fullName => '$name ${lastName ?? ''}'.trim();

  // Detectar rol desde lista Spatie o tipo_usuario legacy
  bool get isAdmin   => roles.contains('admin')   || userType == 'admin';
  bool get isDoctor  => roles.contains('medico')  || userType == 'medico';
  bool get isPatient => roles.contains('paciente') || (!isAdmin && !isDoctor);

  String get rolLabel {
    if (isAdmin)  return 'Administrador';
    if (isDoctor) return 'Médico';
    return 'Paciente';
  }

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  String? get fullPhotoUrl {
    if (photoUrl == null) return null;
    if (photoUrl!.startsWith('http')) return photoUrl;
    return 'http://127.0.0.1:8000$photoUrl';
  }
}
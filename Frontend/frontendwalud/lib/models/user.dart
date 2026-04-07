enum DocumentType {
  cedulaCiudadania,
  tarjetaIdentidad,
  registroCivil,
  cedulaExtranjeria,
  carneDiplomatico,
  pasaporte,
  permisoEspecialPermanencia,
  permisoProteccionTemporal,
}

extension DocumentTypeExtension on DocumentType {
  String get value {
    const map = {
      DocumentType.cedulaCiudadania:            'cedula_ciudadania',
      DocumentType.tarjetaIdentidad:            'tarjeta_identidad',
      DocumentType.registroCivil:               'registro_civil',
      DocumentType.cedulaExtranjeria:           'cedula_extranjeria',
      DocumentType.carneDiplomatico:            'carne_diplomatico',
      DocumentType.pasaporte:                   'pasaporte',
      DocumentType.permisoEspecialPermanencia:  'permiso_especial_permanencia',
      DocumentType.permisoProteccionTemporal:   'permiso_proteccion_temporal',
    };
    return map[this]!;
  }

  String get label {
    const map = {
      DocumentType.cedulaCiudadania:            'Cédula de Ciudadanía',
      DocumentType.tarjetaIdentidad:            'Tarjeta de Identidad',
      DocumentType.registroCivil:               'Registro Civil',
      DocumentType.cedulaExtranjeria:           'Cédula de Extranjería',
      DocumentType.carneDiplomatico:            'Carné Diplomático',
      DocumentType.pasaporte:                   'Pasaporte',
      DocumentType.permisoEspecialPermanencia:  'Permiso Especial de Permanencia',
      DocumentType.permisoProteccionTemporal:   'Permiso por Protección Temporal',
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

class User {
  final int?         id;
  final String       name;
  final String       email;
  final int?         document;
  final DocumentType? documentType;
  final String?      lastName;
  final String?      birthDate;
  final String?      userType;
  final String?      especialidad;
  final String?      token;

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
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id:           json['id'],
      name:         json['name'] ?? '',
      email:        json['email'] ?? '',
      document:     int.tryParse(json['document']?.toString() ?? ''),
      lastName:     json['last_name'] ?? json['apellido'],
      birthDate:    json['birth_date'],
      userType:     json['tipo_usuario'] ?? json['user_type'],
      especialidad: json['especialidad'],
      token:        json['token'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id':           id,
    'name':         name,
    'email':        email,
    'document':     document,
    'tipo_documento': documentType?.value,
    'last_name':    lastName,
    'birth_date':   birthDate,
    'tipo_usuario': userType,
    'especialidad': especialidad,
  };

  String get fullName => '$name ${lastName ?? ''}'.trim();
  bool get isDoctor  => userType == 'medico';
  bool get isPatient => userType == 'paciente';
}
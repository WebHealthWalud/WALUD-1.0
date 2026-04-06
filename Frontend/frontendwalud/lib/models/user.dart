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
    switch (this) {
      case DocumentType.cedulaCiudadania:
        return 'cedula_ciudadania';
      case DocumentType.tarjetaIdentidad:
        return 'tarjeta_identidad';
      case DocumentType.registroCivil:
        return 'registro_civil';
      case DocumentType.cedulaExtranjeria:
        return 'cedula_extranjeria';
      case DocumentType.carneDiplomatico:
        return 'carne_diplomatico';
      case DocumentType.pasaporte:
        return 'pasaporte';
      case DocumentType.permisoEspecialPermanencia:
        return 'permiso_especial_permanencia';
      case DocumentType.permisoProteccionTemporal:
        return 'permiso_proteccion_temporal';
    }
  }

  String get label {
    switch (this) {
      case DocumentType.cedulaCiudadania:
        return 'Cédula de Ciudadanía';
      case DocumentType.tarjetaIdentidad:
        return 'Tarjeta de Identidad';
      case DocumentType.registroCivil:
        return 'Registro Civil';
      case DocumentType.cedulaExtranjeria:
        return 'Cédula de Extranjería';
      case DocumentType.carneDiplomatico:
        return 'Carné Diplomático';
      case DocumentType.pasaporte:
        return 'Pasaporte';
      case DocumentType.permisoEspecialPermanencia:
        return 'Permiso Especial de Permanencia';
      case DocumentType.permisoProteccionTemporal:
        return 'Permiso por Protección Temporal';
    }
  }

  static DocumentType fromString(String value) {
    switch (value) {
      case 'cedula_ciudadania':
        return DocumentType.cedulaCiudadania;
      case 'tarjeta_identidad':
        return DocumentType.tarjetaIdentidad;
      case 'registro_civil':
        return DocumentType.registroCivil;
      case 'cedula_extranjeria':
        return DocumentType.cedulaExtranjeria;
      case 'carne_diplomatico':
        return DocumentType.carneDiplomatico;
      case 'pasaporte':
        return DocumentType.pasaporte;
      case 'permiso_especial_permanencia':
        return DocumentType.permisoEspecialPermanencia;
      case 'permiso_proteccion_temporal':
        return DocumentType.permisoProteccionTemporal;
      default:
        return DocumentType.cedulaCiudadania;
    }
  }
}

class User {
  final int? id;
  final String name;
  final String email;
  final int? document;  
  final DocumentType? documentType;  
  final String? lastName;
  final String? birthDate;
  final String? userType;
  final String? token;

  User({
    this.id,
    required this.name,
    required this.email,
    this.document,
    this.documentType,
    this.lastName,
    this.birthDate,
    this.userType,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
  return User(
    id: json['id'],
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    document: int.tryParse(json['document']?.toString() ?? ''), 
    lastName: json['last_name'] ?? json['apellido'],
    birthDate: json['birth_date'],
    userType: json['tipo_usuario'] ?? json['user_type'],
    token: json['token'],
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'document': document,
      'tipo_documento': documentType?.value,
      'last_name': lastName,
      'birth_date': birthDate,
      'tipo_usuario': userType,
    };
  }

  String get fullName => '$name ${lastName ?? ''}'.trim();
  bool get isDoctor => userType == 'medico';
  bool get isPatient => userType == 'paciente';
}
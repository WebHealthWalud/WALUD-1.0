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
      DocumentType.cedulaCiudadania: 'cedula_ciudadania',
      DocumentType.tarjetaIdentidad: 'tarjeta_identidad',
      DocumentType.registroCivil: 'registro_civil',
      DocumentType.cedulaExtranjeria: 'cedula_extranjeria',
      DocumentType.carneDiplomatico: 'carne_diplomatico',
      DocumentType.pasaporte: 'pasaporte',
      DocumentType.permisoEspecialPermanencia: 'permiso_especial_permanencia',
      DocumentType.permisoProteccionTemporal: 'permiso_proteccion_temporal',
    };
    return map[this]!;
  }

  String get label {
    const map = {
      DocumentType.cedulaCiudadania: 'Cédula de Ciudadanía',
      DocumentType.tarjetaIdentidad: 'Tarjeta de Identidad',
      DocumentType.registroCivil: 'Registro Civil',
      DocumentType.cedulaExtranjeria: 'Cédula de Extranjería',
      DocumentType.carneDiplomatico: 'Carné Diplomático',
      DocumentType.pasaporte: 'Pasaporte',
      DocumentType.permisoEspecialPermanencia:
          'Permiso Especial de Permanencia',
      DocumentType.permisoProteccionTemporal: 'Permiso por Protección Temporal',
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

const List<String> kTiposSangre = [
  'A+',
  'A-',
  'B+',
  'B-',
  'AB+',
  'AB-',
  'O+',
  'O-',
  'desconocido',
];

const List<Map<String, String>> kGeneros = [
  {'value': 'masculino', 'label': 'Masculino'},
  {'value': 'femenino', 'label': 'Femenino'},
  {'value': 'otro', 'label': 'Otro'},
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
  final String? userType;
  final String? especialidad;
  final String? token;
  final String? profilePhotoPath;
  final String? photoUrl;
  final String? phone;
  final String? genero;
  final String? tipoSangre;
  final String? alergias;
  final bool notificacionesEmail;
  final bool notificacionesSms;
  final bool isActive;
  final List<String> roles;

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
    this.notificacionesSms = false,
    this.isActive = true,
    this.roles = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // ── Parsear lista de roles Spatie
    List<String> roleList = [];
    if (json['roles'] != null) {
      final r = json['roles'];
      if (r is List) {
        roleList = r
            .map((e) {
              if (e is String) return e;
              if (e is Map) return e['name']?.toString() ?? '';
              return '';
            })
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    // ✅ FIX ROL: determinar el tipo de usuario con esta prioridad:
    //   1. tipo_from_role  → el accessor de Spatie que agregamos en $appends
    //   2. roles list      → si viene el array de roles de Spatie
    //   3. tipo_usuario    → campo legacy de la BD (puede estar desactualizado)
    //
    // Esto resuelve el bug donde al refrescar tipo_usuario = 'paciente'
    // aunque el usuario sea admin o médico.
    String? resolvedUserType;

    // Prioridad 1: tipo_from_role viene del accessor de Laravel ($appends)
    if (json['tipo_from_role'] != null &&
        json['tipo_from_role'].toString().isNotEmpty) {
      resolvedUserType = json['tipo_from_role'].toString();
    }
    // Prioridad 2: inferir desde la lista de roles Spatie
    else if (roleList.contains('admin')) {
      resolvedUserType = 'admin';
    } else if (roleList.contains('medico')) {
      resolvedUserType = 'medico';
    } else if (roleList.contains('paciente')) {
      resolvedUserType = 'paciente';
    }
    // Prioridad 3: fallback al campo legacy tipo_usuario
    else {
      resolvedUserType =
          json['tipo_usuario']?.toString() ?? json['user_type']?.toString();
    }

    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      document: int.tryParse(json['document']?.toString() ?? ''),
      documentType: json['tipo_documento'] != null
          ? DocumentTypeExtension.fromString(json['tipo_documento'])
          : null,
      lastName: json['last_name'] ?? json['apellido'],
      birthDate: json['birth_date'],
      userType: resolvedUserType, // ← usa el rol resuelto correctamente
      especialidad: json['especialidad'],
      token: json['token'],
      profilePhotoPath: json['profile_photo_path'],
      photoUrl: json['photo_url'],
      phone: json['phone'],
      genero: json['genero'],
      tipoSangre: json['tipo_sangre'],
      alergias: json['alergias'],
      notificacionesEmail:
          json['notificaciones_email'] == true ||
          json['notificaciones_email'] == 1,
      notificacionesSms:
          json['notificaciones_sms'] == true || json['notificaciones_sms'] == 1,
      isActive: json['is_active'] != false && json['is_active'] != 0,
      roles: roleList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'document': document,
    'tipo_documento': documentType?.value,
    'last_name': lastName,
    'birth_date': birthDate,
    'tipo_usuario': userType,
    'especialidad': especialidad,
    'phone': phone,
    'genero': genero,
    'tipo_sangre': tipoSangre,
    'alergias': alergias,
    'notificaciones_email': notificacionesEmail,
    'notificaciones_sms': notificacionesSms,
    'is_active': isActive,
    'roles': roles,
    // ✅ Persistir tipo_from_role para que al reconstruir desde cache
    //    el rol resuelto no se pierda
    'tipo_from_role': userType,
  };

  String get fullName => '$name ${lastName ?? ''}'.trim();

  // ✅ Los getters solo necesitan userType porque fromJson() ya lo resolvió
  //    correctamente desde tipo_from_role o roles de Spatie.
  //    Mantenemos el fallback a roles por si acaso.
  bool get isAdmin => userType == 'admin' || roles.contains('admin');
  bool get isDoctor => userType == 'medico' || roles.contains('medico');
  bool get isPatient => userType == 'paciente' || (!isAdmin && !isDoctor);

  String get rolLabel {
    if (isAdmin) return 'Administrador';
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

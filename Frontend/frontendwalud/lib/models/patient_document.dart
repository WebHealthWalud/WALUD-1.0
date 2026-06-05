class PatientDocument {
  final int?    id;
  final int?    userId;
  final String  nombre;
  final String? tipo;
  final String  archivoPath;
  final String  archivoNombre;
  final String? mimeType;
  final int?    tamanio;
  final String? archivoUrl;
  final DateTime? createdAt;

  PatientDocument({
    this.id,
    this.userId,
    required this.nombre,
    this.tipo,
    required this.archivoPath,
    required this.archivoNombre,
    this.mimeType,
    this.tamanio,
    this.archivoUrl,
    this.createdAt,
  });

  factory PatientDocument.fromJson(Map<String, dynamic> json) {
    return PatientDocument(
      id:             json['id'],
      userId:         json['user_id'],
      nombre:         json['nombre'] ?? '',
      tipo:           json['tipo'],
      archivoPath:    json['archivo_path'] ?? '',
      archivoNombre:  json['archivo_nombre'] ?? '',
      mimeType:       json['mime_type'],
      tamanio:        json['tamanio'],
      archivoUrl:     json['archivo_url'],
      createdAt:      json['created_at'] != null
                          ? DateTime.tryParse(json['created_at'])
                          : null,
    );
  }

  // ✅ Tamaño legible
  String get tamanioLegible {
    if (tamanio == null) return '';
    if (tamanio! < 1024) return '${tamanio} B';
    if (tamanio! < 1024 * 1024) return '${(tamanio! / 1024).toStringAsFixed(1)} KB';
    return '${(tamanio! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ✅ Ícono según tipo
  String get tipoLabel {
    switch (tipo) {
      case 'analisis':   return 'Análisis';
      case 'radiografia': return 'Radiografía';
      case 'receta':     return 'Receta';
      case 'informe':    return 'Informe';
      case 'vacuna':     return 'Vacuna';
      default:           return 'Documento';
    }
  }
}
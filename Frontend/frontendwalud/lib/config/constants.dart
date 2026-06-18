const List<Map<String, String>> kEspecialidades = [
  {'value': 'medicina_general',   'label': 'Medicina General'},
  {'value': 'psicologia',         'label': 'Psicología'},
  {'value': 'psiquiatria',        'label': 'Psiquiatría'},
  {'value': 'dermatologia',       'label': 'Dermatología'},
  {'value': 'nutricion_dietetica','label': 'Nutrición y Dietética'},
  {'value': 'pediatria',          'label': 'Pediatría'},
  {'value': 'ginecologia',        'label': 'Ginecología'},
  {'value': 'medicina_interna',   'label': 'Medicina Interna'},
  {'value': 'endocrinologia',     'label': 'Endocrinología'},
  {'value': 'cardiologia',        'label': 'Cardiología'},
];

String especialidadLabel(String value) {
  return kEspecialidades.firstWhere(
    (e) => e['value'] == value,
    orElse: () => {'label': value},
  )['label']!;
}

// Colores Walud
const kPrimaryColor   = 0xFF4F46E5;
const kSecondaryColor = 0xFF0EA5E9;
const kDarkBlue       = 0xFF1A1A7A;
const kTeal           = 0xFF06B6D4;
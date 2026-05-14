import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _docCtrl      = TextEditingController();
  String _tipoDoc     = 'cedula_ciudadania';
  User?  _patient;
  bool   _isSearching = false;
  bool   _searched    = false;

  Future<void> _search() async {
    if (_docCtrl.text.trim().isEmpty) return;
    setState(() { _isSearching = true; _searched = false; _patient = null; });

    final r = await UserService.searchPatientByDocument(
      _docCtrl.text.trim(), _tipoDoc);

    setState(() {
      _isSearching = false;
      _searched    = true;
      _patient     = r['success'] == true ? r['patient'] as User : null;
    });

    if (r['success'] != true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r['message'] ?? 'Paciente no encontrado'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        const Text('Pacientes', style: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w900,
          color: Color(0xFF1A1A7A))),
        const SizedBox(height: 4),
        Text('Busca pacientes por tipo y número de documento.',
          style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        const SizedBox(height: 24),

        // Buscador
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.search, color: Color(0xFF1A1A7A), size: 20),
              const SizedBox(width: 8),
              const Text('Buscar Paciente', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A7A))),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              // Tipo documento
              Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _tipoDoc,
                      decoration: _deco('Tipo de documento'),
                      isExpanded: true, // ✅ evita overflow
                      items: const [
                        DropdownMenuItem(value: 'cedula_ciudadania',
                            child: Text('CC - Cédula Ciudadanía',
                                style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'tarjeta_identidad',
                            child: Text('TI - Tarjeta Identidad',
                                style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'registro_civil',
                            child: Text('RC - Registro Civil',
                                style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'cedula_extranjeria',
                            child: Text('CE - Cédula Extranjería',
                                style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'carne_diplomatico',
                            child: Text('CD - Carné Diplomático',
                                style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'pasaporte',
                            child: Text('PA - Pasaporte',
                                style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'permiso_especial_permanencia',
                            child: Text('PEP - Permiso Especial',
                                style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'permiso_proteccion_temporal',
                            child: Text('PPT - Prot. Temporal',
                                style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (v) => setState(() => _tipoDoc = v!),
                    ),
                  ),
              const SizedBox(width: 12),
              // Número documento
              Expanded(child: TextFormField(
                controller: _docCtrl,
                keyboardType: TextInputType.number,
                decoration: _deco('Número de documento'),
                onFieldSubmitted: (_) => _search(),
              )),
              const SizedBox(width: 12),
              // Botón buscar
              ElevatedButton.icon(
                onPressed: _isSearching ? null : _search,
                icon: _isSearching
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search, size: 18),
                label: const Text('Buscar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 24),

        // Resultado
        if (_searched && _patient == null)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Center(child: Column(children: [
              Icon(Icons.person_search_outlined,
                  size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('No se encontró ningún paciente con ese documento',
                style: TextStyle(color: Colors.grey[400], fontSize: 14)),
            ])),
          ),

        if (_patient != null) _buildPatientCard(_patient!),
      ]),
    );
  }

  Widget _buildPatientCard(User p) {
    final edad = _calcularEdad(p.birthDate);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // Header azul
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            // Avatar
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                gradient: p.hasPhoto != true
                    ? const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)])
                    : null,
              ),
              child: p.hasPhoto == true
                  ? ClipOval(child: Image.network(
                      p.fullPhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(p),
                    ))
                  : _avatarFallback(p),
            ),
            const SizedBox(width: 20),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.fullName, style: const TextStyle(
                color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.badge_outlined,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text('${_tipoDocLabel(_tipoDoc)}: ${p.document ?? '—'}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.cake_outlined,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text('$edad años', style: const TextStyle(
                    color: Colors.white70, fontSize: 13)),
              ]),
            ])),
            // ID Walud
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'WL-${p.id?.toString().padLeft(5, '0') ?? '00000'}',
                style: const TextStyle(
                  color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.bold)),
            ),
          ]),
        ),

        // Ficha médica
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ficha Médica', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A7A))),
            const SizedBox(height: 16),

            // Stats médicos
            Row(children: [
              Expanded(child: _statCard(
                'TIPO DE SANGRE',
                p.tipoSangre ?? '—',
                const Color(0xFFEF4444),
                Icons.water_drop_outlined,
              )),
              const SizedBox(width: 12),
              Expanded(child: _statCard(
                'GÉNERO',
                _generoLabel(p.genero),
                const Color(0xFF4F46E5),
                Icons.person_outline,
              )),
              const SizedBox(width: 12),
              Expanded(child: _statCard(
                'TELÉFONO',
                p.phone ?? '—',
                const Color(0xFF06B6D4),
                Icons.phone_outlined,
              )),
            ]),

            // Alergias
            if (p.alergias != null && p.alergias!.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text('ALERGIAS', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold,
                color: Colors.grey, letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6,
                children: p.alergias!.split(',').map((a) =>
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(a.trim(), style: const TextStyle(
                      color: Color(0xFFEF4444), fontSize: 12,
                      fontWeight: FontWeight.w500)),
                  )).toList()),
            ],

            // Contacto
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text('INFORMACIÓN DE CONTACTO', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold,
              color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 12),
            _infoRow(Icons.email_outlined, 'Correo', p.email ?? '—'),
            const SizedBox(height: 8),
            _infoRow(Icons.phone_outlined, 'Teléfono', p.phone ?? '—'),
          ]),
        ),
      ]),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(
          fontSize: 9, color: Colors.grey,
          letterSpacing: 1, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: color),
          textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(children: [
    Icon(icon, size: 16, color: Colors.grey[400]),
    const SizedBox(width: 10),
    Text('$label: ', style: TextStyle(
      fontSize: 13, color: Colors.grey[500])),
    Text(value, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w500,
      color: Color(0xFF1A1A7A))),
  ]);

  Widget _avatarFallback(User p) => Center(
    child: Text(
      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white, fontSize: 26,
        fontWeight: FontWeight.bold)),
  );

  int _calcularEdad(String? birthDate) {
    if (birthDate == null) return 0;
    final birth = DateTime.tryParse(birthDate);
    if (birth == null) return 0;
    final now = DateTime.now();
    int age   = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) age--;
    return age;
  }

  String _tipoDocLabel(String tipo) {
    const map = {
      'cedula_ciudadania':           'CC',
      'tarjeta_identidad':           'TI',
      'registro_civil':              'RC',
      'cedula_extranjeria':          'CE',
      'carne_diplomatico':           'CD',
      'pasaporte':                   'PA',
      'permiso_especial_permanencia':'PEP',
      'permiso_proteccion_temporal': 'PPT',
    };
    return map[tipo] ?? tipo;
  }

  String _generoLabel(String? genero) {
    const map = {
      'masculino':         'Masculino',
      'femenino':          'Femenino',
      'otro':              'Otro',
      'prefiero_no_decir': 'No especificado',
    };
    return map[genero] ?? '—';
  }

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
          color: Color(0xFF4F46E5), width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 12),
  );

  @override
  void dispose() {
    _docCtrl.dispose();
    super.dispose();
  }
}
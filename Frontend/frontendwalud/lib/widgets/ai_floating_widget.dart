import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

/// Punto de entrada público.
///
/// Carga el usuario autenticado y muestra el asistente de IA adecuado:
/// - Médico   -> _DoctorAIAssistant  (busca historial clínico por documento)
/// - Paciente -> _PatientAIAssistant (preconsulta / orientación de síntomas)
class AIFloatingWidget extends StatefulWidget {
  const AIFloatingWidget({super.key});

  @override
  State<AIFloatingWidget> createState() => _AIFloatingWidgetState();
}

class _AIFloatingWidgetState extends State<AIFloatingWidget> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final result = await AuthService.getCurrentUser();
    if (result['success'] == true && mounted) {
      setState(() => _currentUser = result['user']);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mientras no sabemos el rol, no mostramos nada (evita el "flash"
    // de un estilo incorrecto antes de que cargue el usuario).
    if (_currentUser == null) return const SizedBox.shrink();

    return _currentUser!.isDoctor
        ? const _DoctorAIAssistant()
        : const _PatientAIAssistant();
  }
}

// ================================================================
// PACIENTE -> Preconsulta / orientación de síntomas
// Identidad visual: índigo + cian, tono cercano y tranquilizador.
// ================================================================
class _PatientAIAssistant extends StatefulWidget {
  const _PatientAIAssistant();

  @override
  State<_PatientAIAssistant> createState() => _PatientAIAssistantState();
}

class _PatientAIAssistantState extends State<_PatientAIAssistant> {
  static const _primary = Color(0xFF4F46E5);
  static const _accent = Color(0xFF06B6D4);
  static const _darkBlue = Color(0xFF1A1A7A);

  final TextEditingController _controller = TextEditingController();

  bool _isOpen = false;
  bool _loading = false;
  Map<String, dynamic>? _response;

  Future<void> _analyzeSymptoms() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _response = null;
    });

    try {
      final response = await ApiService.postAuth(
        'ia/preconsulta',
        {"mensaje": _controller.text.trim()},
      );
      final data = jsonDecode(response.body);
      setState(() => _response = data);
    } catch (e) {
      setState(() => _response = {"error": true, "message": e.toString()});
    }

    setState(() => _loading = false);
  }

  Color _prioridadColor(String? prioridad) {
    switch (prioridad) {
      case 'Alta':
        return const Color(0xFFDC2626);
      case 'Media':
        return const Color(0xFFF59E0B);
      case 'Baja':
      default:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isOpen ? 380 : 70,
        height: _isOpen ? MediaQuery.of(context).size.height * 0.78 : 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20),
          ],
        ),
        child: _isOpen ? _buildPanel() : _buildFab(),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      backgroundColor: _primary,
      onPressed: () => setState(() => _isOpen = true),
      child: const Icon(Icons.smart_toy, color: Colors.white),
    );
  }

  Widget _buildPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_primary, _accent]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.smart_toy, color: _primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Asistente WALUD",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Orientación médica básica",
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _isOpen = false),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Describe tus síntomas...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _analyzeSymptoms,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Analizar síntomas",
                            style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
                if (_response == null) _welcomeCard(),
                if (_response != null) Expanded(child: _resultCard()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _welcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_information_outlined, color: _primary),
              SizedBox(width: 10),
              Text("Bienvenido a WALUD IA",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _darkBlue)),
            ],
          ),
          SizedBox(height: 14),
          Text(
            "Este asistente puede ayudarte a orientar tus síntomas y sugerir el especialista más adecuado.",
            style: TextStyle(height: 1.5, color: Colors.black87),
          ),
          SizedBox(height: 12),
          Text(
            "⚠️ IMPORTANTE:\nLa IA no reemplaza médicos profesionales ni genera diagnósticos definitivos.",
            style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
                height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _resultCard() {
    final isError = _response!['error'] == true;

    if (isError) {
      return _errorCard(
        _response!['message']?.toString() ??
            'No fue posible procesar tu consulta.',
      );
    }

    final especialidad = _response!['especialidad']?.toString() ?? '';
    final prioridad = _response!['prioridad']?.toString() ?? '';
    final urgente = _response!['urgente'] == true;
    final resumen = _response!['resumen']?.toString() ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (urgente)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Posible urgencia: te recomendamos buscar atención médica lo antes posible.",
                      style: TextStyle(
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w600,
                          height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (especialidad.isNotEmpty) _chip(especialidad, _primary),
                    if (prioridad.isNotEmpty)
                      _chip('Prioridad $prioridad', _prioridadColor(prioridad)),
                  ],
                ),
                const SizedBox(height: 14),
                const Text("Resumen",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, color: _darkBlue)),
                const SizedBox(height: 6),
                Text(resumen, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Color(0xFF92400E), height: 1.4)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ================================================================
// MÉDICO -> Resumen clínico del paciente por documento
// Identidad visual: verde azulado clínico, tono profesional,
// deliberadamente distinta a la del paciente.
// ================================================================
class _DoctorAIAssistant extends StatefulWidget {
  const _DoctorAIAssistant();

  @override
  State<_DoctorAIAssistant> createState() => _DoctorAIAssistantState();
}

class _DoctorAIAssistantState extends State<_DoctorAIAssistant> {
  static const _primary = Color(0xFF0F766E);
  static const _accent = Color(0xFF14B8A6);
  static const _darkTeal = Color(0xFF134E4A);

  final TextEditingController _documentController = TextEditingController();

  bool _isOpen = false;
  bool _loading = false;
  Map<String, dynamic>? _response;

  Future<void> _generatePatientSummary() async {
    if (_documentController.text.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _response = null;
    });

    try {
      final response = await ApiService.postAuth(
        'ia/resumen-paciente',
        {"documento": _documentController.text.trim()},
      );
      final data = jsonDecode(response.body);
      setState(() => _response = data);
    } catch (e) {
      setState(() => _response = {"error": true, "message": e.toString()});
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isOpen ? 380 : 70,
        height: _isOpen ? MediaQuery.of(context).size.height * 0.78 : 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20),
          ],
        ),
        child: _isOpen ? _buildPanel() : _buildFab(),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      backgroundColor: _primary,
      onPressed: () => setState(() => _isOpen = true),
      child: const Icon(Icons.folder_shared_outlined, color: Colors.white),
    );
  }

  Widget _buildPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_darkTeal, _accent]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.folder_shared_outlined, color: _primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Asistente Clínico WALUD",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Resumen de historia clínica",
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _isOpen = false),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _documentController,
                  keyboardType: TextInputType.number,
                  maxLines: 1,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.badge_outlined),
                    hintText: "Documento del paciente...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _generatePatientSummary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Consultar historial",
                            style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
                if (_response == null) _welcomeCard(),
                if (_response != null) Expanded(child: _resultCard()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _welcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_shared_outlined, color: _primary),
              SizedBox(width: 10),
              Text("Historial clínico con IA",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _darkTeal)),
            ],
          ),
          SizedBox(height: 14),
          Text(
            "Ingresa el número de documento del paciente para generar un resumen clínico basado en su historia registrada en WALUD.",
            style: TextStyle(height: 1.5, color: Colors.black87),
          ),
          SizedBox(height: 12),
          Text(
            "⚠️ Es un apoyo para la consulta: no reemplaza tu criterio clínico ni inventa información no registrada.",
            style: TextStyle(
                color: Color(0xFF0F766E),
                fontWeight: FontWeight.w500,
                height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _resultCard() {
    final isError = _response!['error'] == true;

    if (isError) {
      return _errorCard(
        _response!['message']?.toString() ??
            'No fue posible generar el resumen.',
      );
    }

    final paciente = _response!['paciente']?.toString() ?? '';
    final documento = _response!['documento']?.toString() ?? '';
    final resumen = _response!['resumen']?.toString() ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: _darkTeal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: _darkTeal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(paciente,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Doc: $documento',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Resumen clínico",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, color: _darkTeal)),
                const SizedBox(height: 6),
                Text(resumen, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Color(0xFF92400E), height: 1.4)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _documentController.dispose();
    super.dispose();
  }
}
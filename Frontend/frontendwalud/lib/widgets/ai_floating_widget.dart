import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AIFloatingWidget extends StatefulWidget {
  const AIFloatingWidget({super.key});

  @override
  State<AIFloatingWidget> createState() => _AIFloatingWidgetState();
}

class _AIFloatingWidgetState extends State<AIFloatingWidget> {
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
        {
          "mensaje": _controller.text.trim(),
        },
      );

      final data = jsonDecode(response.body);

      setState(() {
        _response = data;
      });
    } catch (e) {
      setState(() {
        _response = {
          "error": true,
          "message": e.toString(),
        };
      });
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isOpen ? 380 : 70,
        height: _isOpen
    ? MediaQuery.of(context).size.height * 0.78
    : 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
            ),
          ],
        ),
        child: _isOpen
            ? Column(
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4F46E5),
                          Color(0xFF06B6D4),
                        ],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.smart_toy,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Asistente WALUD",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Orientación médica básica",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isOpen = false;
                            });
                          },
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
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
                              onPressed:
                                  _loading ? null : _analyzeSymptoms,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF4F46E5),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: _loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Analizar síntomas",
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // MENSAJE INICIAL
                          if (_response == null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius:
                                    BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons
                                            .medical_information_outlined,
                                        color: Color(0xFF4F46E5),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "Bienvenido a WALUD IA",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF1A1A7A),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 14),

                                  Text(
                                    "Este asistente puede ayudarte a orientar tus síntomas y sugerir el especialista más adecuado.",
                                    style: TextStyle(
                                      height: 1.5,
                                      color: Colors.black87,
                                    ),
                                  ),

                                  SizedBox(height: 12),

                                  Text(
                                    "⚠️ IMPORTANTE:\nLa IA no reemplaza médicos profesionales ni genera diagnósticos definitivos.",
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // RESPUESTA IA
                          if (_response != null)
                            Expanded(
                              child: SingleChildScrollView(
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color(0xFFF8FAFC),
                                    borderRadius:
                                        BorderRadius.circular(
                                            16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _item(
                                        "Especialidad",
                                        _response![
                                                'especialidad'] ??
                                            '',
                                      ),

                                      _item(
                                        "Prioridad",
                                        _response![
                                                'prioridad'] ??
                                            '',
                                      ),

                                      _item(
                                        "Resumen",
                                        _response![
                                                'resumen'] ??
                                            '',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : FloatingActionButton(
                backgroundColor: const Color(0xFF4F46E5),
                onPressed: () {
                  setState(() {
                    _isOpen = true;
                  });
                },
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _item(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A7A),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
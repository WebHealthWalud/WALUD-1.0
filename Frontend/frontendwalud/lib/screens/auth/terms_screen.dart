import 'package:flutter/material.dart';

/// Pantalla de Términos y Condiciones y Política de Tratamiento de Datos
/// Cumple con: Ley 1581 de 2012, Decreto 1377 de 2013, Ley 1266 de 2008
class TermsScreen extends StatefulWidget {
  final VoidCallback onAccepted;
  final VoidCallback onDeclined;

  const TermsScreen({
    super.key,
    required this.onAccepted,
    required this.onDeclined,
  });

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _acceptedTerms   = false;
  bool _acceptedPrivacy = false;

  bool get _canContinue => _acceptedTerms && _acceptedPrivacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Panel izquierdo decorativo
          if (MediaQuery.of(context).size.width > 900)
            Container(
              width: 340,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A7A), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text('Walud', style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white,
                        )),
                      ]),
                      const Spacer(),
                      const Text('Tu privacidad,\nnuestra prioridad.', style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w900,
                        color: Colors.white, height: 1.3,
                      )),
                      const SizedBox(height: 24),
                      _leftItem(Icons.shield_outlined,
                          'Ley 1581 de 2012', 'Protección de datos personales en Colombia'),
                      const SizedBox(height: 16),
                      _leftItem(Icons.verified_user_outlined,
                          'Decreto 1377 de 2013', 'Reglamentación del tratamiento de datos'),
                      const SizedBox(height: 16),
                      _leftItem(Icons.lock_outline,
                          'Ley 1266 de 2008', 'Habeas data y datos financieros'),
                      const SizedBox(height: 40),
                      Text('© 2026 Walud · SENA CBA',
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
                    ],
                  ),
                ),
              ),
            ),

          // Contenido principal
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8, offset: const Offset(0, 2),
                      )],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gavel_outlined, color: Color(0xFF4F46E5), size: 22),
                        const SizedBox(width: 10),
                        const Text('Términos y Política de Privacidad', style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A1A7A),
                        )),
                        const Spacer(),
                        TextButton(
                          onPressed: widget.onDeclined,
                          child: Text('Cancelar', style: TextStyle(color: Colors.grey[500])),
                        ),
                      ],
                    ),
                  ),

                  // Documento scrolleable
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _docSection('1. INFORMACIÓN GENERAL',
                            'Walud es una plataforma digital de servicios de salud desarrollada por el equipo ADSO-SENA CBA (Centro de Biotecnología Agropecuaria), Mosquera, Cundinamarca. Al registrarte, aceptas los presentes Términos y Condiciones de Uso y la Política de Tratamiento de Datos Personales.'),

                          _docSection('2. TRATAMIENTO DE DATOS PERSONALES (LEY 1581 DE 2012)',
                            'De conformidad con la Ley Estatutaria 1581 de 2012 y el Decreto 1377 de 2013, Walud actúa como Responsable del Tratamiento de los datos personales que recolecta. La información suministrada será utilizada exclusivamente para:\n\n'
                            '• Gestión de citas médicas y teleconsultas\n'
                            '• Administración de historia clínica digital\n'
                            '• Envío de notificaciones y recordatorios médicos\n'
                            '• Procesamiento de pagos de servicios de salud\n'
                            '• Mejora continua de los servicios ofrecidos\n\n'
                            'Los datos NO serán vendidos, cedidos ni transferidos a terceros sin tu consentimiento expreso, salvo obligación legal.'),

                          _docSection('3. DATOS QUE RECOLECTAMOS',
                            'Walud recolecta los siguientes datos personales:\n\n'
                            '• Datos de identificación: nombre completo, tipo y número de documento, fecha de nacimiento, género\n'
                            '• Datos de contacto: correo electrónico, número de teléfono\n'
                            '• Datos de salud (datos sensibles): grupo sanguíneo, alergias, historia clínica, diagnósticos, medicamentos\n'
                            '• Datos financieros: información de pagos y copagos de servicios médicos\n\n'
                            'Los datos de salud son considerados datos sensibles según el artículo 5° de la Ley 1581 de 2012, y su tratamiento requiere tu autorización expresa, la cual otorgas mediante la aceptación de este documento.'),

                          _docSection('4. DERECHOS DEL TITULAR (HABEAS DATA)',
                            'Como titular de los datos tienes derecho a:\n\n'
                            '• Conocer, actualizar y rectificar tus datos personales\n'
                            '• Solicitar prueba de la autorización otorgada\n'
                            '• Ser informado sobre el uso dado a tus datos\n'
                            '• Presentar quejas ante la Superintendencia de Industria y Comercio (SIC)\n'
                            '• Revocar la autorización y/o solicitar la supresión de tus datos\n'
                            '• Acceder gratuitamente a tus datos personales tratados\n\n'
                            'Para ejercer estos derechos puedes contactarnos en: soporte@walud.com.co'),

                          _docSection('5. SEGURIDAD DE LA INFORMACIÓN',
                            'Walud implementa medidas técnicas y administrativas para proteger tus datos:\n\n'
                            '• Cifrado de datos en tránsito y en reposo\n'
                            '• Control de acceso basado en roles (paciente, médico, administrador)\n'
                            '• Autenticación con tokens seguros (Laravel Sanctum)\n'
                            '• Registros de auditoría de accesos\n'
                            '• Alojamiento en servidores con certificados SSL\n\n'
                            'Sin perjuicio de lo anterior, ningún sistema de seguridad es infalible. En caso de brecha de seguridad, serás notificado conforme a la normativa vigente.'),

                          _docSection('6. HISTORIA CLÍNICA DIGITAL',
                            'Los registros médicos almacenados en Walud tienen carácter confidencial y están sujetos a la Resolución 1995 de 1999 del Ministerio de Salud. Solo tú y los profesionales de salud autorizados por ti podrán acceder a dicha información. La historia clínica no podrá ser divulgada sin tu consentimiento expreso, salvo orden judicial.'),

                          _docSection('7. MENORES DE EDAD',
                            'Si eres menor de 18 años, debes contar con la autorización de tu padre, madre o tutor legal para usar la plataforma. El registro de menores de edad debe realizarse por un adulto responsable. Walud se reserva el derecho de solicitar documentación adicional para verificar la autorización parental.'),

                          _docSection('8. MODIFICACIONES',
                            'Walud se reserva el derecho de modificar estos términos. Los cambios serán notificados por correo electrónico con al menos 15 días de anticipación. El uso continuado de la plataforma tras la notificación implica la aceptación de los nuevos términos.'),

                          _docSection('9. LEY APLICABLE Y JURISDICCIÓN',
                            'Estos términos se rigen por las leyes de la República de Colombia. Cualquier controversia será resuelta ante los jueces competentes de Bogotá D.C., Colombia, renunciando expresamente a cualquier otro fuero.'),

                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Versión 1.0 · Vigente desde enero de 2026 · '
                                    'Para consultas: soporte@walud.com.co',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Panel de aceptación fijo al fondo
                  Container(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12, offset: const Offset(0, -3),
                      )],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox términos
                        _checkRow(
                          value: _acceptedTerms,
                          onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                          text: 'He leído y acepto los Términos y Condiciones de Uso de la plataforma Walud.',
                        ),
                        const SizedBox(height: 10),
                        // Checkbox privacidad / datos sensibles
                        _checkRow(
                          value: _acceptedPrivacy,
                          onChanged: (v) => setState(() => _acceptedPrivacy = v ?? false),
                          text: 'Autorizo el tratamiento de mis datos personales, incluyendo datos de salud (datos sensibles), conforme a la Ley 1581 de 2012 y la Política de Privacidad de Walud.',
                        ),
                        const SizedBox(height: 20),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onDeclined,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('No acepto', style: TextStyle(color: Colors.grey[500])),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _canContinue ? widget.onAccepted : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A1A7A),
                                disabledBackgroundColor: Colors.grey.shade200,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _canContinue ? 'Acepto y continuar registro' : 'Debes aceptar ambas condiciones',
                                  style: TextStyle(
                                    color: _canContinue ? Colors.white : Colors.grey[400],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leftItem(IconData icon, String title, String subtitle) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12,
          )),
          Text(subtitle, style: TextStyle(
            color: Colors.white.withOpacity(0.55), fontSize: 11,
          )),
        ]),
      ),
    ]);
  }

  Widget _docSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A7A),
            letterSpacing: 0.5,
          )),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            height: 1.7,
          )),
        ],
      ),
    );
  }

  Widget _checkRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF1A1A7A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(text, style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            )),
          ),
        ),
      ],
    );
  }
}
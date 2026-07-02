import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8EAF6), Color(0xFFE0F7FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildHeroSection(context),
              _buildSpecialtiesSection(context),
              _buildBenefitsSection(),
              _buildFeaturesSection(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      color: Colors.white.withOpacity(0.85),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Walud',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A7A),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'SALUD DIGITAL',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 2,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text(
                  'Registrarse',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── HERO ──────────────────────────────────────────────────────────────────
  Widget _buildHeroSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6EE7B7).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🏥 Telemedicina · Historia Clínica · Citas Digitales',
                    style: TextStyle(
                      color: Color(0xFF0D9488),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tu salud,\nen tus manos',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A7A),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Walud conecta pacientes y médicos especializados en una plataforma segura: '
                  'agenda citas, accede a tu historia clínica y realiza consultas por videollamada, '
                  'todo desde un solo lugar.',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey[600],
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 36),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      icon: const Icon(Icons.person_add_outlined, color: Colors.white, size: 18),
                      label: const Text(
                        'Crear cuenta gratis',
                        style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      icon: const Icon(Icons.login_outlined, color: Color(0xFF4F46E5), size: 18),
                      label: const Text(
                        'Ya tengo cuenta',
                        style: TextStyle(fontSize: 15, color: Color(0xFF4F46E5)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4F46E5)),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    _statChip(Icons.people_alt_outlined, '+500', 'Pacientes'),
                    const SizedBox(width: 24),
                    _statChip(Icons.medical_services_outlined, '8', 'Especialidades'),
                    const SizedBox(width: 24),
                    _statChip(Icons.videocam_outlined, '24/7', 'Disponible'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 60),
          Expanded(
            flex: 4,
            child: _buildHeroCard(),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5), size: 18),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF1A1A7A),
            )),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.health_and_safety_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Panel de Paciente', style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A7A),
                    fontSize: 14,
                  )),
                  Text('Walud · Salud Digital', style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _previewRow(Icons.calendar_today_outlined, 'Próxima cita', 'Cardiología · Hoy 3:00 PM', const Color(0xFF4F46E5)),
          const SizedBox(height: 14),
          _previewRow(Icons.folder_open_outlined, 'Historia Clínica', 'Última actualización: hoy', const Color(0xFF0D9488)),
          const SizedBox(height: 14),
          _previewRow(Icons.videocam_outlined, 'Videoconsulta', 'Dr. disponible ahora', const Color(0xFF7C3AED)),
          const SizedBox(height: 14),
          _previewRow(Icons.payment_outlined, 'Pago verificado', 'Consulta general · 35.000', const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _previewRow(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
          const Spacer(),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey[300]),
        ],
      ),
    );
  }

  // ── ESPECIALIDADES ────────────────────────────────────────────────────────
  Widget _buildSpecialtiesSection(BuildContext context) {
    final specialties = [
      {'icon': Icons.favorite_outline,     'title': 'Cardiología',    'desc': 'Corazón, hipertensión y enfermedades cardiovasculares.',              'color': 0xFFEF4444},
      {'icon': Icons.psychology_outlined,  'title': 'Neurología',     'desc': 'Cefaleas, epilepsia, trastornos del sistema nervioso.',               'color': 0xFF8B5CF6},
      {'icon': Icons.child_care_outlined,  'title': 'Pediatría',      'desc': 'Atención integral para niños y adolescentes.',                        'color': 0xFF06B6D4},
      {'icon': Icons.face_outlined,        'title': 'Dermatología',   'desc': 'Piel, cabello y uñas con diagnóstico por imagen.',                    'color': 0xFFF59E0B},
      {'icon': Icons.pregnant_woman,       'title': 'Ginecología',    'desc': 'Salud femenina, control prenatal y seguimiento hormonal.',             'color': 0xFFEC4899},
      {'icon': Icons.visibility_outlined,  'title': 'Oftalmología',   'desc': 'Visión, salud ocular y cirugía refractiva.',                          'color': 0xFF10B981},
      {'icon': Icons.hearing_outlined,     'title': 'Otorrinolaringología', 'desc': 'Oído, nariz, garganta y vías respiratorias altas.',              'color': 0xFF3B82F6},
      {'icon': Icons.sentiment_satisfied_outlined, 'title': 'Psiquiatría', 'desc': 'Salud mental, ansiedad, depresión y bienestar emocional.',        'color': 0xFF6366F1},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 80),
      color: Colors.white,
      child: Column(
        children: [
          _sectionLabel('ESPECIALIDADES MÉDICAS'),
          const SizedBox(height: 12),
          const Text(
            'Médicos certificados en 8 especialidades',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A7A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Conecta con especialistas verificados y agenda tu consulta presencial o por videollamada en minutos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[500], height: 1.6),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: specialties.map((s) => _specialtyCard(s)).toList(),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ),
            icon: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 18),
            label: const Text(
              'Agendar consulta con un especialista',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A7A),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _specialtyCard(Map<String, dynamic> s) {
    final color = Color(s['color'] as int);
    return Container(
      width: 200,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(s['icon'] as IconData, color: color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(s['title'] as String, style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF1A1A7A),
          )),
          const SizedBox(height: 6),
          Text(s['desc'] as String, style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            height: 1.5,
          )),
        ],
      ),
    );
  }

  // ── BENEFICIOS ────────────────────────────────────────────────────────────
  Widget _buildBenefitsSection() {
    final benefits = [
      {
        'icon': Icons.videocam_outlined,
        'color': 0xFF4F46E5,
        'title': 'Videoconsulta desde casa',
        'desc': 'Consulta a tu médico en tiempo real sin desplazarte. Conexión segura y privada con tu especialista.',
      },
      {
        'icon': Icons.folder_shared_outlined,
        'color': 0xFF0D9488,
        'title': 'Historia Clínica Digital',
        'desc': 'Todos tus diagnósticos, recetas y evoluciones en un solo lugar, disponibles siempre que los necesites.',
      },
      {
        'icon': Icons.notifications_active_outlined,
        'color': 0xFFF59E0B,
        'title': 'Recordatorios inteligentes',
        'desc': 'Recibe alertas de tus citas por correo o SMS para que nunca pierdas una consulta importante.',
      },
      {
        'icon': Icons.lock_outline,
        'color': 0xFF10B981,
        'title': 'Privacidad garantizada',
        'desc': 'Tu información médica está cifrada y protegida conforme a la Ley 1581 de habeas data de Colombia.',
      },
      {
        'icon': Icons.payment_outlined,
        'color': 0xFF7C3AED,
        'title': 'Pagos seguros y transparentes',
        'desc': 'Gestiona copagos con múltiples métodos de pago y recibe comprobantes digitales al instante.',
      },
      {
        'icon': Icons.calendar_month_outlined,
        'color': 0xFF06B6D4,
        'title': 'Agenda 24/7',
        'desc': 'Reserva, modifica o cancela citas en cualquier momento, sin necesidad de llamar a un consultorio.',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 80),
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _sectionLabel('BENEFICIOS DE LA PLATAFORMA'),
          const SizedBox(height: 12),
          const Text(
            '¿Por qué elegir Walud?',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A7A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: benefits.map((b) => _benefitCard(b)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _benefitCard(Map<String, dynamic> b) {
    final color = Color(b['color'] as int);
    return Container(
      width: 300,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(b['icon'] as IconData, color: color, size: 26),
          ),
          const SizedBox(height: 18),
          Text(b['title'] as String, style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1A1A7A),
          )),
          const SizedBox(height: 10),
          Text(b['desc'] as String, style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
            height: 1.6,
          )),
        ],
      ),
    );
  }

  // ── CARACTERÍSTICAS (cómo funciona) ───────────────────────────────────────
  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 80),
      color: Colors.white,
      child: Column(
        children: [
          _sectionLabel('¿CÓMO FUNCIONA?'),
          const SizedBox(height: 12),
          const Text(
            'En 3 pasos tienes tu cita médica',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A7A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 56),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep('01', Icons.person_add_outlined, const Color(0xFF4F46E5),
                'Crea tu cuenta',
                'Regístrate en minutos con tu documento y datos básicos. Sin papeleo, sin filas.'),
              const SizedBox(width: 24),
              _buildStepArrow(),
              const SizedBox(width: 24),
              _buildStep('02', Icons.search_outlined, const Color(0xFF0D9488),
                'Elige tu especialista',
                'Filtra por especialidad, revisa el perfil del médico y escoge el horario que más te convenga.'),
              const SizedBox(width: 24),
              _buildStepArrow(),
              const SizedBox(width: 24),
              _buildStep('03', Icons.check_circle_outline, const Color(0xFF7C3AED),
                'Asiste a tu cita',
                'Recibe recordatorios, únete por videollamada o asiste de forma presencial. Tu historia clínica se actualiza automáticamente.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String num, IconData icon, Color color, String title, String desc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(num, style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: color.withOpacity(0.15),
                  height: 1,
                )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF1A1A7A),
            )),
            const SizedBox(height: 10),
            Text(desc, style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              height: 1.6,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStepArrow() {
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Icon(Icons.arrow_forward_ios, color: Colors.grey[300], size: 20),
    );
  }

  // ── FOOTER ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
      color: const Color(0xFF1A1A7A),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text('Walud', style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white,
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Plataforma de salud digital colombiana.\nConectamos pacientes con especialistas\nde forma segura y eficiente.',
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.55), height: 1.7),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Especialidades', style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.8), fontSize: 13,
                    )),
                    const SizedBox(height: 12),
                    ...['Cardiología', 'Neurología', 'Pediatría', 'Dermatología'].map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(e, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Legal', style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.8), fontSize: 13,
                    )),
                    const SizedBox(height: 12),
                    ...['Política de Privacidad', 'Términos de Uso', 'Habeas Data', 'Contacto'].map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(e, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2026 Walud · Salud Digital Colombia. Todos los derechos reservados.',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
              ),
              Text(
                'Ley 1581 de 2012 · Habeas Data · SENA CBA',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4F46E5),
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
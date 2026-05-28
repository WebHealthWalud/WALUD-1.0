import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

const double _kLandBreakpoint = 800;

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFF3E5F5)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildHeroSection(context),
              _buildQuickAccessSection(),
              _buildFeaturesSection(context),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < _kLandBreakpoint;

    if (isNarrow) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Walud', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
            Row(children: [
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Acceso',
                  style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                child: const Text('Registrarse',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
            ]),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Walud', style: TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
          Row(children: [
            _buildNavItem('Servicios'),
            _buildNavItem('Especialistas'),
            _buildNavItem('Planes'),
            _buildNavItem('Recursos'),
            const SizedBox(width: 32),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Acceso',
                style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600))),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
              child: const Text('Registrarse',
                style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600))),
          ]),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(label, style: const TextStyle(
      color: Color(0xFF1A1A7A), fontWeight: FontWeight.w500)));

  Widget _buildHeroSection(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < _kLandBreakpoint;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 24 : 48,
        vertical: isNarrow ? 40 : 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6EE7B7).withOpacity(0.3),
              borderRadius: BorderRadius.circular(20)),
            child: const Text('Innovación en Salud Digital',
              style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600))),
          const SizedBox(height: 24),
          Text('Tu salud,\nelevada al digital',
            style: TextStyle(
              fontSize: isNarrow ? 40 : 64,
              fontWeight: FontWeight.bold, color: const Color(0xFF1A1A7A), height: 1.2)),
          const SizedBox(height: 24),
          const Text(
            'Experimenta una nueva era de cuidado médico. Walud integra tecnología de vanguardia con calidez humana para ofrecerte el estándar clínico que mereces.',
            style: TextStyle(fontSize: 18, color: Color(0xFF6B7280), height: 1.6)),
          const SizedBox(height: 32),
          Wrap(spacing: 16, runSpacing: 12, children: [
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
              child: const Row(children: [
                Text('Registrarse', style: TextStyle(fontSize: 16, color: Color(0xFFFFFFFF))),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Color(0xFFFFFFFF)),
              ]),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4F46E5)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
              child: const Text('Ver Planes',
                style: TextStyle(fontSize: 16, color: Color(0xFF4F46E5)))),
          ]),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Builder(builder: (context) {
      final isNarrow = MediaQuery.of(context).size.width < _kLandBreakpoint;
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? 24 : 48, vertical: 80),
        color: Colors.grey.shade50,
        child: Column(children: [
          const Text('Accesos Rápidos', style: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
          const SizedBox(height: 12),
          const Text(
            'Todo lo que necesitas para gestionar tu bienestar desde un solo lugar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
          const SizedBox(height: 48),
          if (isNarrow)
            Column(children: [
              _buildQuickAccessCard(
                icon: Icons.chat_bubble_outline, iconColor: const Color(0xFF0D7377),
                title: 'Consulta en Línea',
                description: 'Habla con especialistas de primer nivel en minutos.',
                ctaText: 'Iniciar cita'),
              const SizedBox(height: 24),
              _buildQuickAccessCard(
                icon: Icons.folder_open, iconColor: const Color(0xFF4F46E5),
                title: 'Gestionar Historial',
                description: 'Accede a tus resultados y antecedentes médicos unificados.',
                ctaText: 'Ver mi portal'),
              const SizedBox(height: 24),
              _buildQuickAccessCard(
                icon: Icons.payment, iconColor: const Color(0xFF7C3AED),
                title: 'Pagos Seguros',
                description: 'Administra tus suscripciones y pagos con total transparencia.',
                ctaText: 'Configurar pagos'),
            ])
          else
            Row(children: [
              Expanded(child: _buildQuickAccessCard(
                icon: Icons.chat_bubble_outline, iconColor: const Color(0xFF0D7377),
                title: 'Consulta en Línea',
                description: 'Habla con especialistas de primer nivel en minutos, sin salir de casa y con receta digital incluida.',
                ctaText: 'Iniciar cita')),
              const SizedBox(width: 24),
              Expanded(child: _buildQuickAccessCard(
                icon: Icons.folder_open, iconColor: const Color(0xFF4F46E5),
                title: 'Gestionar Historial',
                description: 'Accede a tus resultados, laboratorios y antecedentes médicos unificados en un portal seguro.',
                ctaText: 'Ver mi portal')),
              const SizedBox(width: 24),
              Expanded(child: _buildQuickAccessCard(
                icon: Icons.payment, iconColor: const Color(0xFF7C3AED),
                title: 'Pagos Seguros',
                description: 'Administra tus suscripciones y pagos de copagos con total transparencia y múltiples métodos.',
                ctaText: 'Configurar pagos')),
            ]),
        ]),
      );
    });
  }

  Widget _buildQuickAccessCard({
    required IconData icon, required Color iconColor,
    required String title, required String description, required String ctaText,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 28)),
        const SizedBox(height: 20),
        Text(title, style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A7A))),
        const SizedBox(height: 12),
        Text(description, style: const TextStyle(
          fontSize: 14, color: Color(0xFF6B7280), height: 1.6)),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: Text(ctaText, style: const TextStyle(
            color: Color(0xFF0D7377), fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(padding: EdgeInsets.zero)),
      ]),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < _kLandBreakpoint;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 24 : 80, vertical: 80),
      child: isNarrow
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildFeaturesContent(),
            ])
          : Row(children: [
              Expanded(child: Column(children: [
                Container(
                  width: 350, height: 350,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/LOGOWALUD.png'),
                      fit: BoxFit.cover)),
                ),
              ])),
              const SizedBox(width: 100),
              Expanded(child: _buildFeaturesContent()),
            ]),
    );
  }

  Widget _buildFeaturesContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text(
        'Diseñado para la precisión clínica, optimizado para el paciente.',
        style: TextStyle(
          fontSize: 28, fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A7A), height: 1.4)),
      const SizedBox(height: 32),
      _buildFeatureItem('Interfaz intuitiva que reduce el estrés durante la gestión de salud.'),
      const SizedBox(height: 16),
      _buildFeatureItem('Sincronización instantánea con dispositivos médicos portátiles.'),
      const SizedBox(height: 16),
      _buildFeatureItem('Privacidad de datos cumpliendo con estándares internacionales HIPAA/GDPR.'),
      const SizedBox(height: 32),
      OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Explorar Funciones',
          style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)))),
    ]);
  }

  Widget _buildFeatureItem(String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: Color(0xFF06B6D4), shape: BoxShape.circle),
        child: const Icon(Icons.check, color: Colors.white, size: 16)),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(
        fontSize: 16, color: Color(0xFF6B7280), height: 1.6))),
    ],
  );

  Widget _buildFooter(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < _kLandBreakpoint;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 24 : 48, vertical: 32),
      color: Colors.grey.shade50,
      child: isNarrow
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Walud', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
              const SizedBox(height: 8),
              const Text('© 2026 Salud Web Walud',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(height: 16),
              Wrap(children: [
                _buildFooterLink('Privacidad'),
                _buildFooterLink('Términos de Uso'),
                _buildFooterLink('Contacto'),
                _buildFooterLink('Soporte'),
              ]),
            ])
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Walud', style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                  SizedBox(height: 8),
                  Text('© 2026 Salud Web Walud',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ]),
                Row(children: [
                  _buildFooterLink('Privacidad'),
                  _buildFooterLink('Términos de Uso'),
                  _buildFooterLink('Contacto'),
                  _buildFooterLink('Soporte'),
                ]),
                Row(children: [
                  _buildSocialIcon(Icons.share),
                  const SizedBox(width: 12),
                  _buildSocialIcon(Icons.email),
                ]),
              ],
            ),
    );
  }

  Widget _buildFooterLink(String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: TextButton(
      onPressed: () {},
      child: Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14))));

  Widget _buildSocialIcon(IconData icon) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white, shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
    child: Icon(icon, size: 20, color: const Color(0xFF4F46E5)));
}
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'screens/landing/landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(const WaludApp());
}

// LandingPage
class WaludApp extends StatelessWidget {
  const WaludApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walud',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'ES'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF4F46E5),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      // Cambiar a LandingPage como página inicial
      // 
        home: const AuthWrapper(),
      // O mantener AuthWrapper si quieres verificar sesión:
      // home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final hasSession = await AuthService.hasValidSession();

    if (mounted) {
      if (hasSession) {
        // ✅ Si hay sesión activa → Dashboard directo
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        // ✅ Si no hay sesión → LandingPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LandingPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Splash mientras verifica
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A7A), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 60, color: Colors.white),
              SizedBox(height: 16),
              Text('WALUD', style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold,
                color: Colors.white, letterSpacing: 2,
              )),
              SizedBox(height: 8),
              Text('SALUD DIGITAL', style: TextStyle(
                fontSize: 12, color: Colors.white70, letterSpacing: 3,
              )),
              SizedBox(height: 40),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    // Muestra un splash/loading mientras verifica
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6EE7B7), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_hospital, size: 80, color: Colors.white),
              SizedBox(height: 24),
              Text(
                'WALUD',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }


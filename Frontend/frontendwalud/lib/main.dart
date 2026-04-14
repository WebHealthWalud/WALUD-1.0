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
      home: const LandingPage(),
      // O mantener AuthWrapper si quieres verificar sesión:
      // home: const AuthWrapper(),
    );
  }
}

// NUEVO: Widget que decide si mostrar Login o Dashboard
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
    // Pequeño delay para mostrar splash si se desea
    await Future.delayed(const Duration(milliseconds: 300));

    final hasSession = await AuthService.hasValidSession();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              hasSession ? const DashboardScreen() : const LoginScreen(),
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
}

// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentController = TextEditingController();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();

  String _userType = 'paciente';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      setState(() {
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(date);
      });
    }
  }

  Future<void> _handleRegister() async {
    // 1. Validar formulario
    if (!_formKey.currentState!.validate()) return;

    // 2. Validar que las contraseñas coincidan
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 3. Mostrar loading
    setState(() => _isLoading = true);

    // 4. Llamar al servicio de registro
    final result = await AuthService.register(
      document: _documentController.text.trim(),
      name: _nameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
      birthDate: _birthDateController.text,
      userType: _userType,
    );

    setState(() => _isLoading = false);

    // 5. Manejar respuesta
    if (mounted) {
      if (result['success']) {
        // ✅ MOSTRAR MENSAJE DE ÉXITO
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Registro exitoso. Por favor inicia sesión.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // ✅ REDIRECCIONAR A LOGIN (no a Dashboard)
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        });
      } else {
        // Manejar errores de validación del backend
        String errorMessage = result['message'];
        if (result['errors'] != null) {
          final errors = result['errors'] as Map<String, dynamic>;
          // Obtener el primer mensaje de error
          errorMessage = errors.values.first?.first ?? errorMessage;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6EE7B7), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: const [
                        Icon(
                          Icons.add_circle,
                          color: Color(0xFF4F46E5),
                          size: 32,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Registrar Cuenta',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A7A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Documento
                    CustomTextField(
                      label: 'Documento',
                      hint: 'Número de identificación',
                      controller: _documentController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese su documento';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nombre
                    CustomTextField(
                      label: 'Nombre',
                      hint: 'Tu nombre',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese su nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Apellido
                    CustomTextField(
                      label: 'Apellido',
                      hint: 'Tu apellido',
                      controller: _lastNameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese su apellido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    CustomTextField(
                      label: 'Email',
                      hint: 'correo@ejemplo.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese su email';
                        }
                        if (!value.contains('@')) {
                          return 'Email inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fecha de Nacimiento
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fecha Nacimiento',
                          style: TextStyle(
                            color: Color(0xFF1A1A7A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectDate,
                          child: AbsorbPointer(
                            child: CustomTextField(
                              label: '',
                              hint: _birthDateController.text.isEmpty
                                  ? 'Seleccionar fecha'
                                  : _birthDateController.text,
                              controller: _birthDateController,
                              suffixIcon: const Icon(
                                Icons.calendar_today,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Contraseña
                    CustomTextField(
                      label: 'Contraseña',
                      hint: '••••••••',
                      controller: _passwordController,
                      isPassword: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirmar Contraseña
                    CustomTextField(
                      label: 'Confirmar Contraseña',
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      isPassword: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Selector de Tipo de Usuario
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tipo de Usuario',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A7A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Paciente'),
                                  value: 'paciente',
                                  groupValue: _userType,
                                  activeColor: const Color(0xFF4F46E5),
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (value) {
                                    setState(() => _userType = value!);
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Médico'),
                                  value: 'medico',
                                  groupValue: _userType,
                                  activeColor: const Color(0xFF4F46E5),
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (value) {
                                    setState(() => _userType = value!);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón Registrar
                    CustomButton(
                      text: 'Registrar',
                      onPressed: _handleRegister,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Link a Login
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        '¿Ya tienes cuenta? Inicia sesión',
                        style: TextStyle(color: Color(0xFF4F46E5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _documentController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }
}

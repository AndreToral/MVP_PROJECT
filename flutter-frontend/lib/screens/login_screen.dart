import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/session_manager.dart';

// ⚠️ NO importar main.dart

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _feedbackMessage = '';
  bool _isSuccess = false;
  bool _isLoading = false;

  // Getter local para acceder a Supabase de forma segura
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Esperar un frame antes de verificar la autenticación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialAuth();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  void _navigateToDashboard() {
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
    }
  }

  void _checkInitialAuth() {
    try {
      if (_supabase.auth.currentUser != null) {
        SessionManager.isClassified().then((isClassified) {
          if (isClassified && mounted) {
            _navigateToDashboard();
          }
        });
      }
    } catch (e) {
      print('⚠️  Error verificando sesión inicial: $e');
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _feedbackMessage = '';
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      print('🔐 Intentando login con: $email');

      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final studentId = response.user!.id;
        await SessionManager.saveStudentId(studentId);

        print('✅ Login exitoso. User ID: $studentId');

        if (mounted) {
          setState(() {
            _feedbackMessage = '¡Inicio de sesión exitoso!';
            _isSuccess = true;
          });

          // Pequeño delay para que el usuario vea el mensaje
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            _navigateToDashboard();
          }
        }

      } else {
        throw Exception('El inicio de sesión falló por una razón desconocida.');
      }
    } on AuthException catch (e) {
      print('❌ Auth error: ${e.message}');
      if (mounted) {
        setState(() {
          _feedbackMessage = 'Error: ${e.message}';
          _isSuccess = false;
        });
      }
    } catch (e) {
      print('❌ Error inesperado: $e');
      if (mounted) {
        setState(() {
          _feedbackMessage = 'Ocurrió un error inesperado: $e';
          _isSuccess = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToSignUp() {
    Navigator.pushNamed(context, '/signup');
  }

  void _handleCancel() {
    if (Navigator.canPop(context)) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(color: kTextColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
            filled: true,
            fillColor: kOnPrimaryColor,
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: kSubtleTextColor, size: 20)
                : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 600;
    final double maxWidth = isDesktop ? 400 : screenWidth * 0.9;

    final Color messageBg = _isSuccess ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);
    final Color messageText = _isSuccess ? const Color(0xFF065F46) : const Color(0xFF991B1B);

    return Scaffold(
      backgroundColor: kScaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: Container(
            width: maxWidth,
            padding: EdgeInsets.all(isDesktop ? 40 : 25),
            decoration: BoxDecoration(
              color: kOnPrimaryColor,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -10,
                  right: -10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: kAccentColor, size: 28),
                    onPressed: _isLoading ? null : _handleCancel,
                    tooltip: 'Cancelar y volver',
                  ),
                ),
                
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.school, color: kPrimaryColor, size: 32),
                          const SizedBox(width: 8),
                          Text(
                            'Tutor VAK',
                            style: kHeadingStyle.copyWith(fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Inicia Sesión en tu Cuenta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Accede a tus temas de estudio personalizados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (_feedbackMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: messageBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _feedbackMessage,
                            style: TextStyle(color: messageText, fontSize: 14),
                          ),
                        ),

                      _buildInputField(
                        controller: _emailController, 
                        label: 'Correo electrónico', 
                        hintText: 'correo@ejemplo.com', 
                        keyboardType: TextInputType.emailAddress, 
                        suffixIcon: Icons.email_outlined,
                        validator: (value) => (value == null || !value.contains('@')) 
                            ? 'Introduce un correo electrónico válido.' 
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        controller: _passwordController, 
                        label: 'Contraseña', 
                        hintText: 'Ingresa tu contraseña', 
                        obscureText: true, 
                        suffixIcon: Icons.lock_outline,
                        validator: (value) => (value == null || value.length < 6) 
                            ? 'La contraseña debe tener al menos 6 caracteres.' 
                            : null,
                      ),
                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : () {
                            print('Olvidaste Contraseña presionado');
                          },
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              fontSize: 14,
                              color: kPrimaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlueButton,
                          foregroundColor: kOnPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 5,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: _isLoading 
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: kOnPrimaryColor, 
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text('Iniciar Sesión'),
                      ),
                      const SizedBox(height: 12),

                      OutlinedButton(
                        onPressed: _isLoading ? null : _handleCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kTextColor,
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Cancelar'),
                      ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: _isLoading ? null : _goToSignUp,
                        child: const Text(
                          '¿Aún no tienes cuenta? Regístrate aquí',
                          style: TextStyle(
                            fontSize: 14,
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
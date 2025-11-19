import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/session_manager.dart';

// ❌ NO importar main.dart

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  // ✅ Getter local para acceder a Supabase de forma segura
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      print('📝 Intentando registrar usuario: $email');

      // PASO 1: Registrar al usuario
      final AuthResponse signUpResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );

      if (signUpResponse.user == null) {
        throw Exception('Error al crear la cuenta');
      }

      print('✅ Usuario registrado: ${signUpResponse.user!.id}');

      // PASO 2: Hacer login automático para establecer la sesión
      print('🔄 Iniciando sesión automática...');
      final AuthResponse signInResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (signInResponse.user == null) {
        throw Exception('Error al iniciar sesión automáticamente');
      }

      final userId = signInResponse.user!.id;
      print('✅ Sesión establecida: $userId');
      
      // PASO 3: Guardar el ID
      await SessionManager.saveStudentId(userId);
      print('✅ ID guardado en SessionManager');
        
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso! Redirigiendo a tu clasificación inicial.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Pequeño delay para que el usuario vea el mensaje
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (mounted) {
          Navigator.pushReplacementNamed(
            context, 
            '/classification',
          );
        }
      

      } else {
        throw Exception('Error desconocido al registrar.');
      }
    } on AuthException catch (e) {
      print('❌ Error de autenticación: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de registro: ${e.message}'),
            backgroundColor: kAccentColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Error inesperado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocurrió un error inesperado: $e'),
            backgroundColor: kAccentColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToLogin() {
    Navigator.pushNamed(context, '/login');
  }

  void _handleCancel() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
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
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final double maxWidth = isDesktop ? 400 : MediaQuery.of(context).size.width * 0.9;

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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crea tu Cuenta',
                    textAlign: TextAlign.center,
                    style: kHeadingStyle.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Únete a UniPrep AI para descubrir tu potencial académico.',
                    textAlign: TextAlign.center,
                    style: kSubtitleStyle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  _buildInputField(
                    controller: _nameController, 
                    label: 'Nombre completo', 
                    hintText: 'Tu nombre',
                    validator: (value) => (value == null || value.isEmpty) 
                        ? 'Por favor, introduce tu nombre.' 
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _emailController, 
                    label: 'Correo electrónico', 
                    hintText: 'correo@ejemplo.com', 
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => (value == null || !value.contains('@')) 
                        ? 'Por favor, introduce un correo electrónico válido.' 
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: _passwordController, 
                    label: 'Contraseña', 
                    hintText: 'Mínimo 8 caracteres', 
                    obscureText: true,
                    validator: (value) => (value == null || value.length < 8) 
                        ? 'La contraseña debe tener al menos 8 caracteres.' 
                        : null,
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegistration,
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
                        : const Text('Registrarse'),
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
                    onPressed: _isLoading ? null : _goToLogin,
                    child: const Text(
                      '¿Ya tienes cuenta? Inicia sesión aquí',
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
          ),
        ),
      ),
    );
  }
}
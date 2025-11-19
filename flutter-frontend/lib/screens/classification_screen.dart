import 'package:flutter/material.dart';
import '../utils/constants.dart'; 
import '../services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/session_manager.dart';

// ⚠️ NO importar main.dart

class ClassificationScreen extends StatefulWidget {
  const ClassificationScreen({super.key});

  @override
  State<ClassificationScreen> createState() => _ClassificationScreenState();
}

class _ClassificationScreenState extends State<ClassificationScreen> {
  // ✅ Getter local para acceder a Supabase
  SupabaseClient get _supabase => Supabase.instance.client;
  
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _selectedOption;
  String _statusMessage = 'Selecciona tu opción preferida para aprender.';
  String? _currentUserId; // Guardar el ID del usuario

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  // ✅ Simplificado: Solo obtener desde Supabase o SessionManager
  Future<void> _initializeUser() async {
    print('🔄 Inicializando usuario...');
    
    // 1. Intentar desde Supabase (debería funcionar ahora con el login automático)
    final user = _supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
        _statusMessage = '✅ Usuario autenticado. Selecciona tu opción.';
      });
      print('✅ Usuario obtenido desde Supabase: ${user.id}');
      await SessionManager.saveStudentId(user.id);
      return;
    }
    
    // 2. Si no está en Supabase, intentar desde SessionManager
    final savedId = await SessionManager.getStudentId();
    if (savedId != null) {
      setState(() {
        _currentUserId = savedId;
        _statusMessage = '✅ Usuario recuperado. Selecciona tu opción.';
      });
      print('✅ Usuario obtenido desde SessionManager: $savedId');
      return;
    }
    
    // 3. Si no hay usuario, redirigir al login
    if (mounted) {
      setState(() {
        _statusMessage = '❌ Sesión no encontrada. Redirigiendo al login...';
      });
      print('❌ No se encontró usuario. Redirigiendo al login...');
      
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  final Map<String, String> _optionsMap = {
    'visual': 'Prefiero diagramas, ver videos y tomar notas con muchos colores.',
    'auditory': 'Me gusta escuchar clases, debatir conceptos y repetir ideas en voz alta.',
    'kinesthetic': 'Necesito experimentar de a mano propia, manipular materiales o realizar simulaciones prácticas.',
  };

  void _classifyStyle() async {
    if (_selectedOption == null) {
      setState(() => _statusMessage = 'Por favor, selecciona una opción.');
      return;
    }

    // ✅ Verificar que tengamos el userId
    if (_currentUserId == null) {
      setState(() => _statusMessage = '❌ Error: Usuario no autenticado. Reintentando...');
      
      // Reintentar inicializar
      await _initializeUser();
      
      // Si aún no hay usuario, abortar
      if (_currentUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor, inicia sesión nuevamente.'),
              backgroundColor: kAccentColor,
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }
    }

    final String textToSend = _optionsMap[_selectedOption]!;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Clasificando tu estilo...';
    });

    try {
      print('📤 Enviando clasificación para usuario: $_currentUserId');
      
      final result = await _apiService.classifyStyle(textToSend, _currentUserId!);
      final style = result['estilo_aprendizaje'];

      print('✅ Clasificación exitosa: $style');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ ¡Clasificado como $style!'),
          backgroundColor: const Color(0xFF10B981),
        ));

        // Esperar un poco antes de navegar
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }

    } catch (e) {
      print('❌ Error en clasificación: $e');
      if (mounted) {
        setState(() => _statusMessage = '❌ Error de clasificación. Intenta de nuevo.');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: kAccentColor,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackgroundColor, 
      appBar: AppBar(
        title: const Text('Test de Estilo de Aprendizaje'),
        backgroundColor: kPrimaryColor,
        foregroundColor: kOnPrimaryColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Container(
              padding: const EdgeInsets.all(30),
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                color: kOnPrimaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Clasificación VAK',
                    textAlign: TextAlign.center,
                    style: kHeadingStyle.copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pregunta VAK: ¿Qué método te ayuda más a retener información nueva y compleja?',
                    textAlign: TextAlign.center,
                    style: kSubtitleStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  ..._optionsMap.keys.map((key) {
                    return RadioListTile<String>(
                      title: Text(
                        _optionsMap[key]!,
                        style: const TextStyle(color: kTextColor),
                      ),
                      value: key,
                      groupValue: _selectedOption,
                      activeColor: kPrimaryColor, 
                      onChanged: (String? value) {
                        setState(() => _selectedOption = value);
                      },
                    );
                  }).toList(),

                  const SizedBox(height: 30),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _classifyStyle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlueButton,
                      foregroundColor: kOnPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: kOnPrimaryColor, strokeWidth: 3),
                          )
                        : const Text('Clasificar mi Estilo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    _statusMessage, 
                    textAlign: TextAlign.center, 
                    style: TextStyle(
                      fontSize: 14,
                      color: _statusMessage.startsWith('❌') ? kAccentColor : kSubtleTextColor,
                      fontWeight: FontWeight.w600,
                    )
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
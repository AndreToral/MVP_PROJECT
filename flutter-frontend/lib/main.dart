import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/landing_page.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/agent_screen.dart';
import 'screens/classification_screen.dart';
import 'screens/dashboard_screen.dart';
import 'utils/constants.dart';
import 'config/env_config.dart';

void main() async {
  print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  print("🚀 INICIO - main() ejecutándose");
  print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  
  WidgetsFlutterBinding.ensureInitialized();
  print("✅ 1. Flutter inicializado");

  // ⚠️ SOLUCIÓN: En lugar de usar .env, define las variables aquí directamente
  // TODO: Cuando despliegues a producción, usa variables de entorno del servidor

  try {
    print("🔄 2. Inicializando Supabase...");
    print("   URL: ${EnvConfig.supabaseUrl.substring(0, 30)}...");
    
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
    
    print("✅ 2. Supabase inicializado correctamente");
    
    // Verificación
    final client = Supabase.instance.client;
    print("✅ 3. Cliente verificado");
    print("   Current user: ${client.auth.currentUser?.id ?? 'No autenticado'}");
    
  } catch (e, stackTrace) {
    print("❌ Error inicializando Supabase:");
    print("   $e");
    print("   $stackTrace");
  }

  print("🎨 4. Iniciando aplicación...");
  print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniPrep AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/agent': (context) => const AgentScreen(),
        '/classification': (context) => const ClassificationScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          print("❌ ERROR CAPTURADO:");
          print(errorDetails.exception);
          print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 20),
                    const Text(
                      '❌ Error en la aplicación',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      errorDetails.exception.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return widget ?? const SizedBox.shrink();
      },
    );
  }
}
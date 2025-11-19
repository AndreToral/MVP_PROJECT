import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/session_manager.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ✅ Getter local para acceder a Supabase
  SupabaseClient get _supabase => Supabase.instance.client;
  
  String? userName;
  String? userEmail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    try {
      // ✅ Usar _supabase en lugar de supabase
      final user = _supabase.auth.currentUser;
      
      if (user != null) {
        setState(() {
          userName = user.userMetadata?['full_name'] ?? 'Usuario';
          userEmail = user.email;
          isLoading = false;
        });
        
        print('✅ Usuario cargado: $userName ($userEmail)');
        
        // Puedes hacer más llamadas si necesitas
        // ✅ Usar _supabase
        final response = await _supabase
            .from('students')
            .select()
            .eq('id', user.id)
            .maybeSingle();
            
        if (response != null) {
          print('✅ Datos del estudiante: $response');
        }
      } else {
        print('⚠️  No hay usuario autenticado');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print('❌ Error cargando datos: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      print('🔓 Cerrando sesión...');
      
      // ✅ Usar _supabase
      await _supabase.auth.signOut();
      await SessionManager.clearSession();
      
      print('✅ Sesión cerrada');
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: kAccentColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: kScaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kScaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        foregroundColor: kOnPrimaryColor,
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de bienvenida
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 48, color: kPrimaryColor),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Bienvenido, $userName!',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: kTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userEmail ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: kSubtleTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Acciones rápidas
            const Text(
              'Acciones Rápidas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  icon: Icons.search,
                  title: 'Buscar Contenido',
                  onTap: () => Navigator.pushNamed(context, '/agent'),
                ),
                _buildActionCard(
                  icon: Icons.assessment,
                  title: 'Test VAK',
                  onTap: () => Navigator.pushNamed(context, '/classification'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: kPrimaryColor),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
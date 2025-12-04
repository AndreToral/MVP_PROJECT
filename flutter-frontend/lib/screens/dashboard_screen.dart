// lib/screens/dashboard_screen.dart (VERSIÓN ACTUALIZADA)

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/session_manager.dart';
import 'quiz_screen.dart'; // 🆕 IMPORTAR PANTALLA DE QUIZ

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SupabaseClient get _supabase => Supabase.instance.client;
  final ApiService _apiService = ApiService();
  
  String _userName = 'Estudiante';
  String _userEmail = '';
  String _learningStyle = 'Cargando...';
  bool _isLoading = true;
  
  // 🆕 DATOS DE APRENDIZAJE ADAPTATIVO
  List<Map<String, dynamic>> _topicsToReview = [];
  int _studyStreak = 0;
  int _topicsMastered = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      final userName = user.userMetadata?['full_name'] ?? 'Estudiante';
      
      // Obtener estilo de aprendizaje
      final styleResponse = await _supabase
          .from('students')
          .select('learning_style')
          .eq('id', user.id)
          .maybeSingle();
      
      // 🆕 OBTENER TEMAS PENDIENTES DE REVISIÓN
      final topicsToReview = await _apiService.getTopicsForReview(user.id);
      
      // 🆕 OBTENER PROGRESO
      final progressResponse = await _supabase
          .from('student_progress')
          .select('study_streak_days, total_topics_mastered')
          .eq('student_id', user.id)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          _userName = userName;
          _userEmail = user.email ?? '';
          _learningStyle = styleResponse?['learning_style'] ?? 'No clasificado';
          _topicsToReview = topicsToReview;
          _studyStreak = progressResponse?['study_streak_days'] ?? 0;
          _topicsMastered = progressResponse?['total_topics_mastered'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando datos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _supabase.auth.signOut();
      await SessionManager.clearSession();
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
    }
  }

  Color _getStyleColor() {
    switch (_learningStyle.toLowerCase()) {
      case 'visual':
        return const Color(0xFF3B82F6);
      case 'auditory':
        return const Color(0xFF10B981);
      case 'kinesthetic':
        return const Color(0xFFF59E0B);
      default:
        return kPrimaryColor;
    }
  }

  IconData _getStyleIcon() {
    switch (_learningStyle.toLowerCase()) {
      case 'visual':
        return Icons.visibility_outlined;
      case 'auditory':
        return Icons.headphones_outlined;
      case 'kinesthetic':
        return Icons.touch_app_outlined;
      default:
        return Icons.psychology_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: kPrimaryColor),
              const SizedBox(height: 20),
              const Text('Cargando tu dashboard...', style: TextStyle(color: kSubtleTextColor)),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          // AppBar personalizado
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kPrimaryColor,
                      kPrimaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              child: Text(
                                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¡Bienvenido, $_userName!',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    _userEmail,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
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
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _handleLogout,
                tooltip: 'Cerrar sesión',
              ),
            ],
          ),

          // Contenido principal
          SliverPadding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Tarjeta de Estilo de Aprendizaje
                _buildStyleCard(),
                const SizedBox(height: 24),

                // 🆕 SECCIÓN DE ESTADÍSTICAS
                _buildStatsSection(),
                const SizedBox(height: 24),

                // 🆕 TEMAS PENDIENTES DE REVISIÓN
                if (_topicsToReview.isNotEmpty) ...[
                  const Text(
                    '📚 Temas Pendientes de Revisión',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._topicsToReview.map((topic) => _TopicToReviewCard(
                    topicName: topic['topic_name'],
                    masteryScore: (topic['mastery_score'] * 100).toInt(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizScreen(
                            topicId: topic['id'],
                            topicName: topic['topic_name'],
                            learningStyle: _learningStyle,
                          ),
                        ),
                      ).then((_) => _loadUserData()); // Recargar al volver
                    },
                  )).toList(),
                  const SizedBox(height: 24),
                ],

                // Título de Acciones Rápidas
                const Text(
                  'Acciones Rápidas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Grid de Acciones
                isMobile
                    ? Column(
                        children: [
                          _ActionCard(
                            icon: Icons.search,
                            title: 'Buscar Contenido',
                            description: 'Encuentra material adaptado a tu estilo',
                            color: const Color(0xFF3B82F6),
                            onTap: () => Navigator.pushNamed(context, '/agent')
                                .then((_) => _loadUserData()),
                          ),
                          const SizedBox(height: 16),
                          _ActionCard(
                            icon: Icons.assessment,
                            title: 'Test VAK',
                            description: 'Actualiza tu clasificación',
                            color: const Color(0xFF8B5CF6),
                            onTap: () => Navigator.pushNamed(context, '/classification'),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.search,
                              title: 'Buscar Contenido',
                              description: 'Encuentra material adaptado a tu estilo',
                              color: const Color(0xFF3B82F6),
                              onTap: () => Navigator.pushNamed(context, '/agent')
                                  .then((_) => _loadUserData()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.assessment,
                              title: 'Test VAK',
                              description: 'Actualiza tu clasificación',
                              color: const Color(0xFF8B5CF6),
                              onTap: () => Navigator.pushNamed(context, '/classification'),
                            ),
                          ),
                        ],
                      ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getStyleColor(),
            _getStyleColor().withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getStyleColor().withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getStyleIcon(),
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu Estilo de Aprendizaje',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _learningStyle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStyleDescription(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 SECCIÓN DE ESTADÍSTICAS
  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            value: '$_studyStreak',
            label: 'Racha de días',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events,
            value: '$_topicsMastered',
            label: 'Temas dominados',
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.schedule,
            value: '${_topicsToReview.length}',
            label: 'Pendientes',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  String _getStyleDescription() {
    switch (_learningStyle.toLowerCase()) {
      case 'visual':
        return 'Aprendes mejor con diagramas, imágenes y videos';
      case 'auditory':
        return 'Aprendes mejor escuchando y discutiendo';
      case 'kinesthetic':
        return 'Aprendes mejor con práctica y experiencia';
      default:
        return 'Completa el test para descubrir tu estilo';
    }
  }
}

// 🆕 WIDGET DE ESTADÍSTICA
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// 🆕 WIDGET DE TEMA PENDIENTE
class _TopicToReviewCard extends StatelessWidget {
  final String topicName;
  final int masteryScore;
  final VoidCallback onTap;

  const _TopicToReviewCard({
    required this.topicName,
    required this.masteryScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.quiz,
                    color: kPrimaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topicName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Dominio: $masteryScore%',
                            style: TextStyle(
                              fontSize: 13,
                              color: masteryScore >= 80
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: kSubtleTextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget de Tarjeta de Acción (ya existía)
class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _isHovered 
                      ? widget.color.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: _isHovered ? 20 : 10,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 32,
                    color: widget.color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: kSubtleTextColor,
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
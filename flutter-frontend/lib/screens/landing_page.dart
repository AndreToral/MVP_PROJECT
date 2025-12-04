import 'package:flutter/material.dart';
import '../utils/constants.dart'; // Importa las constantes

// --- PÁGINA DE ATERRIZAJE (LANDING PAGE) ---

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  // --- FUNCIÓN DE NAVEGACIÓN ACTUALIZADA ---
  void _handleNavigation(BuildContext context, String routeName) {
    // Si la ruta es '/login' o '/signup', navegamos.
    // Para otros enlaces (Inicio, Blog), mantenemos la simulación.
    if (routeName == '/signup' || routeName == '/login') {
      Navigator.pushNamed(context, routeName);
    } else {
      // Simulación para otras rutas (Inicio, Blog)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Simulación de navegación: Ir a "$routeName"')),
      );
      print('Navegando a: $routeName');
    }
  }

  // 1. WIDGET DEL HEADER
  Widget _buildHeader(BuildContext context, bool isMobile, double paddingHorizontal) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0.5,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : paddingHorizontal),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo y Título
            Row(
              children: [
                const Icon(Icons.school, color: kPrimaryColor, size: 28),
                const SizedBox(width: 8),
                Text(
                  'UniPrep AI',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    color: kTextColor,
                  ),
                ),
              ],
            ),

            // Botones de Navegación (Desktop/Tablet)
            if (!isMobile)
              Row(
                children: [
                  TextButton(
                    onPressed: () => _handleNavigation(context, 'Inicio'),
                    child: const Text('Inicio', style: TextStyle(color: kSubtleTextColor)),
                  ),
                  TextButton(
                    // --- NAVEGACIÓN ACTUALIZADA A LOGIN ---
                    onPressed: () => _handleNavigation(context, '/login'),
                    child: const Text('Iniciar Sesión', style: TextStyle(color: kSubtleTextColor)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    // --- NAVEGACIÓN ACTUALIZADA A SIGNUP ---
                    onPressed: () => _handleNavigation(context, '/signup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: kOnPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Crear Cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

            // Icono de Menú (Mobile)
            if (isMobile)
              IconButton(
                icon: const Icon(Icons.menu, color: kSubtleTextColor),
                onPressed: () => print('Menú móvil abierto'),
              ),
          ],
        ),
      ),
    );
  }

  // 2. WIDGET DE LA HERO SECTION
  Widget _buildHeroSection(BuildContext context, bool isMobile) {
    final heroContent = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Título Principal
        Text.rich(
          TextSpan(
            text: 'Descubre tu Potencial de Aprendizaje con ',
            style: kHeadingStyle.copyWith(fontSize: isMobile ? 36 : 48),
            children: const <TextSpan>[
              TextSpan(
                text: 'Tutor VAK Universitario',
                style: TextStyle(color: kPrimaryColor),
              ),
            ],
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 20),

        // Subtítulo
        Text(
          'Tutor VAK Universitario te ayuda a identificar tu estilo de aprendizaje único (Visual, Auditivo, Kinestésico) y te conecta con recursos y temas de estudio personalizados. Optimiza tu rendimiento académico y haz que el aprendizaje sea más efectivo y disfrutable.',
          style: kSubtitleStyle.copyWith(fontSize: isMobile ? 16 : 18),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 30),

        // Botones de Acción
        Row(
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          children: [
            ElevatedButton(
              // --- NAVEGACIÓN ACTUALIZADA A SIGNUP ---
              onPressed: () => _handleNavigation(context, '/signup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: kOnPrimaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                elevation: 5,
              ),
              child: const Text('Crear Cuenta'),
            ),
            const SizedBox(width: 16),
            TextButton(
              // --- NAVEGACIÓN ACTUALIZADA A LOGIN ---
              onPressed: () => _handleNavigation(context, '/login'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryColor),
              ),
              child: const Text('Iniciar Sesión', style: TextStyle(color: kPrimaryColor)),
            ),
          ],
        ),
      ],
    );

    // Contenedor de la Imagen
    final heroImage = Container(
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          './flutter-frontend/assets/images/hero_image.png',
          fit: BoxFit.cover,
        ),
      ),
    );

    // Lógica Responsive
    if (isMobile) {
      return Column(
        children: [
          heroContent,
          const SizedBox(height: 40),
          heroImage,
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: heroContent),
          const SizedBox(width: 40),
          Expanded(child: heroImage),
        ],
      );
    }
  }

  // 3. WIDGET DE LA SECCIÓN DE BENEFICIOS
  Widget _buildBenefitsSection(BuildContext context, bool isMobile, double paddingHorizontal) {
    final List<Map<String, dynamic>> benefits = [
      {
        'icon': Icons.lightbulb_outline,
        'title': 'Identifica tu Estilo VAK',
        'description': 'Realiza nuestra evaluación interactiva para descubrir si aprendes mejor visualizando, escuchando o haciendo.',
      },
      {
        'icon': Icons.headset_mic_outlined,
        'title': 'Contenido Personalizado',
        'description': 'Accede a una biblioteca de recursos curados específicamente para tu estilo VAK dominante, optimizando tu comprensión.',
      },
      {
        'icon': Icons.pan_tool_outlined,
        'title': 'Mejora tu Rendimiento',
        'description': 'Transforma tu experiencia de estudio con técnicas y materiales que se adaptan a cómo tu mente procesa la información.',
      },
    ];

    return Container(
      color: const Color(0xFFF9FAFB),
      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: isMobile ? 60 : 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Beneficios de Aprender con Tutor VAK Universitario',
            style: kHeadingStyle.copyWith(fontSize: isMobile ? 28 : 36, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          
          // ✅ Usar el nuevo BenefitCard con hover
          isMobile
              ? Column(
                  children: benefits.map((b) => BenefitCard(
                    icon: b['icon'] as IconData,
                    title: b['title'] as String,
                    description: b['description'] as String,
                  )).toList(),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: benefits.map((b) => Expanded(
                    child: BenefitCard(
                      icon: b['icon'] as IconData,
                      title: b['title'] as String,
                      description: b['description'] as String,
                    ),
                  )).toList(),
                ),
        ],
      ),
    );
  }

  

  // 4. WIDGET DEL FOOTER
  Widget _buildFooterSection(double paddingHorizontal) {
    final List<Widget> footerItems = [
      // Columna 1: Descripción y Redes Sociales
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tutor VAK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          const Text(
            'Helping university students find their ideal study topics.',
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)), // Gris 400
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(Icons.share, color: Color(0xFF9CA3AF), size: 24),
              SizedBox(width: 12),
              Icon(Icons.email, color: Color(0xFF9CA3AF), size: 24),
              SizedBox(width: 12),
              Icon(Icons.link, color: Color(0xFF9CA3AF), size: 24),
            ],
          ),
        ],
      ),

      // Columna 2: Compañía
      _buildFooterLinkColumn('Compañía', ['Acerca de Nosotros', 'Carreras', 'Blog']),

      // Columna 3: Soporte
      _buildFooterLinkColumn('Soporte', ['Centro de Ayuda', 'Términos de Servicio', 'Política de Privacidad']),
    ];

    return Container(
      color: const Color(0xFF1F2937), // Gris 800
      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 40),
      child: Column(
        children: [
          // Enlaces principales del Footer (usando Wrap para adaptarse a móvil)
          Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: footerItems,
          ),

          const Divider(height: 40, color: Color(0xFF374151)), // Gris 700

          // Copyright
          const Text(
            '© 2025 Tutor VAK Universitario. All rights reserved.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)), // Gris 500
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper para construir las columnas de enlaces del Footer
  Widget _buildFooterLinkColumn(String title, List<String> links) {
    return SizedBox(
      width: 150, // Permite un ancho fijo para las columnas en desktop/tablet
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          ...links.map((link) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: TextButton(
              onPressed: () => print('Navegar a $link'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                link,
                style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)), // Gris 400
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Usamos LayoutBuilder para adaptar la vista a diferentes tamaños (responsive)
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        final paddingHorizontal = isMobile ? 24.0 : 48.0;

        return Scaffold(
          // 1. HEADER (Barra de Navegación)
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60.0),
            child: _buildHeader(context, isMobile, paddingHorizontal),
          ),

          // El cuerpo usa un CustomScrollView para desplazarse y usar Slivers
          body: CustomScrollView(
            slivers: [
              // 2. HERO SECTION
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: isMobile ? 40 : 80),
                  child: _buildHeroSection(context, isMobile),
                ),
              ),

              // 3. BENEFICIOS SECTION
              SliverToBoxAdapter(
                child: _buildBenefitsSection(context, isMobile, paddingHorizontal),
              ),

              // 4. FOOTER
              SliverToBoxAdapter(
                child: _buildFooterSection(paddingHorizontal),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ✅ Widget BenefitCard con efecto hover (agregar al final de la clase)
class BenefitCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;

  const BenefitCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  State<BenefitCard> createState() => _BenefitCardState();
}

class _BenefitCardState extends State<BenefitCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        // ✨ Escala de 1.0 a 1.05 (5% más grande)
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
        margin: const EdgeInsets.all(12),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          // ✨ Sombra más pronunciada al hover
          elevation: _isHovered ? 16 : 8,
          shadowColor: _isHovered 
              ? const Color(0xFF4F46E5).withOpacity(0.3) 
              : Colors.black.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // ✨ Gradiente sutil al hacer hover
              gradient: _isHovered
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        const Color(0xFF4F46E5).withOpacity(0.05),
                      ],
                    )
                  : null,
              color: _isHovered ? null : Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✨ Icono con animación
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isHovered 
                        ? const Color(0xFF4F46E5).withOpacity(0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 48,
                    color: _isHovered 
                        ? const Color(0xFF4F46E5) 
                        : const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Título con color animado
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _isHovered 
                        ? const Color(0xFF4F46E5) 
                        : const Color(0xFF6366F1),
                  ),
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Descripción
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
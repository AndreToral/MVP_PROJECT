// lib/screens/agent_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Importación clave
import 'package:url_launcher/url_launcher.dart'; // Para abrir enlaces
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../utils/session_manager.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _topicController = TextEditingController();
  String? _studentId;
  String _contentResult = 'Escribe un tema universitario y haz clic en "Buscar" para obtener contenido adaptado.';
  bool _isLoading = false;
  String? _styleUsed;

  @override
  void initState() {
    super.initState();
    _loadStudentId();
  }

  void _loadStudentId() async {
    final id = await SessionManager.getStudentId();
    setState(() {
      _studentId = id;
      if (_studentId == null) {
        _contentResult = 'Error: ID de estudiante no encontrado. Por favor, reinicia la clasificación.';
      }
    });
  }

  void _searchContent() async {
    if (_studentId == null || _topicController.text.isEmpty) {
      setState(() => _contentResult = 'Error: ID no cargado o el tema está vacío.');
      return;
    }

    setState(() {
      _isLoading = true;
      _contentResult = 'Buscando y adaptando contenido...';
      _styleUsed = null;
    });

    try {
      // 1. Llamar a la API de Node.js (Obtener Estilo + Generación Gemini + Logs)
      final content = await _apiService.searchContent(_topicController.text, _studentId!);
      
      // Podrías modificar la API para que devuelva el estilo si quieres mostrarlo aquí.
      
      setState(() {
        // _contentResult ahora contiene el Markdown de Gemini
        _contentResult = content; 
      });

    } catch (e) {
      setState(() => _contentResult = '❌ Error al buscar contenido. Verifica la conexión o el tema.');
      // Usar print para el log completo, SnackBar para una notificación breve.
      print(e); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al buscar contenido.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Función clave para abrir enlaces externos
  void _onLinkTap(String? text, String? href, String? title) async {
    if (href != null) {
      final url = Uri.parse(href);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Manejo de error si no se puede abrir el enlace
        if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No se pudo abrir el enlace: $href')),
            );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💡 Tutor Universitario VAK', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Nuevo botón para volver al Dashboard
          IconButton(
            icon: const Icon(LucideIcons.layoutDashboard, color: Colors.white),
            tooltip: 'Regresar al Dashboard',
            onPressed: () {
              // Navigator.pop(context) cierra la pantalla actual y regresa a la anterior (Dashboard)
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                border: Border(left: BorderSide(color: Colors.indigo.shade700, width: 4)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _studentId != null 
                    ? '✅ Clasificado. ID: ${_studentId!.substring(0, 8)}...' 
                    : '⚠️ Cargando ID de estudiante...',
                style: TextStyle(
                  color: Colors.indigo.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Campo de entrada del tema
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: 'Tema de Estudio',
                hintText: 'Ej: Equilibrio de Nash',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.indigo.shade500, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Botón de búsqueda
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _searchContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5,
              ),
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : const Icon(Icons.search),
              label: Text(_isLoading ? 'Buscando...' : 'Buscar Contenido Adaptado', style: const TextStyle(fontSize: 16)),
            ),
            const Divider(height: 30),

            // Área de resultados (USANDO MARKDOWN CON SELECCIÓN COMPLETA)
            Expanded(
              child: SelectionArea( // SelectionArea envuelve todo el contenedor
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Markdown(
                    data: _contentResult, // El texto Markdown de Gemini
                    shrinkWrap: true, // Importante para que funcione dentro del SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Desactiva el scroll interno de Markdown
                    selectable: true, // Permite selección
                    onTapLink: _onLinkTap, // FUNCIÓN CLAVE: Habilitar clics en enlaces
                    
                    // Opcional: Personalización de estilos para una mejor estética
                    styleSheet: MarkdownStyleSheet(
                      // Estilo para títulos H1
                      h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                      // Estilo para títulos H2
                      h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                      // Estilo para títulos H3
                      h3: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.indigo.shade500),
                      // Estilo para enlaces (referencias)
                      a: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                      // Estilo para bloques de código
                      code: const TextStyle(backgroundColor: Color(0xFFE0E0E0), color: Colors.black, fontFamily: 'monospace'),
                      // Estilo para listas no ordenadas (Kinestésico/Visual)
                      listBullet: TextStyle(fontSize: 14, color: Colors.indigo.shade500),
                      // Estilo general del texto
                      p: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
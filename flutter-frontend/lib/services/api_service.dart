// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

// NOTA: Usa la URL de tu API de Node.js desplegada en Railway o localmente
const String _baseUrl = EnvConfig.apiBaseUrl; 

class ApiService {
  // ----------------------------------------------------
  // ENDPOINT 1: CLASIFICACIÓN VAK (ACTUALIZADO)
  // ----------------------------------------------------
  // Ahora recibe el ID del usuario autenticado (userId)
  Future<Map<String, dynamic>> classifyStyle(String textEs, String userId) async {
    final url = Uri.parse('$_baseUrl/classify-style');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text_espanol': textEs,
        // *** CAMBIO CLAVE: Enviamos el ID del usuario al backend ***
        'user_id': userId, 
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // El backend ahora usará este 'user_id' para registrar en la tabla 'students'
      return data; // Contiene 'estilo_aprendizaje' y 'student_id' (que debería ser igual a userId)
    } else {
      // Intentamos decodificar el mensaje de error del backend si existe
      String errorMessage = 'Fallo la clasificacion: ${response.statusCode}';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData.containsKey('message')) {
          errorMessage = 'Fallo la clasificacion: ${errorData['message']}';
        }
      } catch (_) {
        // Si no se puede decodificar el JSON, usamos el mensaje por defecto
        errorMessage += ' - Cuerpo de respuesta: ${response.body}';
      }
      throw Exception(errorMessage);
    }
  }

  // ----------------------------------------------------
  // ENDPOINT 2: BÚSQUEDA DE CONTENIDO (MANTENIDO)
  // ----------------------------------------------------
  // Asumo que 'studentId' aquí es el mismo ID de Supabase
  Future<String> searchContent(String topic, String studentId) async {
    final url = Uri.parse('$_baseUrl/content-agent');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'topic': topic,
        'student_id': studentId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['contenido']; // Retorna solo el contenido adaptado
    } else {
      String errorMessage = 'Fallo la busqueda: ${response.statusCode}';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData.containsKey('message')) {
          errorMessage = 'Fallo la busqueda: ${errorData['message']}';
        }
      } catch (_) {
        errorMessage += ' - Cuerpo de respuesta: ${response.body}';
      }
      throw Exception(errorMessage);
    }
  }

  // ========== 🆕 MÉTODOS DE APRENDIZAJE ADAPTATIVO ==========
  
  /// Generar un quiz adaptativo
  Future<Map<String, dynamic>> generateQuiz(
    String topicName,
    int difficultyLevel,
    String learningStyle,
  ) async {
    final url = Uri.parse('$_baseUrl/learning/generate-quiz');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'topic_name': topicName,
        'difficulty_level': difficultyLevel,
        'learning_style': learningStyle,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error generando quiz: ${response.statusCode}');
    }
  }

  /// Enviar resultados del quiz
  Future<Map<String, dynamic>> submitQuizResults(
    String learningTopicId,
    String studentId,
    double score,
    int timeSpentSeconds,
    List<Map<String, dynamic>> questionsData,
  ) async {
    final url = Uri.parse('$_baseUrl/learning/submit-quiz');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'learning_topic_id': learningTopicId,
        'student_id': studentId,
        'score': score,
        'time_spent_seconds': timeSpentSeconds,
        'questions_data': questionsData,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error enviando resultados: ${response.statusCode}');
    }
  }

  /// Obtener temas pendientes de revisión
  Future<List<Map<String, dynamic>>> getTopicsForReview(String studentId) async {
    final url = Uri.parse('$_baseUrl/learning/topics-to-review?student_id=$studentId');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['topics_to_review']);
    } else {
      throw Exception('Error obteniendo temas: ${response.statusCode}');
    }
  }

  /// Obtener progreso del estudiante
  Future<Map<String, dynamic>> getStudentProgress(String studentId) async {
    final url = Uri.parse('$_baseUrl/learning/student-progress?student_id=$studentId');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error obteniendo progreso: ${response.statusCode}');
    }
  }
}
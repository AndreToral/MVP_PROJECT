// lib/utils/session_manager.dart
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _keyStudentId = 'student_id';

  // Guarda el ID después de la clasificación
  static Future<void> saveStudentId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStudentId, id);
  }

  // Obtiene el ID para futuras búsquedas
  static Future<String?> getStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyStudentId);
  }

  // Verifica si el test ya fue completado
  static Future<bool> isClassified() async {
    return await getStudentId() != null;
  }

  /// Limpia la sesión (ej: al cerrar sesión).
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStudentId);
  }
}
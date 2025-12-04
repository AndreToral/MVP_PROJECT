// lib/screens/quiz_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizScreen extends StatefulWidget {
  final String topicId;
  final String topicName;
  final String learningStyle;

  const QuizScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.learningStyle,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  List<int?> _userAnswers = [];
  DateTime? _startTime;
  
  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final quiz = await _apiService.generateQuiz(
        widget.topicName,
        1, // difficulty_level
        widget.learningStyle,
      );
      
      setState(() {
        _questions = List<Map<String, dynamic>>.from(quiz['questions']);
        _userAnswers = List<int?>.filled(_questions.length, null);
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando quiz: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar el quiz'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _submitQuiz() async {
    // Calcular score
    int correctAnswers = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i]['correct_answer']) {
        correctAnswers++;
      }
    }
    
    final score = correctAnswers / _questions.length;
    final timeSpent = DateTime.now().difference(_startTime!).inSeconds;
    
    try {
      final result = await _apiService.submitQuizResults(
        widget.topicId,
        Supabase.instance.client.auth.currentUser!.id,
        score,
        timeSpent,
        _questions,
      );
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  result['mastery_achieved'] ? Icons.emoji_events : Icons.trending_up,
                  color: result['mastery_achieved'] ? Colors.amber : Colors.blue,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(result['mastery_achieved'] ? '¡Maestría!' : '¡Bien hecho!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Puntuación: ${(score * 100).toInt()}%'),
                const SizedBox(height: 8),
                Text('Dominio: ${(result['new_mastery'] * 100).toInt()}%'),
                const SizedBox(height: 8),
                Text(
                  'Próxima revisión: ${_formatDate(result['next_review_at'])}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo
                  Navigator.pop(context); // Volver a dashboard
                },
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error enviando quiz: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar resultados'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final diff = date.difference(now);
    
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Mañana';
    return '${diff.inDays} días';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cargando Quiz...'),
          backgroundColor: kPrimaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.topicName}'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
            ),
            const SizedBox(height: 20),
            
            // Question number
            Text(
              'Pregunta ${_currentQuestionIndex + 1} de ${_questions.length}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Question text
            Text(
              question['question'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Options
            ...List<Widget>.generate(
              (question['options'] as List).length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _userAnswers[_currentQuestionIndex] = index;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    side: BorderSide(
                      color: _userAnswers[_currentQuestionIndex] == index
                          ? kPrimaryColor
                          : Colors.grey,
                      width: 2,
                    ),
                    backgroundColor: _userAnswers[_currentQuestionIndex] == index
                        ? kPrimaryColor.withOpacity(0.1)
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _userAnswers[_currentQuestionIndex] == index
                              ? kPrimaryColor
                              : Colors.grey[300],
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: TextStyle(
                              color: _userAnswers[_currentQuestionIndex] == index
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question['options'][index],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const Spacer(),
            
            // Navigation buttons
            Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex--;
                        });
                      },
                      child: const Text('Anterior'),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _userAnswers[_currentQuestionIndex] != null
                        ? () {
                            if (_currentQuestionIndex < _questions.length - 1) {
                              setState(() {
                                _currentQuestionIndex++;
                              });
                            } else {
                              // Último quiz, enviar resultados
                              _submitQuiz();
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _currentQuestionIndex < _questions.length - 1
                          ? 'Siguiente'
                          : 'Finalizar',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// controllers/adaptiveLearningController.js

import { GoogleGenAI } from "@google/genai"; // 🔧 IMPORTACIÓN FALTANTE
import { supabase } from '../config/supabaseClient.js';

// 🔧 INICIALIZAR GEMINI AI
const ai = new GoogleGenAI(process.env.GEMINI_API_KEY);

/**
 * Calcular el próximo intervalo de revisión (Spaced Repetition)
 * Basado en el algoritmo SM-2 simplificado
 */
function calculateNextReview(masteryScore, currentInterval = 1) {
  if (masteryScore >= 0.9) {
    return 7; // Excelente: revisar en 7 días
  } else if (masteryScore >= 0.7) {
    return 3; // Bien: revisar en 3 días
  } else if (masteryScore >= 0.5) {
    return 1; // Regular: revisar en 1 día
  } else {
    return 0.25; // Mal: revisar hoy mismo (6 horas)
  }
}

/**
 * Guardar un tema estudiado con seguimiento adaptativo
 */
export const saveStudiedTopic = async (req, res) => {
  const { student_id, topic_name, content_generated, difficulty_level = 1 } = req.body;
  
  if (!student_id || !topic_name) {
    return res.status(400).json({ error: 'student_id y topic_name son requeridos' });
  }
  
  try {
    // Calcular cuándo debe revisarse (por defecto, en 1 día)
    const nextReviewDate = new Date();
    nextReviewDate.setDate(nextReviewDate.getDate() + 1);
    
    const { data, error } = await supabase
      .from('learning_topics')
      .insert({
        student_id,
        topic_name,
        content_generated,
        difficulty_level,
        next_review_at: nextReviewDate.toISOString(),
        last_reviewed_at: new Date().toISOString(),
      })
      .select('id')
      .single();
    
    if (error) throw error;
    
    // Actualizar progreso del estudiante
    await updateStudentProgress(student_id);
    
    return res.status(200).json({
      message: 'Tema guardado exitosamente',
      topic_id: data.id,
      next_review_at: nextReviewDate,
    });
  } catch (error) {
    console.error('Error guardando tema:', error);
    return res.status(500).json({ error: 'Error al guardar el tema' });
  }
};

/**
 * Generar un mini-quiz adaptativo con Gemini
 */
export const generateQuiz = async (req, res) => {
  const { topic_name, difficulty_level = 1, learning_style } = req.body;
  
  try {
    const prompt = `
      Genera un mini-quiz de 3 preguntas sobre "${topic_name}" 
      con nivel de dificultad ${difficulty_level}/3.
      
      Estilo de aprendizaje: ${learning_style}
      
      FORMATO ESTRICTO (responde SOLO con JSON válido):
      {
        "questions": [
          {
            "question": "pregunta aquí",
            "options": ["opción A", "opción B", "opción C", "opción D"],
            "correct_answer": 0,
            "explanation": "explicación breve"
          }
        ]
      }
    `;
    
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: [prompt],
    });
    
    let quizData = response.text.trim();
    
    // Limpiar respuesta (remover markdown si existe)
    quizData = quizData.replace(/```json|```/g, '').trim();
    
    const quiz = JSON.parse(quizData);
    
    return res.status(200).json(quiz);
  } catch (error) {
    console.error('Error generando quiz:', error);
    return res.status(500).json({ error: 'Error al generar el quiz' });
  }
};

/**
 * Guardar resultados del quiz y actualizar mastery
 */
export const submitQuizResults = async (req, res) => {
  const { learning_topic_id, student_id, score, time_spent_seconds, questions_data } = req.body;
  
  try {
    // 1. Guardar evaluación
    await supabase
      .from('topic_assessments')
      .insert({
        learning_topic_id,
        student_id,
        score, // 0.0 - 1.0
        time_spent_seconds,
        questions_data,
      });
    
    // 2. Actualizar mastery_score del tema
    const { data: topic } = await supabase
      .from('learning_topics')
      .select('mastery_score')
      .eq('id', learning_topic_id)
      .single();
    
    // Promedio ponderado: 70% anterior + 30% nuevo
    const newMastery = (topic.mastery_score * 0.7) + (score * 0.3);
    
    // 3. Calcular próxima revisión
    const daysUntilNextReview = calculateNextReview(newMastery);
    const nextReviewDate = new Date();
    nextReviewDate.setDate(nextReviewDate.getDate() + daysUntilNextReview);
    
    // 4. Actualizar tema
    await supabase
      .from('learning_topics')
      .update({
        mastery_score: newMastery,
        last_reviewed_at: new Date().toISOString(),
        next_review_at: nextReviewDate.toISOString(),
      })
      .eq('id', learning_topic_id);
    
    // 5. Verificar si alcanzó maestría (>= 0.8)
    if (newMastery >= 0.8 && topic.mastery_score < 0.8) {
      await updateStudentProgress(student_id, true); // +1 tema dominado
    }
    
    return res.status(200).json({
      message: 'Quiz enviado exitosamente',
      new_mastery: newMastery,
      next_review_at: nextReviewDate,
      mastery_achieved: newMastery >= 0.8,
    });
  } catch (error) {
    console.error('Error guardando resultados del quiz:', error);
    return res.status(500).json({ error: 'Error al guardar resultados' });
  }
};

/**
 * Obtener temas pendientes de revisión
 */
export const getTopicsForReview = async (req, res) => {
  const { student_id } = req.query;
  
  try {
    const { data, error } = await supabase
      .from('learning_topics')
      .select('*')
      .eq('student_id', student_id)
      .lte('next_review_at', new Date().toISOString())
      .order('next_review_at', { ascending: true })
      .limit(5);
    
    if (error) throw error;
    
    return res.status(200).json({
      topics_to_review: data,
      count: data.length,
    });
  } catch (error) {
    console.error('Error obteniendo temas para revisar:', error);
    return res.status(500).json({ error: 'Error al obtener temas' });
  }
};

/**
 * Helper: Actualizar progreso del estudiante
 */
async function updateStudentProgress(student_id, masteredNewTopic = false) {
  try {
    // Obtener datos actuales
    const { data: progress } = await supabase
      .from('student_progress')
      .select('*')
      .eq('student_id', student_id)
      .single();
    
    const today = new Date().toISOString().split('T')[0];
    
    // Calcular racha
    let newStreak = 1;
    if (progress) {
      const lastActivity = progress.last_activity_date;
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const yesterdayStr = yesterday.toISOString().split('T')[0];
      
      if (lastActivity === yesterdayStr) {
        newStreak = progress.study_streak_days + 1;
      } else if (lastActivity === today) {
        newStreak = progress.study_streak_days;
      }
    }
    
    // Upsert
    await supabase
      .from('student_progress')
      .upsert({
        student_id,
        total_topics_studied: (progress?.total_topics_studied || 0) + 1,
        total_topics_mastered: (progress?.total_topics_mastered || 0) + (masteredNewTopic ? 1 : 0),
        study_streak_days: newStreak,
        last_activity_date: today,
        updated_at: new Date().toISOString(),
      });
    
    // Verificar logros
    await checkAndAwardAchievements(student_id, newStreak);
  } catch (error) {
    console.error('Error actualizando progreso:', error);
  }
}

/**
 * Verificar y otorgar logros
 */
async function checkAndAwardAchievements(student_id, streak) {
  const achievements = [];
  
  // Racha de 7 días
  if (streak >= 7) {
    achievements.push({ student_id, achievement_type: 'streak_7' });
  }
  
  // Racha de 30 días
  if (streak >= 30) {
    achievements.push({ student_id, achievement_type: 'streak_30' });
  }
  
  // Insertar logros (ignorar duplicados)
  if (achievements.length > 0) {
    await supabase
      .from('student_achievements')
      .upsert(achievements, { onConflict: 'student_id,achievement_type' });
  }
}
// controllers/searchController.js

import { GoogleGenAI } from "@google/genai";

import { supabase } from '../config/supabaseClient.js'

// Inicializa la Gemini API
const ai = new GoogleGenAI(process.env.GEMINI_API_KEY);

/**
 * Función que maneja los reintentos con retroceso exponencial (Exponential Backoff)
 * para la llamada a la API de Gemini.
 * Esto ayuda a mitigar errores temporales como el 503 (Servicio no disponible).
 */
const fetchWithRetry = async (query, maxRetries = 5) => {
    let attempt = 0;
    while (attempt < maxRetries) {
        try {
            const response = await ai.models.generateContent({
                model: 'gemini-2.5-pro',
                contents: [query],
                config: {
                    tools: [{ googleSearch: {} }],
                    // Con una temperatura baja para respuestas más precisas
                    temperature: 0.2,
                }
            });
            // Si tiene éxito, retorna la respuesta
            return response;

        } catch (error) {
            // Manejo de errores para identificar si es un fallo de servicio (503/UNAVAILABLE)
            const errorMessage = error.message || String(error);
            
            // Si incluye 503, UNAVAILABLE, o es el último intento, lanza el error
            if (errorMessage.includes('503') || errorMessage.includes('UNAVAILABLE') || attempt === maxRetries - 1) {
                console.error(`Error de Gemini (Intento ${attempt + 1}/${maxRetries}):`, errorMessage);
                // Lanzar un error con un mensaje más amigable para el usuario
                throw new Error("El servicio de IA está temporalmente sobrecargado. Intente de nuevo más tarde.");
            }

            // Es un error recuperable, calcular el tiempo de espera para el reintento.
            const delay = Math.pow(2, attempt) * 1000 + Math.floor(Math.random() * 1000); // Retraso exponencial + jitter
            console.log(`Error recuperable detectado. Reintentando en ${delay / 1000}s...`);
            await new Promise(resolve => setTimeout(resolve, delay));
            attempt++;
        }
    }
};


/**
 * Construye el prompt para Gemini con las instrucciones de adaptación VAK.
 */
const buildVAKPrompt = (style, topic) => {
    let adaptation_instructions = '';
    
    // Referencias
    let reference_instruction = '';

    // Instrucciones clave para la adaptación y veracidad
    switch (style) {
        case 'Visual': // Visual
            adaptation_instructions = `
                Estructura la respuesta usando encabezados, listas numeradas o con viñetas, y metáforas visuales. Incluye un 'Resumen con Diagrama' al final, explicando qué elementos deberían representarse visualmente. Evita descripciones largas y densas.
            `;

            reference_instruction = `
                De las 3 a 5 referencias, ASEGÚRATE de que al menos 2 sean enlaces directos a VIDEOS (YouTube, Video o canales universitarios) o a DIAGRAMAS/INFOGRAFÍAS relevantes.
                El resto debe ser académico y confiables(Scopus, Google Scholar, Scielo, etc.).
            `;
            break;
        case 'Auditory': // Auditivo
            adaptation_instructions = `
                **ADAPTACIÓN AUDITIVA:** Lo explicaremos como una conversación o un podcast.
                - Usa un tono dinámico y persuasivo, como si estuvieras en una tutoría uno a uno.
                - Utiliza muchas analogías y ejemplos que se puedan "contar" o "discutir".
                - Incluye una sección final llamada **"Punto Clave para la Memoria Auditiva"** que resuma la idea principal en una frase corta, rítmica o fácil de repetir en voz alta.
            `;
            reference_instruction = `
                De las 3 a 5 referencias, ASEGÚRATE de que al menos 2 sean enlaces a contenido de AUDIO o VIDEO (Podcasts, Conferencias, Canales de YouTube) donde se explique el tema.
                El resto debe ser académico y confiables(Scopus, Google Scholar, Scielo, etc.).
            `;
            
            break;
        case 'Kinesthetic': // Kinestésico
            adaptation_instructions = `
                La explicación debe enfocarse en la práctica y la aplicación. Divide el tema en 'Pasos a Seguir' o 'Ejercicios Prácticos'. Concluye con un mini-desafío o experimento relacionado con el tema.
            `;

            reference_instruction = `
                De las 3 a 5 referencias, ASEGÚRATE de que al menos 2 sean enlaces a SIMULACIONES INTERACTIVAS, TUTORIALES PASO A PASO o guías de LABORATORIO/EJERCICIOS relacionados con el tema.
                El resto debe ser académico y confiables(Scopus, Google Scholar, Scielo, etc.).
            `;
            break;
        default:
            adaptation_instructions = `Proporciona la información de manera estándar y estructurada.`;
            reference_instruction = `Lista 3 a 5 referencias académicas y confiables (Scopus, Google Scholar, Scielo, etc.).`
    }

    // El prompt maestro que combina todo (Veracidad + Rol + Adaptación)
    const master_prompt = `
        Eres un **Tutor Experto Académico y Especialista en Verificación de Hechos**, con un dominio profundo de todas las áreas del conocimiento universitario (Ciencias Sociales, Ingenierías, Humanidades, Salud, Negocios, etc).
        Tu misión es proporcionar información **veraz, confiable y profunda** sobre el tema solicitado, ajustando tambien el corto tiempo que tiene el estudiante para buscar el contenido deseado.

        **Tema de Estudio**: ${topic}
        **Estilo de Aprendizaje del Estudiante**: ${style}

        **INSTRUCCIONES CLAVE DE ADAPTACIÓN**:
        1. Explica el tema a fondo.
        2. Asegúrate de que la explicación se adhiera estrictamente a los hechos y la ciencia.
        3. **SIEMPRE, al final de tu respuesta, crea una sección llamada "Referencias Bibliográficas".**
        
        Instrucciones para la citación:
        1. Utiliza **SOLAMENTE** las URLs completas que se encuentran en la sección 'Fuentes de Búsqueda' que la herramienta de Google te proporciona y confirma que el enlace está activo.
        2. No inventes URLs ni modifiques las existentes.
        3. Si un título que mencionas no aparece en las fuentes de búsqueda proporcionadas en esta ejecución específica o parece caído, omitelo.
        4. Cita SOLAMENTE el título exacto que aparece en los resultados de búsqueda, motiva al estudiante a que investigue el contenido en el buscador (Por ejemplo, si es video de Youtube: "Busca en Youtube: TITULO").
        4. **En esta sección, ${reference_instruction} que verifican la información proporcionada.
        5.  **BUSQUEDA PROFUNDA (DEEP RESEARCH):** Antes de generar tu respuesta, debes **analizar en profundidad** al menos las fuentes diversas obtenidas en el punto 4 sobre el tema. **Sintetiza la información más actual y relevante** para un dominio completo del conocimiento.
        5. ${adaptation_instructions}
    `;
    
    return master_prompt;
};

/**
 * Endpoint principal para la búsqueda de contenido adaptado.
 */
export const searchContent = async (req, res) => {
    // El frontend ahora debe enviar el ID del estudiante y el tema
    const { topic, student_id } = req.body; 
    
    if (!topic || !student_id) {
        return res.status(400).json({ error: 'Se requieren el "topic" y el "student_id".' });
    }

    let estilo_vak = null;
    let contenido_adaptado = '';

    // --- FASE 1: OBTENER ESTILO DE SUPABASE ---
    try {
        console.log(`-> 1. Buscando estilo VAK para el ID: ${student_id}`);
        
        const { data, error } = await supabase
            .from('students')
            .select('learning_style')
            .eq('id', student_id)
            .single(); // Esperamos solo una fila

        if (error && error.code !== 'PGRST116') throw error; // PGRST116 es 'No rows found'
        if (!data) return res.status(404).json({ error: 'Estudiante no encontrado. El test VAK debe ser completado primero.' });
        
        estilo_vak = data.learning_style;
        console.log(`-> Estilo VAK obtenido: ${estilo_vak}`);
        
        // 2. Construir el prompt específico
        const promptFinal = buildVAKPrompt(estilo_vak, topic);
        
        // --- FASE 2: GENERACIÓN DE CONTENIDO CON GEMINI ---
        console.log("-> 2. Llamando a Gemini para generar contenido adaptado...");
        
        const response = await fetchWithRetry(promptFinal);

        contenido_adaptado = response.text;
        
        console.log(`✅ Contenido generado y adaptado a estilo ${estilo_vak}.`);

        // 🆕 GUARDAR AUTOMÁTICAMENTE EN LEARNING_TOPICS
        try {
            const nextReviewDate = new Date();
            nextReviewDate.setDate(nextReviewDate.getDate() + 1);
            
            await supabase
                .from('learning_topics')
                .insert({
                    student_id: student_id,
                    topic_name: topic,
                    content_generated: contenido_adaptado,
                    difficulty_level: 1,
                    next_review_at: nextReviewDate.toISOString(),
                    last_reviewed_at: new Date().toISOString(),
                });
            
            console.log(`✅ Tema "${topic}" guardado para revisión espaciada.`);
        } catch (saveError) {
            console.error('⚠️ Error guardando tema (no crítico):', saveError.message);
        }

    } catch (error) {
        console.error("Error en FASE 1 o 2 (Supabase/Gemini):", error.message);
        return res.status(500).json({ error: 'Error al obtener el estilo VAK o generar el contenido adaptado.' });
    }

    // --- FASE 3: GUARDAR LOG DE BÚSQUEDA ---
    try {
        console.log("-> 3. Guardando log de búsqueda en Supabase...");
        
        const { error } = await supabase
            .from('agent_logs')
            .insert([{
                student_id: student_id,
                search_topic: topic,
                style_used: estilo_vak,
                response_length: contenido_adaptado.length
            }]);
            
        if (error) throw error;
        console.log("✅ Log de búsqueda guardado.");
        
    } catch (error) {
        console.error("⚠️ Error al guardar el log de búsqueda (No crítico para la respuesta):", error.message);
        // NOTA: No detenemos la respuesta al usuario, pero registramos el fallo
    }
    
    // --- FASE 4: RESPUESTA FINAL ---
    return res.status(200).json({
        estilo_usado: estilo_vak,
        contenido: contenido_adaptado,
    });
};
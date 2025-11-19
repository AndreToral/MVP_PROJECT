// controllers/classificationController.js

import { GoogleGenAI } from "@google/genai";
import axios from 'axios';
import { supabase } from '../config/supabaseClient.js';

// Inicializa las APIs (asumiendo que las variables de entorno están cargadas)
const ai = new GoogleGenAI(process.env.GEMINI_API_KEY);
const PYTHON_URL = process.env.PYTHON_CLASSIFIER_URL;

/**
 * 1. Traduce el texto en español a inglés usando Gemini.
 * 2. Llama al microservicio Python para clasificar el texto en inglés.
 * 3. Persiste o actualiza (UPSERT) el estilo de aprendizaje en la tabla 'students'
 * usando el ID de usuario de Supabase como 'id' del estudiante.
 */
export const classifyStyle = async (req, res) => {
    // *** CAMBIO CLAVE: Recibir el user_id del frontend ***
    const { text_espanol, user_id } = req.body; 

    if (!text_espanol) {
        return res.status(400).json({ error: 'El campo "text_espanol" es obligatorio.' });
    }
    // Nueva validación para asegurar la sincronización de IDs
    if (!user_id) {
        return res.status(400).json({ error: 'El campo "user_id" es obligatorio para la persistencia.' });
    }

    let texto_ingles = '';
    let estilo_vak = '';
    // studentId ahora es simplemente el user_id
    const studentId = user_id; 

    // --- FASE 1: TRADUCCIÓN CON GEMINI ---
    try {
        console.log("-> 1. Iniciando traducción con Gemini...");
        
        const promptTraduccion = `
            Traduce al inglés ÚNICAMENTE la siguiente frase, sin añadir preámbulos, explicaciones, opciones o caracteres de formato.
            El output debe ser SÓLO el texto traducido.
            Frase a traducir: "${text_espanol}"
        `;

        const response = await ai.models.generateContent({
            model: 'gemini-2.5-flash', 
            contents: [promptTraduccion],
        });

        texto_ingles = response.text.trim();
        console.log(`-> Traducción exitosa: ${texto_ingles}`);

    } catch (error) {
        console.error("Error en la traducción con Gemini:", error);
        return res.status(500).json({ error: 'Error en el servicio de traducción.' });
    }

    // --- FASE 2: CLASIFICACIÓN CON PYTHON ---
    try {
        console.log("-> 2. Llamando al microservicio Python...");
        
        const pythonResponse = await axios.post(PYTHON_URL, { 
            text: texto_ingles 
        });

        estilo_vak = pythonResponse.data.estilo; 
        
        if (typeof estilo_vak !== 'string' || estilo_vak.length === 0) {
            console.warn(`⚠️ Estilo no válido recibido de Python: ${estilo_vak}. Usando Visual por defecto.`);
            estilo_vak = 'Visual';
        }
        
        console.log(`✅ Clasificación final: ${estilo_vak}`);
        
    } catch (error) {
        console.error("Error al llamar al servicio Python:", error.response ? error.response.data : error.message);
        return res.status(500).json({ 
            error: 'Error al clasificar el texto con el modelo NLP.' 
        });
    }

    // --- FASE 3: PERSISTENCIA (ACTUALIZADO: Usando user_id y upsert) ---
    try {
        console.log(`-> 3. Guardando/Actualizando estilo clasificado en Supabase para el ID: ${user_id}`);

        // Usamos upsert para:
        // 1. Insertar el registro si el ID no existe.
        // 2. Actualizar el registro si el ID ya existe (por si el usuario repite el test).
        const { data, error } = await supabase
            .from('students')
            .upsert(
                { 
                    id: user_id, // Usamos el ID de Auth como clave principal
                    learning_style: estilo_vak,
                    // Opcional: añadir un timestamp de la última clasificación
                    last_classified_at: new Date().toISOString(), 
                },
                // La opción 'onConflict' ya no es necesaria si el ID es la clave primaria
                // y se maneja por defecto con 'upsert', pero a veces se usa para claridad.
                // Lo mantendremos simple:
            )
            .select('id'); 

        if (error) throw error;
        
        // Verificación de que la operación fue exitosa
        if (!data || data.length === 0) {
            throw new Error('Supabase no devolvió el ID del estudiante después de la operación.');
        }

        console.log(`✅ Estilo guardado/actualizado. ID de estudiante: ${data[0].id}`);

    } catch (error) {
        console.error("Error al guardar en Supabase:", error);
        return res.status(500).json({ error: 'Error al persistir la clasificación en la DB.' });
    }

    // --- FASE 4: RESPUESTA FINAL ---
    // student_id siempre será igual a user_id
    return res.status(200).json({ 
        estilo_aprendizaje: estilo_vak,
        student_id: studentId, // Enviamos el user_id de vuelta
        texto_traducido: texto_ingles
    });
};
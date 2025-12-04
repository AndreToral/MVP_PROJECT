// index.js

import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import { classifyStyle } from './controllers/classificationController.js';
import { searchContent } from './controllers/searchController.js';
// 🆕 IMPORTAR CONTROLADORES DE APRENDIZAJE ADAPTATIVO
import {
  saveStudiedTopic,
  generateQuiz,
  submitQuizResults,
  getTopicsForReview
} from './controllers/adaptiveLearningController.js';

// Carga las variables de entorno desde .env
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000; // Usa el puerto 3000 o el definido por Railway

// Middleware
app.use(express.json()); // Para poder leer JSON en las peticiones POST
app.use(cors());
// --- RUTAS ---
// 1. Endpoint para la CLASIFICACIÓN VAK (El primer paso del usuario)
app.post('/api/classify-style', classifyStyle);

// 2. Endpoint para la BÚSQUEDA DE CONTENIDO (Lo implementaremos en el Día 3)
app.post('/api/content-agent', searchContent); 

// --- 🆕 RUTAS DE APRENDIZAJE ADAPTATIVO ---

// 1. Guardar tema estudiado
app.post('/api/learning/save-topic', saveStudiedTopic);

// 2. Generar quiz adaptativo
app.post('/api/learning/generate-quiz', generateQuiz);

// 3. Enviar resultados del quiz
app.post('/api/learning/submit-quiz', submitQuizResults);

// 4. Obtener temas pendientes de revisión
app.get('/api/learning/topics-to-review', getTopicsForReview);

// --- Inicialización del Servidor ---
app.listen(PORT, () => {
    console.log(`✅ Servidor Node.js escuchando en el puerto ${PORT}`);
    // Opcional: Probar que las claves están cargadas
    if (!process.env.GEMINI_API_KEY) {
        console.error("❌ ERROR: GEMINI_API_KEY no está configurada. Revisa tu archivo .env");
    }
});
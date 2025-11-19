// index.js

import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import { classifyStyle } from './controllers/classificationController.js';
import { searchContent } from './controllers/searchController.js';

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

// --- Inicialización del Servidor ---
app.listen(PORT, () => {
    console.log(`✅ Servidor Node.js escuchando en el puerto ${PORT}`);
    // Opcional: Probar que las claves están cargadas
    if (!process.env.GEMINI_API_KEY) {
        console.error("❌ ERROR: GEMINI_API_KEY no está configurada. Revisa tu archivo .env");
    }
});
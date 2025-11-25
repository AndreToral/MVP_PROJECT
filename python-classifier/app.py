# app.py
import os
import pickle
from flask import Flask, request, jsonify
from flask_cors import CORS # Necesario si Node.js y Python corren en diferentes puertos

app = Flask(__name__)
# Permite peticiones desde el frontend (Node.js/Flutter)
# En un entorno de producción (Railway), se recomienda especificar los orígenes
CORS(app) 

# Variables globales para el modelo y el vectorizador
modelo_clasificacion = None
vectorizador_texto = None

# Configuración del modelo directions
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "Vak_model.pkl")
VECTOR_PATH = os.path.join(BASE_DIR, "Tfidf_vectorizer.pkl")

# --- Función para cargar los archivos .pkl ---
def cargar_modelo():
    """Carga el modelo y el vectorizador desde los archivos .pkl."""
    global modelo_clasificacion, vectorizador_texto
    
    try:
        # Cargar el modelo (Ej: Naive Bayes, SVM, etc.)
        with open(MODEL_PATH, 'rb') as f:
            modelo_clasificacion = pickle.load(f)
        
        # Cargar el vectorizador (Ej: TfidfVectorizer, CountVectorizer)
        with open(VECTOR_PATH, 'rb') as f:
            vectorizador_texto = pickle.load(f)
        
        print("✅ Modelos .pkl cargados correctamente en memoria.")
    except FileNotFoundError:
        print("❌ Error: No se encontraron 'modelo.pkl' o 'vectorizador.pkl'.")
        # Esto debería detener el servicio si los archivos son críticos
        exit(1)
    except Exception as e:
        print(f"❌ Error al cargar los modelos: {e}")
        exit(1)

# Llama a la función de carga inmediatamente después de definirla
# Esto se ejecutará tanto localmente como en Gunicorn/Railway
cargar_modelo() # <-- Mover esta llamada aquí

# --- Endpoint de Clasificación ---
@app.route('/classify', methods=['POST'])
def classify_text():
    """
    Recibe un texto en inglés (pre-traducido por Node.js) y retorna la clasificación VAK.
    """
    if not request.json or 'text' not in request.json:
        return jsonify({
            'error': 'Falta el campo "text" en la solicitud JSON.'
        }), 400

    texto_input = request.json['text']
    
    # 1. Verificar si el texto es válido
    if not isinstance(texto_input, str) or len(texto_input.strip()) == 0:
        return jsonify({
            'error': 'El campo "text" debe ser una cadena no vacía.'
        }), 400

    try:
        # 2. Vectorizar el texto de entrada
        # IMPORTANTE: El texto debe estar en el formato (ej. limpio y en inglés)
        # esperado por el vectorizador entrenado.
        texto_vectorizado = vectorizador_texto.transform([texto_input])
        
        # 3. Predecir la clasificación
        prediccion = modelo_clasificacion.predict(texto_vectorizado)
        
        # 4. CORRECCIÓN CRÍTICA: Extraer el string del array de NumPy
        # Ejemplo: array(['Auditory'], dtype=object) -> 'Auditory'
        if prediccion.size > 0:
            # Extraer el primer (y único) elemento y convertirlo a string simple
            estilo_clasificado = str(prediccion[0])
        else:
            # En caso de que la predicción falle (array vacío)
            estilo_clasificado = None 

        # 5. Devolver el resultado
        # Si prediccion.size > 0, estilo_clasificado será 'Auditory' (string).
        # Si falla, será None (lo que Node.js deberá manejar como fallo).
        return jsonify({
            'estilo': estilo_clasificado, # 'V', 'A', o 'K'
            'texto_recibido': texto_input
        })

    except Exception as e:
        # En caso de un error inesperado durante la predicción
        return jsonify({
            'error': f'Error interno durante la clasificación: {e}'
        }), 500

# --- Punto de inicio ---
if __name__ == '__main__':
    # Carga los modelos ANTES de iniciar el servidor
    cargar_modelo()
    
    # Asegúrate de usar el puerto que requiere Railway o tu entorno local (ej. 5000)
    # En Railway, el puerto se puede definir con la variable de entorno PORT
    # Para desarrollo local: app.run(debug=True, port=5000)
    app.run(host='0.0.0.0', port=5000)
# 🎓 UniPrep AI - Tutor VAK Universitario

**Sistema de Aprendizaje Personalizado basado en Estilos VAK (Visual, Auditivo, Kinestésico)**

UniPrep AI es una plataforma educativa que utiliza inteligencia artificial para clasificar el estilo de aprendizaje de los estudiantes universitarios y proporcionar contenido académico adaptado a sus preferencias individuales.

---

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Arquitectura](#-arquitectura)
- [Tecnologías](#-tecnologías)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación](#-instalación)
- [Configuración](#-configuración)
- [Ejecución](#-ejecución)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [API Endpoints](#-api-endpoints)

---

## ✨ Características

- 🧠 **Clasificación VAK con IA**: Utiliza NLP y Gemini AI para determinar el estilo de aprendizaje
- 🎨 **Interfaz Responsive**: Diseño adaptativo para web, móvil y escritorio
- 🔐 **Autenticación Segura**: Sistema completo de registro y login con Supabase
- 📚 **Contenido Personalizado**: Búsqueda de material académico adaptado al estilo VAK
- 🌐 **Referencias Verificadas**: Enlaces a recursos académicos, videos y simulaciones
- 🚀 **Arquitectura Modular**: Frontend (Flutter), Backend (Node.js), Clasificador (Python)

---

## 🏗️ Arquitectura

```
┌─────────────────┐
│  Flutter Web    │
│   (Frontend)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────────┐
│   Node.js API   │◄────►│  Supabase        │
│   (Backend)     │      │  (PostgreSQL +   │
└────────┬────────┘      │   Auth)          │
         │               └──────────────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────────┐
│  Python Flask   │◄────►│  Gemini AI       │
│  (Clasificador) │      │  (Google)        │
└─────────────────┘      └──────────────────┘
```

**Flujo de Datos:**
1. Usuario se registra/inicia sesión → **Supabase Auth** + Confirma cuenta en **Gmail**
2. Usuario responde test VAK → **Node.js** traduce con **Gemini AI**
3. Texto traducido → **Python Classifier** (NLP) → Clasifica estilo
4. Estilo guardado en **Supabase Database**
5. Usuario busca tema → **Node.js** consulta estilo + **Gemini AI** genera contenido
6. Contenido personalizado → Renderizado en **Flutter**

---

## 🛠️ Tecnologías

### Frontend
- **Flutter 3.18** - Framework multiplataforma
- **Dart** - Lenguaje de programación
- **Supabase Flutter** - SDK de Supabase
- **Flutter Markdown** - Renderizado de contenido
- **Lucide Icons** - Iconografía

### Backend (Node.js)
- **Node.js 18+** - Runtime de JavaScript
- **Express.js** - Framework web
- **Supabase JS** - Cliente de Supabase
- **Google Gemini AI** - API de inteligencia artificial
- **Axios** - Cliente HTTP
- **dotenv** - Gestión de variables de entorno
- **CORS** - Middleware de seguridad

### Clasificador (Python)
- **Python 3.9+** - Lenguaje de programación
- **Flask** - Framework web
- **scikit-learn** - Machine Learning
- **TF-IDF Vectorizer** - Procesamiento de texto
- **joblib** - Serialización de modelos

### Base de Datos y Auth
- **Supabase** - Backend as a Service
- **PostgreSQL** - Base de datos relacional

---

## 📦 Requisitos Previos

### Software Necesario
- **Flutter SDK** 3.18 o superior ([Instalar](https://docs.flutter.dev/get-started/install))
- **Node.js** 18 o superior ([Instalar](https://nodejs.org/))
- **Python** 3.9 o superior ([Instalar](https://www.python.org/downloads/))
- **Git** ([Instalar](https://git-scm.com/downloads))

### Cuentas de Servicio
- Cuenta de [Supabase](https://supabase.com) (Gratuita)
- API Key de [Google Gemini AI](https://ai.google.dev/) (Gratuita)

---

## 🚀 Instalación

### 1. Clonar el Repositorio

```bash
git clone https://github.com/AndreToral/MVP_PROJECT.git
cd MVP_PROJECT
```

### 2. Instalar Flutter Frontend

```bash
cd flutter-frontend
flutter pub get
```

### 3. Instalar Node.js Backend

```bash
cd ../node-api-agent
npm install
```

### 4. Instalar Python Classifier

```bash
cd ../python-classifier
pip install -r requirements.txt
```

---

## ⚙️ Configuración

### 1. Configurar Supabase

#### a) Crear Proyecto en Supabase
1. Ve a [supabase.com](https://supabase.com)
2. Crea un nuevo proyecto
3. Copia la URL y la API Key (anon/public)

#### b) Crear Tablas en Supabase
Ejecuta este SQL en el **SQL Editor** de Supabase:

```sql
-- Tabla de estudiantes
CREATE TABLE students (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    learning_style TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_classified_at TIMESTAMPTZ
);

-- Tabla de logs de búsquedas
CREATE TABLE agent_logs (
    id SERIAL PRIMARY KEY,
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    search_topic TEXT NOT NULL,
    style_used TEXT,
    response_length INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar Row Level Security (RLS)
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_logs ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad
CREATE POLICY "Users can view own data" 
    ON students FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "Users can update own data" 
    ON students FOR UPDATE 
    USING (auth.uid() = id);
```

### 2. Configurar Variables de Entorno

#### Flutter Frontend
Crea `flutter-frontend/lib/config/env_config.dart`:

```dart
class EnvConfig {
  static const String supabaseUrl = 'https://tu-proyecto.supabase.co';
  static const String supabaseAnonKey = 'tu-anon-key-aqui';
  static const String apiBaseUrl = 'http://localhost:3000/api';
}
```

#### Node.js Backend
Crea `node-api-agent/.env`:

```env
# Supabase
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-aqui

# Google Gemini AI
GEMINI_API_KEY=tu-gemini-api-key-aqui

# Python Classifier
PYTHON_CLASSIFIER_URL=http://localhost:5000/classify

# Puerto
PORT=3000
```

#### Python Classifier
Crea `python-classifier/.env`:

```env
PORT=5000
```

### 3. Agregar env_config.dart al .gitignore

```bash
echo "lib/config/env_config.dart" >> flutter-frontend/.gitignore
```

---

## 🏃 Ejecución

### 1. Ejecutar Python Classifier

```bash
cd python-classifier
python app.py
```
✅ Corriendo en: `http://localhost:5000`

### 2. Ejecutar Node.js Backend

```bash
cd node-api-agent
node index.js
```
✅ Corriendo en: `http://localhost:3000`

### 3. Ejecutar Flutter Frontend

```bash
cd flutter-frontend
flutter run -d chrome
```
✅ Corriendo en: `http://localhost:64308` (puerto aleatorio)

---

## 📁 Estructura del Proyecto

```
MVP_project/
│
├── flutter-frontend/              # Frontend en Flutter
│   ├── lib/
│   │   ├── config/
│   │   │   └── env_config.dart    # ⚠️ NO subir a Git
│   │   ├── models/
│   │   ├── screens/
│   │   │   ├── agent_screen.dart
│   │   │   ├── classification_screen.dart
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── landing_page.dart
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── services/
│   │   │   └── api_service.dart
│   │   ├── utils/
│   │   │   ├── constants.dart
│   │   │   └── session_manager.dart
│   │   └── main.dart
│   ├── web/
│   ├── pubspec.yaml
│   └── README.md
│
├── node-api-agent/                # Backend en Node.js
│   ├── config/
│   │   └── supabaseClient.js
│   ├── controllers/
│   │   ├── classificationController.js
│   │   └── searchController.js
│   ├── node_modules/
│   ├── .env                       # ⚠️ NO subir a Git
│   ├── index.js
│   ├── package.json
│   └── README.md
│
├── python-classifier/             # Clasificador NLP
│   ├── app.py
│   ├── Procfile
│   ├── requirements.txt
│   ├── Tfidf_vectorizer.pkl
│   ├── Vak_model.pkl
│   └── README.md
│
├── .gitignore
└── README.md                      # Este archivo
```

---

## 🌐 API Endpoints

### Backend (Node.js) - `http://localhost:3000/api`

#### 1. Clasificar Estilo VAK
```http
POST /api/classify-style
Content-Type: application/json

{
  "text_espanol": "Prefiero ver diagramas y videos",
  "user_id": "uuid-del-usuario"
}
```

**Respuesta:**
```json
{
  "estilo_aprendizaje": "Visual",
  "student_id": "uuid-del-usuario",
  "texto_traducido": "I prefer to see diagrams and videos"
}
```

#### 2. Buscar Contenido Adaptado
```http
POST /api/content-agent
Content-Type: application/json

{
  "topic": "Equilibrio de Nash",
  "student_id": "uuid-del-usuario"
}
```

**Respuesta:**
```json
{
  "estilo_usado": "Visual",
  "contenido": "# Equilibrio de Nash\n\n[Contenido en Markdown adaptado...]"
}
```

### Clasificador (Python) - `http://localhost:5000`

#### Clasificar Texto (Inglés)
```http
POST /classify
Content-Type: application/json

{
  "text": "I prefer to see diagrams and videos"
}
```

**Respuesta:**
```json
{
  "estilo": "Visual"
}
```

---
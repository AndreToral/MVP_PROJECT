import 'package:flutter/material.dart';

// --- INSTANCIA DE SUPABASE ---
// Esta instancia global debe ser accedida ÚNICAMENTE después de que
// Supabase haya sido inicializado en main.dart usando las claves del .env.

// --- COLORES ---
// Usando tus colores definidos:
const Color kPrimaryColor = Color(0xFF4F46E5); // Índigo 600
const Color kOnPrimaryColor = Colors.white; // Blanco
const Color kTextColor = Color(0xFF374151); // Gris Oscuro
const Color kSubtleTextColor = Color(0xFF6B7280); // Gris Medio
const Color kBlueButton = Color(0xFF3B82F6); // Azul 500 para el botón de Sign Up

// Color necesario para mensajes de error o acentos de peligro
const Color kAccentColor = Color(0xFFEF4444); // Rojo para acentos o errores

const Color kScaffoldBackgroundColor = Color(0xFFF3F4F6); // Fondo gris claro

// --- ESTILOS DE TEXTO ---
const TextStyle kHeadingStyle = TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: kTextColor, height: 1.1);
const TextStyle kSubtitleStyle = TextStyle(fontSize: 18, color: kSubtleTextColor, height: 1.5);
const TextStyle kFeatureTitleStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kPrimaryColor);
const TextStyle kFeatureDescriptionStyle = TextStyle(fontSize: 14, color: kSubtleTextColor);
import 'package:flutter/material.dart';

class AppColors {
  // Colores principales (equivalentes a las CSS variables de Ionic)
  static const Color azulFondo = Color.fromARGB(255, 26, 58, 110);       // --azul-fondo
  static const Color blanco = Color(0xFFFFFFFF);           // --blanco
  static const Color grisDivider = Color(0xFFE0E0E0);      // --gris-divider
  static const Color grisTexto = Color(0xFF666666);        // --gris-texto
  static const Color verdesuave = Color(0xFF4CAF50);       // --verde-suave
  static const Color ambarSuave = Color(0xFFFFA726);       // --ambar-suave
  static const Color rojoSuave = Color(0xFFEF5350);        // --rojo-suave
  static const Color fondoAzulClaroActivo = Color(0xFF42A5F5); // activo tab
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color progressBg = Color(0xFFDDDDDD);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.azulFondo,
          primary: AppColors.azulFondo,
          background: AppColors.blanco,
        ),
        scaffoldBackgroundColor: AppColors.blanco,
        fontFamily: 'Roboto',
      );
}
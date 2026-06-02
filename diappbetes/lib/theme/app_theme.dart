import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// AppColors — constantes de color para modo claro y oscuro
// ---------------------------------------------------------------------------
class AppColors {
  // ── Colores de marca (siempre iguales) ────────────────────────────────── //
  static const Color azulFondo = Color(0xFF1A3A6E); 
  static const Color fondoAzulClaroActivo = Color(0xFF42A5F5);
  static const Color verdesuave         = Color(0xFF4CAF50);
  static const Color ambarSuave         = Color(0xFFFFA726);
  static const Color rojoSuave          = Color(0xFFEF5350);
  static const Color progressBg         = Color(0xFFDDDDDD);

  // ── Modo claro ────────────────────────────────────────────────────────── //
  static const Color blanco             = Color(0xFFFFFFFF);
  static const Color grisDivider        = Color(0xFFE0E0E0);
  static const Color grisTexto          = Color(0xFF666666);
  static const Color cardBackground     = Color(0xFFFFFFFF);

  // ── Modo oscuro ───────────────────────────────────────────────────────── //
  static const Color darkBackground     = Color(0xFF121212);
  static const Color darkSurface        = Color(0xFF1E1E1E);
  static const Color darkCard           = Color(0xFF2C2C2C);
  static const Color darkDivider        = Color(0xFF3A3A3A);
  static const Color darkTextPrimary    = Color(0xFFE0E0E0);
  static const Color darkTextSecondary  = Color(0xFF9E9E9E);

  // ── Helpers contextuales (usa ThemeContext en widgets) ─────────────────── //
  static Color surface(BuildContext ctx)    => Theme.of(ctx).colorScheme.surface;
  static Color onSurface(BuildContext ctx)  => Theme.of(ctx).colorScheme.onSurface;
  static Color cardBg(BuildContext ctx)     => Theme.of(ctx).cardColor;
  static Color divider(BuildContext ctx)    => Theme.of(ctx).dividerColor;
  static Color textSecondary(BuildContext ctx) => Theme.of(ctx).textTheme.bodySmall!.color!;
}

// ---------------------------------------------------------------------------
// AppTheme — temas claro y oscuro
// ---------------------------------------------------------------------------
class AppTheme {
  // ── Tema CLARO ────────────────────────────────────────────────────────── //
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.azulFondo,
      primary:   AppColors.azulFondo,
      surface:   AppColors.blanco,
      onSurface: AppColors.grisTexto,
    ),
    scaffoldBackgroundColor: AppColors.blanco,
    cardColor:     AppColors.blanco,
    dividerColor:  AppColors.grisDivider,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.azulFondo,
      foregroundColor: AppColors.blanco,
      elevation: 2,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:      AppColors.blanco,
      selectedItemColor:    AppColors.fondoAzulClaroActivo,
      unselectedItemColor:  AppColors.azulFondo,
      type: BottomNavigationBarType.fixed,
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: AppColors.grisTexto, fontSize: 13),
      enabledBorder:  const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grisDivider)),
      focusedBorder:  const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azulFondo)),
      disabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grisDivider)),
    ),
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: AppColors.grisTexto),
      bodyMedium: TextStyle(color: AppColors.grisTexto),
      bodySmall:  TextStyle(color: AppColors.grisTexto),
    ),
  );

  // ── Tema OSCURO ───────────────────────────────────────────────────────── //
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor:  AppColors.azulFondo,
      brightness: Brightness.dark,
      primary:    AppColors.fondoAzulClaroActivo,
      surface:    AppColors.darkSurface,
      onSurface:  AppColors.darkTextPrimary,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor:    AppColors.darkCard,
    dividerColor: AppColors.darkDivider,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A2E),
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 2,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:      AppColors.darkSurface,
      selectedItemColor:    AppColors.fondoAzulClaroActivo,
      unselectedItemColor:  AppColors.darkTextSecondary,
      type: BottomNavigationBarType.fixed,
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
      enabledBorder:  const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.darkDivider)),
      focusedBorder:  const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.fondoAzulClaroActivo)),
      disabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.darkDivider)),
    ),
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: AppColors.darkTextPrimary),
      bodyMedium: TextStyle(color: AppColors.darkTextPrimary),
      bodySmall:  TextStyle(color: AppColors.darkTextSecondary),
    ),
  );

  // Alias mantenido por compatibilidad con código antiguo
  static ThemeData get theme => light;
}
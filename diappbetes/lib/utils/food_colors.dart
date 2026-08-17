import 'package:flutter/material.dart';

Color categoryBg(BuildContext context, String cat) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  if (isDark) {
    const map = {
      'frutas':       Color(0xFF3E2723),
      'proteicos':       Color(0xFF3E1414),
      'pescados':     Color(0xFF1A237E),
      'mariscos':     Color(0xFF004D40),
      'verduras':     Color(0xFF1B3A1B),
      'lacteos':      Color(0xFF2E1A47),
      'cereales':     Color(0xFF3E2723),
      'bolleria':     Color(0xFF4A1428),
      'dulces':       Color(0xFF4A1438),
      'bebidas':      Color(0xFF0D2F4F),
      'legumbres':    Color(0xFF2E3D1A),
      'frutos_secos': Color(0xFF2E1F17),
      'plato':        Color(0xFF1F1A3E),
    };
    return map[cat.toLowerCase()] ?? const Color(0xFF3E2723);
  } else {
    const map = {
      'frutas':       Color(0xFFFFF3E0),
      'proteicos':       Color(0xFFFFEBEE),
      'pescados':     Color(0xFFE3F2FD),
      'mariscos':     Color(0xFFE0F7FA),
      'verduras':     Color(0xFFE8F5E9),
      'lacteos':      Color(0xFFF3E5F5),
      'cereales':     Color(0xFFFFF8E1),
      'bolleria':     Color(0xFFFCE4EC),
      'dulces':       Color(0xFFF8BBD0),
      'bebidas':      Color(0xFFE1F5FE),
      'legumbres':    Color(0xFFF1F8E9),
      'frutos_secos': Color(0xFFEFEBE9),
      'plato':        Color(0xFFEDE7F6),
    };
    return map[cat.toLowerCase()] ?? const Color(0xFFFFF3E0);
  }
}

Color categoryText(BuildContext context, String cat) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  if (isDark) {
    const map = {
      'frutas':       Color(0xFFFFB74D),
      'proteicos':       Color(0xFFEF5350),
      'pescados':     Color(0xFF64B5F6),
      'mariscos':     Color(0xFF4DD0E1),
      'verduras':     Color(0xFF81C784),
      'lacteos':      Color(0xFFBA68C8),
      'cereales':     Color(0xFFFFD54F),
      'bolleria':     Color(0xFFF06292),
      'dulces':       Color(0xFFEC407A),
      'bebidas':      Color(0xFF4FC3F7),
      'legumbres':    Color(0xFFAED581),
      'frutos_secos': Color(0xFFA1887F),
      'plato':        Color(0xFF9575CD),
    };
    return map[cat.toLowerCase()] ?? const Color(0xFFFFB74D);
  } else {
    const map = {
      'frutas':       Color(0xFFE65100),
      'proteicos':       Color(0xFFB71C1C),
      'pescados':     Color(0xFF0D47A1),
      'mariscos':     Color(0xFF006064),
      'verduras':     Color(0xFF1B5E20),
      'lacteos':      Color(0xFF4A148C),
      'cereales':     Color(0xFFF57F17),
      'bolleria':     Color(0xFFAD1457),
      'dulces':       Color(0xFF880E4F),
      'bebidas':      Color(0xFF01579B),
      'legumbres':    Color(0xFF33691E),
      'frutos_secos': Color(0xFF4E342E),
      'plato':        Color(0xFF311B92),
    };
    return map[cat.toLowerCase()] ?? const Color(0xFFE65100);
  }
}
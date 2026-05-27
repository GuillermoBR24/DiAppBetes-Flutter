// lib/utils/food_colors.dart
import 'package:flutter/material.dart';

Color categoryBg(String cat) {
  const map = {
    'frutas':       Color(0xFFFFF3E0),
    'carnes':       Color(0xFFFFEBEE),
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

Color categoryText(String cat) {
  const map = {
    'frutas':       Color(0xFFE65100),
    'carnes':       Color(0xFFB71C1C),
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
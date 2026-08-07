// lib/utils/admin_nav_helper.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminNavHelper {
  /// Verifica si el usuario actual es administrador
  static Future<bool> getIsAdmin() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;
      
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(uid)
          .get();
      
      final role = (doc.data()?['role'] as String?)?.toLowerCase() ?? '';
      return role == 'administrador' || role == 'admin';
    } catch (_) {
      return false;
    }
  }

  /// Construye el BottomNavigationBar con solo 3 ítems principales
  static Widget buildBottomBar({
    required BuildContext context,
    required int currentIndex,
    required Function(int) onTap,
    required bool isAdmin,
  }) {
    // Solo 3 ítems principales
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.refresh), label: 'Historial'),
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Comida'),
    ];

    // Ajustar índice si es necesario
    int safeIndex = currentIndex;
    if (currentIndex < 0 || currentIndex > 2) safeIndex = 1; // ← CAMBIO: validar rango 0-2

    final backgroundColor = Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Theme.of(context).cardColor;
    final selectedItemColor = Theme.of(context).bottomNavigationBarTheme.selectedItemColor ?? Theme.of(context).colorScheme.primary;
    final unselectedItemColor = Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ?? Theme.of(context).textTheme.bodySmall?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3) 
                : const Color(0x1A000000),
            blurRadius: 6, 
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: backgroundColor,
        selectedItemColor: selectedItemColor,
        unselectedItemColor: unselectedItemColor,
        currentIndex: safeIndex,
        onTap: onTap,
        items: items,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Maneja el tap en el BottomNavigationBar
  static void handleTabTap({
    required BuildContext context,
    required int index,
    required bool isAdmin,
    required Function(int) onValidTap,
  }) {
    // Para los 3 ítems principales
    onValidTap(index);
  }
}
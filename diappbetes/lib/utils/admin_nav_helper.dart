import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminNavHelper {
  /// Única definición de "es administrador" (sin distinguir mayúsculas).
  /// Es solo para la interfaz: la seguridad real la aplican firestore.rules.
  static bool isAdminRole(Object? role) {
    final r = role?.toString().trim().toLowerCase() ?? '';
    return r == 'administrador' || r == 'admin';
  }

  static Future<bool> getIsAdmin() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;
      
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(uid)
          .get();
      
      return isAdminRole(doc.data()?['role']);
    } catch (_) {
      return false;
    }
  }

  static Widget buildBottomBar({
    required BuildContext context,
    required int currentIndex,
    required Function(int) onTap,
    required bool isAdmin,
  }) {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.refresh), label: 'Historial'),
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Comida'),
    ];

    int safeIndex = currentIndex;
    if (currentIndex < 0 || currentIndex > 2) safeIndex = 1;

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

  static void handleTabTap({
    required BuildContext context,
    required int index,
    required bool isAdmin,
    required Function(int) onValidTap,
  }) {
    onValidTap(index);
  }
}
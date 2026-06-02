// lib/utils/admin_nav_helper.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

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

  /// Construye el BottomNavigationBar con ítem Admin condicional
  static Widget buildBottomBar({
    required BuildContext context,
    required int currentIndex,
    required Function(int) onTap,
    required bool isAdmin,
  }) {
    final backgroundColor = Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Theme.of(context).cardColor;
    final selectedItemColor = Theme.of(context).bottomNavigationBarTheme.selectedItemColor ?? Theme.of(context).colorScheme.primary;
    final unselectedItemColor = Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ?? Theme.of(context).textTheme.bodySmall?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Ítems base (siempre visibles)
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.refresh), label: 'Historial'),
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Escáner'),
      const BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Comida'),
    ];

    // Agregar Admin SOLO si tiene permisos
    if (isAdmin) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings),
        label: 'Admin',
      ));
    }

    // Ajustar índice si admin no está disponible
    int safeIndex = currentIndex;
    if (!isAdmin && currentIndex >= 4) safeIndex = 1; // Volver a Home

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3) 
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

  /// Maneja el tap en el BottomNavigationBar con lógica de admin
  static void handleTabTap({
    required BuildContext context,
    required int index,
    required bool isAdmin,
    required Function(int) onValidTap,
  }) {
    // Índice del admin (es el último si existe)
    final adminIndex = isAdmin ? 4 : -1;

    // Si tocó Admin
    if (index == adminIndex) {
      if (isAdmin) {
        Navigator.pushNamed(context, '/admin');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔒 Acceso denegado: Se requieren permisos de administrador'),
            backgroundColor: AppColors.rojoSuave,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Para los demás ítems
    onValidTap(index);
  }
}
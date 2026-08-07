// lib/services/maintenance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MaintenanceService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Verifica si la app está en modo mantenimiento
  /// Retorna: 
  /// - null si no hay mantenimiento o el usuario es admin
  /// - String con el mensaje de mantenimiento si está bloqueado
  Future<String?> checkMaintenanceMode() async {
    debugPrint('\n═══════════════════════════════════════════════════════');
    debugPrint('🔧 [MAINTENANCE] Iniciando verificación de modo mantenimiento');
    debugPrint('═══════════════════════════════════════════════════════');
    
    try {
      // 1. Consultar documento de configuración
      debugPrint('📡 [MAINTENANCE] Consultando app_config/global...');
      final doc = await _db.collection('app_config').doc('global').get();
      
      if (!doc.exists) {
        debugPrint('❌ [MAINTENANCE] El documento NO existe');
        debugPrint('✅ [MAINTENANCE] Resultado: null (permitir acceso)');
        return null;
      }
      
      final data = doc.data()!;
      debugPrint('✅ [MAINTENANCE] Documento encontrado');
      debugPrint('📄 [MAINTENANCE] Datos completos: $data');
      
      // 2. Extraer valores
      final maintenanceMode = data['maintenance_mode'] ?? false;
      final maintenanceMessage = data['maintenance_message']?.toString() ?? '';
      
      debugPrint('🔍 [MAINTENANCE] maintenance_mode: $maintenanceMode (${maintenanceMode.runtimeType})');
      debugPrint('🔍 [MAINTENANCE] maintenance_message: "$maintenanceMessage"');
      
      // 3. Si no está en modo mantenimiento, permitir acceso
      if (!maintenanceMode) {
        debugPrint('✅ [MAINTENANCE] Modo mantenimiento DESACTIVADO');
        debugPrint('✅ [MAINTENANCE] Resultado: null (permitir acceso)');
        return null;
      }
      
      debugPrint('⚠️ [MAINTENANCE] Modo mantenimiento ACTIVO');
      
      // 4. Verificar si el usuario actual es administrador
      final user = _auth.currentUser;
      debugPrint('👤 [MAINTENANCE] Usuario actual: ${user?.uid ?? "NO HAY USUARIO"}');
      
      if (user == null) {
        debugPrint('❌ [MAINTENANCE] No hay usuario autenticado');
        final msg = maintenanceMessage.isNotEmpty 
            ? maintenanceMessage 
            : 'La aplicación está en mantenimiento. Intente más tarde.';
        debugPrint('🚫 [MAINTENANCE] Resultado: BLOQUEAR - $msg');
        return msg;
      }
      
      // 5. Obtener el rol del usuario
      debugPrint('📡 [MAINTENANCE] Consultando perfil del usuario ${user.uid}...');
      final profileDoc = await _db.collection('profiles').doc(user.uid).get();
      
      if (!profileDoc.exists) {
        debugPrint('❌ [MAINTENANCE] Perfil NO existe');
        final msg = maintenanceMessage.isNotEmpty 
            ? maintenanceMessage 
            : 'La aplicación está en mantenimiento. Intente más tarde.';
        debugPrint('🚫 [MAINTENANCE] Resultado: BLOQUEAR - $msg');
        return msg;
      }
      
      final profileData = profileDoc.data()!;
      debugPrint('📄 [MAINTENANCE] Datos del perfil: $profileData');
      
      final role = profileData['role']?.toString().toLowerCase() ?? '';
      debugPrint('🔍 [MAINTENANCE] Rol del usuario: "$role"');
      
      final isAdmin = role == 'administrador' || role == 'admin';
      debugPrint('🔍 [MAINTENANCE] ¿Es admin?: $isAdmin');
      
      // 6. Si es admin, permitir acceso incluso en modo mantenimiento
      if (isAdmin) {
        debugPrint('✅ [MAINTENANCE] Usuario es ADMINISTRADOR');
        debugPrint('✅ [MAINTENANCE] Resultado: null (permitir acceso como admin)');
        return null;
      }
      
      // 7. Si no es admin, bloquear acceso con el mensaje
      final msg = maintenanceMessage.isNotEmpty 
          ? maintenanceMessage 
          : 'La aplicación está en mantenimiento. Intente más tarde.';
      debugPrint('🚫 [MAINTENANCE] Usuario NO es admin');
      debugPrint('🚫 [MAINTENANCE] Resultado: BLOQUEAR - $msg');
      debugPrint('═══════════════════════════════════════════════════════\n');
      return msg;
          
    } catch (e, stackTrace) {
      debugPrint('❌ [MAINTENANCE] ERROR: $e');
      debugPrint('📋 [MAINTENANCE] STACK TRACE: $stackTrace');
      debugPrint('✅ [MAINTENANCE] Resultado: null (permitir acceso por error)');
      debugPrint('═══════════════════════════════════════════════════════\n');
      // Si hay error, permitir acceso por defecto
      return null;
    }
  }

  /// Verifica si el modo mantenimiento está activo (sin verificar rol)
  Future<bool> isMaintenanceActive() async {
    try {
      final doc = await _db.collection('app_config').doc('global').get();
      if (!doc.exists) return false;
      return doc.data()?['maintenance_mode'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
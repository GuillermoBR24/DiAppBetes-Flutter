// lib/services/maintenance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MaintenanceService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Verifica si la app está en modo mantenimiento
  /// Retorna: 
  /// - null si no hay mantenimiento o el usuario es admin
  /// - String con el mensaje de mantenimiento si está bloqueado
  Future<String?> checkMaintenanceMode() async {
    print('\n═══════════════════════════════════════════════════════');
    print('🔧 [MAINTENANCE] Iniciando verificación de modo mantenimiento');
    print('═══════════════════════════════════════════════════════');
    
    try {
      // 1. Consultar documento de configuración
      print('📡 [MAINTENANCE] Consultando app_config/global...');
      final doc = await _db.collection('app_config').doc('global').get();
      
      if (!doc.exists) {
        print('❌ [MAINTENANCE] El documento NO existe');
        print('✅ [MAINTENANCE] Resultado: null (permitir acceso)');
        return null;
      }
      
      final data = doc.data()!;
      print('✅ [MAINTENANCE] Documento encontrado');
      print('📄 [MAINTENANCE] Datos completos: $data');
      
      // 2. Extraer valores
      final maintenanceMode = data['maintenance_mode'] ?? false;
      final maintenanceMessage = data['maintenance_message']?.toString() ?? '';
      
      print('🔍 [MAINTENANCE] maintenance_mode: $maintenanceMode (${maintenanceMode.runtimeType})');
      print('🔍 [MAINTENANCE] maintenance_message: "$maintenanceMessage"');
      
      // 3. Si no está en modo mantenimiento, permitir acceso
      if (!maintenanceMode) {
        print('✅ [MAINTENANCE] Modo mantenimiento DESACTIVADO');
        print('✅ [MAINTENANCE] Resultado: null (permitir acceso)');
        return null;
      }
      
      print('⚠️ [MAINTENANCE] Modo mantenimiento ACTIVO');
      
      // 4. Verificar si el usuario actual es administrador
      final user = _auth.currentUser;
      print('👤 [MAINTENANCE] Usuario actual: ${user?.uid ?? "NO HAY USUARIO"}');
      
      if (user == null) {
        print('❌ [MAINTENANCE] No hay usuario autenticado');
        final msg = maintenanceMessage.isNotEmpty 
            ? maintenanceMessage 
            : 'La aplicación está en mantenimiento. Intente más tarde.';
        print('🚫 [MAINTENANCE] Resultado: BLOQUEAR - $msg');
        return msg;
      }
      
      // 5. Obtener el rol del usuario
      print('📡 [MAINTENANCE] Consultando perfil del usuario ${user.uid}...');
      final profileDoc = await _db.collection('profiles').doc(user.uid).get();
      
      if (!profileDoc.exists) {
        print('❌ [MAINTENANCE] Perfil NO existe');
        final msg = maintenanceMessage.isNotEmpty 
            ? maintenanceMessage 
            : 'La aplicación está en mantenimiento. Intente más tarde.';
        print('🚫 [MAINTENANCE] Resultado: BLOQUEAR - $msg');
        return msg;
      }
      
      final profileData = profileDoc.data()!;
      print('📄 [MAINTENANCE] Datos del perfil: $profileData');
      
      final role = profileData['role']?.toString().toLowerCase() ?? '';
      print('🔍 [MAINTENANCE] Rol del usuario: "$role"');
      
      final isAdmin = role == 'administrador' || role == 'admin';
      print('🔍 [MAINTENANCE] ¿Es admin?: $isAdmin');
      
      // 6. Si es admin, permitir acceso incluso en modo mantenimiento
      if (isAdmin) {
        print('✅ [MAINTENANCE] Usuario es ADMINISTRADOR');
        print('✅ [MAINTENANCE] Resultado: null (permitir acceso como admin)');
        return null;
      }
      
      // 7. Si no es admin, bloquear acceso con el mensaje
      final msg = maintenanceMessage.isNotEmpty 
          ? maintenanceMessage 
          : 'La aplicación está en mantenimiento. Intente más tarde.';
      print('🚫 [MAINTENANCE] Usuario NO es admin');
      print('🚫 [MAINTENANCE] Resultado: BLOQUEAR - $msg');
      print('═══════════════════════════════════════════════════════\n');
      return msg;
          
    } catch (e, stackTrace) {
      print('❌ [MAINTENANCE] ERROR: $e');
      print('📋 [MAINTENANCE] STACK TRACE: $stackTrace');
      print('✅ [MAINTENANCE] Resultado: null (permitir acceso por error)');
      print('═══════════════════════════════════════════════════════\n');
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
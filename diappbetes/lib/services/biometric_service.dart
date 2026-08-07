// lib/services/biometric_service.dart
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Claves para SharedPreferences
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricUserIdKey = 'biometric_user_id';
  
  // Claves para FlutterSecureStorage (encriptadas)
  static const String _secureEmailKey = 'biometric_email';
  static const String _securePasswordKey = 'biometric_password';

  /// Verifica si el dispositivo soporta autenticación biométrica
  Future<bool> canCheckBiometrics() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (e) {
      debugPrint('❌ [BIOMETRIC] Error al verificar soporte: $e');
      return false;
    }
  }

  /// Verifica si hay biometría disponible
  Future<bool> isBiometricAvailable() async {
    try {
      final available = await _auth.isDeviceSupported();
      final biometrics = await _auth.getAvailableBiometrics();
      return available && biometrics.isNotEmpty;
    } catch (e) {
      debugPrint('❌ [BIOMETRIC] Error al verificar disponibilidad: $e');
      return false;
    }
  }

  /// Autentica al usuario con biometría
  Future<bool> authenticate() async {
    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: 'Autentícate para acceder a DiAppBetes',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      debugPrint('✅ [BIOMETRIC] Autenticación: $authenticated');
      return authenticated;
    } catch (e) {
      debugPrint('❌ [BIOMETRIC] Error en autenticación: $e');
      return false;
    }
  }

  /// Activa biometría para un usuario específico
  /// Solo se guarda si el usuario confirma y se verifica su huella
  Future<void> enableForUser({
    required String userId,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, true);
    await prefs.setString(_biometricUserIdKey, userId);
    await _secureStorage.write(key: _secureEmailKey, value: email);
    await _secureStorage.write(key: _securePasswordKey, value: password);
    debugPrint('✅ [BIOMETRIC] Habilitado para userId: $userId, email: $email');
  }

  /// Desactiva biometría completamente
  Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
    await prefs.remove(_biometricUserIdKey);
    await _secureStorage.delete(key: _secureEmailKey);
    await _secureStorage.delete(key: _securePasswordKey);
    debugPrint('✅ [BIOMETRIC] Deshabilitado completamente');
  }

  /// Verifica si la biometría está activada
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Obtiene el userId del usuario que tiene huella activa
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_biometricUserIdKey);
  }

  /// Obtiene las credenciales guardadas (solo si biometría está activa)
  Future<Map<String, String?>?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_biometricEnabledKey) ?? false;
    
    if (!enabled) return null;
    
    final email = await _secureStorage.read(key: _secureEmailKey);
    final password = await _secureStorage.read(key: _securePasswordKey);
    
    if (email == null || password == null) return null;
    
    return {'email': email, 'password': password};
  }

  /// Actualiza credenciales si el usuario actual tiene huella activa
  /// Se llama después de un login exitoso con email/password
  Future<void> updateCredentialsIfEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_biometricEnabledKey) ?? false;
    final savedUserId = prefs.getString(_biometricUserIdKey);
    
    // Solo actualizar si la biometría está activa Y es para el mismo usuario
    if (enabled && savedUserId == userId) {
      debugPrint('🔄 [BIOMETRIC] Actualizando credenciales para userId: $userId');
      // Las credenciales ya están guardadas, no necesitamos hacer nada
      // pero podríamos refrescar el password si cambió
    }
  }

  /// Verifica si el usuario actual tiene huella activada en su perfil
  /// Se usa para decidir si mostrar el botón de huella
  Future<bool> isCurrentUserBiometricEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_biometricEnabledKey) ?? false;
    final savedUserId = prefs.getString(_biometricUserIdKey);
    return enabled && savedUserId == userId;
  }
}
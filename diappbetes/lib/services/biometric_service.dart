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

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricUserIdKey = 'biometric_user_id';
  
  static const String _secureEmailKey = 'biometric_email';
  static const String _securePasswordKey = 'biometric_password';

  Future<bool> canCheckBiometrics() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final available = await _auth.isDeviceSupported();
      final biometrics = await _auth.getAvailableBiometrics();
      return available && biometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: 'Autentícate para acceder a DiAppBetes',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return authenticated;
    } catch (e) {
      return false;
    }
  }

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
  }

  Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
    await prefs.remove(_biometricUserIdKey);
    await _secureStorage.delete(key: _secureEmailKey);
    await _secureStorage.delete(key: _securePasswordKey);
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_biometricUserIdKey);
  }

  Future<Map<String, String?>?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_biometricEnabledKey) ?? false;
    
    if (!enabled) return null;
    
    final email = await _secureStorage.read(key: _secureEmailKey);
    final password = await _secureStorage.read(key: _securePasswordKey);
    
    if (email == null || password == null) return null;
    
    return {'email': email, 'password': password};
  }

  Future<void> updateCredentialsIfEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_biometricEnabledKey) ?? false;
    final savedUserId = prefs.getString(_biometricUserIdKey);
    
    if (enabled && savedUserId == userId) {
      debugPrint('🔄 [BIOMETRIC] Actualizando credenciales para userId: $userId');
    }
  }

  Future<bool> isCurrentUserBiometricEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_biometricEnabledKey) ?? false;
    final savedUserId = prefs.getString(_biometricUserIdKey);
    return enabled && savedUserId == userId;
  }
}
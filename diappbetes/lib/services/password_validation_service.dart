// lib/services/password_validation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PasswordValidationService {
  static final PasswordValidationService _instance = PasswordValidationService._internal();
  factory PasswordValidationService() => _instance;
  PasswordValidationService._internal();

  final _db = FirebaseFirestore.instance;

  // ── Verificar si la validación fuerte está activa ─────────────────────── //
  Future<bool> isStrongPasswordRequired() async {
    try {
      final doc = await _db.collection('app_config').doc('global').get();
      if (!doc.exists) return true; // Por defecto, requerir contraseña fuerte
      return doc.data()?['require_strong_password'] ?? true;
    } catch (e) {
      print('⚠️ [PASSWORD] Error obteniendo config: $e');
      return true; // Por seguridad, si falla, requerir contraseña fuerte
    }
  }

  // ── Validar contraseña según la configuración ─────────────────────────── //
  /// Retorna null si es válida, o un mensaje de error si no lo es
  Future<String?> validatePassword(String password) async {
    final requireStrong = await isStrongPasswordRequired();
    
    print('🔐 [PASSWORD] Validando contraseña...');
    print('🔐 [PASSWORD] ¿Requiere contraseña fuerte?: $requireStrong');
    
    if (!requireStrong) {
      // Validación básica (solo Firebase Auth)
      if (password.length < 6) {
        print('❌ [PASSWORD] Contraseña demasiado corta (mínimo 6 caracteres)');
        return 'La contraseña debe tener al menos 6 caracteres';
      }
      print('✅ [PASSWORD] Contraseña válida (modo básico)');
      return null;
    }

    // Validación fuerte
    final errors = <String>[];

    // Mínimo 8 caracteres
    if (password.length < 8) {
      errors.add('mínimo 8 caracteres');
    }

    // Al menos una letra mayúscula
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('al menos una letra mayúscula');
    }

    // Al menos una letra minúscula
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add('al menos una letra minúscula');
    }

    // Al menos un número
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      errors.add('al menos un número');
    }

    // Al menos un símbolo especial
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]').hasMatch(password)) {
      errors.add('al menos un símbolo especial (!@#\$%^&*...)');
    }

    if (errors.isNotEmpty) {
      final message = 'La contraseña debe contener: ${errors.join(', ')}';
      print('❌ [PASSWORD] Contraseña inválida: $message');
      return message;
    }

    print('✅ [PASSWORD] Contraseña válida (modo fuerte)');
    return null;
  }

  // ── Validación síncrona (para usar en validators de TextFormField) ────── //
  /// Versión síncrona que asume que la validación fuerte está activa
  /// Útil para validación en tiempo real mientras se escribe
  static String? validatePasswordSync(String? password, {bool requireStrong = true}) {
    if (password == null || password.isEmpty) {
      return 'La contraseña es obligatoria';
    }

    if (!requireStrong) {
      if (password.length < 6) {
        return 'Mínimo 6 caracteres';
      }
      return null;
    }

    // Validación fuerte
    final errors = <String>[];

    if (password.length < 8) {
      errors.add('8+ caracteres');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('1 mayúscula');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add('1 minúscula');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      errors.add('1 número');
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]').hasMatch(password)) {
      errors.add('1 símbolo');
    }

    if (errors.isNotEmpty) {
      return 'Falta: ${errors.join(', ')}';
    }

    return null;
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class PasswordValidationService {
  static final PasswordValidationService _instance = PasswordValidationService._internal();
  factory PasswordValidationService() => _instance;
  PasswordValidationService._internal();

  final _db = FirebaseFirestore.instance;

  Future<bool> isStrongPasswordRequired() async {
    try {
      final doc = await _db.collection('app_config').doc('global').get();
      if (!doc.exists) return true;
      return doc.data()?['require_strong_password'] ?? true;
    } catch (e) {
      return true;
    }
  }

  Future<String?> validatePassword(String password) async {
    final requireStrong = await isStrongPasswordRequired();
    
    if (!requireStrong) {
      if (password.length < 6) {
        return 'La contraseña debe tener al menos 6 caracteres';
      }
      return null;
    }

    final errors = <String>[];

    if (password.length < 8) {
      errors.add('mínimo 8 caracteres');
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('al menos una letra mayúscula');
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add('al menos una letra minúscula');
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      errors.add('al menos un número');
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]').hasMatch(password)) {
      errors.add('al menos un símbolo especial (!@#\$%^&*...)');
    }

    if (errors.isNotEmpty) {
      final message = 'La contraseña debe contener: ${errors.join(', ')}';
      return message;
    }
    return null;
  }

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
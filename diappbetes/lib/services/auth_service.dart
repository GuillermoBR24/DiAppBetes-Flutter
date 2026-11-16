import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'remember_me_service.dart';
import 'username_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _rememberMeService = RememberMeService();
  final _usernames = UsernameService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isLoggedIn =>
      _auth.currentUser != null && _auth.currentUser!.emailVerified;

  Future<void> register({
    required String email,
    required String password,
    String username = '',
    String birthDate = '',
  }) async {
    // Se reserva un nombre libre ANTES de crear la cuenta de Auth.
    final String finalUsername;
    if (username.isNotEmpty) {
      if (!await _usernames.isAvailable(username)) {
        throw FirebaseAuthException(
          code: 'username-already-in-use',
          message: 'Ese nombre de usuario ya está en uso.',
        );
      }
      finalUsername = username.trim();
    } else {
      finalUsername = await _usernames.suggestAvailable(email.split('@').first);
    }

    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final newUser = credential.user!;

    try {
      await _createProfileBatch(
        uid: newUser.uid,
        email: email,
        username: finalUsername,
        birthDate: birthDate,
      );
      await newUser.sendEmailVerification();
    } catch (_) {
      // Si falla el perfil no se deja una cuenta de Auth huérfana
      // (no podría iniciar sesión ni volver a registrarse con ese email).
      try {
        await newUser.delete();
      } catch (_) {
        await _auth.signOut();
      }
      rethrow;
    }

    await _auth.signOut();
  }

  Future<void> _createProfileBatch({
    required String uid,
    required String email,
    required String username,
    required String birthDate,
  }) async {
    final finalUsername = username;
    final batch = _db.batch();
    _usernames.writeClaim(batch, uid: uid, email: email, username: finalUsername);
    batch.set(_db.collection('profiles').doc(uid), {
      'id': uid,
      'username': finalUsername,
      'username_lower': UsernameService.normalize(finalUsername),
      'email': email,
      'birth_date': birthDate.isEmpty ? null : birthDate,
      'role': 'Usuario',
      'fsi': 50.0,
      'avatar_base64': null,
      'email_verified': false,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

    Future<UserCredential> login({
      required String identifier,
      required String password,
      bool rememberMe = false,
    }) async {
      final cleanIdentifier = identifier.trim();
      String email = cleanIdentifier.toLowerCase();
      if (!cleanIdentifier.contains('@')) {
        final found = await _usernames.lookupEmail(cleanIdentifier);
        if (found == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No se encontró ningún usuario con ese nombre.',
          );
        }
        email = found;
      }
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user!.reload();
      final freshUser = _auth.currentUser!;

      if (!freshUser.emailVerified) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Debes verificar tu correo antes de iniciar sesión.',
        );
      }

      await _db.collection('profiles').doc(freshUser.uid).update({
        'email_verified': true,
        'updated_at': FieldValue.serverTimestamp(),
      });
      await _rememberMeService.setRememberMe(rememberMe);

      return credential;
    }

  Future<void> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.sendEmailVerification();
    await _auth.signOut();
  }

  Future<void> logout() async {
    await _rememberMeService.clear();
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<Map<String, dynamic>?> getMyProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('profiles').doc(uid).get();
    return doc.data();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _db.collection('profiles').doc(uid).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  static String translateError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-not-verified':
        return 'Debes verificar tu correo antes de iniciar sesión.';
      case 'user-not-found':
        return 'No existe ninguna cuenta con ese email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Credenciales incorrectas.';
      case 'username-already-in-use':
        return 'Ese nombre de usuario ya está en uso.';
      case 'email-already-in-use':
        return 'Este email ya está registrado.';
      case 'invalid-email':
        return 'Formato del email incorrecto.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'too-many-requests':
        return 'Demasiados intentos. Inténtalo más tarde.';
      case 'network-request-failed':
        return 'No se pudo conectar con el servidor.';
      default:
        return 'Error: ${e.message}';
    }
  }
}
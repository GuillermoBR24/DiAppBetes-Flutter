
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'remember_me_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _rememberMeService = RememberMeService();

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
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await credential.user!.sendEmailVerification();

    final uid = credential.user!.uid;
    await FirebaseFirestore.instance.collection('profiles').doc(uid).set({
      'id': uid,
      'username': username.isNotEmpty ? username : email.split('@').first,
      'username_lower': (username.isNotEmpty ? username : email.split('@').first).toLowerCase(),
      'email': email,
      'birth_date': birthDate.isEmpty ? null : birthDate,
      'role': 'Usuario',
      'fsi': 50.0,
      'avatar_base64': null,
      'email_verified': false,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await _auth.signOut();
  }

    Future<UserCredential> login({
      required String identifier,
      required String password,
      bool rememberMe = false,
    }) async {
      String email = identifier;
      if (!identifier.contains('@')) {
        final cleanIdentifier = identifier.trim().toLowerCase();
        
        try {
          final query = await _db
              .collection('profiles')
              .where('username_lower', isEqualTo: cleanIdentifier)
              .limit(1)
              .get();

          if (query.docs.isEmpty) {
            throw FirebaseAuthException(
              code: 'user-not-found',
              message: 'No se encontró ningún usuario con ese nombre.',
            );
          }

          final userData = query.docs.first.data();
          email = userData['email'] as String;
        } catch (e) {
          rethrow;
        }
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

  Future<void> deleteAccount() async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _db.collection('profiles').doc(uid).delete();
    await currentUser!.delete();
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
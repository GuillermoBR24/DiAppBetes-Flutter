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

  // ── REGISTER ──────────────────────────────────────────────────────────── //
  Future<void> register({
    required String email,
    required String password,
    String username = '',
    String birthDate = '',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user!.sendEmailVerification();

    final uid = credential.user!.uid;
    final resolvedUsername = username.isNotEmpty ? username : email.split('@').first;

    await _db.collection('profiles').doc(uid).set({
      'id':             uid,
      'username':       resolvedUsername.toLowerCase(),
      'email':          email,
      'birth_date':     birthDate.isEmpty ? null : birthDate,
      'role':           'Usuario',
      'fsi':            50.0,
      'avatar_base64':  null,
      'email_verified': false,
      'created_at':     FieldValue.serverTimestamp(),
      'updated_at':     FieldValue.serverTimestamp(),
    });

    await _auth.signOut();
  }

  // ── LOGIN ─────────────────────────────────────────────────────────────── //
  // [rememberMe]: si es true, la sesión persiste indefinidamente en este
  // dispositivo. Si es false, expirará tras RememberMeService.sessionTimeout
  // de inactividad (gestionado por _AuthWrapper en main.dart).
  Future<UserCredential> login({
    required String identifier,
    required String password,
    bool rememberMe = false,
  }) async {
    String email = identifier;

    if (!identifier.contains('@')) {
      print('🔎 Buscando usuario: $identifier');
      try {
        final query = await _db
            .collection('profiles')
            .where('username', isEqualTo: identifier.toLowerCase())
            .limit(1)
            .get();

        print('📄 Documentos encontrados: ${query.docs.length}');

        if (query.docs.isEmpty) {
          print('❌ No se encontró el usuario en Firestore');
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No se encontró ningún usuario con ese nombre.',
          );
        }

        final userData = query.docs.first.data();
        print('✅ Usuario encontrado: ${userData['email']}');
        email = userData['email'] as String;
      } catch (e) {
        print('❌ Error buscando en Firestore: $e');
        rethrow;
      }
    }

    print('🔑 Intentando login con email: $email');

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

    // ── Guardar preferencia "Recuérdame" para este dispositivo ─────────── //
    await _rememberMeService.setRememberMe(rememberMe);

    return credential;
  }

  // ── REENVIAR EMAIL DE VERIFICACIÓN ───────────────────────────────────── //
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

  // ── LOGOUT ────────────────────────────────────────────────────────────── //
  Future<void> logout() async {
    await _rememberMeService.clear();
    await _auth.signOut();
  }

  // ── RESET PASSWORD ────────────────────────────────────────────────────── //
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── PERFIL ────────────────────────────────────────────────────────────── //
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

  // ── TRADUCIR ERRORES ──────────────────────────────────────────────────── //
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
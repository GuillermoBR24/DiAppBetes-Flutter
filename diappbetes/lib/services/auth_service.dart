import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'remember_me_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  static const String _baseUrl = 'http://localhost:8080/api/auth';

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
    // 1. Firebase Auth crea el usuario (esto sigue siendo del cliente)
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user!.sendEmailVerification();

    final idToken = await credential.user!.getIdToken();

    // 2. El backend Java crea el perfil en Firestore con valores seguros
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'username': username,
        'birthDate': birthDate,
      }),
    );

    if (response.statusCode != 200) {
      // Si falla la creación del perfil, revertimos el registro
      await credential.user!.delete();
      throw Exception('No se pudo crear el perfil: ${response.body}');
    }

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

    // 1. Si es un username, se lo pedimos al backend
    if (!identifier.contains('@')) {
      final resp = await http.get(
        Uri.parse('$_baseUrl/resolve-email?username=${Uri.encodeQueryComponent(identifier.trim())}'),
      );

      if (resp.statusCode != 200) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No se encontró ningún usuario con ese nombre.',
        );
      }

      final data = jsonDecode(resp.body);
      email = data['email'];
    }

    // 2. Firebase Auth verifica la contraseña (esto sigue siendo del cliente)
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

    // 3. El backend confirma el login y sincroniza el perfil
    final idToken = await freshUser.getIdToken();
    final resp = await http.post(
      Uri.parse('$_baseUrl/login-confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (resp.statusCode != 200) {
      await _auth.signOut();
      throw Exception('Error confirmando login: ${resp.body}');
    }

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
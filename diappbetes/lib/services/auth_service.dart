// lib/services/auth_service.dart
import 'package:diappbetes/services/biometric_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isLoggedIn =>
      _auth.currentUser != null && _auth.currentUser!.emailVerified;

  // ── Obtener configuración global con logs ───────────────────────────── //
  Future<Map<String, dynamic>> _getGlobalConfig() async {
    print('\n═══════════════════════════════════════════════════════');
    print('⚙️ [AUTH] Obteniendo configuración global...');
    
    try {
      // Forzar lectura fresca (sin caché)
      final doc = await _db.collection('app_config').doc('global').get(const GetOptions(source: Source.server));
      
      if (!doc.exists) {
        print('❌ [AUTH] Documento app_config/global NO existe');
        print('✅ [AUTH] Usando valores por defecto del código');
        print('═══════════════════════════════════════════════════════\n');
        return {
          'default_fsi': 50.0,
          'default_ratio': 10.0,
          'default_glucose_min': 70.0,
          'default_glucose_max': 180.0,
        };
      }
      
      final data = doc.data()!;
      print('✅ [AUTH] Documento encontrado');
      print('📄 [AUTH] Datos completos: $data');
      print('🔍 [AUTH] Tipo de default_fsi: ${data['default_fsi']?.runtimeType}');
      print('🔍 [AUTH] Tipo de default_ratio: ${data['default_ratio']?.runtimeType}');
      print('═══════════════════════════════════════════════════════\n');
      
      return data;
    } catch (e, stackTrace) {
      print('❌ [AUTH] ERROR obteniendo config: $e');
      print('📋 [AUTH] STACK: $stackTrace');
      print('✅ [AUTH] Usando valores por defecto del código');
      print('═══════════════════════════════════════════════════════\n');
      return {
        'default_fsi': 50.0,
        'default_ratio': 10.0,
        'default_glucose_min': 70.0,
        'default_glucose_max': 180.0,
      };
    }
  }

  // ── REGISTER con logs detallados ──────────────────────────────────────── //
  Future<void> register({
    required String email,
    required String password,
    String username = '',
    String birthDate = '',
  }) async {
    print('\n═══════════════════════════════════════════════════════');
    print('📝 [AUTH] Iniciando registro de usuario...');
    print('═══════════════════════════════════════════════════════');
    
    // 1. Obtener configuración global
    final config = await _getGlobalConfig();
    
    // Extraer valores con conversión segura
    final defaultFsi = _extractDouble(config['default_fsi'], 50.0);
    final defaultRatio = _extractDouble(config['default_ratio'], 10.0);
    
    print('📊 [AUTH] Valores extraídos:');
    print('   - FSI: $defaultFsi (tipo: ${defaultFsi.runtimeType})');
    print('   - Ratio HC: $defaultRatio (tipo: ${defaultRatio.runtimeType})');

    // 2. Crear usuario en Firebase Auth
    print('📡 [AUTH] Creando usuario en Firebase Auth...');
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    print('✅ [AUTH] Usuario creado en Auth: ${credential.user!.uid}');

    // 3. Enviar email de verificación
    print('📧 [AUTH] Enviando email de verificación...');
    await credential.user!.sendEmailVerification();
    print('✅ [AUTH] Email enviado');

    // 4. Crear perfil en Firestore con valores por defecto
    final uid = credential.user!.uid;
    final resolvedUsername = username.isNotEmpty ? username : email.split('@').first;

    print('📡 [AUTH] Creando perfil en Firestore...');
    await _db.collection('profiles').doc(uid).set({
      'id':           uid,
      'username':     resolvedUsername.toLowerCase(),
      'email':        email,
      'birth_date':   birthDate.isEmpty ? null : birthDate,
      'role':         'Usuario',
      'fsi':          defaultFsi,
      'avatar_url':   null,
      'email_verified': false,
      'created_at':   FieldValue.serverTimestamp(),
      'updated_at':   FieldValue.serverTimestamp(),
    });
    print('✅ [AUTH] Perfil creado con FSI: $defaultFsi');

    // 5. Crear ratio HC inicial
    print('📡 [AUTH] Creando ratio HC inicial...');
    await _db.collection('hc_ratios').add({
      'user_id': uid,
      'start_time': '00:00',
      'end_time': '23:59',
      'ratio_value': defaultRatio,
      'created_at': FieldValue.serverTimestamp(),
    });
    print('✅ [AUTH] Ratio HC creado con valor: $defaultRatio');

    print('✅ [AUTH] Registro completado exitosamente');
    print('═══════════════════════════════════════════════════════\n');

    // 6. Cerrar sesión
    await _auth.signOut();
  }

  // ── Helper para extraer double de forma segura ──────────────────────── //
  double _extractDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  // ── LOGIN ─────────────────────────────────────────────────────────────── //
  Future<UserCredential> login({
    required String identifier,
    required String password,
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

    final biometricService = BiometricService();
    final isEnabled = await biometricService.isCurrentUserBiometricEnabled(freshUser.uid);
    if (isEnabled) {
      print(' [AUTH] Usuario tiene huella activa, guardando credenciales');
      await biometricService.enableForUser(
        userId: freshUser.uid,
        email: email,
        password: password,
      );
    }

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
  Future<void> logout() async => await _auth.signOut();

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
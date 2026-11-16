import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Índice público `usernames/{username_en_minusculas}` -> {uid, email, username}.
///
/// Permite iniciar sesión con nombre de usuario SIN Cloud Functions (plan Spark)
/// y sin dejar `profiles` legible por todos: las reglas permiten `get` de un
/// documento concreto, pero prohíben `list`, así que no se puede enumerar.
class UsernameService {
  static final UsernameService _instance = UsernameService._internal();
  factory UsernameService() => _instance;
  UsernameService._internal();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static String normalize(String username) => username.trim().toLowerCase();

  DocumentReference<Map<String, dynamic>> _ref(String username) =>
      _db.collection('usernames').doc(normalize(username));

  /// Email asociado a un nombre de usuario, o null si no existe.
  Future<String?> lookupEmail(String username) async {
    final key = normalize(username);
    if (key.isEmpty || key.contains('/')) return null;
    final doc = await _ref(key).get();
    return doc.data()?['email'] as String?;
  }

  /// ¿Está libre el nombre (o es del propio usuario `uid`)?
  Future<bool> isAvailable(String username, {String? uid}) async {
    final key = normalize(username);
    if (key.isEmpty || key.contains('/')) return false;
    final doc = await _ref(key).get();
    if (!doc.exists) return true;
    return uid != null && doc.data()?['uid'] == uid;
  }

  /// Genera un nombre libre a partir de una base (p. ej. la parte local del email).
  Future<String> suggestAvailable(String base) async {
    var clean = normalize(base).replaceAll('/', '');
    if (clean.isEmpty) clean = 'usuario';
    if (await isAvailable(clean)) return clean;
    for (var i = 0; i < 8; i++) {
      final candidate = '$clean${(DateTime.now().microsecondsSinceEpoch + i * 7919) % 10000}';
      if (await isAvailable(candidate)) return candidate;
    }
    return '$clean${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Escribe en `batch` el alta del nombre nuevo y la baja del anterior.
  void writeClaim(
    WriteBatch batch, {
    required String uid,
    required String email,
    required String username,
    String? previousUsername,
  }) {
    final key = normalize(username);
    batch.set(_ref(key), {
      'uid': uid,
      'email': email,
      'username': username.trim(),
      'username_lower': key,
    });
    if (previousUsername != null &&
        previousUsername.trim().isNotEmpty &&
        normalize(previousUsername) != key) {
      batch.delete(_ref(previousUsername));
    }
  }

  /// Autorreparación para cuentas anteriores a este índice: se llama con la
  /// sesión iniciada y crea su entrada si falta o está desactualizada.
  Future<void> ensureForCurrentUser() async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return;

    try {
      final profile = await _db.collection('profiles').doc(user.uid).get();
      final username = profile.data()?['username']?.toString().trim() ?? '';
      if (username.isEmpty) return;

      final ref = _ref(username);
      final existing = await ref.get();
      if (existing.exists) {
        final d = existing.data()!;
        if (d['uid'] != user.uid) return; // nombre de otra persona: no tocar
        if (d['email'] == email) return; // ya está al día
      }
      await ref.set({
        'uid': user.uid,
        'email': email,
        'username': username,
        'username_lower': normalize(username),
      });
    } catch (_) {
      // Mejor esfuerzo: nunca debe romper el arranque de la app.
    }
  }
}

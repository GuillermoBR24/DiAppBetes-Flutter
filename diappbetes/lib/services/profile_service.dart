import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Obtener perfil ────────────────────────────────────────────────────── //
  Future<Map<String, dynamic>?> getMyProfile() async {
    if (_uid == null) {
      print('⚠️ No hay UID de usuario');
      return null;
    }
    
    print('🔍 Buscando perfil con UID: $_uid');
    final doc = await _db.collection('profiles').doc(_uid).get();
    
    if (!doc.exists) {
      print('❌ Documento no encontrado para UID: $_uid');
      // Intentar buscar por email como fallback
      final query = await _db.collection('profiles')
          .where('email', isEqualTo: _auth.currentUser?.email)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        print('✅ Encontrado por email: ${query.docs.first.id}');
        return query.docs.first.data();
      }
      
      return null;
    }
    
    print('✅ Perfil encontrado');
    return doc.data();
  }

  Future<void> ensureProfileExists() async {
    final uid = _uid;
    if (uid == null) return;
 
    final user = _auth.currentUser!;
    debugPrint('🔧 ProfileService.ensureProfileExists: creando perfil para uid=$uid');
 
    await _db.collection('profiles').doc(uid).set({
      'id':             uid,
      'username':       user.displayName ?? user.email?.split('@').first ?? 'usuario',
      'email':          user.email ?? '',
      'phone':          '',
      'birth_date':     '',
      'role':           'usuario',
      'fsi':            50.0,
      'avatar_url':     null,
      'email_verified': user.emailVerified,
      'created_at':     FieldValue.serverTimestamp(),
      'updated_at':     FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // merge: true para no sobreescribir si ya existe parcialmente
 
    debugPrint('✅ ProfileService.ensureProfileExists: perfil creado/actualizado');
  }

  // ── Stream en tiempo real (para escuchar cambios) ─────────────────────── //
  Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream() {
    return _db.collection('profiles').doc(_uid).snapshots();
  }

  // ── Actualizar info personal ──────────────────────────────────────────── //
  Future<void> updatePersonalInfo({
    required String username,
    required String email,
    required String birthDate,
    required String phone,
  }) async {
    if (_uid == null) return;

    // Si cambió el email, actualizarlo también en Firebase Auth
    final currentEmail = _auth.currentUser?.email ?? '';
    if (email != currentEmail) {
      await _auth.currentUser!.verifyBeforeUpdateEmail(email);
    }

    await _db.collection('profiles').doc(_uid).update({
      'username':   username,
      'email':      email,
      'birth_date': birthDate,
      'phone':      phone,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Actualizar FSI ────────────────────────────────────────────────────── //
  Future<void> updateFsi(double fsi) async {
    if (_uid == null) return;
    await _db.collection('profiles').doc(_uid).update({
      'fsi':        fsi,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Eliminar cuenta completa ──────────────────────────────────────────── //
  // Borra: perfil, hc_ratios, meals, glucose_readings, user_tips del usuario
  Future<void> deleteAccount() async {
    if (_uid == null) return;
    final uid = _uid!;
    final batch = _db.batch();

    // Perfil
    batch.delete(_db.collection('profiles').doc(uid));

    // HC Ratios
    final ratios = await _db
        .collection('hc_ratios')
        .where('user_id', isEqualTo: uid)
        .get();
    for (final doc in ratios.docs) batch.delete(doc.reference);

    // Meals (y sus subcolecciones meal_foods)
    final meals = await _db
        .collection('meals')
        .where('user_id', isEqualTo: uid)
        .get();
    for (final meal in meals.docs) {
      final foods = await meal.reference.collection('meal_foods').get();
      for (final food in foods.docs) batch.delete(food.reference);
      batch.delete(meal.reference);
    }

    // Lecturas de glucosa
    final readings = await _db
        .collection('glucose_readings')
        .where('user_id', isEqualTo: uid)
        .get();
    for (final doc in readings.docs) batch.delete(doc.reference);

    // User tips
    final tips = await _db
        .collection('user_tips')
        .where('user_id', isEqualTo: uid)
        .get();
    for (final doc in tips.docs) batch.delete(doc.reference);

    await batch.commit();

    // Eliminar usuario de Firebase Auth (debe ser la última operación)
    await _auth.currentUser!.delete();
  }
}
// lib/services/profile_service.dart
import 'dart:convert';
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
      'username':       user.displayName ?? user.email?.split('@').first ?? 'Usuario',
      'email':          user.email ?? '',
      'birth_date':     '',
      'role':           'Usuario',
      'fsi':            50.0,
      'avatar_base64':  null, // ← CAMBIO: ahora guardamos base64
      'email_verified': user.emailVerified,
      'created_at':     FieldValue.serverTimestamp(),
      'updated_at':     FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
 
    debugPrint('✅ ProfileService.ensureProfileExists: perfil creado/actualizado');
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream() {
    return _db.collection('profiles').doc(_uid).snapshots();
  }

  Future<void> updatePersonalInfo({
    required String username,
    required String email,
    required String birthDate,
  }) async {
    if (_uid == null) return;

    final currentEmail = _auth.currentUser?.email ?? '';
    if (email != currentEmail) {
      await _auth.currentUser!.verifyBeforeUpdateEmail(email);
    }

    await _db.collection('profiles').doc(_uid).update({
      'username':   username,
      'email':      email,
      'birth_date': birthDate,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFsi(double fsi) async {
    if (_uid == null) return;
    await _db.collection('profiles').doc(_uid).update({
      'fsi':        fsi,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NUEVO: SISTEMA DE AVATAR EN BASE64 (sin Firebase Storage)
  // ═══════════════════════════════════════════════════════════════════════

  /// Guarda el avatar del usuario como base64 en Firestore
  /// [imageBytes]: Bytes de la imagen (ya comprimida)
  /// Retorna true si se guardó correctamente
  Future<bool> updateAvatarBase64(List<int> imageBytes) async {
    if (_uid == null) {
      print('❌ [AVATAR] No hay usuario autenticado');
      return false;
    }

    try {
      print('📤 [AVATAR] Convirtiendo imagen a base64...');
      
      // Convertir a base64
      final base64String = base64Encode(imageBytes);
      final sizeKB = (base64String.length / 1024).toStringAsFixed(1);
      
      print('📏 [AVATAR] Tamaño base64: $sizeKB KB');
      
      // Validar tamaño (Firestore límite 1MB por documento, dejamos margen)
      if (base64String.length > 800 * 1024) { // 800 KB
        print('❌ [AVATAR] Imagen demasiado grande: $sizeKB KB');
        return false;
      }
      
      // Guardar en Firestore
      await _db.collection('profiles').doc(_uid).update({
        'avatar_base64': base64String,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      print('✅ [AVATAR] Avatar guardado correctamente en Firestore');
      return true;
    } catch (e, stackTrace) {
      print('❌ [AVATAR] Error al guardar avatar: $e');
      print('📋 [AVATAR] Stack: $stackTrace');
      return false;
    }
  }

  /// Elimina el avatar del usuario
  Future<void> deleteAvatar() async {
    if (_uid == null) return;

    try {
      print('🗑️ [AVATAR] Eliminando avatar...');
      
      await _db.collection('profiles').doc(_uid).update({
        'avatar_base64': null,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      print('✅ [AVATAR] Avatar eliminado correctamente');
    } catch (e) {
      print('❌ [AVATAR] Error al eliminar avatar: $e');
    }
  }

  // ── Eliminar cuenta completa ──────────────────────────────────────────── //
  Future<void> deleteAccount() async {
    if (_uid == null) return;
    final uid = _uid!;
    final batch = _db.batch();

    batch.delete(_db.collection('profiles').doc(uid));

    final ratios = await _db
        .collection('hc_ratios')
        .where('user_id', isEqualTo: uid)
        .get();
    for (final doc in ratios.docs) batch.delete(doc.reference);

    final meals = await _db
        .collection('meals')
        .where('user_id', isEqualTo: uid)
        .get();
    for (final meal in meals.docs) {
      final foods = await meal.reference.collection('meal_foods').get();
      for (final food in foods.docs) batch.delete(food.reference);
      batch.delete(meal.reference);
    }

    final readings = await _db
        .collection('glucose_readings')
        .where('user_id', isEqualTo: uid)
        .get();
    for (final doc in readings.docs) batch.delete(doc.reference);

    final tips = await _db
        .collection('user_tips')
        .where('user_id', isEqualTo: uid)
        .get();
    for (final doc in tips.docs) batch.delete(doc.reference);

    await batch.commit();
    await _auth.currentUser!.delete();
  }

  Future<void> updateCeliacMode(bool enabled) async {
    if (_uid == null) return;
    await _db.collection('profiles').doc(_uid).update({
      'celiac_mode': enabled,
      'updated_at': FieldValue.serverTimestamp(),
    });
    print('✅ [CELIAC] Modo celíaco actualizado: $enabled');
  }

  Future<bool> getCeliacMode() async {
    final profile = await getMyProfile();
    return profile?['celiac_mode'] == true;
  }

  Future<void> setBiometricLoginEnabled(bool enabled) async {
    if (_uid == null) return;
    await _db.collection('profiles').doc(_uid).update({
      'biometric_login_enabled': enabled,
      'updated_at': FieldValue.serverTimestamp(),
    });
    print('✅ [PROFILE] Biometric login: $enabled');
  }

  Future<bool> isBiometricLoginEnabled() async {
    final profile = await getMyProfile();
    return profile?['biometric_login_enabled'] == true;
  }

  Future<double> getUserFsi() async {
    final profile = await getMyProfile();
    return (profile?['fsi'] as num?)?.toDouble() ?? 50.0;
  }
}
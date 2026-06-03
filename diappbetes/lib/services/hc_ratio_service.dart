import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diappbetes/screens/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HcRatioService {
  static final HcRatioService _instance = HcRatioService._internal();
  factory HcRatioService() => _instance;
  HcRatioService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Obtener ratios HC del usuario ─────────────────────────────────────── //
  Future<List<Map<String, dynamic>>> getHcRatios() async {
    if (_uid == null) return [];
    final snap = await _db
        .collection('hc_ratios')
        .where('user_id', isEqualTo: _uid)
        .orderBy('start_time')
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<double> getCurrentHcRatio() async {
    final ratios = await getHcRatios();
    if (ratios.isEmpty) return 10.0;
    
    final now = TimeOfDay.now();
    final currentMins = now.hour * 60 + now.minute;
    
    for (final ratio in ratios) {
      final startMins = HcRatio.parse(ratio['start_time']?.toString() ?? '00:00');
      final endMins = HcRatio.parse(ratio['end_time']?.toString() ?? '23:59');
      
      if (currentMins >= startMins && currentMins < endMins) {
        return (ratio['ratio_value'] as num?)?.toDouble() ?? 10.0;
      }
    }
    
    return (ratios.first['ratio_value'] as num?)?.toDouble() ?? 10.0;
  }

  // ── Guardar todos los ratios (borra los anteriores y crea los nuevos) ─── //
  Future<void> saveAll(List<Map<String, dynamic>> ratios) async {
    if (_uid == null) return;
    final batch = _db.batch();

    // Borrar ratios existentes
    final existing = await _db
        .collection('hc_ratios')
        .where('user_id', isEqualTo: _uid)
        .get();
    for (final doc in existing.docs) batch.delete(doc.reference);

    // Crear los nuevos
    for (final ratio in ratios) {
      final ref = _db.collection('hc_ratios').doc();
      batch.set(ref, {
        'user_id':     _uid,
        'start_time':  ratio['start_time'],
        'end_time':    ratio['end_time'],
        'ratio_value': ratio['ratio_value'],
        'created_at':  FieldValue.serverTimestamp(),
        'updated_at':  FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
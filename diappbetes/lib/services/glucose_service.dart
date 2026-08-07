import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class GlucoseService {
  static final GlucoseService _instance = GlucoseService._internal();
  factory GlucoseService() => _instance;
  GlucoseService._internal();

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Última lectura de glucosa ─────────────────────────────────────────── //
  // Lee directamente de glucose_readings ordenado por reading_time desc
  Future<String> getLatestGlucoseFormatted() async {
    if (_uid == null) return 'Sin lecturas';
    try {
      final snap = await _db
          .collection('glucose_readings')
          .where('user_id', isEqualTo: _uid)
          .orderBy('reading_time', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return 'Sin lecturas recientes';

      final data  = snap.docs.first.data();
      final level = (data['glucose_level'] as num?)?.toStringAsFixed(0) ?? '—';
      final ts    = data['reading_time'] as Timestamp?;
      final time  = ts?.toDate();

      if (time == null) return '$level mg/dL';

      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      return '$level mg/dL — $h:$m';
    } catch (e) {
      // Si falta el índice compuesto, intenta sin orderBy como fallback
      try {
        final snap = await _db
            .collection('glucose_readings')
            .where('user_id', isEqualTo: _uid)
            .get();

        if (snap.docs.isEmpty) return 'Sin lecturas recientes';

        // Ordena en cliente
        final docs = snap.docs.toList()
          ..sort((a, b) {
            final ta = a.data()['reading_time'] as Timestamp?;
            final tb = b.data()['reading_time'] as Timestamp?;
            if (ta == null || tb == null) return 0;
            return tb.compareTo(ta);
          });

        final data  = docs.first.data();
        final level = (data['glucose_level'] as num?)?.toStringAsFixed(0) ?? '—';
        final ts    = data['reading_time'] as Timestamp?;
        final time  = ts?.toDate();
        if (time == null) return '$level mg/dL';
        final h = time.hour.toString().padLeft(2, '0');
        final m = time.minute.toString().padLeft(2, '0');
        return '$level mg/dL — $h:$m';
      } catch (_) {
        return 'Sin lecturas recientes';
      }
    }
  }

  Future<List<Map<String, dynamic>>> getGlucoseReadingsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snap = await _db
          .collection('glucose_readings')
          .where('user_id', isEqualTo: _uid)
          .orderBy('reading_time', descending: true)
          .get();

      return snap.docs.where((doc) {
        final timestamp = doc.data()['reading_time'] as Timestamp?;
        if (timestamp == null) return false;
        final date = timestamp.toDate();
        return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(endDate.add(const Duration(days: 1)));
      }).map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Error getting readings by range: $e');
      return [];
    }
  }
}
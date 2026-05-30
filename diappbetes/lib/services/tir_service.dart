import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TirService {
  static final TirService _instance = TirService._internal();
  factory TirService() => _instance;
  TirService._internal();

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── % lecturas en rango 70–180 mg/dL (últimos 7 días) ────────────────── //
  // Además extrae el dato de glucemia de las comidas si no hay lecturas
  // separadas, para que el TIR funcione aunque el usuario solo use add_meal
  Future<int> getTirPercentage() async {
    if (_uid == null) return 0;

    final since = DateTime.now().subtract(const Duration(days: 7));

    // 1. Intenta leer glucose_readings (lecturas independientes)
    final readings = await _readingsInRange(since);

    // 2. Si no hay lecturas, usa los glucose_level de las comidas como fuente
    final levels = readings.isNotEmpty
        ? readings
        : await _levelsFromMeals(since);

    if (levels.isEmpty) return 0;

    final inRange = levels.where((v) => v >= 70 && v <= 180).length;
    return ((inRange / levels.length) * 100).round();
  }

  Future<List<double>> _readingsInRange(DateTime since) async {
    try {
      final snap = await _db
          .collection('glucose_readings')
          .where('user_id', isEqualTo: _uid)
          .where('reading_time',
              isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .get();

      return snap.docs
          .map((d) => (d.data()['glucose_level'] as num?)?.toDouble() ?? 0.0)
          .where((v) => v > 0)
          .toList();
    } catch (_) {
      // Fallback sin filtro de fecha si falta índice
      try {
        final snap = await _db
            .collection('glucose_readings')
            .where('user_id', isEqualTo: _uid)
            .get();

        return snap.docs.where((d) {
          final ts = d.data()['reading_time'] as Timestamp?;
          return ts != null && ts.toDate().isAfter(since);
        }).map((d) => (d.data()['glucose_level'] as num?)?.toDouble() ?? 0.0)
            .where((v) => v > 0)
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<List<double>> _levelsFromMeals(DateTime since) async {
    try {
      final snap = await _db
          .collection('meals')
          .where('user_id', isEqualTo: _uid)
          .get();

      return snap.docs.where((d) {
        final ts = d.data()['created_at'] as Timestamp?;
        return ts != null && ts.toDate().isAfter(since);
      }).map((d) => (d.data()['glucose_level'] as num?)?.toDouble() ?? 0.0)
          .where((v) => v > 0)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
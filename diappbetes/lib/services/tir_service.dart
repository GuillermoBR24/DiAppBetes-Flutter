// lib/services/tir_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TirService {
  static final TirService _instance = TirService._internal();
  factory TirService() => _instance;
  TirService._internal();

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Obtener configuración global ────────────────────────────────────── //
  Future<Map<String, dynamic>> _getGlobalConfig() async {
    try {
      final doc = await _db.collection('app_config').doc('global').get();
      if (doc.exists) {
        return doc.data()!;
      }
    } catch (e) {
      print('⚠️ [TIR] Error obteniendo config global: $e');
    }
    // Valores por defecto si no existe el documento
    return {
      'default_glucose_min': 70.0,
      'default_glucose_max': 180.0,
    };
  }

  // ── % lecturas en rango configurado (últimos 7 días) ────────────────── //
  Future<int> getTirPercentage() async {
    if (_uid == null) return 0;

    // Obtener rangos configurados
    final config = await _getGlobalConfig();
    final glucoseMin = (config['default_glucose_min'] as num?)?.toDouble() ?? 70.0;
    final glucoseMax = (config['default_glucose_max'] as num?)?.toDouble() ?? 180.0;
    
    print('📊 [TIR] Rangos de glucosa configurados: $glucoseMin - $glucoseMax mg/dL');

    final since = DateTime.now().subtract(const Duration(days: 7));

    // 1. Intenta leer glucose_readings (lecturas independientes)
    final readings = await _readingsInRange(since);

    // 2. Si no hay lecturas, usa los glucose_level de las comidas como fuente
    final levels = readings.isNotEmpty
        ? readings
        : await _levelsFromMeals(since);

    if (levels.isEmpty) return 0;

    // 3. Calcular % en rango usando valores configurados
    final inRange = levels.where((v) => v >= glucoseMin && v <= glucoseMax).length;
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

  Future<int> getTirPercentageForRange(DateTime startDate, DateTime endDate) async {
    if (_uid == null) return 0;

    try {
      final snap = await _db
          .collection('glucose_readings')
          .where('user_id', isEqualTo: _uid)
          .get();

      final readings = snap.docs.where((doc) {
        final timestamp = doc.data()['reading_time'] as Timestamp?;
        if (timestamp == null) return false;
        final date = timestamp.toDate();
        return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(endDate.add(const Duration(days: 1)));
      }).map((doc) => (doc.data()['glucose_level'] as num?)?.toDouble() ?? 0.0)
          .where((v) => v > 0)
          .toList();

      if (readings.isEmpty) return 0;

      final inRange = readings.where((v) => v >= 70 && v <= 180).length;
      return ((inRange / readings.length) * 100).round();
    } catch (e) {
      print('❌ Error getting TIR for range: $e');
      return 0;
    }
  }
}
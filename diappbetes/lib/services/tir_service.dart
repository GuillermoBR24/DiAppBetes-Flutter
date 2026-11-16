import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'glucose_service.dart';

/// Resumen de un conjunto de lecturas respecto al rango objetivo.
class TirStats {
  final int count;
  final int inRangePct;
  final int lowPct;
  final int highPct;
  final double average;

  const TirStats({
    required this.count,
    required this.inRangePct,
    required this.lowPct,
    required this.highPct,
    required this.average,
  });

  static const empty =
      TirStats(count: 0, inRangePct: 0, lowPct: 0, highPct: 0, average: 0);

  factory TirStats.from(List<double> levels, double min, double max) {
    if (levels.isEmpty) return empty;
    final low = levels.where((v) => v < min).length;
    final high = levels.where((v) => v > max).length;
    final inRange = levels.length - low - high;
    int pct(int n) => ((n / levels.length) * 100).round();
    return TirStats(
      count: levels.length,
      inRangePct: pct(inRange),
      lowPct: pct(low),
      highPct: pct(high),
      average: levels.reduce((a, b) => a + b) / levels.length,
    );
  }
}

class TirService {
  static final TirService _instance = TirService._internal();
  factory TirService() => _instance;
  TirService._internal();

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Límites del rango objetivo, siempre desde la configuración global.
  Future<({double min, double max})> _range() async {
    var min = 70.0;
    var max = 180.0;
    try {
      final doc = await _db.collection('app_config').doc('global').get();
      final data = doc.data();
      if (data != null) {
        min = (data['default_glucose_min'] as num?)?.toDouble() ?? min;
        max = (data['default_glucose_max'] as num?)?.toDouble() ?? max;
      }
    } catch (_) {
      // Sin configuración global se usan los límites por defecto (70-180).
    }
    return (min: min, max: max);
  }

  /// % de lecturas dentro de rango en los últimos 7 días.
  Future<int> getTirPercentage() async => (await getWeeklyStats()).inRangePct;

  /// Estadísticas de los últimos 7 días: en rango, bajas, altas y media.
  Future<TirStats> getWeeklyStats() async {
    if (_uid == null) return TirStats.empty;

    final range = await _range();
    final since = DateTime.now().subtract(const Duration(days: 7));

    // Solo una consulta (por usuario); el filtrado por fecha se hace en cliente
    // porque user_id + reading_time exigiría un índice compuesto.
    var levels = await _levels(
      collection: 'glucose_readings',
      timeField: 'reading_time',
      valueField: 'glucose_level',
      since: since,
    );
    if (levels.isEmpty) {
      // Compatibilidad: datos antiguos sin glucose_readings.
      levels = await _levels(
        collection: 'meals',
        timeField: 'created_at',
        valueField: 'glucose_level',
        since: since,
      );
    }
    return TirStats.from(levels, range.min, range.max);
  }

  /// % de lecturas en rango entre dos días naturales (ambos incluidos).
  Future<int> getTirPercentageForRange(DateTime startDate, DateTime endDate) async {
    if (_uid == null) return 0;

    final range = await _range();
    final readings = await GlucoseService().getGlucoseReadingsByDateRange(startDate, endDate);
    final levels = readings
        .map((r) => (r['glucose_level'] as num?)?.toDouble() ?? 0.0)
        .where((v) => v > 0)
        .toList();
    return TirStats.from(levels, range.min, range.max).inRangePct;
  }

  Future<List<double>> _levels({
    required String collection,
    required String timeField,
    required String valueField,
    required DateTime since,
  }) async {
    try {
      final snap = await _db
          .collection(collection)
          .where('user_id', isEqualTo: _uid)
          .get();

      return snap.docs.where((d) {
        final ts = d.data()[timeField] as Timestamp?;
        return ts != null && ts.toDate().isAfter(since);
      }).map((d) => (d.data()[valueField] as num?)?.toDouble() ?? 0.0)
          .where((v) => v > 0)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GlucoseReading {
  final double level;
  final DateTime time;
  const GlucoseReading({required this.level, required this.time});
}

class GlucoseService {
  static final GlucoseService _instance = GlucoseService._internal();
  factory GlucoseService() => _instance;
  GlucoseService._internal();

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Las `count` lecturas más recientes (la primera es la última).
  Future<List<GlucoseReading>> getLatestReadings({int count = 2}) async {
    if (_uid == null) return [];

    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
    try {
      final snap = await _db
          .collection('glucose_readings')
          .where('user_id', isEqualTo: _uid)
          .orderBy('reading_time', descending: true)
          .limit(count)
          .get();
      docs = snap.docs;
    } catch (_) {
      // Sin índice compuesto: se pide todo y se ordena en cliente.
      try {
        final snap = await _db
            .collection('glucose_readings')
            .where('user_id', isEqualTo: _uid)
            .get();
        docs = snap.docs.toList()
          ..sort((a, b) {
            final ta = a.data()['reading_time'] as Timestamp?;
            final tb = b.data()['reading_time'] as Timestamp?;
            if (ta == null || tb == null) return 0;
            return tb.compareTo(ta);
          });
      } catch (_) {
        return [];
      }
    }

    final result = <GlucoseReading>[];
    for (final d in docs) {
      final level = (d.data()['glucose_level'] as num?)?.toDouble();
      final time = (d.data()['reading_time'] as Timestamp?)?.toDate();
      if (level != null && time != null) {
        result.add(GlucoseReading(level: level, time: time));
      }
      if (result.length == count) break;
    }
    return result;
  }

  /// Guarda una lectura suelta (sin comida asociada).
  Future<void> addReading(double level, {DateTime? at}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Usuario no autenticado');
    final ts = Timestamp.fromDate(at ?? DateTime.now());
    await _db.collection('glucose_readings').add({
      'user_id':       uid,
      'glucose_level': level,
      'reading_time':  ts,
      'created_at':    ts,
      'source':        'manual',
    });
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
        return isWithinDays(timestamp.toDate(), startDate, endDate);
      }).map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Rango por DÍAS naturales, ambos extremos incluidos: desde las 00:00 del
  /// día `start` hasta las 23:59:59 del día `end`. (Antes se incluía también
  /// el día anterior al inicio.)
  static bool isWithinDays(DateTime t, DateTime start, DateTime end) {
    final from = DateTime(start.year, start.month, start.day);
    final until = DateTime(end.year, end.month, end.day).add(const Duration(days: 1));
    return !t.isBefore(from) && t.isBefore(until);
  }
}
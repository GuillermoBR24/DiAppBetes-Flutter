import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TirService {
  static final TirService _instance = TirService._internal();
  factory TirService() => _instance;
  TirService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Calcula el % de lecturas de glucosa en rango (70-180 mg/dL) en los últimos 7 días
  // Equivalente a TirService.getTir() de Angular
  // Rango estándar internacional: 70–180 mg/dL
  Future<int> getTirPercentage() async {
    if (_uid == null) return 0;
    try {
      final since = DateTime.now().subtract(const Duration(days: 7));
      final snap = await _db
          .collection('glucose_readings')
          .where('user_id', isEqualTo: _uid)
          .where('reading_time',
              isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .get();

      if (snap.docs.isEmpty) return 0;

      int inRange = 0;
      for (final doc in snap.docs) {
        final level = (doc.data()['glucose_level'] as num?)?.toDouble() ?? 0;
        if (level >= 70 && level <= 180) inRange++;
      }

      return ((inRange / snap.docs.length) * 100).round();
    } catch (_) {
      return 0;
    }
  }
}
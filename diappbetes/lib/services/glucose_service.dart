import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GlucoseService {
  static final GlucoseService _instance = GlucoseService._internal();
  factory GlucoseService() => _instance;
  GlucoseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Última lectura de glucosa del usuario
  // Equivalente a GlucoseService.getLatestGlucose() de Angular
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

      final data = snap.docs.first.data();
      final level = data['glucose_level'];
      final time  = (data['reading_time'] as Timestamp?)?.toDate();

      final timeStr = time != null
          ? '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}'
          : '';

      return timeStr.isNotEmpty
          ? '${level ?? '—'} mg/dL — $timeStr'
          : '${level ?? '—'} mg/dL';
    } catch (_) {
      return 'Sin lecturas recientes';
    }
  }
}
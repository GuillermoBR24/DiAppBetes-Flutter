import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MealService {
  static final MealService _instance = MealService._internal();
  factory MealService() => _instance;
  MealService._internal();

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<int> getTodayMealCount() async {
    if (_uid == null) return 0;

    final now   = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end   = start.add(const Duration(days: 1));

    try {
      final snap = await _db
          .collection('meals')
          .where('user_id', isEqualTo: _uid)
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('created_at', isLessThan: Timestamp.fromDate(end))
          .get();
      return snap.docs.length;
    } catch (_) {
      try {
        final snap = await _db
            .collection('meals')
            .where('user_id', isEqualTo: _uid)
            .get();

        return snap.docs.where((doc) {
          final ts = doc.data()['created_at'] as Timestamp?;
          if (ts == null) return false;
          final dt = ts.toDate();
          return dt.isAfter(start) && dt.isBefore(end);
        }).length;
      } catch (_) {
        return 0;
      }
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MealService {
  static final MealService _instance = MealService._internal();
  factory MealService() => _instance;
  MealService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Número de comidas registradas hoy
  // Equivalente a MealCountService.getTodayMealCount() de Angular
  Future<int> getTodayMealCount() async {
    if (_uid == null) return 0;
    try {
      final now   = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end   = start.add(const Duration(days: 1));

      final snap = await _db
          .collection('meals')
          .where('user_id', isEqualTo: _uid)
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('created_at', isLessThan: Timestamp.fromDate(end))
          .get();

      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/add_meal_screen.dart';

// ---------------------------------------------------------------------------
// MealCreateService — guarda comidas en Firestore
// ---------------------------------------------------------------------------
class MealCreateService {
  static final MealCreateService _instance = MealCreateService._internal();
  factory MealCreateService() => _instance;
  MealCreateService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Crear comida completa con sus alimentos ───────────────────────────── //
  Future<Map<String, dynamic>> createMeal({
    required String mealType,
    required double glucoseLevel,
    required double totalHc,
    required double totalCalories,
    required double totalRations,
    required double totalInsulin,
    required List<AddedFood> foods,
  }) async {
    if (_uid == null) throw Exception('Usuario no autenticado');

    // 1. Crear documento de comida
    final mealRef = _db.collection('meals').doc();
    final now = FieldValue.serverTimestamp();

    final mealData = {
      'user_id':        _uid,
      'meal_type':      mealType,
      'glucose_level':  glucoseLevel,
      'total_hc':       totalHc,
      'total_calories': totalCalories,
      'total_rations':  totalRations,
      'total_insulin':  totalInsulin,
      'created_at':     now,
      'updated_at':     now,
    };

    final batch = _db.batch();
    batch.set(mealRef, mealData);

    // 2. Crear subcolección meal_foods
    for (final food in foods) {
      final foodRef = mealRef.collection('meal_foods').doc();
      batch.set(foodRef, {
        'food_id':             food.id,
        'name':                food.name,
        'category':            food.category,
        'quantity_grams':      food.quantityGrams,
        'calculated_hc':       food.calculatedHc,
        'calculated_calories': food.calculatedCalories,
        'calculated_rations':  food.calculatedRations,
        'created_at':          now,
      });
    }

    // 3. Crear lectura de glucosa asociada a la comida
    final glucoseRef = _db.collection('glucose_readings').doc();
    batch.set(glucoseRef, {
      'user_id':       _uid,
      'meal_id':       mealRef.id,
      'glucose_level': glucoseLevel,
      'reading_time':  now,
      'created_at':    now,
    });

    await batch.commit();

    return {
      'id':             mealRef.id,
      'meal_type':      mealType,
      'glucose_level':  glucoseLevel,
      'total_hc':       totalHc,
      'total_calories': totalCalories,
      'total_rations':  totalRations,
      'total_insulin':  totalInsulin,
      'created_at':     DateTime.now().toIso8601String(),
    };
  }

  // ── Obtener ratio HC actual según hora del día ────────────────────────── //
  Future<double> getCurrentHcRatio() async {
    if (_uid == null) return 10.0;
    try {
      final now      = DateTime.now();
      final nowMins  = now.hour * 60 + now.minute;

      final snap = await _db
          .collection('hc_ratios')
          .where('user_id', isEqualTo: _uid)
          .get();

      for (final doc in snap.docs) {
        final start = doc.data()['start_time'] as String? ?? '00:00';
        final end   = doc.data()['end_time']   as String? ?? '23:59';
        final startMins = _toMins(start);
        final endMins   = _toMins(end);

        if (nowMins >= startMins && nowMins <= endMins) {
          return (doc.data()['ratio_value'] as num?)?.toDouble() ?? 10.0;
        }
      }
      return 10.0;
    } catch (_) {
      return 10.0;
    }
  }

  // ── Obtener FSI del perfil ────────────────────────────────────────────── //
  Future<double> getUserFsi() async {
    if (_uid == null) return 50.0;
    try {
      final doc = await _db.collection('profiles').doc(_uid).get();
      return (doc.data()?['fsi'] as num?)?.toDouble() ?? 50.0;
    } catch (_) {
      return 50.0;
    }
  }

  int _toMins(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/add_meal_screen.dart';

class MealCreateService {
  static final MealCreateService _instance = MealCreateService._internal();
  factory MealCreateService() => _instance;
  MealCreateService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<Map<String, dynamic>> createMeal({
    required String mealType,
    required double glucoseLevel,
    required double totalHc,
    required double totalCalories,
    required double totalRations,
    required double totalInsulin,
    required List<AddedFood> foods,
    bool insulinManuallyAdjusted = false,
    DateTime? mealDateTime,
  }) async {
    if (_uid == null) throw Exception('Usuario no autenticado');

    final effectiveDateTime = mealDateTime ?? DateTime.now();
    final createdAtTimestamp = Timestamp.fromDate(effectiveDateTime);

    final mealRef = _db.collection('meals').doc();
    final updatedAt = FieldValue.serverTimestamp();

    final mealData = {
      'user_id':        _uid,
      'meal_type':      mealType,
      'glucose_level':  glucoseLevel,
      'total_hc':       totalHc,
      'total_calories': totalCalories,
      'total_rations':  totalRations,
      'total_insulin':  totalInsulin,
      'insulin_manually_adjusted': insulinManuallyAdjusted,
      'created_at':     createdAtTimestamp,
      'updated_at':     updatedAt,
    };

    final batch = _db.batch();
    batch.set(mealRef, mealData);

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
        'created_at':          createdAtTimestamp,
      });
    }

    final glucoseRef = _db.collection('glucose_readings').doc();
    batch.set(glucoseRef, {
      'user_id':       _uid,
      'meal_id':       mealRef.id,
      'glucose_level': glucoseLevel,
      'reading_time':  createdAtTimestamp,
      'created_at':    createdAtTimestamp,
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
      'created_at':     effectiveDateTime.toIso8601String(),
    };
  }

}
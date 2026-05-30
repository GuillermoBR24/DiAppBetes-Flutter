import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ---------------------------------------------------------------------------
// Modelos
// ---------------------------------------------------------------------------
class MealFoodDTO {
  final String name;
  final String category;
  final double quantityGrams;
  final double calculatedHc;
  final double calculatedCalories;
  final double calculatedRations;

  const MealFoodDTO({
    required this.name,
    required this.category,
    required this.quantityGrams,
    required this.calculatedHc,
    required this.calculatedCalories,
    required this.calculatedRations,
  });

  factory MealFoodDTO.fromMap(Map<String, dynamic> d) => MealFoodDTO(
    name:                d['name']?.toString() ?? '',
    category:            d['category']?.toString() ?? 'plato',
    quantityGrams:       (d['quantity_grams'] as num?)?.toDouble() ?? 0,
    calculatedHc:        (d['calculated_hc'] as num?)?.toDouble() ?? 0,
    calculatedCalories:  (d['calculated_calories'] as num?)?.toDouble() ?? 0,
    calculatedRations:   (d['calculated_rations'] as num?)?.toDouble() ?? 0,
  );
}

class MealDTO {
  final String id;
  final String mealType;
  final double totalHc;
  final double totalCalories;
  final double totalRations;
  final double totalInsulin;
  final double glucoseLevel;
  final DateTime createdAt;
  final List<MealFoodDTO> foods;

  const MealDTO({
    required this.id,
    required this.mealType,
    required this.totalHc,
    required this.totalCalories,
    required this.totalRations,
    required this.totalInsulin,
    required this.glucoseLevel,
    required this.createdAt,
    required this.foods,
  });
}

// ---------------------------------------------------------------------------
// HistoryService — carga comidas del usuario desde Firestore
// ---------------------------------------------------------------------------
class HistoryService {
  static final HistoryService _i = HistoryService._internal();
  factory HistoryService() => _i;
  HistoryService._internal();

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Cargar todas las comidas + sus alimentos ──────────────────────────── //
  Future<List<MealDTO>> getMeals() async {
    if (_uid == null) return [];

    final snap = await _db
        .collection('meals')
        .where('user_id', isEqualTo: _uid)
        .orderBy('created_at', descending: true)
        .get();

    // Carga los alimentos de cada comida en paralelo
    final futures = snap.docs.map((doc) async {
      final data = doc.data();

      // Subcolección meal_foods
      final foodsSnap = await doc.reference.collection('meal_foods').get();
      final foods = foodsSnap.docs
          .map((f) => MealFoodDTO.fromMap(f.data()))
          .toList();

      final createdAt = (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();

      return MealDTO(
        id:            doc.id,
        mealType:      data['meal_type']?.toString() ?? '',
        totalHc:       (data['total_hc'] as num?)?.toDouble() ?? 0,
        totalCalories: (data['total_calories'] as num?)?.toDouble() ?? 0,
        totalRations:  (data['total_rations'] as num?)?.toDouble() ?? 0,
        totalInsulin:  (data['total_insulin'] as num?)?.toDouble() ?? 0,
        glucoseLevel:  (data['glucose_level'] as num?)?.toDouble() ?? 0,
        createdAt:     createdAt,
        foods:         foods,
      );
    });

    return await Future.wait(futures);
  }
}
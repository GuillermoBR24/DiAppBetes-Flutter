import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'food_service.dart';

class CustomFoodService {
  static final CustomFoodService _instance = CustomFoodService._internal();
  factory CustomFoodService() => _instance;
  CustomFoodService._internal();

  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;
  String get _storageKey => 'custom_foods_${_uid ?? "anon"}';

  Future<List<Food>> getCustomFoods() async {
    if (_uid == null) return [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return [];

      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Food.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Food>> searchCustomFoods(String query) async {
    final all = await getCustomFoods();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((f) =>
        f.name.toLowerCase().contains(q) ||
        f.category.toLowerCase().contains(q)).toList();
  }

  Future<Food> addCustomFood({
    required String name,
    required String category,
    required double carbsPer100g,
    required double caloriesPer100g,
    bool? containsGluten,
  }) async {
    final foods = await getCustomFoods();

    final newFood = Food(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      category: category,
      carbsPer100g: carbsPer100g,
      caloriesPer100g: caloriesPer100g,
      containsGluten: containsGluten,
      isCustom: true,
    );

    foods.add(newFood);
    await _saveAll(foods);
    return newFood;
  }

  Future<void> updateCustomFood(Food updated) async {
    final foods = await getCustomFoods();
    final index = foods.indexWhere((f) => f.id == updated.id);
    if (index == -1) return;
    foods[index] = updated;
    await _saveAll(foods);
  }

  Future<void> deleteCustomFood(String id) async {
    final foods = await getCustomFoods();
    foods.removeWhere((f) => f.id == id);
    await _saveAll(foods);
  }

  Future<void> _saveAll(List<Food> foods) async {
    if (_uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(foods.map((f) => f.toMap()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
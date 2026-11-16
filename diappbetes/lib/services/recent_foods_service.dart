import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'food_service.dart';

/// Últimos alimentos añadidos a una comida (por usuario, solo en el dispositivo).
class RecentFoodsService {
  static final RecentFoodsService _instance = RecentFoodsService._internal();
  factory RecentFoodsService() => _instance;
  RecentFoodsService._internal();

  static const int maxItems = 8;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  String get _key => 'recent_foods_${_uid ?? "anon"}';

  Future<List<Food>> getRecent() async {
    if (_uid == null) return [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List)
          .map((e) => Food.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Pone `food` el primero, sin duplicados, y recorta la lista.
  Future<void> add(Food food) async {
    if (_uid == null) return;
    try {
      final current = await getRecent();
      final updated = [
        food,
        ...current.where((f) => f.id != food.id),
      ].take(maxItems).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(updated.map((f) => f.toMap()).toList()));
    } catch (_) {
      // Función de comodidad: si falla no afecta a la comida.
    }
  }
}

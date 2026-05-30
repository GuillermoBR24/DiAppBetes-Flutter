import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import 'add_food_modal.dart' show categoryBg, categoryText;

// ---------------------------------------------------------------------------
// Colores por tipo de comida (equivalente a getMealBgColor / getMealTextColor)
// ---------------------------------------------------------------------------
Color mealBg(String type) {
  const map = {
    'desayuno': Color(0xFFFFF9C4),
    'almuerzo': Color(0xFFE8F5E9),
    'comida':   Color(0xFFE3F2FD),
    'merienda': Color(0xFFFCE4EC),
    'cena':     Color(0xFFEDE7F6),
  };
  return map[type.toLowerCase()] ?? const Color(0xFFF5F5F5);
}

Color mealFg(String type) {
  const map = {
    'desayuno': Color(0xFFF9A825),
    'almuerzo': Color(0xFF2E7D32),
    'comida':   Color(0xFF1565C0),
    'merienda': Color(0xFFAD1457),
    'cena':     Color(0xFF4527A0),
  };
  return map[type.toLowerCase()] ?? AppColors.azulFondo;
}

// ---------------------------------------------------------------------------
// MealDetailsModal
// ---------------------------------------------------------------------------
class MealDetailsModal extends StatelessWidget {
  final MealDTO meal;

  const MealDetailsModal({super.key, required this.meal});

  // ── Helpers de formato (equivalente a formatMealTimeOnly / DateOnly) ─── //
  String _timeOnly(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  String _dateOnly(DateTime dt) {
    const meses = ['','ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return '${dt.day} ${meses[dt.month]}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bg = mealBg(meal.mealType);
    final fg = mealFg(meal.mealType);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────── //
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.azulFondo,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Detalles de la Comida',
                      style: TextStyle(color: AppColors.blanco, fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.blanco),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ── Cuerpo scrollable ──────────────────────────────────────── //
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Fila tipo comida ─────────────────────────────── //
                  _row(
                    label: 'Tipo',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        meal.mealType[0].toUpperCase() + meal.mealType.substring(1),
                        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // ── Fecha y hora ─────────────────────────────────── //
                  _row(
                    label: 'Fecha y hora',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_timeOnly(meal.createdAt),
                            style: const TextStyle(color: AppColors.azulFondo, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(_dateOnly(meal.createdAt),
                            style: const TextStyle(color: AppColors.grisTexto, fontSize: 12)),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: AppColors.grisDivider, thickness: 2),
                  ),

                  // ── Macros ───────────────────────────────────────── //
                  _row(label: 'HC Totales',
                      child: Text('${meal.totalHc.toStringAsFixed(1)}g',
                          style: TextStyle(color: AppColors.verdesuave, fontWeight: FontWeight.bold, fontSize: 15))),

                  _row(label: 'Calorías',
                      child: Text('${meal.totalCalories.toStringAsFixed(0)} cal',
                          style: const TextStyle(color: AppColors.azulFondo, fontWeight: FontWeight.bold, fontSize: 15))),

                  _row(label: 'Raciones',
                      child: Text('${meal.totalRations.toStringAsFixed(1)} R',
                          style: const TextStyle(color: AppColors.azulFondo, fontWeight: FontWeight.bold, fontSize: 15))),

                  _row(label: 'Glucemia',
                      child: Text(
                        meal.glucoseLevel > 0 ? '${meal.glucoseLevel.toStringAsFixed(0)} mg/dL' : 'No registrada',
                        style: const TextStyle(color: AppColors.azulFondo, fontWeight: FontWeight.bold, fontSize: 15),
                      )),

                  _row(label: 'U. Insulina',
                      child: Text('${meal.totalInsulin.toStringAsFixed(1)} U',
                          style: const TextStyle(color: AppColors.azulFondo, fontWeight: FontWeight.bold, fontSize: 15))),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: AppColors.grisDivider, thickness: 2),
                  ),

                  // ── Lista de alimentos ────────────────────────────── //
                  Text('Alimentos (${meal.foods.length})',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
                  const SizedBox(height: 10),

                  if (meal.foods.isEmpty)
                    const Center(
                      child: Text('Sin alimentos registrados',
                          style: TextStyle(color: AppColors.grisTexto, fontSize: 13)),
                    )
                  else
                    ...meal.foods.map((food) => _buildFoodItem(food)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fila label/value ─────────────────────────────────────────────────── //
  Widget _row({required String label, required Widget child}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.grisTexto, fontSize: 14)),
        child,
      ],
    ),
  );

  // ── Item de alimento ─────────────────────────────────────────────────── //
  Widget _buildFoodItem(MealFoodDTO food) {
    final bg = categoryBg(food.category);
    final fg = categoryText(food.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(food.name,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: fg)),
          const SizedBox(height: 4),
          Text('Cantidad: ${food.quantityGrams.toStringAsFixed(0)}g',
              style: const TextStyle(fontSize: 12, color: AppColors.grisTexto)),
          Text('HC: ${food.calculatedHc.toStringAsFixed(1)}g  •  '
              'Cal: ${food.calculatedCalories.toStringAsFixed(0)}  •  '
              'Rac: ${food.calculatedRations.toStringAsFixed(1)} R',
              style: const TextStyle(fontSize: 12, color: AppColors.grisTexto)),
        ],
      ),
    );
  }
}
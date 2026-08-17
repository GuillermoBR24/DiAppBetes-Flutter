import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import 'add_food_modal.dart' show categoryBg, categoryText;

Color mealBg(BuildContext context, String type) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  if (isDark) {
    const map = {
      'desayuno': Color(0xFF3E2723),
      'almuerzo': Color(0xFF1B3A1B),
      'comida':   Color(0xFF1A237E),
      'merienda': Color(0xFF4A1428),
      'cena':     Color(0xFF1F1A3E),
    };
    return map[type.toLowerCase()] ?? const Color(0xFF2C2C2C);
  } else {
    const map = {
      'desayuno': Color(0xFFFFF9C4),
      'almuerzo': Color(0xFFE8F5E9),
      'comida':   Color(0xFFE3F2FD),
      'merienda': Color(0xFFFCE4EC),
      'cena':     Color(0xFFEDE7F6),
    };
    return map[type.toLowerCase()] ?? const Color(0xFFF5F5F5);
  }
}

Color mealFg(BuildContext context, String type) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  if (isDark) {
    const map = {
      'desayuno': Color(0xFFFFD54F),
      'almuerzo': Color(0xFF81C784),
      'comida':   Color(0xFF64B5F6),
      'merienda': Color(0xFFF06292),
      'cena':     Color(0xFF9575CD),
    };
    return map[type.toLowerCase()] ?? Theme.of(context).colorScheme.primary;
  } else {
    const map = {
      'desayuno': Color(0xFFF9A825),
      'almuerzo': Color(0xFF2E7D32),
      'comida':   Color(0xFF1565C0),
      'merienda': Color(0xFFAD1457),
      'cena':     Color(0xFF4527A0),
    };
    return map[type.toLowerCase()] ?? Theme.of(context).colorScheme.primary;
  }
}

class MealDetailsModal extends StatelessWidget {
  final MealDTO meal;

  const MealDetailsModal({super.key, required this.meal});

  String _timeOnly(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  String _dateOnly(DateTime dt) {
    const meses = ['','ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return '${dt.day} ${meses[dt.month]}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bg = mealBg(context, meal.mealType);
    final fg = mealFg(context, meal.mealType);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final cardColor = Theme.of(context).cardColor;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Detalles de la Comida',
                      style: TextStyle(color: onPrimaryColor, fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: onPrimaryColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _row(
                    label: 'Tipo',
                    labelColor: textSmallColor,
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

                  _row(
                    label: 'Fecha y hora',
                    labelColor: textSmallColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_timeOnly(meal.createdAt),
                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(_dateOnly(meal.createdAt),
                            style: TextStyle(color: textSmallColor, fontSize: 12)),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: dividerColor, thickness: 2),
                  ),

                  _row(label: 'HC Totales',
                      labelColor: textSmallColor,
                      child: Text('${meal.totalHc.toStringAsFixed(1)}g',
                          style: const TextStyle(color: AppColors.verdesuave, fontWeight: FontWeight.bold, fontSize: 15))),

                  _row(label: 'Calorías',
                      labelColor: textSmallColor,
                      child: Text('${meal.totalCalories.toStringAsFixed(0)} cal',
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 15))),

                  _row(label: 'Raciones',
                      labelColor: textSmallColor,
                      child: Text('${meal.totalRations.toStringAsFixed(1)} R',
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 15))),

                  _row(label: 'Glucemia',
                      labelColor: textSmallColor,
                      child: Text(
                        meal.glucoseLevel > 0 ? '${meal.glucoseLevel.toStringAsFixed(0)} mg/dL' : 'No registrada',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 15),
                      )),

                  _row(label: 'U. Insulina',
                      labelColor: textSmallColor,
                      child: Text('${meal.totalInsulin.toStringAsFixed(1)} U',
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 15))),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: dividerColor, thickness: 2),
                  ),

                  Text('Alimentos (${meal.foods.length})',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 10),

                  if (meal.foods.isEmpty)
                    Center(
                      child: Text('Sin alimentos registrados',
                          style: TextStyle(color: textSmallColor, fontSize: 13)),
                    )
                  else
                    ...meal.foods.map((food) => _buildFoodItem(context, food)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({required String label, required Widget child, Color? labelColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontWeight: FontWeight.bold, color: labelColor, fontSize: 14)),
        child,
      ],
    ),
  );

  Widget _buildFoodItem(BuildContext context, MealFoodDTO food) {
    final bg = categoryBg(context, food.category);
    final fg = categoryText(context, food.category);
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(food.name,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: fg)),
          const SizedBox(height: 4),
          Text('Cantidad: ${food.quantityGrams.toStringAsFixed(0)}g',
              style: TextStyle(fontSize: 12, color: textSmallColor)),
          Text('HC: ${food.calculatedHc.toStringAsFixed(1)}g  •  '
              'Cal: ${food.calculatedCalories.toStringAsFixed(0)}  •  '
              'Rac: ${food.calculatedRations.toStringAsFixed(1)} R',
              style: TextStyle(fontSize: 12, color: textSmallColor)),
        ],
      ),
    );
  }
}
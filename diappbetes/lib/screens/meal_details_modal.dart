import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ───────────────────────────────────────────────────────────────────────────
// Modelo de Alimento (hardcodeado)
// ───────────────────────────────────────────────────────────────────────────
class FoodItem {
  final String id;
  final String name;
  final String category;
  final double quantityGrams;
  final double calculatedHc;
  final int calculatedCalories;
  final double calculatedRations;

  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantityGrams,
    required this.calculatedHc,
    required this.calculatedCalories,
    required this.calculatedRations,
  });
}

// ───────────────────────────────────────────────────────────────────────────
// Modelo de Comida extendido para el modal
// ───────────────────────────────────────────────────────────────────────────
class MealDetail {
  final String id;
  final String mealType;
  final double totalHc;
  final int totalCalories;
  final double totalRations;
  final DateTime createdAt;
  final double? glucoseLevel;
  final double? totalInsulin;
  final List<FoodItem> foods;

  const MealDetail({
    required this.id,
    required this.mealType,
    required this.totalHc,
    required this.totalCalories,
    required this.totalRations,
    required this.createdAt,
    this.glucoseLevel,
    this.totalInsulin,
    required this.foods,
  });
}

// ───────────────────────────────────────────────────────────────────────────
// Función para mostrar el modal (llamar desde HistorialScreen)
// ───────────────────────────────────────────────────────────────────────────
Future<void> showMealDetailsModal(BuildContext context, MealDetail meal) async {
  await showDialog(
    context: context,
    builder: (context) => MealDetailsModal(meal: meal),
    barrierDismissible: true, // Permitir cerrar tocando fuera
  );
}

// ───────────────────────────────────────────────────────────────────────────
// Widget del Modal
// ───────────────────────────────────────────────────────────────────────────
class MealDetailsModal extends StatelessWidget {
  final MealDetail meal;

  const MealDetailsModal({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blanco,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.azulFondo,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detalles de la Comida',
                    style: TextStyle(
                      color: AppColors.blanco,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.blanco),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Contenido scrollable ───────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Card de detalles
                    _buildDetailsCard(context),
                    const SizedBox(height: 16),

                    // Lista de alimentos
                    _buildFoodsList(context),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card: Detalles principales ──────────────────────────────────────────
  Widget _buildDetailsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Tipo de comida (con badge coloreado)
          _buildDetailRow(
            label: 'Tipo',
            value: _capitalize(meal.mealType),
            isBadge: true,
            badgeBgColor: _getMealBgColor(meal.mealType),
            badgeTextColor: _getMealTextColor(meal.mealType),
          ),

          // Fecha y hora
          _buildDetailRow(
            label: 'Fecha y hora',
            value: _formatMealTimeOnly(meal.createdAt),
            valueSub: _formatMealDateOnly(meal.createdAt),
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.grisDivider, thickness: 2),
          ),

          // HC Totales
          _buildDetailRow(
            label: 'HC Totales',
            value: '${meal.totalHc.toStringAsFixed(1)}g',
            isHcValue: true,
          ),

          // Calorías
          _buildDetailRow(
            label: 'Calorías',
            value: '${meal.totalCalories} cal',
          ),

          // Raciones
          _buildDetailRow(
            label: 'Raciones',
            value: '${meal.totalRations.toStringAsFixed(1)} R',
          ),

          // Glucemia
          _buildDetailRow(
            label: 'Glucemia',
            value: meal.glucoseLevel != null 
                ? '${meal.glucoseLevel!.toStringAsFixed(0)} mg/dl' 
                : 'No registrada',
          ),

          // Unidades de Insulina
          _buildDetailRow(
            label: 'U. Insulina',
            value: meal.totalInsulin != null 
                ? '${meal.totalInsulin!.toStringAsFixed(1)} U' 
                : 'No definido',
          ),
        ],
      ),
    );
  }

  // ── Fila de detalle reutilizable ────────────────────────────────────────
  Widget _buildDetailRow({
    required String label,
    required String value,
    String? valueSub,
    bool isHcValue = false,
    bool isBadge = false,
    Color? badgeBgColor,
    Color? badgeTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.grisTexto,
              fontSize: 14,
            ),
          ),
          if (isBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBgColor ?? AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeTextColor ?? AppColors.azulFondo, width: 1),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: badgeTextColor ?? AppColors.azulFondo,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            )
          else if (valueSub != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.azulFondo,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  valueSub,
                  style: TextStyle(
                    color: AppColors.grisTexto,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          else
            Text(
              value,
              style: TextStyle(
                color: isHcValue ? AppColors.verdesuave : AppColors.azulFondo,
                fontWeight: isHcValue ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
        ],
      ),
    );
  }

  // ── Lista de alimentos ──────────────────────────────────────────────────
  Widget _buildFoodsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alimentos (${meal.foods.length})',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.azulFondo,
          ),
        ),
        const SizedBox(height: 12),
        if (meal.foods.isEmpty)
          Center(
            child: Text(
              'No hay alimentos registrados.',
              style: TextStyle(fontSize: 14, color: AppColors.grisTexto),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meal.foods.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _buildFoodItem(meal.foods[index]),
          ),
      ],
    );
  }

  // ── Item individual de alimento ─────────────────────────────────────────
  Widget _buildFoodItem(FoodItem food) {
    final bgColor = _getCategoryBgColor(food.category);
    final textColor = _getCategoryTextColor(food.category);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono de alimento
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu_outlined,
              size: 20,
              color: textColor,
            ),
          ),
          const SizedBox(width: 12),

          // Info del alimento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildFoodDetail('Cantidad', '${food.quantityGrams.toStringAsFixed(0)}g'),
                    _buildFoodDetail('HC', '${food.calculatedHc.toStringAsFixed(1)}g'),
                    _buildFoodDetail('Calorías', '${food.calculatedCalories}'),
                    _buildFoodDetail('Raciones', '${food.calculatedRations.toStringAsFixed(1)} R'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodDetail(String label, String value) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 12, color: AppColors.grisTexto),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          TextSpan(text: value, style: TextStyle(color: AppColors.azulFondo, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Helpers de colores y formato ────────────────────────────────────────
  Color _getMealBgColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'desayuno': return AppColors.desayunoFondo;
      case 'almuerzo': return AppColors.almuerzoFondo;
      case 'comida':   return AppColors.comidaFondo;
      case 'merienda': return AppColors.meriendaFondo;
      case 'cena':     return AppColors.cenaFondo;
      default:         return AppColors.cardBackground;
    }
  }

  Color _getMealTextColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'desayuno': return AppColors.desayunoTexto;
      case 'almuerzo': return AppColors.almuerzoTexto;
      case 'comida':   return AppColors.comidaTexto;
      case 'merienda': return AppColors.meriendaTexto;
      case 'cena':     return AppColors.cenaTexto;
      default:         return AppColors.azulFondo;
    }
  }

  Color _getCategoryBgColor(String category) {
    switch (category.toLowerCase()) {
      case 'frutas': return AppColors.frutasFondo;
      case 'carnes': return AppColors.carnesFondo;
      case 'pescados': return AppColors.pescadosFondo;
      case 'mariscos': return AppColors.mariscosFondo;
      case 'verduras': return AppColors.verdurasFondo;
      case 'lacteos': return AppColors.lacteosFondo;
      case 'cereales': return AppColors.cerealesFondo;
      case 'bolleria': return AppColors.bolleriaFondo;
      case 'dulces': return AppColors.dulcesFondo;
      case 'bebidas': return AppColors.bebidasFondo;
      case 'legumbres': return AppColors.legumbresFondo;
      case 'frutos_secos': return AppColors.frutosSecosFondo;
      case 'plato': return AppColors.platoFondo;
      default: return AppColors.frutasFondo;
    }
  }

  Color _getCategoryTextColor(String category) {
    switch (category.toLowerCase()) {
      case 'frutas': return AppColors.frutasTexto;
      case 'carnes': return AppColors.carnesTexto;
      case 'pescados': return AppColors.pescadosTexto;
      case 'mariscos': return AppColors.mariscosTexto;
      case 'verduras': return AppColors.verdurasTexto;
      case 'lacteos': return AppColors.lacteosTexto;
      case 'cereales': return AppColors.cerealesTexto;
      case 'bolleria': return AppColors.bolleriaTexto;
      case 'dulces': return AppColors.dulcesTexto;
      case 'bebidas': return AppColors.bebidasTexto;
      case 'legumbres': return AppColors.legumbresTexto;
      case 'frutos_secos': return AppColors.frutosSecosTexto;
      case 'plato': return AppColors.platoTexto;
      default: return AppColors.frutasTexto;
    }
  }

  String _formatMealDateOnly(DateTime date) {
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 
                    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final month = months[date.month - 1];
    return '${date.day} $month, ${date.year}';
  }

  String _formatMealTimeOnly(DateTime date) {
    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Extensión para capitalizar (si no la tienes ya en otro archivo)
// ───────────────────────────────────────────────────────────────────────────
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Modelo de la comida creada (hardcodeado — TODO: recibir del MealService)
// ---------------------------------------------------------------------------
class MealSummaryData {
  final String mealType;
  final String createdAt;   // ISO string
  final double totalHc;
  final double totalCalories;
  final double totalRations;
  final double totalInsulin;
  final double glucoseLevel; // TODO: GlucoseByMealService.getGlucoseReadingByMealId()

  const MealSummaryData({
    required this.mealType,
    required this.createdAt,
    required this.totalHc,
    required this.totalCalories,
    required this.totalRations,
    required this.totalInsulin,
    required this.glucoseLevel,
  });
}

// ---------------------------------------------------------------------------
// AddMealSummaryModal
// Equivalente a AddMealSummaryModalComponent de Angular/Ionic
// Se muestra con showDialog() desde AddMealScreen al crear una comida
// ---------------------------------------------------------------------------
class AddMealSummaryModal extends StatelessWidget {
  // Datos hardcodeados — equivalente al mealSummary del .ts + @Input() meal
  // TODO: reemplazar con datos reales recibidos de MealService.createMeal()
  final MealSummaryData meal;

  const AddMealSummaryModal({super.key, required this.meal});

  // ── formatMealDateTime() ─────────────────────────────────────────────── //
  String _formatDateTime(String iso) {
    if (iso.isEmpty) return 'No definido';
    try {
      final dt = DateTime.parse(iso);
      const meses = [
        '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${meses[dt.month]}, ${dt.year} a las $h:$m';
    } catch (_) {
      return 'No definido';
    }
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final cardColor = Theme.of(context).cardColor;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      backgroundColor: cardColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header (equivalente al ion-header) ────────────────────── //
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Text(
              'DiAppBetes',
              style: TextStyle(
                color: onPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // ── Cuerpo — .summary-card ────────────────────────────────── //
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título
                  Text(
                    'Resumen de la Comida',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // ── Filas de datos superiores ─────────────────────── //
                  _detailRow(
                    label: 'Tipo',
                    value: meal.mealType.isNotEmpty
                        ? _capitalize(meal.mealType)
                        : 'No definido',
                    valueColor: primaryColor,
                    labelColor: textSmallColor,
                  ),
                  _detailRow(
                    label: 'Fecha y Hora',
                    value: _formatDateTime(meal.createdAt),
                    valueColor: primaryColor,
                    labelColor: textSmallColor,
                  ),

                  // ── Divider ───────────────────────────────────────── //
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(
                        color: dividerColor, thickness: 2),
                  ),

                  // ── Filas nutricionales ───────────────────────────── //
                  _detailRow(
                    label: 'HC Totales',
                    value: '${meal.totalHc.toStringAsFixed(1)}g',
                    valueColor: AppColors.verdesuave, // .value-hc (semántico)
                    labelColor: textSmallColor,
                  ),
                  _detailRow(
                    label: 'Calorías',
                    value: '${meal.totalCalories.toStringAsFixed(0)} cal',
                    valueColor: primaryColor,
                    labelColor: textSmallColor,
                  ),
                  _detailRow(
                    label: 'Raciones',
                    value: '${meal.totalRations.toStringAsFixed(1)} R',
                    valueColor: primaryColor,
                    labelColor: textSmallColor,
                  ),
                  _detailRow(
                    label: 'Glucemia',
                    value: meal.glucoseLevel > 0
                        ? '${meal.glucoseLevel.toStringAsFixed(0)} mg/dl'
                        : 'No registrada',
                    valueColor: primaryColor,
                    labelColor: textSmallColor,
                  ),
                  _detailRow(
                    label: 'U. Insulina',
                    value: '${meal.totalInsulin.toStringAsFixed(1)} U',
                    valueColor: primaryColor,
                    labelColor: textSmallColor,
                  ),

                  const SizedBox(height: 24),

                  // ── Botón Aceptar ─────────────────────────────────── //
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Aceptar',
                          style: TextStyle(
                            color: onPrimaryColor,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fila label / value (equivalente a .detail-row) ───────────────────── //
  Widget _detailRow({
    required String label,
    required String value,
    required Color valueColor,
    Color? labelColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: labelColor,
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
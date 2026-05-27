import 'package:diappbetes/utils/food_colors.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'add_food_modal.dart' show Food;

// ---------------------------------------------------------------------------
// AddFoodDetailsModal
// Equivalente a AddFoodDetailsModalComponent de Angular/Ionic
// Se abre como Dialog desde AddFoodModal al pulsar el botón +
// ---------------------------------------------------------------------------
class AddFoodDetailsModal extends StatefulWidget {
  final Food selectedFood;
  final bool isEditMode;

  /// Valores previos al editar (solo en isEditMode = true)
  final double? initialQuantity;
  final double? initialRaciones;
  final double? initialHc;
  final double? initialCalories;

  /// Callback al confirmar (añadir o actualizar)
  final void Function(Map<String, dynamic> foodData) onConfirm;

  const AddFoodDetailsModal({
    super.key,
    required this.selectedFood,
    required this.onConfirm,
    this.isEditMode = false,
    this.initialQuantity,
    this.initialRaciones,
    this.initialHc,
    this.initialCalories,
  });

  @override
  State<AddFoodDetailsModal> createState() => _AddFoodDetailsModalState();
}

class _AddFoodDetailsModalState extends State<AddFoodDetailsModal> {
  // ── Estado equivalente a las variables del componente Angular ────────── //
  late double quantity;
  late double raciones;
  late double hc;
  late double calories;

  late TextEditingController _quantityController;
  late TextEditingController _racionesController;

  @override
  void initState() {
    super.initState();

    if (widget.isEditMode) {
      // Modo edición — carga los valores previos del alimento
      quantity  = widget.initialQuantity  ?? 100.0;
      raciones  = widget.initialRaciones  ?? 0.0;
      hc        = widget.initialHc        ?? 0.0;
      calories  = widget.initialCalories  ?? 0.0;
    } else {
      // Modo nuevo — arranca con 100g y calcula
      quantity = 100.0;
      _calcFromQuantity();
    }

    _quantityController =
        TextEditingController(text: quantity.toStringAsFixed(1));
    _racionesController =
        TextEditingController(text: raciones.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _racionesController.dispose();
    super.dispose();
  }

  // ── calculateFromQuantity() ───────────────────────────────────────────── //
  void _calcFromQuantity() {
    final g = quantity;
    if (g >= 0) {
      hc       = double.parse((g * widget.selectedFood.carbsPer100g / 100).toStringAsFixed(1));
      calories = double.parse((g * widget.selectedFood.caloriesPer100g / 100).toStringAsFixed(0));
      raciones = double.parse((hc / 15).toStringAsFixed(1)); // 1 ración = 15g HC
    } else {
      _reset();
    }
  }

  // ── calculateFromRaciones() ───────────────────────────────────────────── //
  void _calcFromRaciones() {
    if (raciones >= 0 && widget.selectedFood.carbsPer100g > 0) {
      hc       = double.parse((raciones * 15).toStringAsFixed(1));
      quantity = double.parse(((hc * 100) / widget.selectedFood.carbsPer100g).toStringAsFixed(1));
      calories = double.parse(((quantity * widget.selectedFood.caloriesPer100g) / 100).toStringAsFixed(0));
    } else {
      _reset();
    }
  }

  void _reset() {
    quantity = 0;
    raciones = 0;
    hc = 0;
    calories = 0;
  }

  // ── addFood() / updateFood() ──────────────────────────────────────────── //
  void _confirm() {
    widget.onConfirm({
      'id':                   widget.selectedFood.id,
      'name':                 widget.selectedFood.name,
      'category':             widget.selectedFood.category,
      'carbs_per_100g':       widget.selectedFood.carbsPer100g,
      'calories_per_100g':    widget.selectedFood.caloriesPer100g,
      'quantity_grams':       quantity,
      'calculated_hc':        hc,
      'calculated_calories':  calories,
      'calculated_rations':   raciones,
    });
    Navigator.pop(context);
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final bgColor   = categoryBg(widget.selectedFood.category);
    final textColor = categoryText(widget.selectedFood.category);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header (equivalente al ion-header) ─────────────────────── //
          Container(
            decoration: const BoxDecoration(
              color: AppColors.azulFondo,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Añadir Alimento a la Comida',
                    style: TextStyle(
                      color: AppColors.blanco,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.blanco),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ── Cuerpo con scroll por si el teclado lo empuja ─────────── //
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Chip del alimento seleccionado ─────────────────── //
                  _buildSelectedFoodChip(bgColor, textColor),
                  const SizedBox(height: 20),

                  // ── Campo: gramos ─────────────────────────────────── //
                  _buildField(
                    label: 'Cantidad (gramos)',
                    controller: _quantityController,
                    onChanged: (v) {
                      setState(() {
                        quantity = double.tryParse(v) ?? 0;
                        _calcFromQuantity();
                        // sincroniza el campo de raciones
                        _racionesController.text = raciones.toStringAsFixed(1);
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── Campo: raciones ───────────────────────────────── //
                  _buildField(
                    label: 'Raciones (15g HC = 1 ración)',
                    controller: _racionesController,
                    onChanged: (v) {
                      setState(() {
                        raciones = double.tryParse(v) ?? 0;
                        _calcFromRaciones();
                        // sincroniza el campo de gramos
                        _quantityController.text = quantity.toStringAsFixed(1);
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Resumen nutricional ───────────────────────────── //
                  _buildNutritionalSummary(bgColor, textColor),
                  const SizedBox(height: 20),

                  // ── Botón añadir / actualizar ─────────────────────── //
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: quantity > 0 ? _confirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.azulFondo,
                        disabledBackgroundColor: AppColors.grisDivider,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        widget.isEditMode ? 'Actualizar' : 'Añadir',
                        style: const TextStyle(
                          color: AppColors.blanco,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  // ── Chip del alimento seleccionado (equivalente a .selected-food) ────── //
  Widget _buildSelectedFoodChip(Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.selectedFood.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.selectedFood.carbsPer100g}g HC  •  '
            '${widget.selectedFood.caloriesPer100g.toStringAsFixed(0)} cal/100g',
            style: const TextStyle(
                fontSize: 13, color: AppColors.grisTexto),
          ),
        ],
      ),
    );
  }

  // ── Resumen nutricional (equivalente a .nutritional-summary) ─────────── //
  Widget _buildNutritionalSummary(Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen Nutricional',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HC: ${hc.toStringAsFixed(1)}g',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.grisTexto)),
              Text('Calorías: ${calories.toStringAsFixed(0)} cal',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.grisTexto)),
              Text('Raciones: ${raciones.toStringAsFixed(1)} R',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.grisTexto)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Campo de texto reutilizable ──────────────────────────────────────── //
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 15, color: AppColors.grisTexto),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.grisTexto, fontSize: 13),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.grisDivider)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.azulFondo)),
      ),
      onChanged: onChanged,
    );
  }
}
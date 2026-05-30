import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/food_service.dart';
import 'add_food_modal.dart' show categoryBg, categoryText;

// ---------------------------------------------------------------------------
// AddFoodDetailsModal — selecciona cantidad y calcula macros
// ---------------------------------------------------------------------------
class AddFoodDetailsModal extends StatefulWidget {
  final Food selectedFood;
  final bool isEditMode;
  final double? initialQuantity;
  final double? initialRaciones;
  final double? initialHc;
  final double? initialCalories;
  final void Function(Map<String, dynamic>) onConfirm;

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
  late double _grams;
  late double _raciones;
  late double _hc;
  late double _calories;

  final _gramsCtrl    = TextEditingController();
  final _racionesCtrl = TextEditingController();

  // Evita que un campo actualice el otro en bucle
  bool _updatingFromGrams    = false;
  bool _updatingFromRaciones = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _grams    = widget.initialQuantity  ?? 100;
      _raciones = widget.initialRaciones  ?? 0;
      _hc       = widget.initialHc        ?? 0;
      _calories = widget.initialCalories  ?? 0;
    } else {
      _grams = 100;
      _calcFromGrams();
    }
    _gramsCtrl.text    = _grams.toStringAsFixed(0);
    _racionesCtrl.text = _raciones.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _gramsCtrl.dispose();
    _racionesCtrl.dispose();
    super.dispose();
  }

  // ── Calcular desde gramos ─────────────────────────────────────────────── //
  void _calcFromGrams() {
    if (_grams < 0) { _grams = 0; }
    _hc       = double.parse((_grams * widget.selectedFood.carbsPer100g / 100).toStringAsFixed(1));
    _calories = double.parse((_grams * widget.selectedFood.caloriesPer100g / 100).toStringAsFixed(0));
    _raciones = double.parse((_hc / 10).toStringAsFixed(1)); // 1 ración = 10g HC
  }

  // ── Calcular desde raciones ───────────────────────────────────────────── //
  void _calcFromRaciones() {
    if (_raciones < 0) { _raciones = 0; }
    _hc       = double.parse((_raciones * 10).toStringAsFixed(1));
    if (widget.selectedFood.carbsPer100g > 0) {
      _grams = double.parse((_hc * 100 / widget.selectedFood.carbsPer100g).toStringAsFixed(0));
    }
    _calories = double.parse((_grams * widget.selectedFood.caloriesPer100g / 100).toStringAsFixed(0));
  }

  void _onGramsChanged(String v) {
    if (_updatingFromRaciones) return;
    _updatingFromGrams = true;
    setState(() {
      _grams = double.tryParse(v) ?? 0;
      _calcFromGrams();
      _racionesCtrl.text = _raciones.toStringAsFixed(1);
    });
    _updatingFromGrams = false;
  }

  void _onRacionesChanged(String v) {
    if (_updatingFromGrams) return;
    _updatingFromRaciones = true;
    setState(() {
      _raciones = double.tryParse(v) ?? 0;
      _calcFromRaciones();
      _gramsCtrl.text = _grams.toStringAsFixed(0);
    });
    _updatingFromRaciones = false;
  }

  void _confirm() {
    widget.onConfirm({
      'id':                   widget.selectedFood.id,
      'name':                 widget.selectedFood.name,
      'category':             widget.selectedFood.category,
      'carbs_per_100g':       widget.selectedFood.carbsPer100g,
      'calories_per_100g':    widget.selectedFood.caloriesPer100g,
      'quantity_grams':       _grams,
      'calculated_hc':        _hc,
      'calculated_calories':  _calories,
      'calculated_rations':   _raciones,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bg   = categoryBg(widget.selectedFood.category);
    final fg   = categoryText(widget.selectedFood.category);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                  child: Text('Añadir a la Comida',
                      style: TextStyle(color: AppColors.blanco, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.blanco),
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
                  // ── Chip del alimento ──────────────────────────────── //
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                              color: fg.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8)),
                          child: widget.selectedFood.iconUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(widget.selectedFood.iconUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.restaurant, color: fg, size: 24)))
                              : Icon(Icons.restaurant, color: fg, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.selectedFood.name,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: fg)),
                              Text('${widget.selectedFood.carbsPer100g.toStringAsFixed(1)}g HC  •  '
                                  '${widget.selectedFood.caloriesPer100g.toStringAsFixed(0)} cal/100g',
                                  style: const TextStyle(fontSize: 12, color: AppColors.grisTexto)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Campos bidireccionales ──────────────────────────── //
                  Row(
                    children: [
                      Expanded(
                        child: _inputField(
                          label: 'Gramos',
                          controller: _gramsCtrl,
                          suffix: 'g',
                          onChanged: _onGramsChanged,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _inputField(
                          label: 'Raciones',
                          controller: _racionesCtrl,
                          suffix: 'R',
                          onChanged: _onRacionesChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('1 ración = 10g de HC',
                      style: TextStyle(fontSize: 11, color: AppColors.grisTexto),
                      textAlign: TextAlign.right),
                  const SizedBox(height: 16),

                  // ── Resumen nutricional ─────────────────────────────── //
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resumen Nutricional',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: fg)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _summaryItem('HC', '${_hc.toStringAsFixed(1)}g', fg),
                            _summaryItem('Calorías', '${_calories.toStringAsFixed(0)} kcal', fg),
                            _summaryItem('Raciones', _raciones.toStringAsFixed(1), fg),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Botón confirmar ─────────────────────────────────── //
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _grams > 0 ? _confirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.azulFondo,
                        disabledBackgroundColor: AppColors.grisDivider,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.isEditMode ? 'Actualizar' : 'Añadir',
                        style: const TextStyle(color: AppColors.blanco, fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.azulFondo),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.grisTexto, fontSize: 13),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: AppColors.grisTexto, fontSize: 13),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grisDivider)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azulFondo)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _summaryItem(String label, String value, Color fg) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: fg)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grisTexto)),
    ],
  );
}
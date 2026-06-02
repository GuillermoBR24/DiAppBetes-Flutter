import 'package:flutter/material.dart';
import '../services/food_service.dart';
import '../services/profile_service.dart';
import '../widgets/gluten_indicator.dart';
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

  // ✅ NUEVO: Modo celíaco
  bool _celiacMode = false;

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
    _loadCeliacMode();
    
    // ✅ DEBUG: Verificar datos del alimento
    print('🔍 [DEBUG] Alimento: ${widget.selectedFood.name}');
    print('🔍 [DEBUG] containsGluten: ${widget.selectedFood.containsGluten}');
  }

  @override
  void dispose() {
    _gramsCtrl.dispose();
    _racionesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCeliacMode() async {
    final celiac = await ProfileService().getCeliacMode();
    print('🔍 [DEBUG] Modo celíaco cargado: $celiac');
    if (mounted) setState(() => _celiacMode = celiac);
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
      'contains_gluten':      widget.selectedFood.containsGluten, // ✅ NUEVO
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bg   = categoryBg(context, widget.selectedFood.category);
    final fg   = categoryText(context, widget.selectedFood.category);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final cardColor = Theme.of(context).cardColor;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────── //
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
                  child: Text('Añadir a la Comida',
                      style: TextStyle(color: onPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
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
                                  style: TextStyle(fontSize: 12, color: textSmallColor)),
                              // ✅ NUEVO: Indicador de gluten (siempre que el modo esté activo)
                              if (_celiacMode) ...[
                                const SizedBox(height: 6),
                                GlutenIndicator(
                                  containsGluten: widget.selectedFood.containsGluten,
                                  size: 12,
                                ),
                              ],
                              // ✅ DEBUG: Si no se muestra, mostrar por qué
                              if (!_celiacMode) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'ℹ️ Activa el modo celíaco en Settings para ver esta información',
                                  style: TextStyle(fontSize: 11, color: textSmallColor, fontStyle: FontStyle.italic),
                                ),
                              ],
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
                          primaryColor: primaryColor,
                          textSmallColor: textSmallColor,
                          dividerColor: dividerColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _inputField(
                          label: 'Raciones',
                          controller: _racionesCtrl,
                          suffix: 'R',
                          onChanged: _onRacionesChanged,
                          primaryColor: primaryColor,
                          textSmallColor: textSmallColor,
                          dividerColor: dividerColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('1 ración = 10g de HC',
                      style: TextStyle(fontSize: 11, color: textSmallColor),
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
                            _summaryItem('HC', '${_hc.toStringAsFixed(1)}g', fg, textSmallColor),
                            _summaryItem('Calorías', '${_calories.toStringAsFixed(0)} kcal', fg, textSmallColor),
                            _summaryItem('Raciones', _raciones.toStringAsFixed(1), fg, textSmallColor),
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
                        backgroundColor: primaryColor,
                        disabledBackgroundColor: Theme.of(context).disabledColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.isEditMode ? 'Actualizar' : 'Añadir',
                        style: TextStyle(color: onPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600),
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
    required Color primaryColor,
    required Color? textSmallColor,
    required Color dividerColor,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textSmallColor, fontSize: 13),
        suffixText: suffix,
        suffixStyle: TextStyle(color: textSmallColor, fontSize: 13),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: dividerColor)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _summaryItem(String label, String value, Color fg, Color? labelColor) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: fg)),
      Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
    ],
  );
}
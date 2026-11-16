import 'package:flutter/material.dart';
import 'package:diappbetes/widgets/app_feedback.dart';
import '../services/food_service.dart';
import '../services/custom_food_service.dart';

class AddCustomFoodModal extends StatefulWidget {
  final Food? editingFood;

  const AddCustomFoodModal({super.key, this.editingFood});

  @override
  State<AddCustomFoodModal> createState() => _AddCustomFoodModalState();
}

class _AddCustomFoodModalState extends State<AddCustomFoodModal> {
  final _formKey = GlobalKey<FormState>();
  final _customFoodService = CustomFoodService();

  late TextEditingController _nameCtrl;
  late TextEditingController _carbsCtrl;
  late TextEditingController _caloriesCtrl;
  String _category = 'plato';
  bool? _containsGluten;

  bool _saving = false;

  static const _categories = [
    'cereales', 'proteicos', 'pescados', 'mariscos', 'verduras', 'lacteos',
    'frutas', 'legumbres', 'frutos_secos', 'bolleria', 'dulces', 'bebidas', 'plato',
  ];

  bool get _isEditing => widget.editingFood != null;

  @override
  void initState() {
    super.initState();
    final f = widget.editingFood;
    _nameCtrl = TextEditingController(text: f?.name ?? '');
    _carbsCtrl = TextEditingController(text: f != null ? f.carbsPer100g.toString() : '');
    _caloriesCtrl = TextEditingController(text: f != null ? f.caloriesPer100g.toString() : '');
    _category = f?.category ?? 'plato';
    _containsGluten = f?.containsGluten;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _carbsCtrl.dispose();
    _caloriesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final carbs = double.parse(_carbsCtrl.text.replaceAll(',', '.'));
      final calories = double.parse(_caloriesCtrl.text.replaceAll(',', '.'));

      if (_isEditing) {
        final updated = widget.editingFood!.copyWith(
          name: _nameCtrl.text.trim(),
          category: _category,
          carbsPer100g: carbs,
          caloriesPer100g: calories,
          containsGluten: _containsGluten,
        );
        await _customFoodService.updateCustomFood(updated);
        if (mounted) Navigator.pop(context, updated);
      } else {
        final created = await _customFoodService.addCustomFood(
          name: _nameCtrl.text.trim(),
          category: _category,
          carbsPer100g: carbs,
          caloriesPer100g: calories,
          containsGluten: _containsGluten,
        );
        if (mounted) Navigator.pop(context, created);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppDialog.error(
          context,
          title: 'No se ha guardado el alimento',
          message: friendlyError(e),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                Icon(Icons.restaurant_menu, color: onPrimaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_isEditing ? 'Editar Alimento' : 'Nuevo Alimento Personal',
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isEditing)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Este alimento se guardará solo en tu dispositivo, no se sube a ningún servidor.',
                                style: TextStyle(fontSize: 12, color: textSmallColor),
                              ),
                            ),
                          ],
                        ),
                      ),

                    TextFormField(
                      controller: _nameCtrl,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        labelStyle: TextStyle(color: textSmallColor, fontSize: 13),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: dividerColor)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _category,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        labelStyle: TextStyle(color: textSmallColor, fontSize: 13),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: dividerColor)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c[0].toUpperCase() + c.substring(1).replaceAll('_', ' ')),
                      )).toList(),
                      onChanged: (v) => setState(() => _category = v ?? 'plato'),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _carbsCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: 'HC / 100g',
                              labelStyle: TextStyle(color: textSmallColor, fontSize: 13),
                              suffixText: 'g',
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: dividerColor)),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                            ),
                            validator: (v) {
                              final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                              if (val == null || val < 0) return 'Valor inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _caloriesCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: 'Cal / 100g',
                              labelStyle: TextStyle(color: textSmallColor, fontSize: 13),
                              suffixText: 'kcal',
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: dividerColor)),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                            ),
                            validator: (v) {
                              final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                              if (val == null || val < 0) return 'Valor inválido';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text('¿Contiene gluten?', style: TextStyle(fontSize: 13, color: textSmallColor)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _glutenChip('Sí', true, primaryColor, textColor, dividerColor),
                        const SizedBox(width: 8),
                        _glutenChip('No', false, primaryColor, textColor, dividerColor),
                        const SizedBox(width: 8),
                        _glutenChip('No lo sé', null, primaryColor, textColor, dividerColor),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(color: onPrimaryColor, strokeWidth: 2))
                            : Text(_isEditing ? 'Guardar Cambios' : 'Añadir Alimento',
                                style: TextStyle(color: onPrimaryColor, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glutenChip(String label, bool? value, Color primaryColor, Color? textColor, Color dividerColor) {
    final selected = _containsGluten == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _containsGluten = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? primaryColor.withValues(alpha: 0.15) : null,
            border: Border.all(color: selected ? primaryColor : dividerColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: selected ? primaryColor : textColor,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              )),
        ),
      ),
    );
  }
}
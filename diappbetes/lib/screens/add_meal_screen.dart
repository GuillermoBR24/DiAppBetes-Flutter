import 'package:diappbetes/screens/add_food_detail_modal.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/food_service.dart';
import '../services/meal_create_service.dart';
import 'add_food_modal.dart';
import 'add_meal_summary_modal.dart';

// ---------------------------------------------------------------------------
// Modelo AddedFood
// ---------------------------------------------------------------------------
class AddedFood {
  final String id;
  String name;
  String category;
  double carbsPer100g;
  double caloriesPer100g;
  double quantityGrams;
  double calculatedHc;
  double calculatedCalories;
  double calculatedRations;

  AddedFood({
    required this.id,
    required this.name,
    required this.category,
    required this.carbsPer100g,
    required this.caloriesPer100g,
    required this.quantityGrams,
    required this.calculatedHc,
    required this.calculatedCalories,
    required this.calculatedRations,
  });
}

// ---------------------------------------------------------------------------
// AddMealScreen
// ---------------------------------------------------------------------------
class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _mealService = MealCreateService();

  late String _mealTime;
  String _mealType    = '';
  String _glucemiaText = '';

  double _ratioValue = 10.0;
  double _fsi        = 50.0;

  List<AddedFood> _addedFoods = [];
  bool _saving = false;
  int  _selectedTab = 2;

  final _glucemiaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setNow();
    _loadUserData();
  }

  @override
  void dispose() {
    _glucemiaCtrl.dispose();
    super.dispose();
  }

  // ── Cargar ratio HC actual y FSI del usuario ──────────────────────────── //
  Future<void> _loadUserData() async {
    final ratio = await _mealService.getCurrentHcRatio();
    final fsi   = await _mealService.getUserFsi();
    if (mounted) setState(() { _ratioValue = ratio; _fsi = fsi; });
  }

  void _setNow() {
    final now = DateTime.now();
    _mealTime = '${now.year}-${_p(now.month)}-${_p(now.day)}  ${_p(now.hour)}:${_p(now.minute)}';
  }
  String _p(int n) => n.toString().padLeft(2, '0');

  bool get _isFormValid =>
      _mealType.isNotEmpty &&
      (double.tryParse(_glucemiaText) ?? 0) > 0 &&
      _addedFoods.isNotEmpty;

  double get _totalHc       => _addedFoods.fold(0, (s, f) => s + f.calculatedHc);
  double get _totalCalories => _addedFoods.fold(0, (s, f) => s + f.calculatedCalories);
  double get _totalRations  => _addedFoods.fold(0, (s, f) => s + f.calculatedRations);

  // ── Añadir alimento ───────────────────────────────────────────────────── //
  void _openAddFoodModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFoodModal(
        onFoodAdded: (data) => setState(() {
          _addedFoods.add(AddedFood(
            id:                  data['id'],
            name:                data['name'],
            category:            data['category'],
            carbsPer100g:        (data['carbs_per_100g'] as num).toDouble(),
            caloriesPer100g:     (data['calories_per_100g'] as num).toDouble(),
            quantityGrams:       (data['quantity_grams'] as num).toDouble(),
            calculatedHc:        (data['calculated_hc'] as num).toDouble(),
            calculatedCalories:  (data['calculated_calories'] as num).toDouble(),
            calculatedRations:   (data['calculated_rations'] as num).toDouble(),
          ));
        }),
      ),
    );
  }

  // ── Editar alimento ───────────────────────────────────────────────────── //
  void _editFood(int index) {
    final food = _addedFoods[index];
    showDialog(
      context: context,
      builder: (_) => AddFoodDetailsModal(
        selectedFood: Food(
          id: food.id, name: food.name, category: food.category,
          carbsPer100g: food.carbsPer100g, caloriesPer100g: food.caloriesPer100g,
        ),
        isEditMode:      true,
        initialQuantity: food.quantityGrams,
        initialRaciones: food.calculatedRations,
        initialHc:       food.calculatedHc,
        initialCalories: food.calculatedCalories,
        onConfirm: (data) => setState(() {
          _addedFoods[index] = AddedFood(
            id: data['id'], name: data['name'], category: data['category'],
            carbsPer100g:       (data['carbs_per_100g'] as num).toDouble(),
            caloriesPer100g:    (data['calories_per_100g'] as num).toDouble(),
            quantityGrams:      (data['quantity_grams'] as num).toDouble(),
            calculatedHc:       (data['calculated_hc'] as num).toDouble(),
            calculatedCalories: (data['calculated_calories'] as num).toDouble(),
            calculatedRations:  (data['calculated_rations'] as num).toDouble(),
          );
        }),
      ),
    );
  }

  void _removeFood(int index) => setState(() => _addedFoods.removeAt(index));

  // ── Crear comida → guarda en Firestore → muestra resumen ─────────────── //
  Future<void> _createMeal() async {
    if (!_isFormValid || _saving) return;
    setState(() => _saving = true);

    final glucemia = double.tryParse(_glucemiaText) ?? 0;
    double totalInsulin = 0;
    if (_ratioValue > 0 && _fsi > 0) {
      totalInsulin = double.parse(
          ((_totalHc / _ratioValue) + ((glucemia - 110) / _fsi)).toStringAsFixed(1));
    }

    try {
      final mealData = await _mealService.createMeal(
        mealType:      _mealType,
        glucoseLevel:  glucemia,
        totalHc:       _totalHc,
        totalCalories: _totalCalories,
        totalRations:  _totalRations,
        totalInsulin:  totalInsulin,
        foods:         _addedFoods,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AddMealSummaryModal(
          meal: MealSummaryData(
            mealType:      mealData['meal_type'],
            createdAt:     mealData['created_at'],
            totalHc:       (mealData['total_hc'] as num).toDouble(),
            totalCalories: (mealData['total_calories'] as num).toDouble(),
            totalRations:  (mealData['total_rations'] as num).toDouble(),
            totalInsulin:  (mealData['total_insulin'] as num).toDouble(),
            glucoseLevel:  (mealData['glucose_level'] as num).toDouble(),
          ),
        ),
      );

      if (!mounted) return;
      setState(() {
        _addedFoods.clear();
        _mealType    = '';
        _glucemiaText = '';
        _glucemiaCtrl.clear();
        _setNow();
      });
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: ${e.toString()}'),
          backgroundColor: AppColors.rojoSuave,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onTabTapped(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);
    if (index == 0) Navigator.pushNamed(context, '/historial');
    if (index == 1) Navigator.pushNamed(context, '/home');
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      appBar: AppBar(
        backgroundColor: AppColors.azulFondo,
        title: const Text('DiAppBetes',
            style: TextStyle(color: AppColors.blanco, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.blanco),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            _buildDetailsCard(),
            const SizedBox(height: 12),
            _buildFoodsCard(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: (_isFormValid && !_saving) ? _createMeal : null,
                icon: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: AppColors.blanco, strokeWidth: 2))
                    : const Icon(Icons.save, color: AppColors.blanco),
                label: Text(_saving ? 'Guardando...' : 'Crear Comida',
                    style: const TextStyle(color: AppColors.blanco, fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulFondo,
                  disabledBackgroundColor: AppColors.grisDivider,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildDetailsCard() {
    const opciones = ['desayuno', 'almuerzo', 'comida', 'merienda', 'cena'];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detalles de la comida',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
          const SizedBox(height: 14),

          // Fecha/hora readonly
          Row(children: [
            const Icon(Icons.access_time, size: 16, color: AppColors.azulFondo),
            const SizedBox(width: 6),
            Text(_mealTime, style: const TextStyle(fontSize: 14, color: AppColors.grisTexto)),
          ]),
          const Divider(color: AppColors.grisDivider),
          const SizedBox(height: 8),

          // Tipo de comida
          DropdownButtonFormField<String>(
            value: _mealType.isEmpty ? null : _mealType,
            hint: const Text('Seleccionar tipo', style: TextStyle(color: AppColors.grisTexto, fontSize: 14)),
            style: const TextStyle(color: AppColors.grisTexto, fontSize: 15),
            decoration: const InputDecoration(
              labelText: 'Tipo de comida',
              labelStyle: TextStyle(color: AppColors.grisTexto, fontSize: 13),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grisDivider)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azulFondo)),
            ),
            items: opciones.map((o) => DropdownMenuItem(
              value: o,
              child: Text(o[0].toUpperCase() + o.substring(1),
                  style: const TextStyle(color: AppColors.grisTexto)),
            )).toList(),
            onChanged: (v) => setState(() => _mealType = v ?? ''),
          ),
          const SizedBox(height: 12),

          // Glucemia
          TextField(
            controller: _glucemiaCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 15, color: AppColors.grisTexto),
            decoration: const InputDecoration(
              labelText: 'Glucemia (mg/dL)',
              labelStyle: TextStyle(color: AppColors.grisTexto, fontSize: 13),
              suffixText: 'mg/dL',
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grisDivider)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azulFondo)),
            ),
            onChanged: (v) => setState(() => _glucemiaText = v),
          ),

          // Indicador ratio/FSI cargado
          const SizedBox(height: 8),
          Text('Ratio HC: ${_ratioValue.toStringAsFixed(1)} g/U  •  FSI: ${_fsi.toStringAsFixed(0)} mg/dL/U',
              style: const TextStyle(fontSize: 11, color: AppColors.grisTexto)),
        ],
      ),
    );
  }

  Widget _buildFoodsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Alimentos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
              ElevatedButton(
                onPressed: _openAddFoodModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulFondo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: const Icon(Icons.add, color: AppColors.blanco, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_addedFoods.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Pulsa + para añadir alimentos',
                    style: TextStyle(color: AppColors.grisTexto, fontSize: 14)),
              ),
            )
          else ...[
            ..._addedFoods.asMap().entries.map((e) => _buildFoodItem(e.key, e.value)),
            const Divider(color: AppColors.grisDivider),
            // Totales
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _totalChip('HC', '${_totalHc.toStringAsFixed(1)}g', AppColors.azulFondo),
                  _totalChip('Cal', '${_totalCalories.toStringAsFixed(0)}', AppColors.ambarSuave),
                  _totalChip('Rac', _totalRations.toStringAsFixed(1), AppColors.verdesuave),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodItem(int i, AddedFood food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        border: Border.all(color: AppColors.grisDivider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.restaurant, size: 24, color: AppColors.azulFondo),
            const SizedBox(width: 8),
            Expanded(child: Text(food.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.azulFondo),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            IconButton(
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              icon: const Icon(Icons.edit, size: 18, color: AppColors.azulFondo),
              onPressed: () => _editFood(i),
            ),
            const SizedBox(width: 6),
            IconButton(
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete, size: 18, color: AppColors.rojoSuave),
              onPressed: () => _removeFood(i),
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            _infoChip('${food.quantityGrams.toStringAsFixed(0)}g'),
            const SizedBox(width: 8),
            _infoChip('HC: ${food.calculatedHc.toStringAsFixed(1)}g'),
            const SizedBox(width: 8),
            _infoChip('${food.calculatedCalories.toStringAsFixed(0)} cal'),
          ]),
        ],
      ),
    );
  }

  Widget _infoChip(String text) =>
      Text(text, style: const TextStyle(fontSize: 11, color: AppColors.grisTexto));

  Widget _totalChip(String label, String value, Color color) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grisTexto)),
    ],
  );

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.blanco,
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, -2))],
      ),
      child: BottomNavigationBar(
        backgroundColor: AppColors.blanco,
        selectedItemColor: AppColors.fondoAzulClaroActivo,
        unselectedItemColor: AppColors.azulFondo,
        currentIndex: _selectedTab,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.refresh),    label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.home),       label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Comida'),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.cardBackground, borderRadius: BorderRadius.circular(24),
      boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
    ),
    child: child,
  );
}
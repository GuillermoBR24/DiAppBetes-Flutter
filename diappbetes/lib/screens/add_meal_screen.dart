import 'package:diappbetes/screens/add_food_detail_modal.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'add_food_modal.dart';
import 'add_meal_summary_modal.dart';

// ---------------------------------------------------------------------------
// Modelos
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
  late String mealTime;
  String mealType = '';
  String glucemiaText = '';

  // TODO: reemplazar con CurrentHcRatioService.getCurrentHcRatio()
  double ratioValue = 12.0;

  // TODO: reemplazar con ProfileService.getMyProfile()
  double fsi = 50.0;

  // TODO: reemplazar con datos reales al quitar hardcode
  List<AddedFood> addedFoods = [
    AddedFood(
      id: '1',
      name: 'Arroz blanco',
      category: 'cereales',
      carbsPer100g: 28.0,
      caloriesPer100g: 130.0,
      quantityGrams: 150,
      calculatedHc: 42.0,
      calculatedCalories: 195.0,
      calculatedRations: 3.5,
    ),
    AddedFood(
      id: '2',
      name: 'Pechuga de pollo',
      category: 'carnes',
      carbsPer100g: 0.0,
      caloriesPer100g: 165.0,
      quantityGrams: 120,
      calculatedHc: 0.0,
      calculatedCalories: 198.0,
      calculatedRations: 0.0,
    ),
  ];

  int _selectedTab = 2;
  late TextEditingController _glucemiaController;

  @override
  void initState() {
    super.initState();
    _setDateTimeToNow();
    _glucemiaController = TextEditingController(text: glucemiaText);
  }

  @override
  void dispose() {
    _glucemiaController.dispose();
    super.dispose();
  }

  void _setDateTimeToNow() {
    final now = DateTime.now();
    mealTime =
        '${now.year}-${_pad(now.month)}-${_pad(now.day)}  ${_pad(now.hour)}:${_pad(now.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  bool get _isFormValid =>
      mealTime.isNotEmpty &&
      mealType.isNotEmpty &&
      (double.tryParse(glucemiaText) ?? 0) > 0 &&
      addedFoods.isNotEmpty;

  double get _totalHc => addedFoods.fold(0, (s, f) => s + f.calculatedHc);
  double get _totalCalories => addedFoods.fold(0, (s, f) => s + f.calculatedCalories);
  double get _totalRations => addedFoods.fold(0, (s, f) => s + f.calculatedRations);

  void _removeFood(int index) => setState(() => addedFoods.removeAt(index));

  // ── Editar alimento ──────────────────────────────────────────────────── //
  void _editFood(int index) {
    final food = addedFoods[index];
    showDialog(
      context: context,
      builder: (_) => AddFoodDetailsModal(
        selectedFood: Food(
          id: food.id,
          name: food.name,
          category: food.category,
          carbsPer100g: food.carbsPer100g,
          caloriesPer100g: food.caloriesPer100g,
        ),
        isEditMode: true,
        initialQuantity: food.quantityGrams,
        initialRaciones: food.calculatedRations,
        initialHc: food.calculatedHc,
        initialCalories: food.calculatedCalories,
        onConfirm: (data) => setState(() {
          addedFoods[index] = AddedFood(
            id: data['id'],
            name: data['name'],
            category: data['category'],
            carbsPer100g: (data['carbs_per_100g'] as num).toDouble(),
            caloriesPer100g: (data['calories_per_100g'] as num).toDouble(),
            quantityGrams: (data['quantity_grams'] as num).toDouble(),
            calculatedHc: (data['calculated_hc'] as num).toDouble(),
            calculatedCalories: (data['calculated_calories'] as num).toDouble(),
            calculatedRations: (data['calculated_rations'] as num).toDouble(),
          );
        }),
      ),
    );
  }

  // ── Abrir modal de búsqueda de alimentos ─────────────────────────────── //
  void _openAddFoodModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFoodModal(
        onFoodAdded: (data) => setState(() {
          addedFoods.add(AddedFood(
            id: data['id'],
            name: data['name'],
            category: data['category'],
            carbsPer100g: (data['carbs_per_100g'] as num).toDouble(),
            caloriesPer100g: (data['calories_per_100g'] as num).toDouble(),
            quantityGrams: (data['quantity_grams'] as num).toDouble(),
            calculatedHc: (data['calculated_hc'] as num).toDouble(),
            calculatedCalories: (data['calculated_calories'] as num).toDouble(),
            calculatedRations: (data['calculated_rations'] as num).toDouble(),
          ));
        }),
      ),
    );
  }

  // ── Crear comida → muestra resumen → navega a /home ──────────────────── //
  Future<void> _createMeal() async {
    if (!_isFormValid) return;

    final glucemia = double.tryParse(glucemiaText) ?? 0;
    double totalInsulin = 0;

    if (ratioValue > 0 && fsi > 0) {
      totalInsulin = double.parse(
          ((_totalHc / ratioValue) + ((glucemia - 110) / fsi))
              .toStringAsFixed(1));
    }

    // TODO: llamar a MealService.createMeal(...) y usar la respuesta real
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddMealSummaryModal(
        meal: MealSummaryData(
          mealType: mealType,
          createdAt: DateTime.now().toIso8601String(),
          totalHc: _totalHc,
          totalCalories: _totalCalories,
          totalRations: _totalRations,
          totalInsulin: totalInsulin,
          glucoseLevel: glucemia,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      addedFoods.clear();
      mealType = '';
      glucemiaText = '';
      _glucemiaController.clear();
      _setDateTimeToNow();
    });
    Navigator.pushReplacementNamed(context, '/home');
  }

  // ── Navegación bottom bar ─────────────────────────────────────────────── //
  void _onTabTapped(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);
    switch (index) {
      case 0: Navigator.pushNamed(context, '/historial'); break;
      case 1: Navigator.pushNamed(context, '/home'); break;
    }
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      appBar: AppBar(
        backgroundColor: AppColors.azulFondo,
        title: const Text(
          'DiAppBetes',
          style: TextStyle(color: AppColors.blanco, fontWeight: FontWeight.bold, fontSize: 20),
        ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailsCard(),
            const SizedBox(height: 12),
            _buildFoodsCard(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isFormValid ? _createMeal : null,
                icon: const Icon(Icons.save, color: AppColors.blanco),
                label: const Text(
                  'Crear Comida',
                  style: TextStyle(color: AppColors.blanco, fontSize: 16, fontWeight: FontWeight.w600),
                ),
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

  // ── Tarjeta detalles ─────────────────────────────────────────────────── //
  Widget _buildDetailsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detalles de la comida',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
          const SizedBox(height: 14),
          _readonlyField(label: 'Fecha y hora', value: mealTime, icon: Icons.access_time),
          const SizedBox(height: 12),
          _buildMealTypeDropdown(),
          const SizedBox(height: 12),
          TextField(
            controller: _glucemiaController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 15, color: AppColors.grisTexto),
            decoration: const InputDecoration(
              labelText: 'Glucemia (mg/dl)',
              labelStyle: TextStyle(color: AppColors.grisTexto, fontSize: 13),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grisDivider)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azulFondo)),
            ),
            onChanged: (v) => setState(() => glucemiaText = v),
          ),
        ],
      ),
    );
  }

  Widget _readonlyField({required String label, required String value, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grisTexto)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: AppColors.azulFondo), const SizedBox(width: 6)],
            Text(value, style: const TextStyle(fontSize: 15, color: AppColors.grisTexto)),
          ],
        ),
        const Divider(color: AppColors.grisDivider),
      ],
    );
  }

  Widget _buildMealTypeDropdown() {
    const opciones = ['desayuno', 'almuerzo', 'comida', 'merienda', 'cena'];
    return DropdownButtonFormField<String>(
      value: mealType.isEmpty ? null : mealType,
      hint: const Text('Seleccionar Tipo', style: TextStyle(color: AppColors.grisTexto, fontSize: 14)),
      style: const TextStyle(color: AppColors.grisTexto, fontSize: 15),
      decoration: const InputDecoration(
        labelText: 'Tipo Comida',
        labelStyle: TextStyle(color: AppColors.grisTexto, fontSize: 13),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grisDivider)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azulFondo)),
      ),
      items: opciones.map((o) => DropdownMenuItem(
        value: o,
        child: Text(o[0].toUpperCase() + o.substring(1), style: const TextStyle(color: AppColors.grisTexto)),
      )).toList(),
      onChanged: (v) => setState(() => mealType = v ?? ''),
    );
  }

  // ── Tarjeta alimentos ────────────────────────────────────────────────── //
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
          if (addedFoods.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No se han añadido alimentos aún.',
                    style: TextStyle(color: AppColors.grisTexto, fontSize: 14)),
              ),
            )
          else
            ...addedFoods.asMap().entries.map((e) => _buildFoodItem(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildFoodItem(int index, AddedFood food) {
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
          Row(
            children: [
              const Icon(Icons.restaurant, size: 28, color: AppColors.azulFondo),
              const SizedBox(width: 10),
              Expanded(
                child: Text(food.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.azulFondo)),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.edit, size: 20, color: AppColors.azulFondo),
                onPressed: () => _editFood(index),
              ),
              const SizedBox(width: 6),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete, size: 20, color: AppColors.rojoSuave),
                onPressed: () => _removeFood(index),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Peso: ${food.quantityGrams.toStringAsFixed(0)}g',
                  style: const TextStyle(fontSize: 12, color: AppColors.grisTexto)),
              const SizedBox(width: 8),
              Text('Raciones: ${food.calculatedRations.toStringAsFixed(1)} R',
                  style: const TextStyle(fontSize: 12, color: AppColors.grisTexto)),
              const SizedBox(width: 8),
              Text('Cal: ${food.calculatedCalories.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grisTexto)),
            ],
          ),
        ],
      ),
    );
  }

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
          BottomNavigationBarItem(icon: Icon(Icons.refresh), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
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
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}
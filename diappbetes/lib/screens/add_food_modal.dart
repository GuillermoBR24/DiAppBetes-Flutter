import 'package:diappbetes/screens/add_food_detail_modal.dart';
import 'package:diappbetes/utils/food_colors.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Modelo Food (hardcodeado — TODO: conectar con FoodService.getAllFoods())
// ---------------------------------------------------------------------------
class Food {
  final String id;
  final String name;
  final String category;
  final double carbsPer100g;
  final double caloriesPer100g;

  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.carbsPer100g,
    required this.caloriesPer100g,
  });
}

// ---------------------------------------------------------------------------
// Datos hardcodeados
// ---------------------------------------------------------------------------
const _hardcodedFoods = [
  Food(id: '1',  name: 'Manzana',          category: 'frutas',       carbsPer100g: 14.0, caloriesPer100g: 52.0),
  Food(id: '2',  name: 'Plátano',           category: 'frutas',       carbsPer100g: 23.0, caloriesPer100g: 89.0),
  Food(id: '3',  name: 'Pechuga de pollo',  category: 'carnes',       carbsPer100g: 0.0,  caloriesPer100g: 165.0),
  Food(id: '4',  name: 'Salmón',            category: 'pescados',     carbsPer100g: 0.0,  caloriesPer100g: 208.0),
  Food(id: '5',  name: 'Arroz blanco',      category: 'cereales',     carbsPer100g: 28.0, caloriesPer100g: 130.0),
  Food(id: '6',  name: 'Pan integral',      category: 'cereales',     carbsPer100g: 41.0, caloriesPer100g: 247.0),
  Food(id: '7',  name: 'Leche entera',      category: 'lacteos',      carbsPer100g: 4.8,  caloriesPer100g: 61.0),
  Food(id: '8',  name: 'Yogur natural',     category: 'lacteos',      carbsPer100g: 3.6,  caloriesPer100g: 59.0),
  Food(id: '9',  name: 'Lentejas',          category: 'legumbres',    carbsPer100g: 20.0, caloriesPer100g: 116.0),
  Food(id: '10', name: 'Tomate',            category: 'verduras',     carbsPer100g: 3.9,  caloriesPer100g: 18.0),
  Food(id: '11', name: 'Espinacas',         category: 'verduras',     carbsPer100g: 1.4,  caloriesPer100g: 23.0),
  Food(id: '12', name: 'Almendras',         category: 'frutos_secos', carbsPer100g: 22.0, caloriesPer100g: 579.0),
  Food(id: '13', name: 'Croissant',         category: 'bolleria',     carbsPer100g: 46.0, caloriesPer100g: 406.0),
  Food(id: '14', name: 'Chocolate negro',   category: 'dulces',       carbsPer100g: 46.0, caloriesPer100g: 546.0),
  Food(id: '15', name: 'Zumo de naranja',   category: 'bebidas',      carbsPer100g: 10.4, caloriesPer100g: 45.0),
  Food(id: '16', name: 'Gambas',            category: 'mariscos',     carbsPer100g: 0.0,  caloriesPer100g: 85.0),
  Food(id: '17', name: 'Cocido madrileño',  category: 'plato',        carbsPer100g: 12.0, caloriesPer100g: 180.0),
];

// ---------------------------------------------------------------------------
// AddFoodModal — equivalente al AddFoodModalComponent de Angular/Ionic
// Se muestra con: showModalBottomSheet / showDialog desde AddMealScreen
// ---------------------------------------------------------------------------
class AddFoodModal extends StatefulWidget {
  /// Callback cuando el usuario selecciona un alimento y confirma cantidad
  final void Function(Map<String, dynamic> foodData)? onFoodAdded;

  const AddFoodModal({super.key, this.onFoodAdded});

  @override
  State<AddFoodModal> createState() => _AddFoodModalState();
}

class _AddFoodModalState extends State<AddFoodModal> {
  // TODO: reemplazar con FoodService.getAllFoods()
  final List<Food> _allFoods = _hardcodedFoods;
  List<Food> _filteredFoods = List.from(_hardcodedFoods);

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filtrar (equivalente a filterFoods()) ──────────────────────────── //
  void _filterFoods(String term) {
    final t = term.toLowerCase().trim();
    setState(() {
      _filteredFoods = t.isEmpty
          ? List.from(_allFoods)
          : _allFoods
              .where((f) =>
                  f.name.toLowerCase().contains(t) ||
                  f.category.toLowerCase().contains(t))
              .toList();
    });
  }

  // ── Seleccionar alimento → abre AddFoodDetailsModal ─────────────────── //
  void _selectFood(Food food) {
    Navigator.pop(context); // cierra el bottom sheet de búsqueda
    showDialog(
      context: context,
      builder: (_) => AddFoodDetailsModal(
        selectedFood: food,
        onConfirm: (data) => widget.onFoodAdded?.call(data),
      ),
    );
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final searching = _searchController.text.isNotEmpty;

    return Container(
      // Altura del sheet: ~85% de la pantalla
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Header (equivalente al ion-header) ────────────────────── //
          Container(
            decoration: const BoxDecoration(
              color: AppColors.azulFondo,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Añadir Alimento',
                    style: TextStyle(
                      color: AppColors.blanco,
                      fontSize: 18,
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

          // ── Buscador ──────────────────────────────────────────────── //
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterFoods,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.grisTexto),
              decoration: InputDecoration(
                hintText: 'Buscar alimento...',
                hintStyle: const TextStyle(color: AppColors.grisTexto),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.azulFondo),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // ── Lista de alimentos ─────────────────────────────────────── //
          Expanded(
            child: _filteredFoods.isEmpty
                ? Center(
                    child: Text(
                      searching
                          ? 'No se encontraron alimentos para\n"${_searchController.text}"'
                          : 'Cargando alimentos...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.grisTexto, fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: _filteredFoods.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.grisDivider),
                    itemBuilder: (_, i) =>
                        _buildFoodRow(_filteredFoods[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Fila de un alimento (equivalente al ion-item del *ngFor) ─────────── //
  Widget _buildFoodRow(Food food) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Nombre + macros
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulFondo,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${food.carbsPer100g}g HC  •  ${food.caloriesPer100g.toStringAsFixed(0)} cal/100g',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.grisTexto),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Chip categoría (equivalente al ion-label.foodCategory con span)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: categoryBg(food.category),
              borderRadius: BorderRadius.circular(18),
            ),
            constraints: const BoxConstraints(minWidth: 80),
            child: Text(
              food.category,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: categoryText(food.category),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botón añadir (equivalente al ion-button.add-btn)
          GestureDetector(
            onTap: () => _selectFood(food),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.azulFondo,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add,
                  color: AppColors.blanco, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Diálogo de detalles del alimento
// Equivalente a AddFoodDetailsModalComponent
// ---------------------------------------------------------------------------
class _FoodDetailsDialog extends StatefulWidget {
  final Food food;
  final void Function(Map<String, dynamic>) onConfirm;

  const _FoodDetailsDialog(
      {required this.food, required this.onConfirm});

  @override
  State<_FoodDetailsDialog> createState() => _FoodDetailsDialogState();
}

class _FoodDetailsDialogState extends State<_FoodDetailsDialog> {
  final TextEditingController _gramsController =
      TextEditingController(text: '100');

  double get _grams =>
      double.tryParse(_gramsController.text) ?? 0;
  double get _calcHc =>
      (_grams * widget.food.carbsPer100g) / 100;
  double get _calcCal =>
      (_grams * widget.food.caloriesPer100g) / 100;
  double get _calcRations => _calcHc / 10; // 1 ración = 10g HC

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.food.name,
        style: const TextStyle(
            color: AppColors.azulFondo, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Campo gramos
          TextField(
            controller: _gramsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cantidad (gramos)',
              labelStyle:
                  TextStyle(color: AppColors.grisTexto, fontSize: 13),
              suffixText: 'g',
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.grisDivider)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.azulFondo)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Preview nutricional calculado
          StatefulBuilder(
            builder: (_, __) => Column(
              children: [
                _previewRow('HC', '${_calcHc.toStringAsFixed(1)} g'),
                _previewRow('Calorías',
                    '${_calcCal.toStringAsFixed(0)} kcal'),
                _previewRow(
                    'Raciones', _calcRations.toStringAsFixed(1)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.grisTexto)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.azulFondo,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _grams > 0
              ? () {
                  widget.onConfirm({
                    'id': widget.food.id,
                    'name': widget.food.name,
                    'category': widget.food.category,
                    'carbs_per_100g': widget.food.carbsPer100g,
                    'calories_per_100g': widget.food.caloriesPer100g,
                    'quantity_grams': _grams,
                    'calculated_hc': double.parse(
                        _calcHc.toStringAsFixed(1)),
                    'calculated_calories': double.parse(
                        _calcCal.toStringAsFixed(0)),
                    'calculated_rations': double.parse(
                        _calcRations.toStringAsFixed(1)),
                  });
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Añadir',
              style: TextStyle(color: AppColors.blanco)),
        ),
      ],
    );
  }

  Widget _previewRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.grisTexto)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azulFondo)),
          ],
        ),
      );
}
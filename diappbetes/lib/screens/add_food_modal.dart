import 'package:diappbetes/screens/add_food_detail_modal.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/food_service.dart';

// ---------------------------------------------------------------------------
// Colores por categoría
// ---------------------------------------------------------------------------
Color categoryBg(String cat) {
  const map = {
    'frutas':       Color(0xFFFFF3E0),
    'carnes':       Color(0xFFFFEBEE),
    'pescados':     Color(0xFFE3F2FD),
    'mariscos':     Color(0xFFE0F7FA),
    'verduras':     Color(0xFFE8F5E9),
    'lacteos':      Color(0xFFF3E5F5),
    'cereales':     Color(0xFFFFF8E1),
    'bolleria':     Color(0xFFFCE4EC),
    'dulces':       Color(0xFFF8BBD0),
    'bebidas':      Color(0xFFE1F5FE),
    'legumbres':    Color(0xFFF1F8E9),
    'frutos_secos': Color(0xFFEFEBE9),
    'plato':        Color(0xFFEDE7F6),
  };
  return map[cat.toLowerCase()] ?? const Color(0xFFFFF3E0);
}

Color categoryText(String cat) {
  const map = {
    'frutas':       Color(0xFFE65100),
    'carnes':       Color(0xFFB71C1C),
    'pescados':     Color(0xFF0D47A1),
    'mariscos':     Color(0xFF006064),
    'verduras':     Color(0xFF1B5E20),
    'lacteos':      Color(0xFF4A148C),
    'cereales':     Color(0xFFF57F17),
    'bolleria':     Color(0xFFAD1457),
    'dulces':       Color(0xFF880E4F),
    'bebidas':      Color(0xFF01579B),
    'legumbres':    Color(0xFF33691E),
    'frutos_secos': Color(0xFF4E342E),
    'plato':        Color(0xFF311B92),
  };
  return map[cat.toLowerCase()] ?? const Color(0xFFE65100);
}

// ---------------------------------------------------------------------------
// AddFoodModal — búsqueda con OpenFoodFacts + fallback local
// ---------------------------------------------------------------------------
class AddFoodModal extends StatefulWidget {
  final void Function(Map<String, dynamic> foodData)? onFoodAdded;

  const AddFoodModal({super.key, this.onFoodAdded});

  @override
  State<AddFoodModal> createState() => _AddFoodModalState();
}

class _AddFoodModalState extends State<AddFoodModal> {
  final _foodService    = FoodService();
  final _searchCtrl     = TextEditingController();

  List<Food> _foods        = [];
  bool       _loading      = false;
  bool       _searching    = false; // true = búsqueda API activa
  String     _searchTerm   = '';

  // Debounce para no llamar a la API en cada tecla
  DateTime? _lastKeyPress;

  @override
  void initState() {
    super.initState();
    // Carga los alimentos locales al abrir el modal
    setState(() => _foods = _foodService.getLocalFoods());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Búsqueda con debounce de 600ms ───────────────────────────────────── //
  void _onSearchChanged(String term) {
    setState(() => _searchTerm = term);
    _lastKeyPress = DateTime.now();

    if (term.trim().isEmpty) {
      setState(() {
        _foods    = _foodService.getLocalFoods();
        _searching = false;
      });
      return;
    }

    Future.delayed(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(_lastKeyPress!);
      if (elapsed.inMilliseconds < 590) return; // otro keypress llegó antes

      setState(() { _loading = true; _searching = true; });
      final results = await _foodService.searchFoods(term.trim());
      if (!mounted) return;
      setState(() { _foods = results; _loading = false; });
    });
  }

  // ── Seleccionar alimento → abre modal de detalles ────────────────────── //
  void _selectFood(Food food) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => AddFoodDetailsModal(
        selectedFood: food,
        onConfirm: (data) => widget.onFoodAdded?.call(data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────── //
          Container(
            decoration: const BoxDecoration(
              color: AppColors.azulFondo,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Añadir Alimento',
                      style: TextStyle(color: AppColors.blanco, fontSize: 18, fontWeight: FontWeight.bold)),
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
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 15, color: AppColors.grisTexto),
              decoration: InputDecoration(
                hintText: 'Buscar alimento...',
                hintStyle: const TextStyle(color: AppColors.grisTexto),
                prefixIcon: const Icon(Icons.search, color: AppColors.azulFondo),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.azulFondo)))
                    : (_searchTerm.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.grisTexto),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            })
                        : null),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // ── Indicador de fuente ───────────────────────────────────── //
          if (_searching && !_loading)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _foods.isEmpty
                    ? 'Sin resultados para "$_searchTerm"'
                    : '${_foods.length} resultados de OpenFoodFacts',
                style: const TextStyle(fontSize: 11, color: AppColors.grisTexto),
                textAlign: TextAlign.center,
              ),
            ),

          // ── Lista ─────────────────────────────────────────────────── //
          Expanded(
            child: _foods.isEmpty && !_loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: AppColors.grisDivider),
                        const SizedBox(height: 8),
                        Text(
                          _searchTerm.isNotEmpty
                              ? 'Sin resultados para "$_searchTerm"'
                              : 'Escribe para buscar alimentos',
                          style: const TextStyle(color: AppColors.grisTexto, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _foods.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.grisDivider),
                    itemBuilder: (_, i) => _buildFoodRow(_foods[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodRow(Food food) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Thumbnail o icono de categoría
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: categoryBg(food.category),
              borderRadius: BorderRadius.circular(8),
            ),
            child: food.iconUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(food.iconUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.restaurant,
                            color: categoryText(food.category), size: 22)),
                  )
                : Icon(Icons.restaurant, color: categoryText(food.category), size: 22),
          ),
          const SizedBox(width: 10),

          // Nombre + macros
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.azulFondo),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${food.carbsPer100g.toStringAsFixed(1)}g HC  •  '
                    '${food.caloriesPer100g.toStringAsFixed(0)} cal/100g',
                    style: const TextStyle(fontSize: 12, color: AppColors.grisTexto)),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Chip categoría
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: categoryBg(food.category),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(food.category,
                style: TextStyle(fontSize: 10, color: categoryText(food.category), fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),

          // Botón añadir
          GestureDetector(
            onTap: () => _selectFood(food),
            child: Container(
              width: 30, height: 30,
              decoration: const BoxDecoration(color: AppColors.azulFondo, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: AppColors.blanco, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
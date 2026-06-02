import 'package:diappbetes/screens/add_food_detail_modal.dart';
import 'package:flutter/material.dart';
import '../services/food_service.dart';

// ---------------------------------------------------------------------------
// Colores por categoría
// ---------------------------------------------------------------------------
Color categoryBg(BuildContext context, String cat) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  if (isDark) {
    const map = {
      'frutas':       Color(0xFF3E2723),
      'carnes':       Color(0xFF3E1414),
      'pescados':     Color(0xFF1A237E),
      'mariscos':     Color(0xFF004D40),
      'verduras':     Color(0xFF1B3A1B),
      'lacteos':      Color(0xFF2E1A47),
      'cereales':     Color(0xFF3E2723),
      'bolleria':     Color(0xFF4A1428),
      'dulces':       Color(0xFF4A1438),
      'bebidas':      Color(0xFF0D2F4F),
      'legumbres':    Color(0xFF2E3D1A),
      'frutos_secos': Color(0xFF2E1F17),
      'plato':        Color(0xFF1F1A3E),
    };
    return map[cat.toLowerCase()] ?? const Color(0xFF3E2723);
  } else {
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
}

Color categoryText(BuildContext context, String cat) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  if (isDark) {
    const map = {
      'frutas':       Color(0xFFFFB74D),
      'carnes':       Color(0xFFEF5350),
      'pescados':     Color(0xFF64B5F6),
      'mariscos':     Color(0xFF4DD0E1),
      'verduras':     Color(0xFF81C784),
      'lacteos':      Color(0xFFBA68C8),
      'cereales':     Color(0xFFFFD54F),
      'bolleria':     Color(0xFFF06292),
      'dulces':       Color(0xFFEC407A),
      'bebidas':      Color(0xFF4FC3F7),
      'legumbres':    Color(0xFFAED581),
      'frutos_secos': Color(0xFFA1887F),
      'plato':        Color(0xFF9575CD),
    };
    return map[cat.toLowerCase()] ?? const Color(0xFFFFB74D);
  } else {
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────── //
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text('Añadir Alimento',
                      style: TextStyle(color: onPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: onPrimaryColor),
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
              style: TextStyle(fontSize: 15, color: textColor),
              decoration: InputDecoration(
                hintText: 'Buscar alimento...',
                hintStyle: TextStyle(color: textSmallColor),
                prefixIcon: Icon(Icons.search, color: primaryColor),
                suffixIcon: _loading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)))
                    : (_searchTerm.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: textSmallColor),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            })
                        : null),
                filled: true,
                fillColor: isDark 
                    ? surfaceColor.withOpacity(0.5)
                    : const Color(0xFFF5F5F5),
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
                style: TextStyle(fontSize: 11, color: textSmallColor),
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
                        Icon(Icons.search_off, size: 48, color: dividerColor),
                        const SizedBox(height: 8),
                        Text(
                          _searchTerm.isNotEmpty
                              ? 'Sin resultados para "$_searchTerm"'
                              : 'Escribe para buscar alimentos',
                          style: TextStyle(color: textColor, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _foods.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: dividerColor),
                    itemBuilder: (_, i) => _buildFoodRow(_foods[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodRow(Food food) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final bg = categoryBg(context, food.category);
    final fg = categoryText(context, food.category);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Thumbnail o icono de categoría
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: food.iconUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(food.iconUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.restaurant,
                            color: fg, size: 22)),
                  )
                : Icon(Icons.restaurant, color: fg, size: 22),
          ),
          const SizedBox(width: 10),

          // Nombre + macros
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${food.carbsPer100g.toStringAsFixed(1)}g HC  •  '
                    '${food.caloriesPer100g.toStringAsFixed(0)} cal/100g',
                    style: TextStyle(fontSize: 12, color: textSmallColor)),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Chip categoría
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(food.category,
                style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),

          // Botón añadir
          GestureDetector(
            onTap: () => _selectFood(food),
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
              child: Icon(Icons.add, color: onPrimaryColor, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
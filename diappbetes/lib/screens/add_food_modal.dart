import 'dart:convert';
import 'package:diappbetes/screens/add_custom_food_modal.dart';
import 'package:diappbetes/screens/add_food_detail_modal.dart';
import 'package:diappbetes/services/custom_food_service.dart';
import 'package:diappbetes/services/profile_service.dart';
import 'package:diappbetes/theme/app_theme.dart';
import 'package:diappbetes/widgets/gluten_indicator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/food_service.dart';

Color categoryBg(BuildContext context, String cat) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  if (isDark) {
    const map = {
      'frutas':       Color(0xFF3E2723),
      'proteicos':       Color(0xFF3E1414),
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
      'proteicos':       Color(0xFFFFEBEE),
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
      'proteicos':       Color(0xFFEF5350),
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
      'proteicos':       Color(0xFFB71C1C),
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

class AddFoodModal extends StatefulWidget {
  final void Function(Map<String, dynamic> foodData)? onFoodAdded;

  const AddFoodModal({super.key, this.onFoodAdded});

  @override
  State<AddFoodModal> createState() => _AddFoodModalState();
}

class _AddFoodModalState extends State<AddFoodModal> {
  final _foodService = FoodService();
  final _customFoodService = CustomFoodService();
  final _searchCtrl  = TextEditingController();
  bool _celiacMode   = false;

  List<Food> _foods      = [];
  String     _searchTerm = '';

  bool _scanning = false;
  String? _lastScannedCode;
  bool _scanningLoading = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _loadCeliacMode();
  }

  Future<void> _openAddCustomFood({Food? editing}) async {
    final result = await showDialog<Food>(
      context: context,
      builder: (_) => AddCustomFoodModal(editingFood: editing),
    );
    if (result != null) {
      await _loadFoods();
    }
  }

  Future<void> _deleteCustomFood(Food food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: const Text('Eliminar alimento'),
        content: Text('¿Eliminar "${food.name}" de tus alimentos personales?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.rojoSuave)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _customFoodService.deleteCustomFood(food.id);
      await _loadFoods();
    }
  }

  Future<void> _loadFoods() async {
    final custom = await _customFoodService.getCustomFoods();
    if (mounted) {
      setState(() {
        _foods = [...custom, ..._foodService.getLocalFoods()];
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _loadCeliacMode() async {
    final celiac = await ProfileService().getCeliacMode();
    if (mounted) setState(() => _celiacMode = celiac);
  }

  void _onSearchChanged(String term) async {
    final customMatches = await _customFoodService.searchCustomFoods(term);
    final localMatches = _foodService.searchFoods(term);
    setState(() {
      _searchTerm = term;
      _foods = [...customMatches, ...localMatches];
    });
  }

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

  void _startScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    setState(() {
      _scanning = true;
      _lastScannedCode = null;
      _scanningLoading = false;
    });
  }

  void _stopScanner() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() {
      _scanning = false;
      _scanningLoading = false;
    });
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode == _lastScannedCode || _scanningLoading) return;

    _lastScannedCode = barcode;
    await _scannerController?.stop();
    if (!mounted) return;
    setState(() => _scanningLoading = true);

    try {
      final food = await _fetchProductFromBarcode(barcode);
      if (!mounted) return;

      _stopScanner();

      if (food != null) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => AddFoodDetailsModal(
            selectedFood: food,
            onConfirm: (data) => widget.onFoodAdded?.call(data),
          ),
        );
      } else {
        _showNotFoundDialog(barcode);
      }
    } catch (e) {
      if (!mounted) return;
      _stopScanner();
      _showNotFoundDialog(barcode);
    }
  }

  Future<Food?> _fetchProductFromBarcode(String barcode) async {
    final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json'
        '?fields=product_name,product_name_es,product_name_en,brands,'
        'nutriments,image_front_small_url,image_url,'
        'allergens,allergens_tags,ingredients_analysis_tags,ingredients_text,ingredients_text_es');

    final response = await http.get(url,
        headers: {'User-Agent': 'DiAppBetes/1.0 (contact@diappbetes.com)'})
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['status'] != 1) return null;

    final product    = json['product'] as Map<String, dynamic>? ?? {};
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    final brand = product['brands']?.toString();
    final rawName = product['product_name']?.toString()
        ?? product['product_name_es']?.toString()
        ?? product['product_name_en']?.toString()
        ?? 'Producto desconocido';
    final name = (brand != null && brand.isNotEmpty && !rawName.toLowerCase().contains(brand.toLowerCase()))
        ? '$rawName ($brand)'
        : rawName;

    final carbs = (nutriments['carbohydrates_100g'] as num?)?.toDouble()
        ?? (nutriments['carbohydrates'] as num?)?.toDouble()
        ?? 0.0;

    final calories = (nutriments['energy-kcal_100g'] as num?)?.toDouble()
        ?? (nutriments['energy-kcal'] as num?)?.toDouble()
        ?? ((nutriments['energy_100g'] as num?)?.toDouble() ?? 0.0) / 4.184;

    final bool? hasGluten = _detectGluten(product);

    return Food(
      id: barcode,
      name: name,
      category: 'plato',
      carbsPer100g: carbs,
      caloriesPer100g: calories,
      iconUrl: product['image_front_small_url']?.toString()
          ?? product['image_url']?.toString(),
      containsGluten: hasGluten,
    );
  }

  bool? _detectGluten(Map<String, dynamic> product) {
    final allergensTags = product['allergens_tags'] as List?;
    if (allergensTags != null) {
      for (final tag in allergensTags) {
        final tagStr = tag.toString().toLowerCase();
        if (tagStr.contains('en:gluten') ||
            tagStr.contains('en:wheat') ||
            tagStr.contains('en:barley') ||
            tagStr.contains('en:rye') ||
            tagStr.contains('en:oats')) {
          return true;
        }
      }
      if (allergensTags.isNotEmpty) return false;
    }

    final allergens = product['allergens']?.toString().toLowerCase() ?? '';
    if (allergens.contains('gluten') ||
        allergens.contains('trigo') ||
        allergens.contains('wheat') ||
        allergens.contains('barley') ||
        allergens.contains('centeño') ||
        allergens.contains('cebada')) {
      return true;
    }

    final analysisTags = product['ingredients_analysis_tags'] as List?;
    if (analysisTags != null) {
      for (final tag in analysisTags) {
        final tagStr = tag.toString().toLowerCase();
        if (tagStr.contains('gluten')) return true;
      }
    }

    final ingredients = '${product['ingredients_text']?.toString().toLowerCase() ?? ''} ${product['ingredients_text_es']?.toString().toLowerCase() ?? ''}';

    if (ingredients.contains('trigo') ||
        ingredients.contains('harina de trigo') ||
        ingredients.contains('gluten') ||
        ingredients.contains('cebada') ||
        ingredients.contains('centeno') ||
        ingredients.contains('avena')) {
      return true;
    }

    if (allergens.isEmpty && allergensTags == null && ingredients.isEmpty) {
      return null;
    }

    return false;
  }

  void _showNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text('Producto no encontrado',
            style: TextStyle(
              color: Theme.of(ctx).colorScheme.primary,
              fontWeight: FontWeight.bold,
            )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Theme.of(ctx).dividerColor),
            const SizedBox(height: 12),
            Text('No se encontraron datos para el código:\n$barcode',
                style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _scannerController?.start();
              setState(() {
                _scanningLoading = false;
                _lastScannedCode = null;
              });
            },
            child: Text('Escanear de nuevo',
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                )),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _stopScanner();
            },
            child: Text('Cancelar',
                style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color)),
          ),
        ],
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
                  icon: Icon(
                    _scanning ? Icons.keyboard : Icons.qr_code_scanner,
                    color: onPrimaryColor,
                  ),
                  tooltip: _scanning ? 'Volver a buscar' : 'Escanear código',
                  onPressed: () {
                    if (_scanning) {
                      _stopScanner();
                    } else {
                      _startScanner();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: onPrimaryColor),
                  tooltip: 'Añadir alimento personal',
                  onPressed: _openAddCustomFood,
                ),
                IconButton(
                  icon: Icon(Icons.close, color: onPrimaryColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: _scanning
                ? _buildScannerView(primaryColor, onPrimaryColor)
                : _buildSearchView(
                    primaryColor: primaryColor,
                    cardColor: cardColor,
                    textColor: textColor,
                    textSmallColor: textSmallColor,
                    dividerColor: dividerColor,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchView({
    required Color primaryColor,
    required Color cardColor,
    required Color? textColor,
    required Color? textSmallColor,
    required Color dividerColor,
    required bool isDark,
    required Color surfaceColor,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            style: TextStyle(fontSize: 15, color: textColor),
            decoration: InputDecoration(
              hintText: 'Buscar alimento (ej. pollo, pasta, manzana)...',
              hintStyle: TextStyle(color: textSmallColor),
              prefixIcon: Icon(Icons.search, color: primaryColor),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: textSmallColor),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearchChanged('');
                      })
                  : null,
              filled: true,
              fillColor: isDark
                  ? surfaceColor.withValues(alpha: 0.5)
                  : const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        Expanded(
          child: _foods.isEmpty
              ? _buildEmptyState(primaryColor, onPrimaryColor: Theme.of(context).colorScheme.onPrimary,
                  textColor: textColor, dividerColor: dividerColor)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _foods.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: dividerColor),
                  itemBuilder: (_, i) => _buildFoodRow(_foods[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color primaryColor,
      {required Color onPrimaryColor, required Color? textColor, required Color dividerColor}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: dividerColor),
            const SizedBox(height: 12),
            Text(
              _searchTerm.isNotEmpty
                  ? 'No encontramos "$_searchTerm" en el catálogo general'
                  : 'Escribe para buscar alimentos',
              style: TextStyle(color: textColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (_searchTerm.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '¿Tienes el envase a mano? Escanea su código de barras\npara obtener el dato exacto del producto.',
                style: TextStyle(color: textColor?.withValues(alpha: 0.7), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _startScanner,
                icon: Icon(Icons.qr_code_scanner, color: onPrimaryColor, size: 18),
                label: Text('Escanear producto',
                    style: TextStyle(color: onPrimaryColor, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView(Color primaryColor, Color onPrimaryColor) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: MobileScanner(
            controller: _scannerController!,
            onDetect: _onBarcodeDetected,
          ),
        ),

        CustomPaint(
          size: Size.infinite,
          painter: _ScanFramePainter(primaryColor),
        ),

        const Positioned(
          top: 20,
          left: 0, right: 0,
          child: Text(
            'Apunta al código de barras del producto',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),

        Positioned(
          bottom: 30,
          left: 0, right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => _scannerController?.toggleTorch(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_on, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text('Linterna', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (_scanningLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: onPrimaryColor),
                  const SizedBox(height: 16),
                  const Text('Buscando producto...',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
      ],
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(food.name,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (food.isCustom) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Personal', style: TextStyle(fontSize: 9, color: primaryColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('${food.carbsPer100g.toStringAsFixed(1)}g HC  •  '
                    '${food.caloriesPer100g.toStringAsFixed(0)} cal/100g',
                    style: TextStyle(fontSize: 12, color: textSmallColor)),
              ],
            ),
          ),
          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Text(food.category, style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 6),

          if (_celiacMode && food.containsGluten != null) ...[
            GlutenIndicator(containsGluten: food.containsGluten, size: 12, showLabel: false),
            const SizedBox(width: 4),
          ],

          if (food.isCustom) ...[
            IconButton(
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              icon: Icon(Icons.edit, size: 16, color: textSmallColor),
              onPressed: () => _openAddCustomFood(editing: food),
            ),
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.rojoSuave),
              onPressed: () => _deleteCustomFood(food),
            ),
            const SizedBox(width: 4),
          ],

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

class _ScanFramePainter extends CustomPainter {
  final Color borderColor;
  _ScanFramePainter(this.borderColor);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final frameW = w * 0.75;
    final frameH = frameW * 0.55;
    final left   = (w - frameW) / 2;
    final top    = (h - frameH) / 2;

    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final clear   = Paint()..blendMode = BlendMode.clear;
    final border  = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), overlay);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, frameW, frameH), const Radius.circular(12)),
      clear,
    );
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, frameW, frameH), const Radius.circular(12)),
      border,
    );

    final corner = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const len = 24.0;

    canvas.drawLine(Offset(left, top + len), Offset(left, top), corner);
    canvas.drawLine(Offset(left, top), Offset(left + len, top), corner);
    canvas.drawLine(Offset(left + frameW - len, top), Offset(left + frameW, top), corner);
    canvas.drawLine(Offset(left + frameW, top), Offset(left + frameW, top + len), corner);
    canvas.drawLine(Offset(left, top + frameH - len), Offset(left, top + frameH), corner);
    canvas.drawLine(Offset(left, top + frameH), Offset(left + len, top + frameH), corner);
    canvas.drawLine(Offset(left + frameW - len, top + frameH), Offset(left + frameW, top + frameH), corner);
    canvas.drawLine(Offset(left + frameW, top + frameH - len), Offset(left + frameW, top + frameH), corner);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}
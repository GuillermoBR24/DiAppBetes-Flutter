import 'dart:convert';
import 'package:diappbetes/services/hc_ratio_service.dart';
import 'package:diappbetes/services/profile_service.dart';
import 'package:diappbetes/widgets/gluten_indicator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannedProduct {
  final String barcode;
  final String name;
  final String brand;
  final double carbsPer100g;
  final double caloriesPer100g;
  final double fatPer100g;
  final double proteinPer100g;
  final String? imageUrl;
  final bool? containsGluten;

  const ScannedProduct({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.carbsPer100g,
    required this.caloriesPer100g,
    required this.fatPer100g,
    required this.proteinPer100g,
    this.imageUrl,
    this.containsGluten,
  });

  factory ScannedProduct.fromOpenFoodFacts(String barcode, Map<String, dynamic> data) {
    final product    = data['product'] as Map<String, dynamic>? ?? {};
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
    final bool? hasGluten = _detectGluten(product);

    return ScannedProduct(
      barcode:         barcode,
      name:            product['product_name']?.toString()
                        ?? product['product_name_es']?.toString()
                        ?? product['product_name_en']?.toString()
                        ?? 'Producto desconocido',
      brand:           product['brands']?.toString() ?? '',
      carbsPer100g:    (nutriments['carbohydrates_100g'] as num?)?.toDouble()
                        ?? (nutriments['carbohydrates'] as num?)?.toDouble()
                        ?? 0.0,
      caloriesPer100g: (nutriments['energy-kcal_100g'] as num?)?.toDouble()
                        ?? (nutriments['energy-kcal'] as num?)?.toDouble()
                        ?? ((nutriments['energy_100g'] as num?)?.toDouble() ?? 0.0) / 4.184,
      fatPer100g:      (nutriments['fat_100g'] as num?)?.toDouble() ?? 0.0,
      proteinPer100g:  (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0.0,
      imageUrl:        product['image_front_small_url']?.toString()
                        ?? product['image_url']?.toString(),
      containsGluten:  hasGluten,
    );
  }
  
  static bool? _detectGluten(Map<String, dynamic> product) {
    final allergensTags = product['allergens_tags'] as List?;
    if (allergensTags != null) {
      for (final tag in allergensTags) {
        final tagStr = tag.toString().toLowerCase();
        if (tagStr.contains('gluten') || tagStr.contains('wheat') || 
            tagStr.contains('barley') || tagStr.contains('rye')) {
          return true;
        }
      }
      if (allergensTags.isNotEmpty) return false;
    }

    final allergens = product['allergens']?.toString().toLowerCase() ?? '';
    if (allergens.contains('gluten') || allergens.contains('trigo') ||
        allergens.contains('wheat') || allergens.contains('centeño')) {
      return true;
    }

    final analysisTags = product['ingredients_analysis_tags'] as List?;
    if (analysisTags != null) {
      for (final tag in analysisTags) {
        final tagStr = tag.toString().toLowerCase();
        if (tagStr.contains('gluten')) return true;
      }
    }

    if (allergens.isEmpty && allergensTags == null) return null;
    
    return false;
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _scanning    = true;
  bool _loading     = false;
  String? _lastCode;

  int _scannerKey = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    try {
      _controller.stop();
    } catch (_) {}
    try {
      _controller.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode == _lastCode || _loading) return;

    _lastCode = barcode;
    
    try {
      await _controller.stop();
    } catch (e) {
      debugPrint('⚠️ [SCANNER] Error al detener tras detección: $e');
    }
    
    if (!mounted) return;
    setState(() { _scanning = false; _loading = true; });

    try {
      final product = await _fetchProduct(barcode);
      if (!mounted) return;
      setState(() => _loading = false);

      if (product != null) {
        _showProductModal(product);
      } else {
        _showNotFound(barcode);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _showNotFound(barcode);
      }
    }
  }

  Future<ScannedProduct?> _fetchProduct(String barcode) async {
    final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json'
        '?fields=product_name,product_name_es,product_name_en,brands,'
        'nutriments,image_front_small_url,image_url,'
        'allergens,allergens_tags,ingredients_analysis_tags');

    final response = await http.get(url,
        headers: {'User-Agent': 'DiAppBetes/1.0 (contact@diappbetes.com)'})
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['status'] != 1) return null;

    return ScannedProduct.fromOpenFoodFacts(barcode, json);
  }

  void _resumeScanner() {
    try {
      _controller.stop();
    } catch (e) {
      debugPrint('⚠️ [SCANNER] Error al detener: $e');
    }
    
    setState(() {
      _scanning = false;
      _lastCode = null;
      _scannerKey++;
    });
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      setState(() {
        _scanning = true;
      });
      
      try {
        _controller.start();
      } catch (e) {
        _recreateController();
      }
    });
  }

  void _recreateController() {
    try {
      _controller.dispose();
    } catch (_) {}
    
    setState(() {
      _scannerKey++;
    });
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _scanning = true;
      });
    });
  }

  void _showProductModal(ScannedProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _ProductModal(
        product: product,
        onRescan: () {
          Navigator.pop(context);
          _resumeScanner();
        },
        onClose: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    ).then((_) {
      if (mounted && !_scanning) {
        _resumeScanner();
      }
    });
  }

  void _showNotFound(String barcode) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                style: TextStyle(
                  color: Theme.of(ctx).textTheme.bodyMedium?.color, 
                  fontSize: 13,
                ),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { 
              Navigator.pop(context); 
              _resumeScanner();
            },
            child: Text('Escanear de nuevo',
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.primary, 
                  fontWeight: FontWeight.bold,
                )),
          ),
        ],
      ),
    ).then((_) {
      if (mounted && !_scanning) {
        _resumeScanner();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, 
              color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('DiAppBetes',
            style: TextStyle(
              color: Theme.of(context).appBarTheme.foregroundColor, 
              fontWeight: FontWeight.bold,
            )),
      ),
      body: Stack(
        children: [
          if (_scanning)
            MobileScanner(
              key: ValueKey('scanner_$_scannerKey'),
              controller: _controller,
              onDetect: _onBarcodeDetected,
            ),
          if (_scanning) _buildScanOverlay(primaryColor),
          if (_loading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: onPrimaryColor),
                    const SizedBox(height: 16),
                    Text('Buscando producto...',
                        style: TextStyle(color: onPrimaryColor, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(Color primaryColor) {
    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: _ScanFramePainter(primaryColor),
        ),
        const Positioned(
          top: 60,
          left: 0, right: 0,
          child: Text(
            'Apunta al código de barras del producto',
            style: TextStyle(color: Colors.white, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0, right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => _controller.toggleTorch(),
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
      ],
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

class _ProductModal extends StatefulWidget {
  final ScannedProduct product;
  final VoidCallback onRescan;
  final VoidCallback? onClose;

  const _ProductModal({
    required this.product, 
    required this.onRescan,
    this.onClose,
  });

  @override
  State<_ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends State<_ProductModal> {
  final TextEditingController _racionesCtrl = TextEditingController();
  final _gramsCtrl = TextEditingController(text: '100');
  double _grams = 100;
  double _raciones = 0;
  double _hc = 0;
  double _calories = 0;

  final _glucoseCtrl = TextEditingController(text: '100');
  double _glucose = 100;
  double _insulin = 0;
  double _ratioValue = 10.0;
  double _fsi = 50.0;

  bool _editingGrams = true;
  bool _celiacMode = false;

  @override
  void initState() {
    super.initState();
    _calcFromGrams();
    _racionesCtrl.text = _raciones.toStringAsFixed(1);
    _loadUserData();
    _loadCeliacMode();
  }

  @override
  void dispose() {
    _gramsCtrl.dispose();
    _racionesCtrl.dispose();
    _glucoseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final profileService = ProfileService();
    final hcRatioService = HcRatioService();
    
    final ratio = await hcRatioService.getCurrentHcRatio();
    final fsi = await profileService.getUserFsi();
    
    if (mounted) {
      setState(() {
        _ratioValue = ratio;
        _fsi = fsi;
        _calcInsulin();
      });
    }
  }

  Future<void> _loadCeliacMode() async {
    final celiac = await ProfileService().getCeliacMode();
    if (mounted) setState(() => _celiacMode = celiac);
  }

  void _calcFromGrams() {
    if (_grams < 0) _grams = 0;
    _hc = double.parse((_grams * widget.product.carbsPer100g / 100).toStringAsFixed(1));
    _calories = double.parse((_grams * widget.product.caloriesPer100g / 100).toStringAsFixed(0));
    _raciones = double.parse((_hc / 10).toStringAsFixed(1));
    _calcInsulin();
  }

  void _calcFromRaciones() {
    if (_raciones < 0) _raciones = 0;
    _hc = double.parse((_raciones * 10).toStringAsFixed(1));
    if (widget.product.carbsPer100g > 0) {
      _grams = double.parse((_hc * 100 / widget.product.carbsPer100g).toStringAsFixed(0));
    }
    _calories = double.parse((_grams * widget.product.caloriesPer100g / 100).toStringAsFixed(0));
    _calcInsulin();
  }

  void _calcInsulin() {
    if (_ratioValue > 0 && _fsi > 0) {
      _insulin = double.parse(
        ((_hc / _ratioValue) + ((_glucose - 110) / _fsi)).toStringAsFixed(1)
      );
      if (_insulin < 0) _insulin = 0;
    }
  }

  void _onGramsChanged(String v) {
    if (!_editingGrams) return;
    setState(() {
      _grams = double.tryParse(v) ?? 0;
      _calcFromGrams();
      _racionesCtrl.text = _raciones.toStringAsFixed(1);
    });
  }

  void _onRacionesChanged(String v) {
    _editingGrams = false;
    setState(() {
      _raciones = double.tryParse(v) ?? 0;
      _calcFromRaciones();
      _gramsCtrl.text = _grams.toStringAsFixed(0);
    });
    _editingGrams = true;
  }

  void _onGlucoseChanged(String v) {
    setState(() {
      _glucose = double.tryParse(v) ?? 0;
      _calcInsulin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final cardColor = Theme.of(context).cardColor;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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
                Expanded(
                  child: Text('Producto Escaneado',
                      style: TextStyle(
                        color: onPrimaryColor, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                      )),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: onPrimaryColor),
                  onPressed: () {
                    if (widget.onClose != null) {
                      widget.onClose!();
                    } else {
                      Navigator.pop(context);
                    }
                  },
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
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: widget.product.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(widget.product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                          Icons.restaurant, color: primaryColor, size: 28)),
                                )
                              : Icon(Icons.restaurant, color: primaryColor, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.product.name,
                                  style: TextStyle(
                                    fontSize: 15, 
                                    fontWeight: FontWeight.bold, 
                                    color: primaryColor,
                                  ),
                                  maxLines: 2, 
                                  overflow: TextOverflow.ellipsis),
                              if (widget.product.brand.isNotEmpty)
                                Text(widget.product.brand,
                                    style: TextStyle(fontSize: 12, color: textSmallColor)),
                              const SizedBox(height: 4),
                              Text('${widget.product.carbsPer100g.toStringAsFixed(1)}g HC · '
                                  '${widget.product.caloriesPer100g.toStringAsFixed(0)} cal/100g',
                                  style: TextStyle(fontSize: 12, color: textSmallColor)),
                              if (_celiacMode && widget.product.containsGluten != null) ...[
                                const SizedBox(height: 6),
                                GlutenIndicator(
                                  containsGluten: widget.product.containsGluten,
                                  size: 12,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

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
                  const SizedBox(height: 20),

                  _inputField(
                    label: 'Glucosa actual',
                    controller: _glucoseCtrl,
                    suffix: 'mg/dL',
                    onChanged: _onGlucoseChanged,
                    primaryColor: primaryColor,
                    textSmallColor: textSmallColor,
                    dividerColor: dividerColor,
                  ),
                  const SizedBox(height: 4),
                  Text('Objetivo: 110 mg/dL',
                      style: TextStyle(fontSize: 11, color: textSmallColor),
                      textAlign: TextAlign.right),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resumen Nutricional',
                            style: TextStyle(
                              fontSize: 15, 
                              fontWeight: FontWeight.bold, 
                              color: primaryColor,
                            )),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _nutrientColumn('HC', '${_hc.toStringAsFixed(1)}g', primaryColor),
                            _nutrientColumn('Calorías', '${_calories.toStringAsFixed(0)} kcal', primaryColor),
                            _nutrientColumn('Raciones', _raciones.toStringAsFixed(1), primaryColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.vaccines, color: onPrimaryColor, size: 24),
                            const SizedBox(width: 8),
                            Text('Insulina necesaria',
                                style: TextStyle(
                                  color: onPrimaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${_insulin.toStringAsFixed(1)} U',
                            style: TextStyle(
                              color: onPrimaryColor,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 8),
                        Text('Ratio: ${_ratioValue.toStringAsFixed(1)} g/U  •  FSI: ${_fsi.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: onPrimaryColor.withValues(alpha: 0.8),
                              fontSize: 11,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: widget.onRescan,
                      icon: Icon(Icons.qr_code_scanner, color: onPrimaryColor),
                      label: Text('Escanear otro producto',
                          style: TextStyle(
                            color: onPrimaryColor, 
                            fontSize: 16, 
                            fontWeight: FontWeight.w600,
                          )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
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

  Widget _nutrientColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: color,
            )),
        Text(label,
            style: TextStyle(
              fontSize: 11, 
              color: Theme.of(context).textTheme.bodySmall?.color,
            )),
      ],
    );
  }
}
// lib/screens/scanner_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Modelo del producto escaneado
// ---------------------------------------------------------------------------
class ScannedProduct {
  final String barcode;
  final String name;
  final String brand;
  final double carbsPer100g;
  final double caloriesPer100g;
  final double fatPer100g;
  final double proteinPer100g;
  final String? imageUrl;

  const ScannedProduct({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.carbsPer100g,
    required this.caloriesPer100g,
    required this.fatPer100g,
    required this.proteinPer100g,
    this.imageUrl,
  });

  factory ScannedProduct.fromOpenFoodFacts(String barcode, Map<String, dynamic> data) {
    final product    = data['product'] as Map<String, dynamic>? ?? {};
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

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
    );
  }
}

// ---------------------------------------------------------------------------
// ScannerScreen
// ---------------------------------------------------------------------------
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

  // ── Código detectado → buscar en OpenFoodFacts ───────────────────────── //
  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode == _lastCode || _loading) return;

    _lastCode = barcode;
    
    try {
      await _controller.stop();
    } catch (e) {
      print('⚠️ [SCANNER] Error al detener tras detección: $e');
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

  // ── Consulta OpenFoodFacts por código de barras ───────────────────────── //
  Future<ScannedProduct?> _fetchProduct(String barcode) async {
    final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json'
        '?fields=product_name,product_name_es,product_name_en,brands,'
        'nutriments,image_front_small_url,image_url');

    final response = await http.get(url,
        headers: {'User-Agent': 'DiAppBetes/1.0 (contact@diappbetes.com)'})
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['status'] != 1) return null;

    return ScannedProduct.fromOpenFoodFacts(barcode, json);
  }

  // ── Reanuda la cámara ─────────────────────────────────────────────────── //
  void _resumeScanner() {
    print('🔄 [SCANNER] Reanudando scanner...');
    
    // Detener primero por si acaso
    try {
      _controller.stop();
    } catch (e) {
      print('⚠️ [SCANNER] Error al detener: $e');
    }
    
    setState(() {
      _scanning = false;
      _lastCode = null;
      _scannerKey++; // ← Cambiar key para forzar reconstrucción
    });
    
    // Pequeño delay para dar tiempo al sistema a liberar la cámara
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      setState(() {
        _scanning = true;
      });
      
      // Iniciar el controlador
      try {
        _controller.start();
        print('✅ [SCANNER] Scanner reanudado correctamente');
      } catch (e) {
        print('❌ [SCANNER] Error al reanudar: $e');
        // Si falla, intentar recrear el controlador
        _recreateController();
      }
    });
  }

  void _recreateController() {
    print('🔧 [SCANNER] Recreando controlador...');
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

  // ── Modal con los datos del producto ─────────────────────────────────── //
  void _showProductModal(ScannedProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,  // ← No se puede cerrar tocando fuera
      enableDrag: false,      // ← No se puede cerrar arrastrando
      builder: (_) => _ProductModal(
        product: product,
        onRescan: () {
          Navigator.pop(context);
          _resumeScanner();
        },
        onClose: () {
          Navigator.pop(context);
          // No reanudar scanner, volver a pantalla anterior
          Navigator.pop(context);
        },
      ),
    ).then((_) {
      // Fallback: si el modal se cierra de forma inesperada, reanudar scanner
      if (mounted && !_scanning) {
        print('🔄 [SCANNER] Modal cerrado inesperadamente, reanudando scanner...');
        _resumeScanner();
      }
    });
  }

  // ── Producto no encontrado ────────────────────────────────────────────── //
  void _showNotFound(String barcode) {
    showDialog(
      context: context,
      barrierDismissible: false,  // ← No se puede cerrar tocando fuera
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
              _resumeScanner();  // ← Reanudar al cerrar
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
      // Fallback: si el diálogo se cierra de forma inesperada, reanudar scanner
      if (mounted && !_scanning) {
        print('🔄 [SCANNER] Diálogo cerrado inesperadamente, reanudando scanner...');
        _resumeScanner();
      }
    });
  }

  // =========================================================================
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
          // ✅ USAR KEY para forzar reconstrucción
          if (_scanning)
            MobileScanner(
              key: ValueKey('scanner_$_scannerKey'), // ← CLAVE IMPORTANTE
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

  // ── Overlay con recuadro guía y linterna ─────────────────────────────── //
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

// ---------------------------------------------------------------------------
// Pintor del recuadro de escaneo
// ---------------------------------------------------------------------------
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

    final overlay = Paint()..color = Colors.black.withOpacity(0.55);
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

// ---------------------------------------------------------------------------
// Modal del producto escaneado — calculadora de raciones
// ---------------------------------------------------------------------------
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
  final _gramsCtrl    = TextEditingController(text: '100');
  final _racionesCtrl = TextEditingController();

  double _grams    = 100;
  double _hc       = 0;
  double _calories = 0;
  double _raciones = 0;

  bool _editingGrams = true;

  @override
  void initState() {
    super.initState();
    _calcFromGrams();
    _racionesCtrl.text = _raciones.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _gramsCtrl.dispose();
    _racionesCtrl.dispose();
    super.dispose();
  }

  void _calcFromGrams() {
    _hc       = double.parse((_grams * widget.product.carbsPer100g / 100).toStringAsFixed(1));
    _calories = double.parse((_grams * widget.product.caloriesPer100g / 100).toStringAsFixed(0));
    _raciones = double.parse((_hc / 10).toStringAsFixed(1));
  }

  void _calcFromRaciones() {
    _hc       = double.parse((_raciones * 10).toStringAsFixed(1));
    if (widget.product.carbsPer100g > 0) {
      _grams = double.parse((_hc * 100 / widget.product.carbsPer100g).toStringAsFixed(0));
    }
    _calories = double.parse((_grams * widget.product.caloriesPer100g / 100).toStringAsFixed(0));
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final cardColor = Theme.of(context).cardColor;
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
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(children: [
              Expanded(
                child: Text('Producto Escaneado',
                    style: TextStyle(color: onPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
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
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: isDark 
                              ? surfaceColor.withOpacity(0.5)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: widget.product.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(widget.product.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(Icons.fastfood, size: 36, color: primaryColor)))
                            : Icon(Icons.fastfood, size: 36, color: primaryColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.product.name,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                                    color: primaryColor),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (widget.product.brand.isNotEmpty)
                              Text(widget.product.brand,
                                  style: TextStyle(fontSize: 12, color: textSmallColor)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Cód: ${widget.product.barcode}',
                                  style: TextStyle(fontSize: 11, color: primaryColor)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? surfaceColor.withOpacity(0.5)
                          : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Valores nutricionales por 100g',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                color: primaryColor)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _macroCol('HC', '${widget.product.carbsPer100g.toStringAsFixed(1)}g',
                                AppColors.ambarSuave, textSmallColor),
                            _macroCol('Calorías',
                                '${widget.product.caloriesPer100g.toStringAsFixed(0)} kcal',
                                AppColors.rojoSuave, textSmallColor),
                            _macroCol('Grasas', '${widget.product.fatPer100g.toStringAsFixed(1)}g',
                                AppColors.verdesuave, textSmallColor),
                            _macroCol('Proteínas',
                                '${widget.product.proteinPer100g.toStringAsFixed(1)}g',
                                primaryColor, textSmallColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('Calculadora de raciones',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                          color: primaryColor)),
                  const SizedBox(height: 4),
                  Text('Introduce los gramos o las raciones — el otro campo se calcula solo.',
                      style: TextStyle(fontSize: 12, color: textSmallColor)),
                  const SizedBox(height: 14),

                  Row(children: [
                    Expanded(child: _inputField(
                      label: 'Gramos',
                      suffix: 'g',
                      controller: _gramsCtrl,
                      onChanged: _onGramsChanged,
                      primaryColor: primaryColor,
                      textSmallColor: textSmallColor,
                      dividerColor: dividerColor,
                    )),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.swap_horiz, color: primaryColor),
                    ),
                    Expanded(child: _inputField(
                      label: 'Raciones',
                      suffix: 'R',
                      controller: _racionesCtrl,
                      onChanged: _onRacionesChanged,
                      primaryColor: primaryColor,
                      textSmallColor: textSmallColor,
                      dividerColor: dividerColor,
                    )),
                  ]),
                  const SizedBox(height: 4),
                  Text('1 ración = 10g HC',
                      style: TextStyle(fontSize: 11, color: textSmallColor),
                      textAlign: TextAlign.right),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _resultCol('HC total', '${_hc.toStringAsFixed(1)}g', AppColors.ambarSuave, textSmallColor),
                        _resultCol('Calorías', '${_calories.toStringAsFixed(0)} kcal', AppColors.rojoSuave, textSmallColor),
                        _resultCol('Raciones', _raciones.toStringAsFixed(1), primaryColor, textSmallColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: widget.onRescan,
                      icon: Icon(Icons.qr_code_scanner, color: primaryColor),
                      label: Text('Escanear otro producto',
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _macroCol(String label, String value, Color color, Color? labelColor) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: labelColor)),
    ],
  );

  Widget _resultCol(String label, String value, Color color, Color? labelColor) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
    ],
  );

  Widget _inputField({
    required String label,
    required String suffix,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required Color primaryColor,
    required Color? textSmallColor,
    required Color dividerColor,
  }) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
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
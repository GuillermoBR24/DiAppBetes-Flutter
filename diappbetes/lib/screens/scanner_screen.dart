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

  bool _scanning    = true;   // cámara activa
  bool _loading     = false;  // consultando API
  String? _lastCode;          // evita procesar el mismo código dos veces
  int _selectedTab  = 2;      // escáner = posición central en el futuro

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Código detectado → buscar en OpenFoodFacts ───────────────────────── //
  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode == _lastCode || _loading) return;

    _lastCode = barcode;
    await _controller.stop(); // pausa la cámara
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
    if (json['status'] != 1) return null; // producto no encontrado

    return ScannedProduct.fromOpenFoodFacts(barcode, json);
  }

  // ── Reanuda la cámara ─────────────────────────────────────────────────── //
  void _resumeScanner() {
    setState(() { _scanning = true; _lastCode = null; });
    _controller.start();
  }

  // ── Modal con los datos del producto ─────────────────────────────────── //
  void _showProductModal(ScannedProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductModal(
        product: product,
        onRescan: () {
          Navigator.pop(context);
          _resumeScanner();
        },
      ),
    );
  }

  // ── Producto no encontrado ────────────────────────────────────────────── //
  void _showNotFound(String barcode) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Producto no encontrado',
            style: TextStyle(color: AppColors.azulFondo, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.grisDivider),
            const SizedBox(height: 12),
            Text('No se encontraron datos para el código:\n$barcode',
                style: const TextStyle(color: AppColors.grisTexto, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _resumeScanner(); },
            child: const Text('Escanear de nuevo',
                style: TextStyle(color: AppColors.azulFondo, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);
    switch (index) {
      case 0: Navigator.pushReplacementNamed(context, '/historial'); break;
      case 1: Navigator.pushReplacementNamed(context, '/home'); break;
      case 3: Navigator.pushNamed(context, '/add-meal'); break;
    }
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.azulFondo,
        titleSpacing: 0, // ← Elimina el margen izquierdo por defecto del AppBar
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 16), // ← Margen izquierdo opcional para separar del borde
            // Fondo blanco con bordes redondeados + Logo
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.blanco, // ← Fondo blanco
                borderRadius: BorderRadius.circular(8), // ← Bordes circulares (ajusta el valor)
                // Opcional: sombra sutil para profundidad
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8), // ← Recorta la imagen a los bordes redondeados
                child: Image.asset(
                  'assets/favicon.png',
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.image_not_supported, color: AppColors.azulFondo, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12), // ← Espacio entre logo y texto
            // Título
            const Text('DiAppBetes',
                style: TextStyle(
                  color: AppColors.blanco, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 20
                )),
          ],
        ),
      ),
      body: Stack(
        children: [
          // ── Cámara ─────────────────────────────────────────────────── //
          if (_scanning)
            MobileScanner(
              controller: _controller,
              onDetect: _onBarcodeDetected,
            ),

          // ── Overlay con guía de escaneo ─────────────────────────────── //
          if (_scanning) _buildScanOverlay(),

          // ── Spinner mientras carga la API ─────────────────────────── //
          if (_loading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.blanco),
                    SizedBox(height: 16),
                    Text('Buscando producto...',
                        style: TextStyle(color: AppColors.blanco, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Overlay con recuadro guía y linterna ─────────────────────────────── //
  Widget _buildScanOverlay() {
    return Stack(
      children: [
        // Fondo semitransparente excepto el recuadro central
        CustomPaint(
          size: Size.infinite,
          painter: _ScanFramePainter(),
        ),

        // Instrucción
        const Positioned(
          top: 60,
          left: 0, right: 0,
          child: Text(
            'Apunta al código de barras del producto',
            style: TextStyle(color: Colors.white, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),

        // Botón linterna
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
          BottomNavigationBarItem(icon: Icon(Icons.refresh),         label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.home),            label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Escáner'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant),      label: 'Comida'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pintor del recuadro de escaneo
// ---------------------------------------------------------------------------
class _ScanFramePainter extends CustomPainter {
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
      ..color = AppColors.azulFondo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Fondo oscuro completo
    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), overlay);

    // Hueco transparente
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, frameW, frameH), const Radius.circular(12)),
      clear,
    );
    canvas.restore();

    // Borde azul del recuadro
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, frameW, frameH), const Radius.circular(12)),
      border,
    );

    // Esquinas destacadas
    final corner = Paint()
      ..color = AppColors.azulFondo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const len = 24.0;

    // Esquina sup-izq
    canvas.drawLine(Offset(left, top + len), Offset(left, top), corner);
    canvas.drawLine(Offset(left, top), Offset(left + len, top), corner);
    // Esquina sup-der
    canvas.drawLine(Offset(left + frameW - len, top), Offset(left + frameW, top), corner);
    canvas.drawLine(Offset(left + frameW, top), Offset(left + frameW, top + len), corner);
    // Esquina inf-izq
    canvas.drawLine(Offset(left, top + frameH - len), Offset(left, top + frameH), corner);
    canvas.drawLine(Offset(left, top + frameH), Offset(left + len, top + frameH), corner);
    // Esquina inf-der
    canvas.drawLine(Offset(left + frameW - len, top + frameH), Offset(left + frameW, top + frameH), corner);
    canvas.drawLine(Offset(left + frameW, top + frameH - len), Offset(left + frameW, top + frameH), corner);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ---------------------------------------------------------------------------
// Modal del producto escaneado — calculadora de raciones
// ---------------------------------------------------------------------------
class _ProductModal extends StatefulWidget {
  final ScannedProduct product;
  final VoidCallback onRescan;

  const _ProductModal({required this.product, required this.onRescan});

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

  bool _editingGrams = true; // evita bucle al sincronizar campos

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
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.azulFondo,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(children: [
              const Expanded(
                child: Text('Producto Escaneado',
                    style: TextStyle(color: AppColors.blanco, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.blanco),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Info del producto ──────────────────────────────── //
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen o icono
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: widget.product.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(widget.product.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.fastfood, size: 36, color: AppColors.azulFondo)))
                            : const Icon(Icons.fastfood, size: 36, color: AppColors.azulFondo),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.product.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                                    color: AppColors.azulFondo),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (widget.product.brand.isNotEmpty)
                              Text(widget.product.brand,
                                  style: const TextStyle(fontSize: 12, color: AppColors.grisTexto)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Cód: ${widget.product.barcode}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.azulFondo)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Tabla de macros por 100g ───────────────────────── //
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Valores nutricionales por 100g',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                color: AppColors.azulFondo)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _macroCol('HC', '${widget.product.carbsPer100g.toStringAsFixed(1)}g',
                                AppColors.ambarSuave),
                            _macroCol('Calorías',
                                '${widget.product.caloriesPer100g.toStringAsFixed(0)} kcal',
                                AppColors.rojoSuave),
                            _macroCol('Grasas', '${widget.product.fatPer100g.toStringAsFixed(1)}g',
                                AppColors.verdesuave),
                            _macroCol('Proteínas',
                                '${widget.product.proteinPer100g.toStringAsFixed(1)}g',
                                AppColors.azulFondo),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Calculadora bidireccional ──────────────────────── //
                  const Text('Calculadora de raciones',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                          color: AppColors.azulFondo)),
                  const SizedBox(height: 4),
                  const Text('Introduce los gramos o las raciones — el otro campo se calcula solo.',
                      style: TextStyle(fontSize: 12, color: AppColors.grisTexto)),
                  const SizedBox(height: 14),

                  Row(children: [
                    Expanded(child: _inputField(
                      label: 'Gramos',
                      suffix: 'g',
                      controller: _gramsCtrl,
                      onChanged: _onGramsChanged,
                    )),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.swap_horiz, color: AppColors.azulFondo),
                    ),
                    Expanded(child: _inputField(
                      label: 'Raciones',
                      suffix: 'R',
                      controller: _racionesCtrl,
                      onChanged: _onRacionesChanged,
                    )),
                  ]),
                  const SizedBox(height: 4),
                  const Text('1 ración = 10g HC',
                      style: TextStyle(fontSize: 11, color: AppColors.grisTexto),
                      textAlign: TextAlign.right),
                  const SizedBox(height: 16),

                  // ── Resultado calculado ────────────────────────────── //
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _resultCol('HC total', '${_hc.toStringAsFixed(1)}g', AppColors.ambarSuave),
                        _resultCol('Calorías', '${_calories.toStringAsFixed(0)} kcal', AppColors.rojoSuave),
                        _resultCol('Raciones', _raciones.toStringAsFixed(1), AppColors.azulFondo),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Botón escanear de nuevo ────────────────────────── //
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: widget.onRescan,
                      icon: const Icon(Icons.qr_code_scanner, color: AppColors.azulFondo),
                      label: const Text('Escanear otro producto',
                          style: TextStyle(color: AppColors.azulFondo, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.azulFondo),
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

  Widget _macroCol(String label, String value, Color color) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grisTexto)),
    ],
  );

  Widget _resultCol(String label, String value, Color color) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grisTexto)),
    ],
  );

  Widget _inputField({
    required String label,
    required String suffix,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textAlign: TextAlign.center,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azulFondo),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.grisTexto, fontSize: 13),
      suffixText: suffix,
      suffixStyle: const TextStyle(color: AppColors.grisTexto, fontSize: 13),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grisDivider)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azulFondo)),
    ),
    onChanged: onChanged,
  );
}
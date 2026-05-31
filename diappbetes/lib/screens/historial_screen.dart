import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import 'meal_details_modal.dart';

// ---------------------------------------------------------------------------
// HistorialScreen — equivalente a HistorialPage de Angular/Ionic
// ---------------------------------------------------------------------------
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _historyService = HistoryService();

  List<MealDTO> _allMeals      = [];
  List<MealDTO> _filteredMeals = [];
  bool          _loading       = true;

  DateTime _selectedDate   = DateTime.now();
  String   _selectedType   = 'todas';
  int      _selectedTab    = 0;

  // ── Estadísticas del día ──────────────────────────────────────────────── //
  double _totalHc       = 0;
  double _totalCalories = 0;
  double _avgHc         = 0;
  int    _totalMeals    = 0;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  // ── Cargar comidas desde Firestore ────────────────────────────────────── //
  Future<void> _loadMeals() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final meals = await _historyService.getMeals();
      if (!mounted) return;
      setState(() {
        _allMeals = meals;
        _loading  = false;
      });
      _applyFilters();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al cargar: ${e.toString()}'),
          backgroundColor: AppColors.rojoSuave,
        ));
      }
    }
  }

  // ── Filtrar por fecha + tipo (equivalente a filterMealsByDate()) ──────── //
  void _applyFilters() {
    final dateStr = _isoDate(_selectedDate);

    var filtered = _allMeals.where((m) => _isoDate(m.createdAt) == dateStr).toList();

    if (_selectedType != 'todas') {
      filtered = filtered.where((m) => m.mealType.toLowerCase() == _selectedType).toList();
    }

    setState(() {
      _filteredMeals = filtered;
      _calcStats(filtered);
    });
  }

  // ── Calcular estadísticas del día ─────────────────────────────────────── //
  void _calcStats(List<MealDTO> meals) {
    if (meals.isEmpty) {
      _totalMeals = 0;
      return;
    }
    double hc = 0, cal = 0;
    for (final m in meals) {
      hc  += m.totalHc;
      cal += m.totalCalories;
    }
    _totalHc       = double.parse(hc.toStringAsFixed(1));
    _totalCalories = double.parse(cal.toStringAsFixed(0));
    _avgHc         = double.parse((hc / meals.length).toStringAsFixed(1));
    _totalMeals    = meals.length;
  }

  // ── Selector de fecha con CalendarDatePicker ──────────────────────────── //
  Future<void> _openCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.azulFondo,
            onPrimary: AppColors.blanco,
            surface: AppColors.blanco,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _applyFilters();
    }
  }

  // ── Abrir modal de detalles ────────────────────────────────────────────── //
  void _openMealDetails(MealDTO meal) {
    showDialog(
      context: context,
      builder: (_) => MealDetailsModal(meal: meal),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────── //
  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  String _dateLabel(DateTime d) {
    const dias  = ['lunes','martes','miércoles','jueves','viernes','sábado','domingo'];
    const meses = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
    final wd = d.weekday - 1;
    return '${dias[wd]}, ${d.day} de ${meses[d.month - 1]}';
  }

  String _formatMealDate(DateTime dt) {
    const meses = ['','ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    final h = dt.hour.toString().padLeft(2,'0');
    final m = dt.minute.toString().padLeft(2,'0');
    return '${dt.day} ${meses[dt.month]}, ${dt.year} a las $h:$m';
  }

  void _onTabTapped(int i) {
    if (i == _selectedTab) return;
    setState(() => _selectedTab = i);
    switch (i) {
      case 1: Navigator.pushReplacementNamed(context, '/home'); break;
      case 2: Navigator.pushReplacementNamed(context, '/scanner'); break;
      case 3: Navigator.pushReplacementNamed(context, '/add-meal'); break;
    }
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.blanco),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.azulFondo))
          : RefreshIndicator(
              color: AppColors.azulFondo,
              onRefresh: _loadMeals,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mis Comidas',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
                    const SizedBox(height: 10),

                    // ── Selector de fecha ────────────────────────────── //
                    GestureDetector(
                      onTap: _openCalendar,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: AppColors.azulFondo),
                            const SizedBox(width: 8),
                            Text(
                              _dateLabel(_selectedDate),
                              style: const TextStyle(color: AppColors.azulFondo, fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_drop_down, color: AppColors.azulFondo),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Tarjeta comidas ─────────────────────────────── //
                    _buildMealsCard(),
                    const SizedBox(height: 12),

                    // ── Tarjeta estadísticas ────────────────────────── //
                    _buildStatsCard(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Tarjeta comidas ───────────────────────────────────────────────────── //
  Widget _buildMealsCard() {
    const tipos = ['todas','desayuno','almuerzo','comida','merienda','cena'];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con contador
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Comidas (${_filteredMeals.length})',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
            ],
          ),
          const SizedBox(height: 10),

          // Filtro por tipo
          DropdownButtonFormField<String>(
            value: _selectedType,
            style: const TextStyle(color: AppColors.grisTexto, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Filtrar por tipo',
              labelStyle: TextStyle(color: AppColors.grisTexto, fontSize: 13),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grisDivider)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azulFondo)),
            ),
            items: tipos.map((t) => DropdownMenuItem(
              value: t,
              child: Text(t[0].toUpperCase() + t.substring(1),
                  style: const TextStyle(color: AppColors.grisTexto)),
            )).toList(),
            onChanged: (v) { setState(() => _selectedType = v ?? 'todas'); _applyFilters(); },
          ),
          const SizedBox(height: 12),

          // Lista de comidas
          if (_filteredMeals.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No se han registrado comidas aún.',
                    style: TextStyle(color: AppColors.grisTexto, fontSize: 14)),
              ),
            )
          else
            ..._filteredMeals.asMap().entries.map((e) => _buildMealItem(e.key, e.value)),
        ],
      ),
    );
  }

  // ── Item de comida (equivalente al .meal-item del HTML) ──────────────── //
  Widget _buildMealItem(int i, MealDTO meal) {
    final bg = mealBg(meal.mealType);
    final fg = mealFg(meal.mealType);

    return GestureDetector(
      onTap: () => _openMealDetails(meal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fg.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: nombre tipo + HC
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${meal.mealType[0].toUpperCase()}${meal.mealType.substring(1)} ${i + 1}',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: fg),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${meal.totalHc.toStringAsFixed(1)}g',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: fg)),
                    const Text('HC', style: TextStyle(fontSize: 11, color: AppColors.grisTexto)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Fecha
            Row(children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.grisTexto),
              const SizedBox(width: 4),
              Text(_formatMealDate(meal.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.grisTexto)),
            ]),
            const SizedBox(height: 4),

            // Detalles
            Row(children: [
              Text('${meal.totalCalories.toStringAsFixed(0)} cal',
                  style: const TextStyle(fontSize: 12, color: AppColors.grisTexto)),
              const SizedBox(width: 10),
              Text('${meal.foods.length} alimentos',
                  style: const TextStyle(fontSize: 12, color: AppColors.grisTexto)),
              const SizedBox(width: 10),
              Text('${meal.totalRations.toStringAsFixed(1)} raciones',
                  style: const TextStyle(fontSize: 12, color: AppColors.grisTexto)),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Tarjeta estadísticas ──────────────────────────────────────────────── //
  Widget _buildStatsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estadísticas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              _statItem(Icons.restaurant,    'Comidas Totales', '$_totalMeals'),
              _statItem(Icons.fastfood,       'HC Totales',      '${_totalHc}g'),
              _statItem(Icons.bolt,           'Calorías',        '${_totalCalories.toStringAsFixed(0)}'),
              _statItem(Icons.analytics,      'HC Media',        '${_avgHc}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, size: 26, color: AppColors.azulFondo),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grisTexto)),
              Text(value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.azulFondo),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────── //
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

// ── _Card ────────────────────────────────────────────────────────────────── //
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
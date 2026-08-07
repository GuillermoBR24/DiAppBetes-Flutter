import 'package:diappbetes/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/history_service.dart';
import '../utils/admin_nav_helper.dart';
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
  
  // ── Estado para navegación con AdminNavHelper ────────────────────────── //
  int _selectedTab = 0;
  bool _isAdmin = false;

  // ── Estadísticas del día ──────────────────────────────────────────────── //
  double _totalHc       = 0;
  double _totalCalories = 0;
  double _avgHc         = 0;
  int    _totalMeals    = 0;

  @override
  void initState() {
    super.initState();
    _loadMeals();
    _checkAdminRole();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAdminRole();
  }

  // ── Verificar rol de administrador ───────────────────────────────────── //
  Future<void> _checkAdminRole() async {
    final isAdmin = await AdminNavHelper.getIsAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
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
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: Theme.of(context).colorScheme.primary,
            onPrimary: Theme.of(context).colorScheme.onPrimary,
            surface: Theme.of(context).cardColor,
            onSurface: Theme.of(context).textTheme.bodyLarge?.color,
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

  // ── Manejo de tabs con AdminNavHelper ────────────────────────────────── //
  void _onTabTapped(int index) {
    AdminNavHelper.handleTabTap(
      context: context,
      index: index,
      isAdmin: _isAdmin,
      onValidTap: (validIndex) {
        setState(() => _selectedTab = validIndex);
        switch (validIndex) {
          case 1: Navigator.pushReplacementNamed(context, '/home'); break;
          case 2: Navigator.pushReplacementNamed(context, '/add-meal'); break;
        }
      },
    );
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'DiAppBetes',
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              color: primaryColor,
              onRefresh: () async {
                await _loadMeals();
                await _checkAdminRole();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mis Comidas',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryColor)),
                    const SizedBox(height: 10),

                    // ── Selector de fecha ────────────────────────────── //
                    GestureDetector(
                      onTap: _openCalendar,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              _dateLabel(_selectedDate),
                              style: TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_drop_down, color: primaryColor),
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
      bottomNavigationBar: AdminNavHelper.buildBottomBar(
        context: context,
        currentIndex: _selectedTab,
        onTap: _onTabTapped,
        isAdmin: _isAdmin,
      ),
    );
  }

  // ── Tarjeta comidas ───────────────────────────────────────────────────── //
  Widget _buildMealsCard() {
    const tipos = ['todas','desayuno','almuerzo','comida','merienda','cena'];
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con contador
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Comidas (${_filteredMeals.length})',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
            ],
          ),
          const SizedBox(height: 10),

          // Filtro por tipo
          DropdownButtonFormField<String>(
            value: _selectedType,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Filtrar por tipo',
              labelStyle: TextStyle(color: textSmallColor, fontSize: 13),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: dividerColor)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
            ),
            items: tipos.map((t) => DropdownMenuItem(
              value: t,
              child: Text(t[0].toUpperCase() + t.substring(1),
                  style: TextStyle(color: textColor)),
            )).toList(),
            onChanged: (v) { setState(() => _selectedType = v ?? 'todas'); _applyFilters(); },
          ),
          const SizedBox(height: 12),

          // Lista de comidas
          if (_filteredMeals.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No se han registrado comidas aún.',
                    style: TextStyle(color: textColor, fontSize: 14)),
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
    final bg = mealBg(context, meal.mealType);
    final fg = mealFg(context, meal.mealType);
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;

    return GestureDetector(
      onTap: () => _openMealDetails(meal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fg.withValues(alpha: 0.4)),
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
                    Text('HC', style: TextStyle(fontSize: 11, color: textSmallColor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Fecha
            Row(children: [
              Icon(Icons.access_time, size: 14, color: textSmallColor),
              const SizedBox(width: 4),
              Text(_formatMealDate(meal.createdAt),
                  style: TextStyle(fontSize: 12, color: textSmallColor)),
            ]),
            const SizedBox(height: 4),

            // Detalles
            Row(children: [
              Text('${meal.totalCalories.toStringAsFixed(0)} cal',
                  style: TextStyle(fontSize: 12, color: textSmallColor)),
              const SizedBox(width: 10),
              Text('${meal.foods.length} alimentos',
                  style: TextStyle(fontSize: 12, color: textSmallColor)),
              const SizedBox(width: 10),
              Text('${meal.totalRations.toStringAsFixed(1)} raciones',
                  style: TextStyle(fontSize: 12, color: textSmallColor)),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Tarjeta estadísticas ──────────────────────────────────────────────── //
  Widget _buildStatsCard() {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estadísticas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
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
              _statItem(Icons.bolt,           'Calorías',        _totalCalories.toStringAsFixed(0)),
              _statItem(Icons.analytics,      'HC Media',        '${_avgHc}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.5)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, size: 26, color: primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: textSmallColor)),
              Text(value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── _Card ────────────────────────────────────────────────────────────────── //
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0x1A000000),
            blurRadius: 12, 
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
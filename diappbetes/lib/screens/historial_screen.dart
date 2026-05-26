import 'package:diappbetes/screens/meal_details_modal.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ───────────────────────────────────────────────────────────────────────────
// Modelo de Comida (hardcodeado)
// ───────────────────────────────────────────────────────────────────────────
class Meal {
  final String id;
  final String mealType; // desayuno, almuerzo, comida, merienda, cena
  final double totalHc;
  final int totalCalories;
  final double totalRations;
  final List<String> foods;
  final DateTime createdAt;

  const Meal({
    required this.id,
    required this.mealType,
    required this.totalHc,
    required this.totalCalories,
    required this.totalRations,
    required this.foods,
    required this.createdAt,
  });
}

// ───────────────────────────────────────────────────────────────────────────
// Estadísticas diarias
// ───────────────────────────────────────────────────────────────────────────
class DailyStats {
  final double totalHc;
  final int totalCalories;
  final double totalRations;
  final double avgHc;
  final int totalMealsDay;

  const DailyStats({
    required this.totalHc,
    required this.totalCalories,
    required this.totalRations,
    required this.avgHc,
    required this.totalMealsDay,
  });

  static const empty = DailyStats(
    totalHc: 0,
    totalCalories: 0,
    totalRations: 0,
    avgHc: 0,
    totalMealsDay: 0,
  );
}

// ───────────────────────────────────────────────────────────────────────────
// Pantalla de Historial
// ───────────────────────────────────────────────────────────────────────────
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  // ── Estado ──────────────────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  String _selectedMealType = 'todas';
  List<Meal> _allMeals = [];
  List<Meal> _filteredMeals = [];
  DailyStats _dailyStats = DailyStats.empty;
  int _selectedTab = 0; // Historial seleccionado por defecto

  // ── Datos hardcodeados (simulando respuesta del backend) ─────────────────
  static final List<Meal> _hardcodedMeals = [
    Meal(
      id: '1',
      mealType: 'desayuno',
      totalHc: 45.5,
      totalCalories: 320,
      totalRations: 3.0,
      foods: ['Pan integral', 'Aceite de oliva', 'Tomate'],
      createdAt: DateTime(2024, 5, 27, 8, 30),
    ),
    Meal(
      id: '2',
      mealType: 'almuerzo',
      totalHc: 28.2,
      totalCalories: 180,
      totalRations: 2.0,
      foods: ['Manzana', 'Yogur natural'],
      createdAt: DateTime(2024, 5, 27, 11, 15),
    ),
    Meal(
      id: '3',
      mealType: 'comida',
      totalHc: 62.8,
      totalCalories: 540,
      totalRations: 4.5,
      foods: ['Arroz integral', 'Pechuga de pollo', 'Ensalada', 'Aceite'],
      createdAt: DateTime(2024, 5, 27, 14, 0),
    ),
    Meal(
      id: '4',
      mealType: 'merienda',
      totalHc: 15.0,
      totalCalories: 95,
      totalRations: 1.0,
      foods: ['Puñado de almendras'],
      createdAt: DateTime(2024, 5, 27, 17, 30),
    ),
    Meal(
      id: '5',
      mealType: 'cena',
      totalHc: 38.4,
      totalCalories: 410,
      totalRations: 2.5,
      foods: ['Salmón', 'Brócoli al vapor', 'Quinoa'],
      createdAt: DateTime(2024, 5, 27, 20, 45),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _allMeals = _hardcodedMeals;
    _filterMealsByDate();
  }

  // ── Lógica de filtrado y estadísticas ───────────────────────────────────
  void _filterMealsByDate() {
    final selectedDateString = _formatDateToISO(_selectedDate);
    
    var filtered = _allMeals.where((meal) {
      final mealDateString = _formatDateToISO(meal.createdAt);
      return mealDateString == selectedDateString;
    }).toList();

    if (_selectedMealType != 'todas') {
      filtered = filtered
          .where((meal) => meal.mealType.toLowerCase() == _selectedMealType.toLowerCase())
          .toList();
    }

    setState(() {
      _filteredMeals = filtered;
      _calculateDailyStats();
    });
  }

  void _calculateDailyStats() {
    if (_filteredMeals.isEmpty) {
      setState(() => _dailyStats = DailyStats.empty);
      return;
    }

    double totalHc = 0;
    int totalCalories = 0;
    double totalRations = 0;

    for (final meal in _filteredMeals) {
      totalHc += meal.totalHc;
      totalCalories += meal.totalCalories;
      totalRations += meal.totalRations;
    }

    final avgHc = totalHc / _filteredMeals.length;

    setState(() {
      _dailyStats = DailyStats(
        totalHc: double.parse(totalHc.toStringAsFixed(1)),
        totalCalories: totalCalories,
        totalRations: double.parse(totalRations.toStringAsFixed(1)),
        avgHc: double.parse(avgHc.toStringAsFixed(1)),
        totalMealsDay: _filteredMeals.length,
      );
    });
  }

  // ── Formateadores de fecha ──────────────────────────────────────────────
  String _formatDateToISO(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatMealDate(DateTime date) {
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final month = months[date.month - 1];
    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    return '${date.day} $month, ${date.year} a las $hours:$minutes';
  }

  String _getTodayDateLabel(DateTime date) {
    // Días de la semana en español
    const weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    // Meses en español
    const months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 
                    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    
    final weekday = weekdays[date.weekday - 1]; // weekday: 1=Lunes, 7=Domingo
    final day = date.day;
    final month = months[date.month - 1];
    
    return StringExtension('$weekday, $day de $month').capitalize();
  }

  // ── Colores dinámicos por tipo de comida ────────────────────────────────
  Color _getMealBgColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'desayuno': return AppColors.desayunoFondo;
      case 'almuerzo': return AppColors.almuerzoFondo;
      case 'comida':   return AppColors.comidaFondo;
      case 'merienda': return AppColors.meriendaFondo;
      case 'cena':     return AppColors.cenaFondo;
      default:         return AppColors.cardBackground;
    }
  }

  Color _getMealTextColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'desayuno': return AppColors.desayunoTexto;
      case 'almuerzo': return AppColors.almuerzoTexto;
      case 'comida':   return AppColors.comidaTexto;
      case 'merienda': return AppColors.meriendaTexto;
      case 'cena':     return AppColors.cenaTexto;
      default:         return AppColors.azulFondo;
    }
  }

  // ── Helpers UI ──────────────────────────────────────────────────────────
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _filterMealsByDate();
    }
  }

  void _onTabTapped(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);
    switch (index) {
      case 1: Navigator.pushNamed(context, '/home'); break;
      case 2: Navigator.pushNamed(context, '/add-meal'); break;
    }
  }

  void _openMealDetails(Meal meal) {
    final mealDetail = MealDetail(
      id: meal.id,
      mealType: meal.mealType,
      totalHc: meal.totalHc,
      totalCalories: meal.totalCalories,
      totalRations: meal.totalRations,
      createdAt: meal.createdAt,
      glucoseLevel: 112.0, // Hardcodeado
      totalInsulin: 4.5,   // Hardcodeado
      foods: _getHardcodedFoods(meal.mealType),
    );

    showMealDetailsModal(context, mealDetail);
  }

  List<FoodItem> _getHardcodedFoods(String mealType) {
  switch (mealType.toLowerCase()) {
    case 'desayuno':
      return const [
        FoodItem(id: '1', name: 'Pan integral', category: 'cereales', 
                 quantityGrams: 60, calculatedHc: 30.0, calculatedCalories: 160, calculatedRations: 2.0),
        FoodItem(id: '2', name: 'Aceite de oliva', category: 'verduras', 
                 quantityGrams: 10, calculatedHc: 0, calculatedCalories: 90, calculatedRations: 0),
        FoodItem(id: '3', name: 'Tomate', category: 'verduras', 
                 quantityGrams: 100, calculatedHc: 4.5, calculatedCalories: 20, calculatedRations: 0.3),
      ];
    case 'almuerzo':
      return const [
        FoodItem(id: '4', name: 'Manzana', category: 'frutas', 
                 quantityGrams: 150, calculatedHc: 18.0, calculatedCalories: 80, calculatedRations: 1.2),
        FoodItem(id: '5', name: 'Yogur natural', category: 'lacteos', 
                 quantityGrams: 125, calculatedHc: 6.0, calculatedCalories: 70, calculatedRations: 0.4),
      ];
    case 'comida':
      return const [
        FoodItem(id: '6', name: 'Arroz integral', category: 'cereales', 
                 quantityGrams: 80, calculatedHc: 24.0, calculatedCalories: 110, calculatedRations: 1.6),
        FoodItem(id: '7', name: 'Pechuga de pollo', category: 'carnes', 
                 quantityGrams: 120, calculatedHc: 0, calculatedCalories: 165, calculatedRations: 0),
        FoodItem(id: '8', name: 'Ensalada mixta', category: 'verduras', 
                 quantityGrams: 150, calculatedHc: 8.0, calculatedCalories: 45, calculatedRations: 0.5),
        FoodItem(id: '9', name: 'Aceite de oliva', category: 'verduras', 
                 quantityGrams: 15, calculatedHc: 0, calculatedCalories: 135, calculatedRations: 0),
      ];
    case 'merienda':
      return const [
        FoodItem(id: '10', name: 'Almendras', category: 'frutos_secos', 
                 quantityGrams: 30, calculatedHc: 3.0, calculatedCalories: 180, calculatedRations: 0.2),
      ];
    case 'cena':
      return const [
        FoodItem(id: '11', name: 'Salmón', category: 'pescados', 
                 quantityGrams: 150, calculatedHc: 0, calculatedCalories: 280, calculatedRations: 0),
        FoodItem(id: '12', name: 'Brócoli al vapor', category: 'verduras', 
                 quantityGrams: 200, calculatedHc: 12.0, calculatedCalories: 70, calculatedRations: 0.8),
        FoodItem(id: '13', name: 'Quinoa', category: 'cereales', 
                 quantityGrams: 60, calculatedHc: 22.0, calculatedCalories: 120, calculatedRations: 1.5),
      ];
    default:
      return const [];
  }
}

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      appBar: AppBar(
        backgroundColor: AppColors.azulFondo,
        automaticallyImplyLeading: false,
        title: const Text(
          'DiAppBetes',
          style: TextStyle(
            color: AppColors.blanco,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.blanco),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Mis Comidas',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulFondo,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showDatePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getTodayDateLabel(_selectedDate),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.azulFondo,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMealsCard(),
                  const SizedBox(height: 16),
                  _buildStatsCard(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Card: Lista de comidas ──────────────────────────────────────────────
  Widget _buildMealsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comidas (${_filteredMeals.length})',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.azulFondo,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grisDivider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMealType,
                isExpanded: true,
                dropdownColor: AppColors.blanco,
                items: const [
                  DropdownMenuItem(value: 'todas', child: Text('Todas')),
                  DropdownMenuItem(value: 'desayuno', child: Text('Desayuno')),
                  DropdownMenuItem(value: 'almuerzo', child: Text('Almuerzo')),
                  DropdownMenuItem(value: 'comida', child: Text('Comida')),
                  DropdownMenuItem(value: 'merienda', child: Text('Merienda')),
                  DropdownMenuItem(value: 'cena', child: Text('Cena')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMealType = value);
                    _filterMealsByDate();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_filteredMeals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No se han registrado comidas aún.',
                  style: TextStyle(fontSize: 16, color: AppColors.grisTexto),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredMeals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildMealItem(_filteredMeals[index], index),
            ),
        ],
      ),
    );
  }

  // ── Item individual de comida ───────────────────────────────────────────
  Widget _buildMealItem(Meal meal, int index) {
    final bgColor = _getMealBgColor(meal.mealType);
    final textColor = _getMealTextColor(meal.mealType);
    final mealTypeName = _capitalize(meal.mealType);

    return GestureDetector(
      onTap: () => _openMealDetails(meal),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$mealTypeName ${index + 1}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${meal.totalHc.toStringAsFixed(1)}g',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.verdesuave,
                      ),
                    ),
                    Text('HC', style: TextStyle(fontSize: 12, color: AppColors.grisTexto)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time_outlined, size: 18, color: AppColors.grisTexto),
                const SizedBox(width: 4),
                Text(
                  _formatMealDate(meal.createdAt),
                  style: TextStyle(fontSize: 13, color: AppColors.grisTexto),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('${meal.totalCalories} cal', style: TextStyle(fontSize: 13, color: AppColors.grisTexto)),
                const SizedBox(width: 12),
                Text('${meal.foods.length} alimentos', style: TextStyle(fontSize: 13, color: AppColors.grisTexto)),
                const SizedBox(width: 12),
                Text('${meal.totalRations.toStringAsFixed(1)} raciones', style: TextStyle(fontSize: 13, color: AppColors.grisTexto)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Card: Estadísticas ──────────────────────────────────────────────────
  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.azulFondo,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildStatItem(icon: Icons.restaurant, label: 'Comidas Totales', value: _dailyStats.totalMealsDay.toString()),
              _buildStatItem(icon: Icons.water_drop_outlined, label: 'HC Totales', value: '${_dailyStats.totalHc}g'),
              _buildStatItem(icon: Icons.flash_on, label: 'Calorías Totales', value: _dailyStats.totalCalories.toString()),
              _buildStatItem(icon: Icons.analytics_outlined, label: 'HC Media', value: '${_dailyStats.avgHc}g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: AppColors.azulFondo),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: AppColors.grisTexto), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation Bar ───────────────────────────────────────────────
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

// ───────────────────────────────────────────────────────────────────────────
// Extensión para capitalizar strings (helper)
// ───────────────────────────────────────────────────────────────────────────
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
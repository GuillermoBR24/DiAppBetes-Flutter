import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:diappbetes/utils/admin_nav_helper.dart';
import 'package:diappbetes/widgets/app_feedback.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  final _db = FirebaseFirestore.instance;
  
  bool _loading = true;
  
  int _totalUsers = 0;
  int _totalAdmins = 0;
  int _totalMeals = 0;
  int _totalGlucoseReadings = 0;
  int _newUsersThisWeek = 0;
  
  double _avgMealsPerUser = 0;
  double _avgGlucosePerUser = 0;
  
  Map<String, int> _mealsByType = {};
  
  Map<String, int> _weeklyActivity = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    
    try {
      await Future.wait([
        _loadUserStats(),
        _loadMealStats(),
        _loadGlucoseStats(),
        _loadWeeklyActivity(),
      ]);
      
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppToast.error(context, 'No se pudieron cargar las estadísticas. ${friendlyError(e)}');
      }
    }
  }

  Future<void> _loadUserStats() async {
    final profilesSnap = await _db.collection('profiles').get();
    final users = profilesSnap.docs;
    
    _totalUsers = users.length;
    _totalAdmins = users.where((u) {
      final role = u.data()['role']?.toString().toLowerCase() ?? '';
      return AdminNavHelper.isAdminRole(role);
    }).length;
    
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    _newUsersThisWeek = users.where((u) {
      final createdAt = u.data()['created_at'];
      if (createdAt is Timestamp) {
        return createdAt.toDate().isAfter(weekAgo);
      }
      return false;
    }).length;
  }

  Future<void> _loadMealStats() async {
    final mealsSnap = await _db.collection('meals').get();
    final meals = mealsSnap.docs;
    
    _totalMeals = meals.length;
    
    Map<String, int> byType = {};
    for (var meal in meals) {
      final type = meal.data()['meal_type']?.toString().toLowerCase() ?? 'otros';
      byType[type] = (byType[type] ?? 0) + 1;
    }
    _mealsByType = byType;
    
    if (_totalUsers > 0) {
      _avgMealsPerUser = _totalMeals / _totalUsers;
    }
  }

  Future<void> _loadGlucoseStats() async {
    final readingsSnap = await _db.collection('glucose_readings').get();
    _totalGlucoseReadings = readingsSnap.docs.length;
    
    if (_totalUsers > 0) {
      _avgGlucosePerUser = _totalGlucoseReadings / _totalUsers;
    }
  }

  Future<void> _loadWeeklyActivity() async {
    final now = DateTime.now();
    Map<String, int> activity = {};
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.day}/${date.month}';
      activity[dateStr] = 0;
    }
    
    final mealsSnap = await _db.collection('meals').get();
    for (var meal in mealsSnap.docs) {
      final createdAt = meal.data()['created_at'];
      if (createdAt is Timestamp) {
        final mealDate = createdAt.toDate();
        final isRecent = now.difference(mealDate).inDays <= 6;
        if (isRecent) {
          final dateStr = '${mealDate.day}/${mealDate.month}';
          activity[dateStr] = (activity[dateStr] ?? 0) + 1;
        }
      }
    }
    
    _weeklyActivity = activity;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).cardColor;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Estadísticas',
            style: TextStyle(
              color: Theme.of(context).appBarTheme.foregroundColor,
              fontWeight: FontWeight.bold,
            )),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              color: primaryColor,
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen General',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _statCard(
                          icon: Icons.people,
                          title: 'Total Usuarios',
                          value: '$_totalUsers',
                          subtitle: '$_totalAdmins admins',
                          color: primaryColor,
                        ),
                        _statCard(
                          icon: Icons.person_add,
                          title: 'Nuevos (7 días)',
                          value: '$_newUsersThisWeek',
                          subtitle: 'Esta semana',
                          color: AppColors.verdesuave,
                        ),
                        _statCard(
                          icon: Icons.restaurant,
                          title: 'Total Comidas',
                          value: '$_totalMeals',
                          subtitle: '${_avgMealsPerUser.toStringAsFixed(1)} por usuario',
                          color: AppColors.ambarSuave,
                        ),
                        _statCard(
                          icon: Icons.bloodtype,
                          title: 'Lecturas Glucosa',
                          value: '$_totalGlucoseReadings',
                          subtitle: '${_avgGlucosePerUser.toStringAsFixed(1)} por usuario',
                          color: AppColors.rojoSuave,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Actividad Semanal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDark 
                                ? Colors.black.withValues(alpha: 0.3) 
                                : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AspectRatio(
                        aspectRatio: 2,
                        child: _weeklyActivity.isEmpty
                            ? Center(
                                child: Text(
                                  'Sin datos',
                                  style: TextStyle(color: textSmallColor),
                                ),
                              )
                            : BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: (_weeklyActivity.values.isNotEmpty 
                                      ? _weeklyActivity.values.reduce((a, b) => a > b ? a : b) * 1.2 
                                      : 10),
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          rod.toY.round().toString(),
                                          const TextStyle(color: Colors.white, fontSize: 12),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final labels = _weeklyActivity.keys.toList();
                                          if (value.toInt() >= 0 && value.toInt() < labels.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                labels[value.toInt()],
                                                style: TextStyle(fontSize: 12, color: textSmallColor),
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: _weeklyActivity.entries.map((entry) {
                                    return BarChartGroupData(
                                      x: _weeklyActivity.keys.toList().indexOf(entry.key),
                                      barRods: [
                                        BarChartRodData(
                                          toY: entry.value.toDouble(),
                                          color: primaryColor,
                                          width: 16,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(6),
                                            topRight: Radius.circular(6),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Distribución de Comidas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDark 
                                ? Colors.black.withValues(alpha: 0.3) 
                                : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _mealsByType.isEmpty
                          ? Center(
                              child: Text(
                                'Sin datos de comidas',
                                style: TextStyle(color: textSmallColor),
                              ),
                            )
                          : Column(
                              children: _mealsByType.entries.map((entry) {
                                final percentage = _totalMeals > 0 
                                    ? (entry.value / _totalMeals * 100).round() 
                                    : 0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _capitalize(entry.key),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 150,
                                        child: LinearProgressIndicator(
                                          value: percentage / 100,
                                          backgroundColor: isDark 
                                              ? Colors.grey[800] 
                                              : Colors.grey[200],
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            _getMealTypeColor(entry.key),
                                          ),
                                          minHeight: 8,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 50,
                                        child: Text(
                                          '$percentage%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: textSmallColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Color _getMealTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'desayuno':
        return const Color(0xFFF9A825);
      case 'almuerzo':
        return const Color(0xFF2E7D32);
      case 'comida':
        return const Color(0xFF1565C0);
      case 'merienda':
        return const Color(0xFFAD1457);
      case 'cena':
        return const Color(0xFF4527A0);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
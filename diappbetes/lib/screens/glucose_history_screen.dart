import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/glucose_service.dart';
import '../services/tir_service.dart';
import '../utils/admin_nav_helper.dart';

class GlucoseHistoryScreen extends StatefulWidget {
  const GlucoseHistoryScreen({super.key});

  @override
  State<GlucoseHistoryScreen> createState() => _GlucoseHistoryScreenState();
}

class _GlucoseHistoryScreenState extends State<GlucoseHistoryScreen> {
  final _glucoseService = GlucoseService();
  final _tirService = TirService();

  int _selectedDays = 7;
  DateTime? _startDate;
  DateTime? _endDate;
  
  bool _loading = true;
  List<Map<String, dynamic>> _readings = [];
  
  double _averageGlucose = 0;
  double _minGlucose = 0;
  double _maxGlucose = 0;
  int _tirPercentage = 0;
  
  // Estado para navegación
  // ignore: unused_field
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(Duration(days: _selectedDays));
    _loadData();
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    final isAdmin = await AdminNavHelper.getIsAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final readings = await _glucoseService.getGlucoseReadingsByDateRange(
        _startDate!,
        _endDate!,
      );
      
      final tir = await _tirService.getTirPercentageForRange(
        _startDate!,
        _endDate!,
      );

      if (readings.isNotEmpty) {
        final values = readings.map((r) => (r['glucose_level'] as num).toDouble()).toList();
        _averageGlucose = values.reduce((a, b) => a + b) / values.length;
        _minGlucose = values.reduce((a, b) => a < b ? a : b);
        _maxGlucose = values.reduce((a, b) => a > b ? a : b);
      }

      if (mounted) {
        setState(() {
          _readings = readings;
          _tirPercentage = tir;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onFilterChanged(int days) {
    setState(() {
      _selectedDays = days;
      _endDate = DateTime.now();
      _startDate = _endDate!.subtract(Duration(days: days));
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: _filterChip('7 días', 7, primaryColor, onPrimaryColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _filterChip('30 días', 30, primaryColor, onPrimaryColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _filterChip('90 días', 90, primaryColor, onPrimaryColor),
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: SkeletonList(count: 3),
                  )
                : RefreshIndicator(
                    color: primaryColor,
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStatsCards(primaryColor),
                          const SizedBox(height: 16),

                          _buildEvolutionChart(primaryColor),
                          const SizedBox(height: 16),

                          _buildTirDistribution(primaryColor),
                          const SizedBox(height: 16),

                          _buildRecentReadings(primaryColor),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int days, Color primaryColor, Color onPrimaryColor) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () => _onFilterChanged(days),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Theme.of(context).dividerColor,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? onPrimaryColor : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(Color primaryColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statCard('Media', '${_averageGlucose.toStringAsFixed(1)} mg/dL', Icons.show_chart, primaryColor)),
            const SizedBox(width: 8),
            Expanded(child: _statCard('Mín', _minGlucose.toStringAsFixed(0), Icons.arrow_downward, AppColors.rojoSuave)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _statCard('Máx', _maxGlucose.toStringAsFixed(0), Icons.arrow_upward, Colors.orange)),
            const SizedBox(width: 8),
            Expanded(child: _statCard('TIR', '$_tirPercentage%', Icons.tablet, AppColors.verdesuave)),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0x1A000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionChart(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0x1A000000),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evolución de Glucosas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _readings.isEmpty
                ? const EmptyState(
                    icon: Icons.show_chart,
                    title: 'No hay lecturas en este período',
                    message: 'Prueba con otro rango de fechas o registra una glucemia desde el inicio.',
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 50,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Theme.of(context).dividerColor,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (_readings.length / 5).ceil().toDouble(),
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= _readings.length) return const Text('');
                              final timestamp = _readings[value.toInt()]['reading_time'];
                              final date = timestamp is Timestamp 
                                  ? timestamp.toDate() 
                                  : DateTime.parse(timestamp.toString());
                              
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${date.day}/${date.month}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _readings.asMap().entries.map((e) {
                            return FlSpot(
                              e.key.toDouble(),
                              (e.value['glucose_level'] as num).toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: primaryColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              final glucose = ( _readings[index]['glucose_level'] as num).toDouble();
                              Color dotColor;
                              if (glucose < 70) {
                                dotColor = AppColors.rojoSuave;
                              } else if (glucose > 180) {
                                dotColor = Colors.orange;
                              } else {
                                dotColor = AppColors.verdesuave;
                              }
                              return FlDotCirclePainter(
                                radius: 4,
                                color: dotColor,
                                strokeWidth: 2,
                                strokeColor: Theme.of(context).cardColor,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withValues(alpha: 0.3),
                                primaryColor.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final reading = _readings[spot.x.toInt()];
                              final glucose = (reading['glucose_level'] as num).toDouble();
                              final timestamp = reading['reading_time'];
                              final date = timestamp is Timestamp 
                                  ? timestamp.toDate() 
                                  : DateTime.parse(timestamp.toString());
                              
                              return LineTooltipItem(
                                '${DateFormat('dd/MM HH:mm').format(date)}\n',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                children: [
                                  TextSpan(
                                    text: '$glucose mg/dL',
                                    style: TextStyle(
                                      color: glucose < 70
                                          ? AppColors.rojoSuave
                                          : glucose > 180
                                              ? Colors.orange
                                              : AppColors.verdesuave,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTirDistribution(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0x1A000000),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución TIR',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: _tirPercentage == 0 
                    ? [
                        PieChartSectionData(
                          value: 100,
                          title: 'Sin datos',
                          color: Theme.of(context).dividerColor,
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ]
                    : [
                        PieChartSectionData(
                          value: _tirPercentage.toDouble(),
                          title: '$_tirPercentage%',
                          color: AppColors.verdesuave,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: (100 - _tirPercentage).toDouble(),
                          title: '${100 - _tirPercentage}%',
                          color: AppColors.rojoSuave,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tirLegendItem('En rango', AppColors.verdesuave),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 16,
                color: Theme.of(context).dividerColor,
              ),
              const SizedBox(width: 12),
              _tirLegendItem('Fuera de rango', AppColors.rojoSuave),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tirLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReadings(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0x1A000000),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Últimas Lecturas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _readings.isEmpty
              ? const EmptyState(
                  icon: Icons.water_drop_outlined,
                  title: 'No hay lecturas registradas',
                  message: 'Tus glucemias aparecerán aquí cuando las registres.',
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _readings.length > 10 ? 10 : _readings.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final reading = _readings[index];
                    final glucose = (reading['glucose_level'] as num).toDouble();
                    
                    final timestamp = reading['reading_time'];
                    final date = timestamp is Timestamp 
                        ? timestamp.toDate() 
                        : DateTime.parse(timestamp.toString());
                    
                    Color statusColor;
                    String statusText;
                    
                    if (glucose < 70) {
                      statusColor = AppColors.rojoSuave;
                      statusText = 'Hipo';
                    } else if (glucose <= 180) {
                      statusColor = AppColors.verdesuave;
                      statusText = 'Normal';
                    } else {
                      statusColor = Colors.orange;
                      statusText = 'Hiper';
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          glucose < 70
                              ? Icons.arrow_downward
                              : glucose > 180
                                  ? Icons.arrow_upward
                                  : Icons.check,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '$glucose mg/dL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
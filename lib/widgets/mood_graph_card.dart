import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'glass_widgets.dart';
import '../utils/app_colors.dart';
import '../providers/mood_provider.dart';

import '../screens/mood_history_screen.dart';

class MoodGraphCard extends StatefulWidget {
  const MoodGraphCard({super.key});

  @override
  State<MoodGraphCard> createState() => _MoodGraphCardState();
}

class _MoodGraphCardState extends State<MoodGraphCard> {
  String _timeRange = 'Weekly'; // 'Weekly', 'Monthly', 'Yearly'
  
  @override
  void initState() {
    super.initState();
    // Load mood data when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final moodProvider = Provider.of<MoodProvider>(context, listen: false);
      if (moodProvider.moodEntries.isEmpty) {
        moodProvider.loadMoodHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        final trend = moodProvider.getMoodTrend();
        final isLoading = moodProvider.isLoading;
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MoodHistoryScreen()),
            );
          },
          child: GlassWidget(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_timeRange Mood',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      _buildTrendIndicator(trend),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Time range selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimeRangeButton('Weekly'),
                      _buildTimeRangeButton('Monthly'),
                      _buildTimeRangeButton('Yearly'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mood chart
                  if (isLoading)
                    const SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(AppColors.accentTeal),
                        ),
                      ),
                    )
                  else if (moodProvider.moodEntries.isEmpty)
                    const SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(
                          'No mood data yet.\nStart tracking your mood!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: _buildTitlesData(),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _generateMoodData(moodProvider),
                              isCurved: true,
                              gradient: const LinearGradient(
                                colors: [AppColors.accentTeal, AppColors.accentBlue],
                              ),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: AppColors.accentTeal,
                                    strokeWidth: 2,
                                    strokeColor: AppColors.textPrimary,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accentTeal.withAlpha((255 * 0.3).toInt()),
                                    AppColors.accentTeal.withAlpha((255 * 0.0).toInt()),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                          minX: 0,
                          maxX: _getMaxX(),
                          minY: 1,
                          maxY: 5,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Mood legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMoodLegend('😔', 'Low', AppColors.moodSad),
                      _buildMoodLegend('😐', 'Neutral', AppColors.textSecondary),
                      _buildMoodLegend('😊', 'Good', AppColors.moodHappy),
                      _buildMoodLegend('😄', 'Great', AppColors.moodCalm),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeRangeButton(String range) {
    final isSelected = _timeRange == range;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _timeRange = range;
        });
        
        // Load appropriate data based on range
        final moodProvider = Provider.of<MoodProvider>(context, listen: false);
        int days = 7;
        if (range == 'Monthly') days = 30;
        if (range == 'Yearly') days = 365;
        moodProvider.loadMoodHistory(days: days);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.accentTeal.withAlpha((255 * 0.2).toInt())
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.accentTeal
                : Colors.transparent,
          ),
        ),
        child: Text(
          range,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? AppColors.accentTeal : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(String trend) {
    Color color;
    String icon;
    
    switch (trend) {
      case 'Improving':
        color = AppColors.moodHappy;
        icon = '↗';
        break;
      case 'Declining':
        color = AppColors.moodSad;
        icon = '↘';
        break;
      default:
        color = AppColors.textSecondary;
        icon = '→';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.2).toInt()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$icon $trend',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            
            if (_timeRange == 'Weekly') {
              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              if (index < days.length) {
                return Text(
                  days[index],
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                );
              }
            } else if (_timeRange == 'Monthly') {
              // Show every 5 days
              if (index % 5 == 0 && index <= 30) {
                return Text(
                  index.toString(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                );
              }
            } else if (_timeRange == 'Yearly') {
              // Show months
              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
              if (index < months.length) {
                return Text(
                  months[index],
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                );
              }
            }
            
            return const SizedBox.shrink();
          },
          reservedSize: 22,
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
    );
  }

  double _getMaxX() {
    switch (_timeRange) {
      case 'Weekly':
        return 6;
      case 'Monthly':
        return 30;
      case 'Yearly':
        return 11;
      default:
        return 6;
    }
  }

  List<FlSpot> _generateMoodData(MoodProvider moodProvider) {
    if (moodProvider.moodEntries.isEmpty) {
      return [];
    }
    
    final now = DateTime.now();
    final spots = <FlSpot>[];
    
    if (_timeRange == 'Weekly') {
      // Get data for each day of the current week
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      
      for (int i = 0; i < 7; i++) {
        final day = startOfWeek.add(Duration(days: i));
        final entries = moodProvider.getMoodEntriesForDate(day);
        
        if (entries.isNotEmpty) {
          // Calculate average mood score for the day
          final totalScore = entries.fold<double>(0, (sum, entry) => sum + entry.moodScore);
          final averageScore = totalScore / entries.length;
          spots.add(FlSpot(i.toDouble(), averageScore));
        }
      }
    } else if (_timeRange == 'Monthly') {
      // Get data for each day of the current month
      final startOfMonth = DateTime(now.year, now.month, 1);
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      
      for (int i = 0; i < daysInMonth; i++) {
        final day = startOfMonth.add(Duration(days: i));
        final entries = moodProvider.getMoodEntriesForDate(day);
        
        if (entries.isNotEmpty) {
          final totalScore = entries.fold<double>(0, (sum, entry) => sum + entry.moodScore);
          final averageScore = totalScore / entries.length;
          spots.add(FlSpot(i.toDouble(), averageScore));
        }
      }
    } else if (_timeRange == 'Yearly') {
      // Get data for each month of the current year
      for (int month = 1; month <= 12; month++) {
        final entriesForMonth = moodProvider.moodEntries.where((entry) {
          final entryDate = DateTime.parse(entry.date);
          return entryDate.month == month && entryDate.year == now.year;
        }).toList();
        
        if (entriesForMonth.isNotEmpty) {
          final totalScore = entriesForMonth.fold<double>(0, (sum, entry) => sum + entry.moodScore);
          final averageScore = totalScore / entriesForMonth.length;
          spots.add(FlSpot((month - 1).toDouble(), averageScore));
        }
      }
    }
    
    // If no data points, add a default neutral point
    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 3));
    }
    
    return spots;
  }

  Widget _buildMoodLegend(String emoji, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha((255 * 0.2).toInt()),
            shape: BoxShape.circle,
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

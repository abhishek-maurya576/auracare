import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:fl_chart/fl_chart.dart';
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../providers/mood_provider.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = '7d';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load mood data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final moodProvider = provider.Provider.of<MoodProvider>(context, listen: false);
      moodProvider.loadMoodHistory(days: _getTimeRangeDays());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getTimeRangeDays() {
    switch (_selectedTimeRange) {
      case '7d': return 7;
      case '30d': return 30;
      case '90d': return 90;
      case '1y': return 365;
      default: return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        title: const Text(
          'Insights & Analytics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Trends'),
            Tab(text: 'Patterns'),
            Tab(text: 'Wellness'),
          ],
        ),
      ),
      body: Stack(
        children: [
          const AuraBackground(),
          SafeArea(
            child: Column(
              children: [
                // Time Range Selector
                _buildTimeRangeSelector(),
                
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildTrendsTab(),
                      _buildPatternsTab(),
                      _buildWellnessTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Text(
            'Time Range:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['7d', '30d', '90d', '1y'].map((range) {
                  final isSelected = _selectedTimeRange == range;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTimeRange = range;
                      });
                      // Reload data with new time range
                      provider.Provider.of<MoodProvider>(context, listen: false)
                          .loadMoodHistory(days: _getTimeRangeDays());
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        _getTimeRangeLabel(range),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeRangeLabel(String range) {
    switch (range) {
      case '7d': return '7 Days';
      case '30d': return '30 Days';
      case '90d': return '3 Months';
      case '1y': return '1 Year';
      default: return range;
    }
  }

  Widget _buildOverviewTab() {
    return provider.Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        if (moodProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final moodStats = moodProvider.getMoodStatistics();
        final stressAnalysis = moodProvider.getStressAnalysis();
        final patternAnalysis = moodProvider.getMoodPatternAnalysis();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Key Metrics Cards
            _buildKeyMetricsRow(moodStats, stressAnalysis),
            
            const SizedBox(height: 20),

            // Mood Distribution Chart
            _buildMoodDistributionCard(patternAnalysis),
            
            const SizedBox(height: 20),

            // Recent Insights
            _buildRecentInsightsCard(moodStats, stressAnalysis, patternAnalysis),
            
            const SizedBox(height: 20),

            // Quick Actions
            _buildQuickActionsCard(),
          ],
        );
      },
    );
  }

  Widget _buildKeyMetricsRow(Map<String, dynamic> moodStats, Map<String, dynamic> stressAnalysis) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Average Mood',
            '${(moodStats['averageMoodScore'] as double).toStringAsFixed(1)}/5',
            Icons.mood_rounded,
            _getMoodColor(moodStats['averageMoodScore'] as double),
            'Based on ${moodStats['totalEntries']} entries',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Stress Level',
            '${(stressAnalysis['averageStress'] as double).toStringAsFixed(1)}/10',
            Icons.psychology_rounded,
            _getStressColor(stressAnalysis['averageStress'] as double),
            _getStressDescription(stressAnalysis['averageStress'] as double),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return GlassWidget(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodDistributionCard(Map<String, dynamic> patternAnalysis) {
    final moodDistribution = patternAnalysis['moodDistribution'] as Map<String, int>;
    
    if (moodDistribution.isEmpty) {
      return GlassWidget(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text(
              'No mood data available',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    return GlassWidget(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mood Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(moodDistribution),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildMoodLegend(moodDistribution),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, int> moodDistribution) {
    final total = moodDistribution.values.fold<int>(0, (sum, count) => sum + count);
    final colors = [
      const Color(0xFFFFD66E), // Happy
      const Color(0xFF7EE7D1), // Good
      const Color(0xFFFFFFFF), // Neutral
      const Color(0xFF8B5CF6), // Low
      const Color(0xFF6366F1), // Stressed
    ];
    
    int colorIndex = 0;
    return moodDistribution.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );
    }).toList();
  }

  Widget _buildMoodLegend(Map<String, int> moodDistribution) {
    final colors = [
      const Color(0xFFFFD66E), // Happy
      const Color(0xFF7EE7D1), // Good
      const Color(0xFFFFFFFF), // Neutral
      const Color(0xFF8B5CF6), // Low
      const Color(0xFF6366F1), // Stressed
    ];
    
    int colorIndex = 0;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: moodDistribution.entries.map((entry) {
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        
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
            Text(
              '${entry.key} (${entry.value})',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRecentInsightsCard(
    Map<String, dynamic> moodStats,
    Map<String, dynamic> stressAnalysis,
    Map<String, dynamic> patternAnalysis,
  ) {
    final insights = <Map<String, dynamic>>[];
    
    // Generate insights based on data
    final avgMood = moodStats['averageMoodScore'] as double;
    final streak = moodStats['streakDays'] as int;
    final bestTime = patternAnalysis['bestTimeOfDay'] as String;
    final improvementRate = patternAnalysis['improvementRate'] as double;

    if (avgMood >= 4.0) {
      insights.add({
        'icon': Icons.sentiment_very_satisfied_rounded,
        'color': Colors.green,
        'title': 'Great Mood Trend!',
        'description': 'Your average mood is ${avgMood.toStringAsFixed(1)}/5. Keep it up!',
      });
    } else if (avgMood <= 2.5) {
      insights.add({
        'icon': Icons.sentiment_dissatisfied_rounded,
        'color': Colors.orange,
        'title': 'Mood Needs Attention',
        'description': 'Consider trying meditation or talking to someone.',
      });
    }

    if (streak >= 7) {
      insights.add({
        'icon': Icons.local_fire_department_rounded,
        'color': Colors.orange,
        'title': 'Amazing Streak!',
        'description': 'You\'ve been consistent for $streak days. Fantastic!',
      });
    }

    if (bestTime != 'Unknown') {
      insights.add({
        'icon': Icons.schedule_rounded,
        'color': Colors.blue,
        'title': 'Best Time: ${bestTime.toUpperCase()}',
        'description': 'You tend to feel better in the $bestTime.',
      });
    }

    if (improvementRate > 10) {
      insights.add({
        'icon': Icons.trending_up_rounded,
        'color': Colors.green,
        'title': 'Improving Trend',
        'description': 'Your mood has improved by ${improvementRate.toStringAsFixed(1)}%!',
      });
    } else if (improvementRate < -10) {
      insights.add({
        'icon': Icons.trending_down_rounded,
        'color': Colors.red,
        'title': 'Declining Trend',
        'description': 'Consider focusing on self-care activities.',
      });
    }

    if (insights.isEmpty) {
      insights.add({
        'icon': Icons.info_rounded,
        'color': Colors.blue,
        'title': 'Keep Tracking',
        'description': 'More insights will appear as you log more moods.',
      });
    }

    return GlassWidget(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...insights.take(3).map((insight) => _buildInsightItem(
              insight['icon'],
              insight['color'],
              insight['title'],
              insight['description'],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, Color color, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return GlassWidget(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Export Data',
                    Icons.download_rounded,
                    Colors.blue,
                    () => _exportData(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Share Progress',
                    Icons.share_rounded,
                    Colors.green,
                    () => _shareProgress(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab() {
    return const Center(
      child: Text(
        'Trends analysis coming soon!',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildPatternsTab() {
    return const Center(
      child: Text(
        'Pattern analysis coming soon!',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildWellnessTab() {
    return const Center(
      child: Text(
        'Wellness score coming soon!',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Color _getMoodColor(double mood) {
    if (mood >= 4.0) return Colors.green;
    if (mood >= 3.0) return Colors.blue;
    if (mood >= 2.0) return Colors.orange;
    return Colors.red;
  }

  Color _getStressColor(double stress) {
    if (stress <= 3.0) return Colors.green;
    if (stress <= 6.0) return Colors.orange;
    return Colors.red;
  }

  String _getStressDescription(double stress) {
    if (stress <= 3.0) return 'Low stress';
    if (stress <= 6.0) return 'Moderate stress';
    return 'High stress';
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareProgress() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Progress sharing feature coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../providers/mood_provider.dart';
import '../models/mood_entry.dart';
import '../utils/app_colors.dart';

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  String _timeRange = 'Week'; // 'Week', 'Month', 'Year'
  bool _isCalendarView = false;
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    // Load mood data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final moodProvider = Provider.of<MoodProvider>(context, listen: false);
      moodProvider.loadMoodHistory(days: _getDaysForRange(_timeRange));
    });
  }
  
  int _getDaysForRange(String range) {
    switch (range) {
      case 'Week':
        return 7;
      case 'Month':
        return 30;
      case 'Year':
        return 365;
      default:
        return 30;
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        ),
        title: const GlassWidget(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Mood History',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isCalendarView = !_isCalendarView;
              });
            },
            icon: Icon(
              _isCalendarView ? Icons.view_list_rounded : Icons.calendar_month_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: _isCalendarView ? 'List View' : 'Calendar View',
          ),
        ],
      ),
      body: Stack(
        children: [
          const AuraBackground(),
          
          SafeArea(
            child: Column(
              children: [
                // Time range selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimeRangeButton('Week'),
                      _buildTimeRangeButton('Month'),
                      _buildTimeRangeButton('Year'),
                    ],
                  ),
                ),
                
                // Main content
                Expanded(
                  child: _isCalendarView 
                      ? _buildCalendarView() 
                      : _buildListView(),
                ),
              ],
            ),
          ),
        ],
      ),
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
        moodProvider.loadMoodHistory(days: _getDaysForRange(range));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.accentTeal.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? AppColors.accentTeal
                : Colors.transparent,
          ),
        ),
        child: Text(
          range,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? AppColors.accentTeal : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildListView() {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        if (moodProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.accentTeal),
            ),
          );
        }
        
        if (moodProvider.moodEntries.isEmpty) {
          return const Center(
            child: Text(
              'No mood entries yet.\nStart tracking your mood!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          );
        }
        
        // Group entries by date
        final groupedEntries = <String, List<MoodEntry>>{};
        for (final entry in moodProvider.moodEntries) {
          if (!groupedEntries.containsKey(entry.date)) {
            groupedEntries[entry.date] = [];
          }
          groupedEntries[entry.date]!.add(entry);
        }
        
        // Sort dates in descending order
        final sortedDates = groupedEntries.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final entries = groupedEntries[date]!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ...entries.map((entry) => _buildMoodEntryCard(entry)),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }
  
  Widget _buildCalendarView() {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        if (moodProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.accentTeal),
            ),
          );
        }
        
        // Create a map of dates to mood entries for easy lookup
        final entriesByDate = <String, List<MoodEntry>>{};
        for (final entry in moodProvider.moodEntries) {
          if (!entriesByDate.containsKey(entry.date)) {
            entriesByDate[entry.date] = [];
          }
          entriesByDate[entry.date]!.add(entry);
        }
        
        return Column(
          children: [
            // Calendar header
            GlassWidget(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = DateTime(
                                _selectedDate.year,
                                _selectedDate.month - 1,
                                _selectedDate.day,
                              );
                            });
                          },
                          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = DateTime(
                                _selectedDate.year,
                                _selectedDate.month + 1,
                                _selectedDate.day,
                              );
                            });
                          },
                          icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Day labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        Text('S', style: TextStyle(color: AppColors.textSecondary)),
                        Text('M', style: TextStyle(color: AppColors.textSecondary)),
                        Text('T', style: TextStyle(color: AppColors.textSecondary)),
                        Text('W', style: TextStyle(color: AppColors.textSecondary)),
                        Text('T', style: TextStyle(color: AppColors.textSecondary)),
                        Text('F', style: TextStyle(color: AppColors.textSecondary)),
                        Text('S', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Calendar grid
                    _buildCalendarGrid(entriesByDate),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Selected day's entries
            Expanded(
              child: _buildSelectedDayEntries(entriesByDate),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildCalendarGrid(Map<String, List<MoodEntry>> entriesByDate) {
    // Get the first day of the month
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    
    // Get the last day of the month
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    
    // Get the weekday of the first day (0 = Sunday, 6 = Saturday)
    final firstWeekday = firstDay.weekday % 7;
    
    // Calculate the total number of days to display (including padding)
    final totalDays = firstWeekday + lastDay.day;
    
    // Calculate the number of weeks
    final weeks = (totalDays / 7).ceil();
    
    return Column(
      children: List.generate(weeks, (weekIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
              
              if (dayNumber < 1 || dayNumber > lastDay.day) {
                // Empty cell
                return const SizedBox(width: 36, height: 36);
              }
              
              final date = DateTime(_selectedDate.year, _selectedDate.month, dayNumber);
              final dateString = DateFormat('yyyy-MM-dd').format(date);
              final hasEntries = entriesByDate.containsKey(dateString);
              
              // Calculate average mood for the day
              double moodScore = 3.0; // Neutral default
              String emoji = '😐';
              
              if (hasEntries) {
                final entries = entriesByDate[dateString]!;
                final totalScore = entries.fold<double>(0, (sum, entry) => sum + entry.moodScore);
                moodScore = totalScore / entries.length;
                
                // Get emoji based on average mood
                if (moodScore >= 4.5) {
                  emoji = '😄';
                } else if (moodScore >= 3.5) {
                  emoji = '😊';
                } else if (moodScore >= 2.5) {
                  emoji = '😐';
                } else if (moodScore >= 1.5) {
                  emoji = '😔';
                } else {
                  emoji = '😣';
                }
              }
              
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.accentTeal.withValues(alpha: 0.3)
                        : (isToday ? AppColors.accentBlue.withValues(alpha: 0.2) : Colors.transparent),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentTeal
                          : (isToday ? AppColors.accentBlue : Colors.transparent),
                      width: isSelected || isToday ? 2 : 0,
                    ),
                  ),
                  child: Center(
                    child: hasEntries
                        ? Text(emoji, style: const TextStyle(fontSize: 16))
                        : Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              color: isSelected || isToday
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
  
  Widget _buildSelectedDayEntries(Map<String, List<MoodEntry>> entriesByDate) {
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final hasEntries = entriesByDate.containsKey(dateString);
    
    if (!hasEntries) {
      return Center(
        child: GlassWidget(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mood_rounded,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No mood entries for ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    final entries = entriesByDate[dateString]!;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return _buildMoodEntryCard(entries[index]);
      },
    );
  }
  
  Widget _buildMoodEntryCard(MoodEntry entry) {
    // Parse color from hex string if available
    Color moodColor;
    if (entry.additionalData != null && entry.additionalData!.containsKey('color')) {
      final colorHex = entry.additionalData!['color'] as String;
      moodColor = Color(int.parse('0xFF$colorHex'));
    } else {
      // Fallback to default color based on mood score
      if (entry.moodScore >= 4.5) {
        moodColor = AppColors.moodHappy;
      } else if (entry.moodScore >= 3.5) {
        moodColor = AppColors.moodCalm;
      } else if (entry.moodScore >= 2.5) {
        moodColor = AppColors.textSecondary;
      } else if (entry.moodScore >= 1.5) {
        moodColor = AppColors.moodSad;
      } else {
        moodColor = AppColors.moodStressed;
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassWidget(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji and time
              Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: moodColor.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Text(
                        entry.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(entry.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // Mood details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.mood,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    if (entry.note != null && entry.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.note!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    
                    // AI Analysis if available
                    if (entry.additionalData != null && 
                        entry.additionalData!.containsKey('aiAnalysis') &&
                        entry.additionalData!['aiAnalysis'] != null) ...[
                      const SizedBox(height: 8),
                      const Divider(color: AppColors.glassBorder),
                      const SizedBox(height: 4),
                      
                      // AI supportive message
                      if (entry.additionalData!['aiAnalysis']['supportiveMessage'] != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.psychology_rounded,
                              size: 16,
                              color: AppColors.accentTeal,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.additionalData!['aiAnalysis']['supportiveMessage'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d, yyyy').format(date);
    }
  }
  
  String _formatTime(DateTime timestamp) {
    return DateFormat('h:mm a').format(timestamp);
  }
}

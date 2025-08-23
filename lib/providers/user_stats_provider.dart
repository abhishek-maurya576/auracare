import 'package:flutter/foundation.dart';
import '../models/mood_entry.dart';

class UserStatsProvider extends ChangeNotifier {
  // Remove unused firebase service for now
  // final FirebaseService _firebaseService = FirebaseService();
  
  // User statistics
  Map<String, dynamic> _userStats = {};
  Map<String, dynamic> _wellnessScore = {};
  List<Map<String, dynamic>> _achievements = [];
  Map<String, dynamic> _streakData = {};
  Map<String, dynamic> _goalProgress = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic> get userStats => _userStats;
  Map<String, dynamic> get wellnessScore => _wellnessScore;
  List<Map<String, dynamic>> get achievements => _achievements;
  Map<String, dynamic> get streakData => _streakData;
  Map<String, dynamic> get goalProgress => _goalProgress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize user statistics
  Future<void> initializeStats(String userId, List<MoodEntry> moodEntries) async {
    _setLoading(true);
    
    try {
      await _calculateUserStats(moodEntries);
      await _calculateWellnessScore(moodEntries);
      await _calculateAchievements(moodEntries);
      await _calculateStreakData(moodEntries);
      await _calculateGoalProgress(moodEntries);
      
      _error = null;
    } catch (e) {
      _error = 'Failed to calculate user statistics: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Calculate comprehensive user statistics
  Future<void> _calculateUserStats(List<MoodEntry> moodEntries) async {
    if (moodEntries.isEmpty) {
      _userStats = {
        'totalEntries': 0,
        'averageMoodScore': 0.0,
        'averageStressLevel': 0.0,
        'mostCommonMood': 'No data',
        'bestTimeOfDay': 'Unknown',
        'totalDaysTracked': 0,
        'consistencyRate': 0.0,
        'improvementRate': 0.0,
      };
      return;
    }

    final totalEntries = moodEntries.length;
    final averageMoodScore = moodEntries.fold<double>(0, (sum, entry) => sum + entry.moodScore) / totalEntries;
    final averageStressLevel = moodEntries.fold<double>(0, (sum, entry) => sum + entry.calculatedStressLevel) / totalEntries;

    // Most common mood
    final moodCounts = <String, int>{};
    for (final entry in moodEntries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }
    final mostCommonMood = moodCounts.entries.isNotEmpty
        ? moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'No data';

    // Best time of day
    final timeDistribution = <String, List<double>>{};
    for (final entry in moodEntries) {
      final hour = entry.timestamp.hour;
      final timeOfDay = hour < 12 ? 'morning' : hour < 17 ? 'afternoon' : 'evening';
      timeDistribution.putIfAbsent(timeOfDay, () => []).add(entry.moodScore);
    }

    String bestTimeOfDay = 'Unknown';
    double bestAvgScore = 0.0;
    timeDistribution.forEach((time, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg > bestAvgScore) {
        bestAvgScore = avg;
        bestTimeOfDay = time;
      }
    });

    // Total days tracked
    final uniqueDates = moodEntries.map((e) => e.date).toSet();
    final totalDaysTracked = uniqueDates.length;

    // Consistency rate (days with entries / total days since first entry)
    final sortedEntries = List<MoodEntry>.from(moodEntries)
      ..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
    
    double consistencyRate = 0.0;
    if (sortedEntries.isNotEmpty) {
      final firstDate = DateTime.parse(sortedEntries.first.date);
      final lastDate = DateTime.parse(sortedEntries.last.date);
      final totalPossibleDays = lastDate.difference(firstDate).inDays + 1;
      consistencyRate = totalDaysTracked / totalPossibleDays;
    }

    // Improvement rate
    double improvementRate = 0.0;
    if (moodEntries.length >= 7) {
      final firstHalf = moodEntries.sublist(0, moodEntries.length ~/ 2);
      final secondHalf = moodEntries.sublist(moodEntries.length ~/ 2);
      
      final firstAvg = firstHalf.fold<double>(0, (sum, e) => sum + e.moodScore) / firstHalf.length;
      final secondAvg = secondHalf.fold<double>(0, (sum, e) => sum + e.moodScore) / secondHalf.length;
      
      improvementRate = ((secondAvg - firstAvg) / firstAvg) * 100;
    }

    _userStats = {
      'totalEntries': totalEntries,
      'averageMoodScore': averageMoodScore,
      'averageStressLevel': averageStressLevel,
      'mostCommonMood': mostCommonMood,
      'bestTimeOfDay': bestTimeOfDay,
      'totalDaysTracked': totalDaysTracked,
      'consistencyRate': consistencyRate,
      'improvementRate': improvementRate,
    };
  }

  // Calculate wellness score (0-100)
  Future<void> _calculateWellnessScore(List<MoodEntry> moodEntries) async {
    if (moodEntries.isEmpty) {
      _wellnessScore = {
        'overall': 0.0,
        'mood': 0.0,
        'stress': 0.0,
        'consistency': 0.0,
        'trend': 0.0,
        'description': 'No data available',
        'recommendations': [],
      };
      return;
    }

    // Mood component (0-25 points)
    final avgMood = _userStats['averageMoodScore'] as double;
    final moodScore = (avgMood / 5.0) * 25;

    // Stress component (0-25 points)
    final avgStress = _userStats['averageStressLevel'] as double;
    final stressScore = ((10 - avgStress) / 10.0) * 25;

    // Consistency component (0-25 points)
    final consistencyRate = _userStats['consistencyRate'] as double;
    final consistencyScore = consistencyRate * 25;

    // Trend component (0-25 points)
    final improvementRate = _userStats['improvementRate'] as double;
    final trendScore = improvementRate > 0 
        ? (improvementRate / 50.0).clamp(0.0, 1.0) * 25
        : 0.0;

    final overallScore = (moodScore + stressScore + consistencyScore + trendScore).clamp(0.0, 100.0);

    // Generate description and recommendations
    String description;
    List<String> recommendations = [];

    if (overallScore >= 80) {
      description = 'Excellent wellness! You\'re doing great.';
      recommendations.add('Keep up your current routine');
      recommendations.add('Consider helping others on their wellness journey');
    } else if (overallScore >= 60) {
      description = 'Good wellness. You\'re on the right track.';
      recommendations.add('Try to maintain consistency in mood tracking');
      recommendations.add('Consider adding meditation to your routine');
    } else if (overallScore >= 40) {
      description = 'Fair wellness. There\'s room for improvement.';
      recommendations.add('Focus on stress management techniques');
      recommendations.add('Try to identify and avoid mood triggers');
      recommendations.add('Consider talking to a mental health professional');
    } else {
      description = 'Wellness needs attention. Consider seeking support.';
      recommendations.add('Reach out to a mental health professional');
      recommendations.add('Use the app\'s breathing exercises daily');
      recommendations.add('Connect with supportive friends or family');
      recommendations.add('Consider joining a support group');
    }

    _wellnessScore = {
      'overall': overallScore,
      'mood': moodScore,
      'stress': stressScore,
      'consistency': consistencyScore,
      'trend': trendScore,
      'description': description,
      'recommendations': recommendations,
    };
  }

  // Calculate achievements and badges
  Future<void> _calculateAchievements(List<MoodEntry> moodEntries) async {
    final totalEntries = moodEntries.length;
    final longestStreak = _calculateLongestStreak(moodEntries);
    final avgMood = moodEntries.isNotEmpty 
        ? moodEntries.fold<double>(0, (sum, e) => sum + e.moodScore) / totalEntries
        : 0.0;

    _achievements = [
      {
        'id': 'first_entry',
        'title': 'First Step',
        'description': 'Logged your first mood entry',
        'icon': 'star',
        'color': 'yellow',
        'earned': totalEntries >= 1,
        'progress': totalEntries >= 1 ? 1.0 : 0.0,
        'category': 'milestone',
      },
      {
        'id': 'week_warrior',
        'title': 'Week Warrior',
        'description': 'Maintained a 7-day streak',
        'icon': 'calendar_week',
        'color': 'blue',
        'earned': longestStreak >= 7,
        'progress': (longestStreak / 7.0).clamp(0.0, 1.0),
        'category': 'streak',
      },
      {
        'id': 'consistency_king',
        'title': 'Consistency King',
        'description': 'Maintained a 30-day streak',
        'icon': 'fire',
        'color': 'orange',
        'earned': longestStreak >= 30,
        'progress': (longestStreak / 30.0).clamp(0.0, 1.0),
        'category': 'streak',
      },
      {
        'id': 'mood_master',
        'title': 'Mood Master',
        'description': 'Logged 50 mood entries',
        'icon': 'psychology',
        'color': 'purple',
        'earned': totalEntries >= 50,
        'progress': (totalEntries / 50.0).clamp(0.0, 1.0),
        'category': 'milestone',
      },
      {
        'id': 'wellness_warrior',
        'title': 'Wellness Warrior',
        'description': 'Logged 100 mood entries',
        'icon': 'fitness_center',
        'color': 'green',
        'earned': totalEntries >= 100,
        'progress': (totalEntries / 100.0).clamp(0.0, 1.0),
        'category': 'milestone',
      },
      {
        'id': 'positive_vibes',
        'title': 'Positive Vibes',
        'description': 'Maintained average mood above 4.0',
        'icon': 'sentiment_very_satisfied',
        'color': 'green',
        'earned': avgMood >= 4.0,
        'progress': (avgMood / 5.0).clamp(0.0, 1.0),
        'category': 'mood',
      },
      {
        'id': 'streak_legend',
        'title': 'Streak Legend',
        'description': 'Maintained a 100-day streak',
        'icon': 'emoji_events',
        'color': 'gold',
        'earned': longestStreak >= 100,
        'progress': (longestStreak / 100.0).clamp(0.0, 1.0),
        'category': 'streak',
      },
      {
        'id': 'early_bird',
        'title': 'Early Bird',
        'description': 'Logged 10 morning mood entries',
        'icon': 'wb_sunny',
        'color': 'yellow',
        'earned': _countMorningEntries(moodEntries) >= 10,
        'progress': (_countMorningEntries(moodEntries) / 10.0).clamp(0.0, 1.0),
        'category': 'habit',
      },
      {
        'id': 'night_owl',
        'title': 'Night Owl',
        'description': 'Logged 10 evening mood entries',
        'icon': 'nights_stay',
        'color': 'indigo',
        'earned': _countEveningEntries(moodEntries) >= 10,
        'progress': (_countEveningEntries(moodEntries) / 10.0).clamp(0.0, 1.0),
        'category': 'habit',
      },
      {
        'id': 'self_aware',
        'title': 'Self Aware',
        'description': 'Added notes to 25 mood entries',
        'icon': 'psychology',
        'color': 'teal',
        'earned': _countEntriesWithNotes(moodEntries) >= 25,
        'progress': (_countEntriesWithNotes(moodEntries) / 25.0).clamp(0.0, 1.0),
        'category': 'insight',
      },
    ];
  }

  // Calculate streak data
  Future<void> _calculateStreakData(List<MoodEntry> moodEntries) async {
    final currentStreak = _calculateCurrentStreak(moodEntries);
    final longestStreak = _calculateLongestStreak(moodEntries);
    final streakHistory = _calculateStreakHistory(moodEntries);

    _streakData = {
      'current': currentStreak,
      'longest': longestStreak,
      'history': streakHistory,
      'isOnStreak': currentStreak > 0,
      'daysUntilNextMilestone': _getDaysUntilNextMilestone(currentStreak),
      'nextMilestone': _getNextMilestone(currentStreak),
    };
  }

  // Calculate goal progress
  Future<void> _calculateGoalProgress(List<MoodEntry> moodEntries) async {
    final totalEntries = moodEntries.length;
    final currentStreak = _calculateCurrentStreak(moodEntries);
    final avgMood = moodEntries.isNotEmpty 
        ? moodEntries.fold<double>(0, (sum, e) => sum + e.moodScore) / totalEntries
        : 0.0;

    _goalProgress = {
      'daily_tracking': {
        'title': 'Daily Mood Tracking',
        'description': 'Track your mood every day',
        'current': currentStreak,
        'target': 7,
        'progress': (currentStreak / 7.0).clamp(0.0, 1.0),
        'completed': currentStreak >= 7,
        'type': 'streak',
      },
      'consistency_goal': {
        'title': 'Consistency Champion',
        'description': 'Maintain a 30-day streak',
        'current': currentStreak,
        'target': 30,
        'progress': (currentStreak / 30.0).clamp(0.0, 1.0),
        'completed': currentStreak >= 30,
        'type': 'streak',
      },
      'entry_milestone': {
        'title': 'Mood Explorer',
        'description': 'Log 50 mood entries',
        'current': totalEntries,
        'target': 50,
        'progress': (totalEntries / 50.0).clamp(0.0, 1.0),
        'completed': totalEntries >= 50,
        'type': 'count',
      },
      'wellness_goal': {
        'title': 'Positive Mindset',
        'description': 'Maintain average mood above 4.0',
        'current': avgMood,
        'target': 4.0,
        'progress': (avgMood / 4.0).clamp(0.0, 1.0),
        'completed': avgMood >= 4.0,
        'type': 'average',
      },
    };
  }

  // Helper methods
  int _calculateCurrentStreak(List<MoodEntry> moodEntries) {
    if (moodEntries.isEmpty) return 0;

    final sortedEntries = List<MoodEntry>.from(moodEntries)
      ..sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

    int streak = 0;
    DateTime? lastDate;

    for (final entry in sortedEntries) {
      final entryDate = DateTime.parse(entry.date);
      
      if (lastDate == null) {
        // Check if the most recent entry is today or yesterday
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        
        if (entryDate.year == today.year && entryDate.month == today.month && entryDate.day == today.day) {
          streak = 1;
          lastDate = entryDate;
        } else if (entryDate.year == yesterday.year && entryDate.month == yesterday.month && entryDate.day == yesterday.day) {
          streak = 1;
          lastDate = entryDate;
        } else {
          break; // No recent entry, streak is 0
        }
      } else {
        final expectedDate = lastDate.subtract(const Duration(days: 1));
        if (entryDate.year == expectedDate.year && 
            entryDate.month == expectedDate.month && 
            entryDate.day == expectedDate.day) {
          streak++;
          lastDate = entryDate;
        } else {
          break; // Gap in streak
        }
      }
    }

    return streak;
  }

  int _calculateLongestStreak(List<MoodEntry> moodEntries) {
    if (moodEntries.isEmpty) return 0;

    final sortedEntries = List<MoodEntry>.from(moodEntries)
      ..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

    int longestStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;

    for (final entry in sortedEntries) {
      final entryDate = DateTime.parse(entry.date);
      
      if (lastDate == null) {
        currentStreak = 1;
        longestStreak = 1;
      } else {
        final difference = entryDate.difference(lastDate).inDays;
        if (difference == 1) {
          currentStreak++;
          longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;
        } else if (difference > 1) {
          currentStreak = 1;
        }
      }
      lastDate = entryDate;
    }

    return longestStreak;
  }

  List<Map<String, dynamic>> _calculateStreakHistory(List<MoodEntry> moodEntries) {
    // This would calculate historical streak data for visualization
    // For now, return empty list - can be implemented later for advanced analytics
    return [];
  }

  int _getDaysUntilNextMilestone(int currentStreak) {
    final milestones = [7, 14, 30, 60, 100, 365];
    for (final milestone in milestones) {
      if (currentStreak < milestone) {
        return milestone - currentStreak;
      }
    }
    return 0; // Already at highest milestone
  }

  int _getNextMilestone(int currentStreak) {
    final milestones = [7, 14, 30, 60, 100, 365];
    for (final milestone in milestones) {
      if (currentStreak < milestone) {
        return milestone;
      }
    }
    return 365; // Highest milestone
  }

  int _countMorningEntries(List<MoodEntry> moodEntries) {
    return moodEntries.where((entry) => entry.timestamp.hour < 12).length;
  }

  int _countEveningEntries(List<MoodEntry> moodEntries) {
    return moodEntries.where((entry) => entry.timestamp.hour >= 18).length;
  }

  int _countEntriesWithNotes(List<MoodEntry> moodEntries) {
    return moodEntries.where((entry) => entry.note != null && entry.note!.isNotEmpty).length;
  }

  // Get achievements by category
  List<Map<String, dynamic>> getAchievementsByCategory(String category) {
    return _achievements.where((achievement) => achievement['category'] == category).toList();
  }

  // Get earned achievements
  List<Map<String, dynamic>> getEarnedAchievements() {
    return _achievements.where((achievement) => achievement['earned'] == true).toList();
  }

  // Get progress towards next achievement
  Map<String, dynamic>? getNextAchievement() {
    final unearned = _achievements.where((achievement) => achievement['earned'] == false).toList();
    if (unearned.isEmpty) return null;
    
    // Sort by progress (closest to completion first)
    unearned.sort((a, b) => (b['progress'] as double).compareTo(a['progress'] as double));
    return unearned.first;
  }

  // Export user statistics
  Map<String, dynamic> exportStats() {
    return {
      'userStats': _userStats,
      'wellnessScore': _wellnessScore,
      'achievements': _achievements,
      'streakData': _streakData,
      'goalProgress': _goalProgress,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

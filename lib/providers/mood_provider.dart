import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';
import '../services/firebase_service.dart';
import '../services/user_profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MoodProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final UserProfileService _profileService = UserProfileService();
  
  List<MoodEntry> _moodEntries = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<MoodEntry> get moodEntries => _moodEntries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get the most recent mood entry
  MoodEntry? get latestMood => _moodEntries.isNotEmpty ? _moodEntries.first : null;
  
  // Initialize and load mood data
  Future<void> loadMoodHistory({int days = 30}) async {
    _setLoading(true);
    
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final moodData = await _firebaseService.getMoodHistory(
        startDate: startDate,
        endDate: endDate,
        limit: 100,
      );
      
      _moodEntries = moodData.map((data) => MoodEntry.fromJson(data)).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load mood history: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }
  
  // Save a new mood entry with enhanced features
  Future<void> saveMoodEntry({
    required String mood,
    required String emoji,
    String? note,
    int intensity = 5,
    List<String> triggers = const [],
    List<String> tags = const [],
    String? aiAnalysis,
    Map<String, dynamic>? aiInsights,
    double? stressLevel,
    String? location,
    Map<String, dynamic>? additionalData,
  }) async {
    _setLoading(true);

    try {
      await _firebaseService.saveMoodData(
        mood: mood,
        emoji: emoji,
        note: note,
        intensity: intensity,
        triggers: triggers,
        tags: tags,
        aiAnalysis: aiAnalysis,
        aiInsights: aiInsights,
        stressLevel: stressLevel,
        location: location,
        additionalData: additionalData,
      );
      
      // Reload mood history to include the new entry
      await loadMoodHistory();
      
      // Update user profile with new mood patterns for personalization
      await _updateUserMoodPatterns();
      
      _error = null;
    } catch (e) {
      _error = 'Failed to save mood entry: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }
  
  // Get mood entries for a specific date
  List<MoodEntry> getMoodEntriesForDate(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return _moodEntries.where((entry) => entry.date == dateString).toList();
  }
  
  // Get mood entries for the current week
  List<MoodEntry> getWeeklyMoodEntries() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return _moodEntries.where((entry) {
      final entryDate = DateTime.parse(entry.date);
      return entryDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
             entryDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }
  
  // Get average mood score for the week
  double getWeeklyAverageMoodScore() {
    final weeklyEntries = getWeeklyMoodEntries();
    if (weeklyEntries.isEmpty) return 3.0; // Neutral default
    
    final sum = weeklyEntries.fold<double>(
      0, (sum, entry) => sum + entry.moodScore);
    return sum / weeklyEntries.length;
  }
  
  // Get mood trend (improving, declining, stable)
  String getMoodTrend() {
    if (_moodEntries.length < 3) return 'Not enough data';
    
    // Compare recent mood scores
    final recentScores = _moodEntries.take(3).map((e) => e.moodScore).toList();
    final average = recentScores.reduce((a, b) => a + b) / recentScores.length;
    
    // Compare with previous period
    final previousEntries = _moodEntries.skip(3).take(3).toList();
    if (previousEntries.isEmpty) return 'Stable';
    
    final previousScores = previousEntries.map((e) => e.moodScore).toList();
    final previousAverage = previousScores.reduce((a, b) => a + b) / previousScores.length;
    
    final difference = average - previousAverage;
    if (difference > 0.5) return 'Improving';
    if (difference < -0.5) return 'Declining';
    return 'Stable';
  }
  
  // Get data for mood graph
  List<Map<String, dynamic>> getMoodGraphData() {
    // Group entries by date and calculate average mood score per day
    final Map<String, List<MoodEntry>> entriesByDate = {};
    
    for (final entry in _moodEntries) {
      if (!entriesByDate.containsKey(entry.date)) {
        entriesByDate[entry.date] = [];
      }
      entriesByDate[entry.date]!.add(entry);
    }
    
    // Calculate average mood score for each day
    final List<Map<String, dynamic>> graphData = [];
    
    entriesByDate.forEach((date, entries) {
      final totalScore = entries.fold<double>(0, (sum, entry) => sum + entry.moodScore);
      final averageScore = totalScore / entries.length;
      final totalIntensity = entries.fold<int>(0, (sum, entry) => sum + entry.intensity);
      final averageIntensity = totalIntensity / entries.length;
      final averageStress = entries.fold<double>(0, (sum, entry) => sum + entry.calculatedStressLevel) / entries.length;
      
      graphData.add({
        'date': date,
        'score': averageScore,
        'intensity': averageIntensity,
        'stress': averageStress,
        'entries': entries.length,
      });
    });
    
    // Sort by date
    graphData.sort((a, b) => a['date'].compareTo(b['date']));
    
    return graphData;
  }

  // Get stress level analysis
  Map<String, dynamic> getStressAnalysis() {
    if (_moodEntries.isEmpty) {
      return {
        'averageStress': 0.0,
        'crisisCount': 0,
        'trend': 'stable',
        'recommendations': [],
      };
    }

    final stressLevels = _moodEntries.map((e) => e.calculatedStressLevel).toList();
    final averageStress = stressLevels.reduce((a, b) => a + b) / stressLevels.length;
    final crisisCount = _moodEntries.where((e) => e.isCrisisLevel).length;
    
    // Determine stress trend
    String trend = 'stable';
    if (_moodEntries.length >= 3) {
      final recent = _moodEntries.take(3).map((e) => e.calculatedStressLevel).toList();
      final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
      final previous = _moodEntries.skip(3).take(3).map((e) => e.calculatedStressLevel).toList();
      
      if (previous.isNotEmpty) {
        final previousAvg = previous.reduce((a, b) => a + b) / previous.length;
        if (recentAvg > previousAvg + 1) {
          trend = 'increasing';
        } else if (recentAvg < previousAvg - 1) {
          trend = 'decreasing';
        }
      }
    }

    // Generate recommendations based on stress level
    final recommendations = <String>[];
    if (averageStress >= 7) {
      recommendations.add('Consider reaching out to a mental health professional');
      recommendations.add('Try the breathing exercises in the app');
      recommendations.add('Connect with the community for support');
    } else if (averageStress >= 5) {
      recommendations.add('Practice daily mindfulness meditation');
      recommendations.add('Take regular breaks throughout the day');
      recommendations.add('Consider journaling your thoughts');
    }

    return {
      'averageStress': averageStress,
      'crisisCount': crisisCount,
      'trend': trend,
      'recommendations': recommendations,
    };
  }

  // Get mood pattern analysis
  Map<String, dynamic> getMoodPatternAnalysis() {
    if (_moodEntries.isEmpty) {
      return {
        'mostCommonMood': 'No data',
        'moodDistribution': {},
        'bestTimeOfDay': 'Unknown',
        'commonTriggers': [],
        'improvementRate': 0.0,
      };
    }

    // Mood distribution
    final moodCounts = <String, int>{};
    final timeDistribution = <String, List<double>>{};
    final triggerCounts = <String, int>{};

    for (final entry in _moodEntries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
      
      // Time of day analysis
      final hour = entry.timestamp.hour;
      final timeOfDay = hour < 12 ? 'morning' : hour < 17 ? 'afternoon' : 'evening';
      timeDistribution.putIfAbsent(timeOfDay, () => []).add(entry.moodScore);
      
      // Trigger analysis
      for (final trigger in entry.triggers) {
        triggerCounts[trigger] = (triggerCounts[trigger] ?? 0) + 1;
      }
    }

    // Find best time of day
    String bestTime = 'Unknown';
    double bestAvgScore = 0.0;
    timeDistribution.forEach((time, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg > bestAvgScore) {
        bestAvgScore = avg;
        bestTime = time;
      }
    });

    // Calculate improvement rate
    double improvementRate = 0.0;
    if (_moodEntries.length >= 7) {
      final firstHalf = _moodEntries.sublist(0, _moodEntries.length ~/ 2);
      final secondHalf = _moodEntries.sublist(_moodEntries.length ~/ 2);
      
      final firstAvg = firstHalf.fold<double>(0, (sum, e) => sum + e.moodScore) / firstHalf.length;
      final secondAvg = secondHalf.fold<double>(0, (sum, e) => sum + e.moodScore) / secondHalf.length;
      
      improvementRate = ((secondAvg - firstAvg) / firstAvg) * 100;
    }

    return {
      'mostCommonMood': moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key,
      'moodDistribution': moodCounts,
      'bestTimeOfDay': bestTime,
      'commonTriggers': triggerCounts.entries.take(3).map((e) => e.key).toList(),
      'improvementRate': improvementRate,
    };
  }

  // Get crisis detection alerts
  List<MoodEntry> getCrisisAlerts() {
    return _moodEntries.where((entry) => entry.isCrisisLevel).toList();
  }

  // Get filtered mood entries
  List<MoodEntry> getFilteredEntries({
    String? mood,
    List<String>? triggers,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
    double? minStressLevel,
    double? maxStressLevel,
  }) {
    return _moodEntries.where((entry) {
      if (mood != null && entry.mood != mood) return false;
      if (triggers != null && !triggers.any((t) => entry.triggers.contains(t))) return false;
      if (tags != null && !tags.any((t) => entry.tags.contains(t))) return false;
      
      if (startDate != null) {
        final entryDate = DateTime.parse(entry.date);
        if (entryDate.isBefore(startDate)) return false;
      }
      
      if (endDate != null) {
        final entryDate = DateTime.parse(entry.date);
        if (entryDate.isAfter(endDate)) return false;
      }
      
      if (minStressLevel != null && entry.calculatedStressLevel < minStressLevel) return false;
      if (maxStressLevel != null && entry.calculatedStressLevel > maxStressLevel) return false;
      
      return true;
    }).toList();
  }

  // Get mood statistics summary
  Map<String, dynamic> getMoodStatistics() {
    if (_moodEntries.isEmpty) {
      return {
        'totalEntries': 0,
        'averageMoodScore': 0.0,
        'averageIntensity': 0.0,
        'averageStress': 0.0,
        'streakDays': 0,
        'longestStreak': 0,
      };
    }

    final totalEntries = _moodEntries.length;
    final averageMoodScore = _moodEntries.fold<double>(0, (sum, e) => sum + e.moodScore) / totalEntries;
    final averageIntensity = _moodEntries.fold<int>(0, (sum, e) => sum + e.intensity) / totalEntries;
    final averageStress = _moodEntries.fold<double>(0, (sum, e) => sum + e.calculatedStressLevel) / totalEntries;

    // Calculate streak
    int currentStreak = 0;
    int longestStreak = 0;
    DateTime? lastDate;
    
    final sortedEntries = List<MoodEntry>.from(_moodEntries)
      ..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

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

    return {
      'totalEntries': totalEntries,
      'averageMoodScore': averageMoodScore,
      'averageIntensity': averageIntensity,
      'averageStress': averageStress,
      'streakDays': currentStreak,
      'longestStreak': longestStreak,
    };
  }
  
  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Update user profile with mood patterns for personalized AI responses
  Future<void> _updateUserMoodPatterns() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _moodEntries.isNotEmpty) {
        await _profileService.updateMoodPatterns(user.uid, _moodEntries);
        debugPrint('User mood patterns updated for personalization');
      }
    } catch (e) {
      debugPrint('Error updating user mood patterns: $e');
      // Don't throw error as this shouldn't prevent mood saving
    }
  }
}

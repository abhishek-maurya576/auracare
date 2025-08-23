import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String id;
  final String mood;
  final String emoji;
  final String? note;
  final DateTime timestamp;
  final String date; // YYYY-MM-DD format
  final int intensity; // 1-10 scale
  final List<String> triggers;
  final List<String> tags;
  final String? aiAnalysis;
  final Map<String, dynamic>? aiInsights;
  final double? stressLevel; // 0-10 scale
  final String? location;
  final Map<String, dynamic>? additionalData;

  MoodEntry({
    required this.id,
    required this.mood,
    required this.emoji,
    this.note,
    required this.timestamp,
    required this.date,
    this.intensity = 5,
    this.triggers = const [],
    this.tags = const [],
    this.aiAnalysis,
    this.aiInsights,
    this.stressLevel,
    this.location,
    this.additionalData,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String? ?? '',
      mood: json['mood'] as String,
      emoji: json['emoji'] as String,
      note: json['note'] as String?,
      timestamp: json['timestamp'] != null 
          ? (json['timestamp'] is String 
              ? DateTime.parse(json['timestamp'] as String)
              : (json['timestamp'] as Timestamp).toDate())
          : DateTime.now(),
      date: json['date'] as String,
      intensity: json['intensity'] as int? ?? 5,
      triggers: List<String>.from(json['triggers'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      aiAnalysis: json['aiAnalysis'] as String?,
      aiInsights: json['aiInsights'] as Map<String, dynamic>?,
      stressLevel: json['stressLevel'] != null 
          ? (json['stressLevel'] as num).toDouble() 
          : null,
      location: json['location'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood': mood,
      'emoji': emoji,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
      'date': date,
      'intensity': intensity,
      'triggers': triggers,
      'tags': tags,
      'aiAnalysis': aiAnalysis,
      'aiInsights': aiInsights,
      'stressLevel': stressLevel,
      'location': location,
      'additionalData': additionalData,
    };
  }

  MoodEntry copyWith({
    String? id,
    String? mood,
    String? emoji,
    String? note,
    DateTime? timestamp,
    String? date,
    int? intensity,
    List<String>? triggers,
    List<String>? tags,
    String? aiAnalysis,
    Map<String, dynamic>? aiInsights,
    double? stressLevel,
    String? location,
    Map<String, dynamic>? additionalData,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      mood: mood ?? this.mood,
      emoji: emoji ?? this.emoji,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
      date: date ?? this.date,
      intensity: intensity ?? this.intensity,
      triggers: triggers ?? this.triggers,
      tags: tags ?? this.tags,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      aiInsights: aiInsights ?? this.aiInsights,
      stressLevel: stressLevel ?? this.stressLevel,
      location: location ?? this.location,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Helper methods
  double get moodScore {
    switch (mood.toLowerCase()) {
      case 'very happy':
      case 'happy':
        return 5.0;
      case 'good':
      case 'calm':
        return 4.0;
      case 'neutral':
        return 3.0;
      case 'low':
      case 'sad':
        return 2.0;
      case 'very low':
      case 'stressed':
        return 1.0;
      default:
        return 3.0;
    }
  }

  // Get stress level based on mood and intensity
  double get calculatedStressLevel {
    if (stressLevel != null) return stressLevel!;
    
    // Calculate stress based on mood and intensity
    double baseStress = 6.0 - moodScore; // Higher mood score = lower stress
    double intensityFactor = (intensity - 5).abs() / 5.0; // 0-1 scale
    
    return (baseStress + intensityFactor * 2.0).clamp(0.0, 10.0);
  }

  // Check if stress level indicates crisis
  bool get isCrisisLevel => calculatedStressLevel >= 7.0;

  // Get mood category for analysis
  String get moodCategory {
    final score = moodScore;
    if (score >= 4.5) return 'positive';
    if (score >= 3.5) return 'neutral';
    if (score >= 2.5) return 'low';
    return 'critical';
  }

  // Get common triggers as predefined list
  static List<String> get commonTriggers => [
    'work_stress',
    'relationship_issues',
    'health_concerns',
    'financial_worries',
    'sleep_problems',
    'social_anxiety',
    'family_conflicts',
    'academic_pressure',
    'loneliness',
    'weather_changes',
  ];

  // Get mood tags for filtering
  static List<String> get moodTags => [
    'morning',
    'afternoon',
    'evening',
    'night',
    'work',
    'home',
    'social',
    'alone',
    'exercise',
    'medication',
    'therapy',
    'weekend',
    'weekday',
  ];

  String get moodColor {
    switch (mood.toLowerCase()) {
      case 'very happy':
      case 'happy':
        return '#FFD66E'; // Happy yellow
      case 'good':
      case 'calm':
        return '#7EE7D1'; // Calm teal
      case 'neutral':
        return '#FFFFFF'; // Neutral white
      case 'low':
      case 'sad':
        return '#8B5CF6'; // Sad purple
      case 'very low':
      case 'stressed':
        return '#6366F1'; // Stressed indigo
      default:
        return '#FFFFFF';
    }
  }
}

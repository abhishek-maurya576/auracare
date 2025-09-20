
/// Enhanced user profile model for personalized AI interactions

import 'package:flutter/foundation.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final int? age;
  final DateTime? birthDate; // Birth date for age calculation and COPPA compliance
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  
  // Personalization data for AI
  final Map<String, dynamic>? preferences;
  final List<String>? interests;
  final List<String>? mentalHealthGoals;
  final List<String>? mentalHealthChallenges; // For crisis intervention
  final List<String>? preferredCopingStrategies;
  final List<String>? copingStrategies; // Alias for compatibility
  final String? communicationStyle; // 'supportive', 'direct', 'gentle', 'motivational'
  final List<String>? triggers; // Known stress/anxiety triggers
  final List<String>? strengths; // Personal strengths to reinforce
  final String? personalityType; // MBTI, Big Five, etc.
  final Map<String, dynamic>? therapyHistory; // Previous therapy experience
  final List<String>? supportNetwork; // Family, friends, professionals
  final String? timezone;
  final String? language;
  
  // Mood and wellness patterns
  final Map<String, dynamic>? moodPatterns;
  final Map<String, dynamic>? stressPatterns;
  final List<String>? successfulInterventions; // What has worked before
  final Map<String, dynamic>? crisisProtocol; // Emergency contacts and procedures
  
  // AI interaction preferences
  final bool enablePersonalization;
  final bool shareEmotionalState;
  final bool allowMoodTracking;
  final bool enableProactiveSupport;
  final int conversationDepth; // 1-5 scale for how deep conversations should go
  final List<String>? topicsToAvoid;
  final List<String>? preferredTopics;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.birthDate,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.preferences,
    this.interests,
    this.mentalHealthGoals,
    this.mentalHealthChallenges,
    this.preferredCopingStrategies,
    this.copingStrategies,
    this.communicationStyle,
    this.triggers,
    this.strengths,
    this.personalityType,
    this.therapyHistory,
    this.supportNetwork,
    this.timezone,
    this.language,
    this.moodPatterns,
    this.stressPatterns,
    this.successfulInterventions,
    this.crisisProtocol,
    this.enablePersonalization = true,
    this.shareEmotionalState = true,
    this.allowMoodTracking = true,
    this.enableProactiveSupport = false,
    this.conversationDepth = 3,
    this.topicsToAvoid,
    this.preferredTopics,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      age: json['age'] as int?,
      birthDate: json['birthDate'] != null 
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      preferences: json['preferences'] as Map<String, dynamic>?,
      interests: _safeListFromJson(json['interests']),
      mentalHealthGoals: _safeListFromJson(json['mentalHealthGoals']),
      mentalHealthChallenges: _safeListFromJson(json['mentalHealthChallenges']),
      preferredCopingStrategies: _safeListFromJson(json['preferredCopingStrategies']),
      copingStrategies: _safeListFromJson(json['copingStrategies']),
      communicationStyle: json['communicationStyle'] as String?,
      triggers: _safeListFromJson(json['triggers']),
      strengths: _safeListFromJson(json['strengths']),
      personalityType: json['personalityType'] as String?,
      therapyHistory: json['therapyHistory'] as Map<String, dynamic>?,
      supportNetwork: _safeListFromJson(json['supportNetwork']),
      timezone: json['timezone'] as String?,
      language: json['language'] as String?,
      moodPatterns: json['moodPatterns'] as Map<String, dynamic>?,
      stressPatterns: json['stressPatterns'] as Map<String, dynamic>?,
      successfulInterventions: _safeListFromJson(json['successfulInterventions']),
      crisisProtocol: json['crisisProtocol'] as Map<String, dynamic>?,
      enablePersonalization: json['enablePersonalization'] as bool? ?? true,
      shareEmotionalState: json['shareEmotionalState'] as bool? ?? true,
      allowMoodTracking: json['allowMoodTracking'] as bool? ?? true,
      enableProactiveSupport: json['enableProactiveSupport'] as bool? ?? false,
      conversationDepth: json['conversationDepth'] as int? ?? 3,
      topicsToAvoid: _safeListFromJson(json['topicsToAvoid']),
      preferredTopics: _safeListFromJson(json['preferredTopics']),
    );
  }

  /// Safely convert JSON list to List<String> with type validation
  static List<String>? _safeListFromJson(dynamic jsonList) {
    if (jsonList == null) return null;
    if (jsonList is! List) return null;
    
    try {
      return jsonList
          .where((item) => item is String)
          .cast<String>()
          .toList();
    } catch (e) {
      debugPrint('Warning: Failed to parse list from JSON: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'birthDate': birthDate?.toIso8601String(),
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'preferences': preferences,
      'interests': interests,
      'mentalHealthGoals': mentalHealthGoals,
      'mentalHealthChallenges': mentalHealthChallenges,
      'preferredCopingStrategies': preferredCopingStrategies,
      'copingStrategies': copingStrategies,
      'communicationStyle': communicationStyle,
      'triggers': triggers,
      'strengths': strengths,
      'personalityType': personalityType,
      'therapyHistory': therapyHistory,
      'supportNetwork': supportNetwork,
      'timezone': timezone,
      'language': language,
      'moodPatterns': moodPatterns,
      'stressPatterns': stressPatterns,
      'successfulInterventions': successfulInterventions,
      'crisisProtocol': crisisProtocol,
      'enablePersonalization': enablePersonalization,
      'shareEmotionalState': shareEmotionalState,
      'allowMoodTracking': allowMoodTracking,
      'enableProactiveSupport': enableProactiveSupport,
      'conversationDepth': conversationDepth,
      'topicsToAvoid': topicsToAvoid,
      'preferredTopics': preferredTopics,
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    DateTime? birthDate,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    List<String>? interests,
    List<String>? mentalHealthGoals,
    List<String>? mentalHealthChallenges,
    List<String>? preferredCopingStrategies,
    List<String>? copingStrategies,
    String? communicationStyle,
    List<String>? triggers,
    List<String>? strengths,
    String? personalityType,
    Map<String, dynamic>? therapyHistory,
    List<String>? supportNetwork,
    String? timezone,
    String? language,
    Map<String, dynamic>? moodPatterns,
    Map<String, dynamic>? stressPatterns,
    List<String>? successfulInterventions,
    Map<String, dynamic>? crisisProtocol,
    bool? enablePersonalization,
    bool? shareEmotionalState,
    bool? allowMoodTracking,
    bool? enableProactiveSupport,
    int? conversationDepth,
    List<String>? topicsToAvoid,
    List<String>? preferredTopics,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      birthDate: birthDate ?? this.birthDate,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      interests: interests ?? this.interests,
      mentalHealthGoals: mentalHealthGoals ?? this.mentalHealthGoals,
      mentalHealthChallenges: mentalHealthChallenges ?? this.mentalHealthChallenges,
      preferredCopingStrategies: preferredCopingStrategies ?? this.preferredCopingStrategies,
      copingStrategies: copingStrategies ?? this.copingStrategies,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      triggers: triggers ?? this.triggers,
      strengths: strengths ?? this.strengths,
      personalityType: personalityType ?? this.personalityType,
      therapyHistory: therapyHistory ?? this.therapyHistory,
      supportNetwork: supportNetwork ?? this.supportNetwork,
      timezone: timezone ?? this.timezone,
      language: language ?? this.language,
      moodPatterns: moodPatterns ?? this.moodPatterns,
      stressPatterns: stressPatterns ?? this.stressPatterns,
      successfulInterventions: successfulInterventions ?? this.successfulInterventions,
      crisisProtocol: crisisProtocol ?? this.crisisProtocol,
      enablePersonalization: enablePersonalization ?? this.enablePersonalization,
      shareEmotionalState: shareEmotionalState ?? this.shareEmotionalState,
      allowMoodTracking: allowMoodTracking ?? this.allowMoodTracking,
      enableProactiveSupport: enableProactiveSupport ?? this.enableProactiveSupport,
      conversationDepth: conversationDepth ?? this.conversationDepth,
      topicsToAvoid: topicsToAvoid ?? this.topicsToAvoid,
      preferredTopics: preferredTopics ?? this.preferredTopics,
    );
  }

  /// Generate a personalization context string for AI prompts
  String generatePersonalizationContext() {
    if (!enablePersonalization) return '';

    final context = StringBuffer();
    context.writeln('USER PROFILE CONTEXT (Use this to personalize responses):');
    
    // Basic info
    context.writeln('- Name: $name');
    if (age != null) context.writeln('- Age: $age');
    
    // Communication preferences
    if (communicationStyle != null) {
      context.writeln('- Preferred communication style: $communicationStyle');
    }
    
    // Mental health goals
    if (mentalHealthGoals != null && mentalHealthGoals!.isNotEmpty) {
      context.writeln('- Mental health goals: ${mentalHealthGoals!.join(", ")}');
    }
    
    // Coping strategies that work
    if (preferredCopingStrategies != null && preferredCopingStrategies!.isNotEmpty) {
      context.writeln('- Preferred coping strategies: ${preferredCopingStrategies!.join(", ")}');
    }
    
    // Known triggers
    if (triggers != null && triggers!.isNotEmpty) {
      context.writeln('- Known triggers to be mindful of: ${triggers!.join(", ")}');
    }
    
    // Personal strengths
    if (strengths != null && strengths!.isNotEmpty) {
      context.writeln('- Personal strengths to reinforce: ${strengths!.join(", ")}');
    }
    
    // Interests for engagement
    if (interests != null && interests!.isNotEmpty) {
      context.writeln('- Interests: ${interests!.join(", ")}');
    }
    
    // Successful interventions
    if (successfulInterventions != null && successfulInterventions!.isNotEmpty) {
      context.writeln('- Previously successful interventions: ${successfulInterventions!.join(", ")}');
    }
    
    // Topics to avoid
    if (topicsToAvoid != null && topicsToAvoid!.isNotEmpty) {
      context.writeln('- Topics to avoid: ${topicsToAvoid!.join(", ")}');
    }
    
    // Conversation depth preference
    context.writeln('- Conversation depth preference: $conversationDepth/5 (1=surface level, 5=very deep)');
    
    context.writeln('');
    context.writeln('IMPORTANT: Use this profile information to:');
    context.writeln('- Address the user by name when appropriate');
    context.writeln('- Tailor your communication style to their preferences');
    context.writeln('- Reference their goals and strengths');
    context.writeln('- Suggest coping strategies they prefer');
    context.writeln('- Be mindful of their triggers');
    context.writeln('- Adjust conversation depth to their comfort level');
    context.writeln('');

    return context.toString();
  }

  /// Generate mood context for AI based on recent patterns
  String generateMoodContext() {
    if (!shareEmotionalState || moodPatterns == null) return '';

    final context = StringBuffer();
    context.writeln('RECENT MOOD PATTERNS:');
    
    if (moodPatterns!.containsKey('averageMood')) {
      context.writeln('- Average mood: ${moodPatterns!['averageMood']}');
    }
    
    if (moodPatterns!.containsKey('trend')) {
      context.writeln('- Mood trend: ${moodPatterns!['trend']}');
    }
    
    if (moodPatterns!.containsKey('commonTriggers')) {
      final triggers = moodPatterns!['commonTriggers'] as List?;
      if (triggers != null && triggers.isNotEmpty) {
        context.writeln('- Recent triggers: ${triggers.join(", ")}');
      }
    }
    
    if (stressPatterns != null) {
      if (stressPatterns!.containsKey('averageStress')) {
        context.writeln('- Average stress level: ${stressPatterns!['averageStress']}/10');
      }
      
      if (stressPatterns!.containsKey('trend')) {
        context.writeln('- Stress trend: ${stressPatterns!['trend']}');
      }
    }
    
    context.writeln('');
    return context.toString();
  }

  /// Check if user is in a potential crisis state
  bool get isPotentialCrisis {
    if (stressPatterns == null) return false;
    
    final averageStress = stressPatterns!['averageStress'] as double?;
    final trend = stressPatterns!['trend'] as String?;
    
    return (averageStress != null && averageStress >= 8.0) ||
           (trend == 'rapidly_increasing');
  }

  /// Get crisis protocol information
  Map<String, dynamic>? get crisisInfo {
    return crisisProtocol;
  }
}
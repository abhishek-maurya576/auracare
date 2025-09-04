import 'package:cloud_firestore/cloud_firestore.dart';

/// Journal Entry Model for encrypted personal journaling
class JournalEntry {
  final String id;
  final String userId;
  final String title;
  final String content; // This will be encrypted
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String? moodId; // Link to mood entry
  final String? mood; // Mood string for compatibility
  final int wordCount;
  final bool isEncrypted;
  final String? encryptionKeyId;
  final JournalEntryType type;
  final Map<String, dynamic>? metadata;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.moodId,
    this.mood,
    required this.wordCount,
    this.isEncrypted = true,
    this.encryptionKeyId,
    this.type = JournalEntryType.freeform,
    this.metadata,
  });

  /// Create from Firestore document
  factory JournalEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return JournalEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      tags: List<String>.from(data['tags'] ?? []),
      moodId: data['moodId'],
      mood: data['mood'],
      wordCount: data['wordCount'] ?? 0,
      isEncrypted: data['isEncrypted'] ?? true,
      encryptionKeyId: data['encryptionKeyId'],
      type: JournalEntryType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => JournalEntryType.freeform,
      ),
      metadata: data['metadata'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'moodId': moodId,
      'mood': mood,
      'wordCount': wordCount,
      'isEncrypted': isEncrypted,
      'encryptionKeyId': encryptionKeyId,
      'type': type.toString(),
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  JournalEntry copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? moodId,
    String? mood,
    int? wordCount,
    bool? isEncrypted,
    String? encryptionKeyId,
    JournalEntryType? type,
    Map<String, dynamic>? metadata,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      moodId: moodId ?? this.moodId,
      mood: mood ?? this.mood,
      wordCount: wordCount ?? this.wordCount,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      encryptionKeyId: encryptionKeyId ?? this.encryptionKeyId,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Get reading time estimate
  String get readingTime {
    final wordsPerMinute = 200;
    final minutes = (wordCount / wordsPerMinute).ceil();
    return minutes <= 1 ? '1 min read' : '$minutes min read';
  }

  /// Get content preview (first 100 characters)
  String get preview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  /// Check if entry was created today
  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
           createdAt.month == now.month &&
           createdAt.day == now.day;
  }

  /// Check if entry was created this week
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return createdAt.isAfter(weekStart);
  }
}

/// Types of journal entries
enum JournalEntryType {
  freeform,     // Free-form writing
  prompted,     // AI-prompted writing
  gratitude,    // Gratitude journal
  reflection,   // Daily reflection
  goals,        // Goal setting
  dreams,       // Dream journal
  therapy,      // Therapy notes
  crisis,       // Crisis journaling
}

/// Extension for journal entry type display
extension JournalEntryTypeExtension on JournalEntryType {
  String get displayName {
    switch (this) {
      case JournalEntryType.freeform:
        return 'Free Writing';
      case JournalEntryType.prompted:
        return 'Guided Writing';
      case JournalEntryType.gratitude:
        return 'Gratitude';
      case JournalEntryType.reflection:
        return 'Reflection';
      case JournalEntryType.goals:
        return 'Goals';
      case JournalEntryType.dreams:
        return 'Dreams';
      case JournalEntryType.therapy:
        return 'Therapy Notes';
      case JournalEntryType.crisis:
        return 'Crisis Support';
    }
  }

  String get icon {
    switch (this) {
      case JournalEntryType.freeform:
        return '✍️';
      case JournalEntryType.prompted:
        return '💭';
      case JournalEntryType.gratitude:
        return '🙏';
      case JournalEntryType.reflection:
        return '🤔';
      case JournalEntryType.goals:
        return '🎯';
      case JournalEntryType.dreams:
        return '🌙';
      case JournalEntryType.therapy:
        return '💚';
      case JournalEntryType.crisis:
        return '🆘';
    }
  }

  String get description {
    switch (this) {
      case JournalEntryType.freeform:
        return 'Express yourself freely without any constraints';
      case JournalEntryType.prompted:
        return 'Write with AI-generated prompts to guide your thoughts';
      case JournalEntryType.gratitude:
        return 'Focus on things you\'re grateful for today';
      case JournalEntryType.reflection:
        return 'Reflect on your day, experiences, and feelings';
      case JournalEntryType.goals:
        return 'Set intentions and track your progress';
      case JournalEntryType.dreams:
        return 'Record and explore your dreams';
      case JournalEntryType.therapy:
        return 'Private space for therapy-related thoughts';
      case JournalEntryType.crisis:
        return 'Safe space for difficult moments';
    }
  }
}

/// Journal writing prompt model
class JournalPrompt {
  final String id;
  final String prompt;
  final JournalEntryType type;
  final List<String> tags;
  final String? ageGroup; // For age-appropriate prompts
  final int difficulty; // 1-5 scale
  final String? followUpPrompt;

  JournalPrompt({
    required this.id,
    required this.prompt,
    required this.type,
    this.tags = const [],
    this.ageGroup,
    this.difficulty = 1,
    this.followUpPrompt,
  });

  /// Get age-appropriate prompts for different user groups
  static List<JournalPrompt> getAgeAppropriatePrompts(String ageGroup) {
    switch (ageGroup) {
      case 'teen':
        return [
          JournalPrompt(
            id: 'teen_1',
            prompt: 'What\'s one thing that made you smile today, even if it was small?',
            type: JournalEntryType.reflection,
            tags: ['positivity', 'daily'],
            ageGroup: 'teen',
            difficulty: 1,
          ),
          JournalPrompt(
            id: 'teen_2',
            prompt: 'If you could give advice to someone going through what you\'re experiencing, what would you say?',
            type: JournalEntryType.reflection,
            tags: ['wisdom', 'perspective'],
            ageGroup: 'teen',
            difficulty: 3,
          ),
          JournalPrompt(
            id: 'teen_3',
            prompt: 'Describe a moment when you felt proud of yourself recently.',
            type: JournalEntryType.reflection,
            tags: ['self-esteem', 'achievement'],
            ageGroup: 'teen',
            difficulty: 2,
          ),
        ];
      
      case 'young_adult':
        return [
          JournalPrompt(
            id: 'ya_1',
            prompt: 'What does success mean to you right now, and how has that definition changed?',
            type: JournalEntryType.goals,
            tags: ['success', 'growth'],
            ageGroup: 'young_adult',
            difficulty: 4,
          ),
          JournalPrompt(
            id: 'ya_2',
            prompt: 'Write about a relationship that has shaped who you are today.',
            type: JournalEntryType.reflection,
            tags: ['relationships', 'growth'],
            ageGroup: 'young_adult',
            difficulty: 3,
          ),
        ];
      
      default:
        return [
          JournalPrompt(
            id: 'general_1',
            prompt: 'What are three things you\'re grateful for today?',
            type: JournalEntryType.gratitude,
            tags: ['gratitude', 'positivity'],
            difficulty: 1,
          ),
          JournalPrompt(
            id: 'general_2',
            prompt: 'How are you feeling right now, and what might be contributing to that feeling?',
            type: JournalEntryType.reflection,
            tags: ['emotions', 'awareness'],
            difficulty: 2,
          ),
        ];
    }
  }
}
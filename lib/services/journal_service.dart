import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';

import '../services/privacy_security_service.dart';
import '../services/gemini_service.dart';

/// Journal Service for encrypted journaling with AI prompts
class JournalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'journal_entries';
  
  /// Save journal entry with encryption
  static Future<String> saveJournalEntry({
    required String userId,
    required String title,
    required String content,
    required JournalEntryType type,
    List<String> tags = const [],
    String? moodId,
    String? existingEntryId,
  }) async {
    try {
      // Get or generate encryption key for user
      final encryptionKey = await PrivacySecurityService.getUserEncryptionKey(userId);
      
      // Encrypt content
      final encryptedContent = PrivacySecurityService.encryptData(content, encryptionKey);
      final encryptedTitle = PrivacySecurityService.encryptData(title, encryptionKey);
      
      // Calculate word count
      final wordCount = content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
      
      final now = DateTime.now();
      
      final entry = JournalEntry(
        id: existingEntryId ?? '',
        userId: userId,
        title: encryptedTitle,
        content: encryptedContent,
        createdAt: existingEntryId != null ? 
          (await getJournalEntry(userId, existingEntryId))?.createdAt ?? now : now,
        updatedAt: now,
        tags: tags,
        moodId: moodId,
        wordCount: wordCount,
        isEncrypted: true,
        encryptionKeyId: 'user_$userId',
        type: type,
        metadata: {
          'version': '1.0',
          'platform': 'flutter',
          'encrypted_at': now.toIso8601String(),
        },
      );

      DocumentReference docRef;
      if (existingEntryId != null) {
        // Update existing entry
        docRef = _firestore.collection(_collection).doc(existingEntryId);
        await docRef.update(entry.toFirestore());
      } else {
        // Create new entry
        docRef = await _firestore.collection(_collection).add(entry.toFirestore());
      }

      debugPrint('✅ Journal entry saved: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error saving journal entry: $e');
      throw Exception('Failed to save journal entry: $e');
    }
  }

  /// Get journal entry by ID with decryption
  static Future<JournalEntry?> getJournalEntry(String userId, String entryId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(entryId).get();
      
      if (!doc.exists) return null;
      
      final entry = JournalEntry.fromFirestore(doc);
      
      // Verify user ownership
      if (entry.userId != userId) {
        throw Exception('Unauthorized access to journal entry');
      }
      
      // Decrypt content if encrypted
      if (entry.isEncrypted) {
        final encryptionKey = await PrivacySecurityService.getUserEncryptionKey(userId);
        final decryptedTitle = PrivacySecurityService.decryptData(entry.title, encryptionKey);
        final decryptedContent = PrivacySecurityService.decryptData(entry.content, encryptionKey);
        
        return entry.copyWith(
          title: decryptedTitle,
          content: decryptedContent,
        );
      }
      
      return entry;
    } catch (e) {
      debugPrint('❌ Error getting journal entry: $e');
      return null;
    }
  }

  /// Get all journal entries for user
  static Future<List<JournalEntry>> getUserJournalEntries(
    String userId, {
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
    JournalEntryType? type,
    List<String>? tags,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (limit > 0) {
        query = query.limit(limit);
      }

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString());
      }

      final querySnapshot = await query.get();
      final entries = <JournalEntry>[];

      for (final doc in querySnapshot.docs) {
        final entry = JournalEntry.fromFirestore(doc);
        
        // Decrypt content if encrypted
        if (entry.isEncrypted) {
          try {
            final encryptionKey = await PrivacySecurityService.getUserEncryptionKey(userId);
            final decryptedTitle = PrivacySecurityService.decryptData(entry.title, encryptionKey);
            final decryptedContent = PrivacySecurityService.decryptData(entry.content, encryptionKey);
            
            final decryptedEntry = entry.copyWith(
              title: decryptedTitle,
              content: decryptedContent,
            );
            
            // Filter by tags if specified
            if (tags == null || tags.isEmpty || 
                tags.any((tag) => decryptedEntry.tags.contains(tag))) {
              entries.add(decryptedEntry);
            }
          } catch (e) {
            debugPrint('⚠️ Failed to decrypt journal entry ${entry.id}: $e');
            // Skip entries that can't be decrypted
          }
        } else {
          // Filter by tags if specified
          if (tags == null || tags.isEmpty || 
              tags.any((tag) => entry.tags.contains(tag))) {
            entries.add(entry);
          }
        }
      }

      debugPrint('✅ Retrieved ${entries.length} journal entries for user $userId');
      return entries;
    } catch (e) {
      debugPrint('❌ Error getting journal entries: $e');
      return [];
    }
  }

  /// Delete journal entry
  static Future<bool> deleteJournalEntry(String userId, String entryId) async {
    try {
      // Verify ownership first
      final entry = await getJournalEntry(userId, entryId);
      if (entry == null || entry.userId != userId) {
        throw Exception('Unauthorized deletion attempt');
      }

      await _firestore.collection(_collection).doc(entryId).delete();
      debugPrint('✅ Journal entry deleted: $entryId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting journal entry: $e');
      return false;
    }
  }

  /// Generate AI writing prompt based on user profile and mood
  static Future<String> generateWritingPrompt({
    required String userId,
    JournalEntryType type = JournalEntryType.freeform,
    String? currentMood,
    String? recentContext,
  }) async {
    try {
      // Get user's age category for appropriate prompts
      final ageCategory = await _getUserAgeCategory(userId);
      
      String promptContext = '''
Generate a thoughtful, supportive writing prompt for a journal entry. 

User Context:
- Age group: ${ageCategory.toString().split('.').last}
- Journal type: ${type.displayName}
- Current mood: ${currentMood ?? 'not specified'}
- Recent context: ${recentContext ?? 'none provided'}

Requirements:
- Make it ${_getAgeAppropriateLanguage(ageCategory)}
- Focus on ${type.description}
- Be encouraging and non-judgmental
- Provide a specific, actionable prompt
- Keep it concise (1-2 sentences)
- Make it personally meaningful

Generate ONE writing prompt that would help this person explore their thoughts and feelings in a healthy way:
''';

      final geminiService = GeminiService();
      final prompt = await geminiService.generateContent(promptContext);
      
      debugPrint('✅ Generated writing prompt for user $userId');
      return prompt.trim();
    } catch (e) {
      debugPrint('❌ Error generating writing prompt: $e');
      // Return fallback prompts
      return _getFallbackPrompt(type);
    }
  }

  /// Get journal statistics for user
  static Future<JournalStatistics> getJournalStatistics(String userId) async {
    try {
      final entries = await getUserJournalEntries(userId, limit: 0); // Get all entries
      
      final now = DateTime.now();
      final thisWeek = now.subtract(Duration(days: now.weekday - 1));
      final thisMonth = DateTime(now.year, now.month, 1);
      
      final weeklyEntries = entries.where((e) => e.createdAt.isAfter(thisWeek)).length;
      final monthlyEntries = entries.where((e) => e.createdAt.isAfter(thisMonth)).length;
      
      final totalWords = entries.fold<int>(0, (total, entry) => total + entry.wordCount);
      final averageWordsPerEntry = entries.isEmpty ? 0 : (totalWords / entries.length).round();
      
      // Calculate streak
      int currentStreak = 0;
      DateTime checkDate = DateTime(now.year, now.month, now.day);
      
      for (int i = 0; i < 365; i++) { // Check up to a year
        final hasEntryOnDate = entries.any((entry) {
          final entryDate = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
          return entryDate.isAtSameMomentAs(checkDate);
        });
        
        if (hasEntryOnDate) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      
      // Get most used tags
      final tagCounts = <String, int>{};
      for (final entry in entries) {
        for (final tag in entry.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
      
      final mostUsedTags = tagCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      
      return JournalStatistics(
        totalEntries: entries.length,
        weeklyEntries: weeklyEntries,
        monthlyEntries: monthlyEntries,
        totalWords: totalWords,
        averageWordsPerEntry: averageWordsPerEntry,
        currentStreak: currentStreak,
        longestStreak: currentStreak, // For now, same as current streak
        mostUsedTags: mostUsedTags.take(5).map((e) => e.key).toList(),
        longestEntry: entries.isEmpty ? 0 : entries.map((e) => e.wordCount).reduce(max),
        firstEntryDate: entries.isEmpty ? null : entries.last.createdAt,
        entriesThisWeek: weeklyEntries,
        entriesThisMonth: monthlyEntries,
        favoriteWritingTime: 'Evening', // Default for now
        moodDistribution: {}, // Empty for now
      );
    } catch (e) {
      debugPrint('❌ Error getting journal statistics: $e');
      return JournalStatistics.empty();
    }
  }

  /// Search journal entries
  static Future<List<JournalEntry>> searchJournalEntries(
    String userId,
    String searchQuery, {
    int limit = 20,
  }) async {
    try {
      // Get all entries (we'll filter locally since Firestore doesn't support full-text search)
      final allEntries = await getUserJournalEntries(userId, limit: 0);
      
      final searchTerms = searchQuery.toLowerCase().split(' ');
      final matchingEntries = <JournalEntry>[];
      
      for (final entry in allEntries) {
        final searchableText = '${entry.title} ${entry.content} ${entry.tags.join(' ')}'.toLowerCase();
        
        final matchesAll = searchTerms.every((term) => searchableText.contains(term));
        if (matchesAll) {
          matchingEntries.add(entry);
        }
      }
      
      // Sort by relevance (entries with more matches first)
      matchingEntries.sort((a, b) {
        final aText = '${a.title} ${a.content}'.toLowerCase();
        final bText = '${b.title} ${b.content}'.toLowerCase();
        
        final aMatches = searchTerms.fold<int>(0, (accumulator, term) {
          return accumulator + RegExp(term).allMatches(aText).length;
        });
        
        final bMatches = searchTerms.fold<int>(0, (accumulator, term) {
          return accumulator + RegExp(term).allMatches(bText).length;
        });
        
        return bMatches.compareTo(aMatches);
      });
      
      return matchingEntries.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Error searching journal entries: $e');
      return [];
    }
  }

  /// Export journal entries to JSON
  static Future<String> exportJournalEntries(String userId) async {
    try {
      final entries = await getUserJournalEntries(userId, limit: 0);
      
      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'user_id': userId,
        'total_entries': entries.length,
        'entries': entries.map((entry) => {
          'id': entry.id,
          'title': entry.title,
          'content': entry.content,
          'created_at': entry.createdAt.toIso8601String(),
          'updated_at': entry.updatedAt.toIso8601String(),
          'tags': entry.tags,
          'type': entry.type.displayName,
          'word_count': entry.wordCount,
        }).toList(),
      };
      
      return jsonEncode(exportData);
    } catch (e) {
      debugPrint('❌ Error exporting journal entries: $e');
      throw Exception('Failed to export journal entries: $e');
    }
  }

  // Helper methods
  static Future<AgeCategory> _getUserAgeCategory(String userId) async {
    // This would typically get the user's profile from a provider or service
    // For now, return a default
    return AgeCategory.youngAdult;
  }

  static String _getAgeAppropriateLanguage(AgeCategory ageCategory) {
    switch (ageCategory) {
      case AgeCategory.youngTeen:
        return 'simple, encouraging, and relatable to teen experiences';
      case AgeCategory.teen:
        return 'supportive, honest, and relevant to teenage challenges';
      case AgeCategory.youngAdult:
        return 'thoughtful, empowering, and focused on growth';
      case AgeCategory.adult:
        return 'mature, insightful, and comprehensive';
      default:
        return 'warm, supportive, and encouraging';
    }
  }

  static String _getFallbackPrompt(JournalEntryType type) {
    switch (type) {
      case JournalEntryType.gratitude:
        return 'What are three things you\'re grateful for today, and why do they matter to you?';
      case JournalEntryType.reflection:
        return 'How are you feeling right now, and what experiences today contributed to these feelings?';
      case JournalEntryType.goals:
        return 'What\'s one small step you can take tomorrow toward something that matters to you?';
      case JournalEntryType.dreams:
        return 'Describe a recent dream or a dream you have for your future.';
      case JournalEntryType.therapy:
        return 'What thoughts or feelings would be helpful to explore right now?';
      case JournalEntryType.crisis:
        return 'You\'re in a safe space here. What would help you feel a little better right now?';
      default:
        return 'What\'s on your mind today? Write about anything that feels important to you.';
    }
  }
}

/// Journal statistics model
class JournalStatistics {
  final int totalEntries;
  final int weeklyEntries;
  final int monthlyEntries;
  final int totalWords;
  final int averageWordsPerEntry;
  final int currentStreak;
  final int longestStreak; // For compatibility
  final List<String> mostUsedTags;
  final int longestEntry;
  final DateTime? firstEntryDate;
  final int entriesThisWeek; // Alias for weeklyEntries
  final int entriesThisMonth; // Alias for monthlyEntries
  final String? favoriteWritingTime;
  final Map<String, int>? moodDistribution;

  JournalStatistics({
    required this.totalEntries,
    required this.weeklyEntries,
    required this.monthlyEntries,
    required this.totalWords,
    required this.averageWordsPerEntry,
    required this.currentStreak,
    required this.longestStreak,
    required this.mostUsedTags,
    required this.longestEntry,
    this.firstEntryDate,
    required this.entriesThisWeek,
    required this.entriesThisMonth,
    this.favoriteWritingTime,
    this.moodDistribution,
  });

  factory JournalStatistics.empty() {
    return JournalStatistics(
      totalEntries: 0,
      weeklyEntries: 0,
      monthlyEntries: 0,
      totalWords: 0,
      averageWordsPerEntry: 0,
      currentStreak: 0,
      longestStreak: 0,
      mostUsedTags: [],
      longestEntry: 0,
      firstEntryDate: null,
      entriesThisWeek: 0,
      entriesThisMonth: 0,
      favoriteWritingTime: null,
      moodDistribution: null,
    );
  }

  /// Get formatted streak text
  String get streakText {
    if (currentStreak == 0) return 'Start your streak today!';
    if (currentStreak == 1) return '1 day streak 🔥';
    return '$currentStreak day streak 🔥';
  }

  /// Get writing consistency level
  String get consistencyLevel {
    if (totalEntries == 0) return 'Getting Started';
    if (currentStreak >= 30) return 'Dedicated Writer';
    if (currentStreak >= 14) return 'Consistent Writer';
    if (currentStreak >= 7) return 'Regular Writer';
    if (weeklyEntries >= 3) return 'Active Writer';
    return 'Occasional Writer';
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';

class JournalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'journal_entries';

  // Create a new journal entry
  Future<String> createJournalEntry(JournalEntry entry) async {
    try {
      debugPrint('Creating journal entry: ${entry.title}');
      
      final docRef = await _firestore.collection(_collection).add(entry.toFirestore());
      
      debugPrint('✅ Journal entry created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating journal entry: $e');
      throw 'Failed to save journal entry: $e';
    }
  }

  // Update an existing journal entry
  Future<void> updateJournalEntry(JournalEntry entry) async {
    try {
      debugPrint('Updating journal entry: ${entry.id}');
      
      final updatedEntry = entry.copyWith(updatedAt: DateTime.now());
      
      await _firestore
          .collection(_collection)
          .doc(entry.id)
          .update(updatedEntry.toFirestore());
      
      debugPrint('✅ Journal entry updated: ${entry.id}');
    } catch (e) {
      debugPrint('❌ Error updating journal entry: $e');
      throw 'Failed to update journal entry: $e';
    }
  }

  // Delete a journal entry
  Future<void> deleteJournalEntry(String entryId) async {
    try {
      debugPrint('Deleting journal entry: $entryId');
      
      await _firestore.collection(_collection).doc(entryId).delete();
      
      debugPrint('✅ Journal entry deleted: $entryId');
    } catch (e) {
      debugPrint('❌ Error deleting journal entry: $e');
      throw 'Failed to delete journal entry: $e';
    }
  }

  // Get all journal entries for a user
  Future<List<JournalEntry>> getUserJournalEntries(String userId, {
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('Loading journal entries for user: $userId');
      
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      // Apply date filters if provided
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Apply limit if provided
      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      
      final entries = querySnapshot.docs
          .map((doc) => JournalEntry.fromFirestore(doc))
          .toList();
      
      debugPrint('✅ Loaded ${entries.length} journal entries');
      return entries;
    } catch (e) {
      debugPrint('❌ Error loading journal entries: $e');
      throw 'Failed to load journal entries: $e';
    }
  }

  // Get a specific journal entry
  Future<JournalEntry?> getJournalEntry(String entryId) async {
    try {
      debugPrint('Loading journal entry: $entryId');
      
      final doc = await _firestore.collection(_collection).doc(entryId).get();
      
      if (doc.exists) {
        final entry = JournalEntry.fromFirestore(doc);
        debugPrint('✅ Journal entry loaded: ${entry.title}');
        return entry;
      } else {
        debugPrint('⚠️ Journal entry not found: $entryId');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error loading journal entry: $e');
      throw 'Failed to load journal entry: $e';
    }
  }

  // Get journal entries by mood
  Future<List<JournalEntry>> getJournalEntriesByMood(String userId, String mood) async {
    try {
      debugPrint('Loading journal entries for mood: $mood');
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('mood', isEqualTo: mood)
          .orderBy('createdAt', descending: true)
          .get();
      
      final entries = querySnapshot.docs
          .map((doc) => JournalEntry.fromFirestore(doc))
          .toList();
      
      debugPrint('✅ Loaded ${entries.length} entries for mood: $mood');
      return entries;
    } catch (e) {
      debugPrint('❌ Error loading entries by mood: $e');
      throw 'Failed to load entries by mood: $e';
    }
  }

  // Get journal entries by tags
  Future<List<JournalEntry>> getJournalEntriesByTag(String userId, String tag) async {
    try {
      debugPrint('Loading journal entries for tag: $tag');
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('tags', arrayContains: tag)
          .orderBy('createdAt', descending: true)
          .get();
      
      final entries = querySnapshot.docs
          .map((doc) => JournalEntry.fromFirestore(doc))
          .toList();
      
      debugPrint('✅ Loaded ${entries.length} entries for tag: $tag');
      return entries;
    } catch (e) {
      debugPrint('❌ Error loading entries by tag: $e');
      throw 'Failed to load entries by tag: $e';
    }
  }

  // Get journal statistics for a user
  Future<Map<String, dynamic>> getJournalStatistics(String userId) async {
    try {
      debugPrint('Loading journal statistics for user: $userId');
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();
      
      final entries = querySnapshot.docs
          .map((doc) => JournalEntry.fromFirestore(doc))
          .toList();
      
      // Calculate statistics
      final totalEntries = entries.length;
      final totalWords = entries.fold<int>(0, (total, entry) => total + entry.wordCount);
      final averageWordsPerEntry = totalEntries > 0 ? (totalWords / totalEntries).round() : 0;
      
      // Mood distribution
      final moodCounts = <String, int>{};
      for (final entry in entries) {
        moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
      }
      
      // Tag frequency
      final tagCounts = <String, int>{};
      for (final entry in entries) {
        for (final tag in entry.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
      
      // Recent activity (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentEntries = entries.where((entry) => entry.createdAt.isAfter(thirtyDaysAgo)).length;
      
      // Longest streak
      int currentStreak = 0;
      int longestStreak = 0;
      DateTime? lastEntryDate;
      
      final sortedEntries = entries..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      for (final entry in sortedEntries) {
        final entryDate = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
        
        if (lastEntryDate == null) {
          currentStreak = 1;
          lastEntryDate = entryDate;
        } else {
          final daysDifference = lastEntryDate.difference(entryDate).inDays;
          
          if (daysDifference == 1) {
            currentStreak++;
          } else if (daysDifference > 1) {
            longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;
            currentStreak = 1;
          }
          
          lastEntryDate = entryDate;
        }
      }
      
      longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;
      
      final statistics = {
        'totalEntries': totalEntries,
        'totalWords': totalWords,
        'averageWordsPerEntry': averageWordsPerEntry,
        'recentEntries': recentEntries,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'moodDistribution': moodCounts,
        'topTags': tagCounts,
        'firstEntryDate': entries.isNotEmpty ? entries.last.createdAt.toIso8601String() : null,
        'lastEntryDate': entries.isNotEmpty ? entries.first.createdAt.toIso8601String() : null,
      };
      
      debugPrint('✅ Journal statistics calculated: $totalEntries entries, $totalWords words');
      return statistics;
    } catch (e) {
      debugPrint('❌ Error calculating journal statistics: $e');
      throw 'Failed to calculate journal statistics: $e';
    }
  }

  // Search journal entries
  Future<List<JournalEntry>> searchJournalEntries(String userId, String searchQuery) async {
    try {
      debugPrint('Searching journal entries for: "$searchQuery"');
      
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation that searches in title and content
      // For production, consider using Algolia or similar service
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final allEntries = querySnapshot.docs
          .map((doc) => JournalEntry.fromFirestore(doc))
          .toList();
      
      // Filter entries that contain the search query
      final searchResults = allEntries.where((entry) {
        final query = searchQuery.toLowerCase();
        return entry.title.toLowerCase().contains(query) ||
               entry.content.toLowerCase().contains(query) ||
               entry.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
      
      debugPrint('✅ Found ${searchResults.length} entries matching "$searchQuery"');
      return searchResults;
    } catch (e) {
      debugPrint('❌ Error searching journal entries: $e');
      throw 'Failed to search journal entries: $e';
    }
  }

  // Stream journal entries for real-time updates
  Stream<List<JournalEntry>> streamUserJournalEntries(String userId, {int? limit}) {
    Query query = _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => JournalEntry.fromFirestore(doc))
          .toList();
    });
  }
}
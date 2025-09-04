import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';

/// Journal Provider for managing journal entries state
class JournalProvider with ChangeNotifier {
  List<JournalEntry> _entries = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _statistics;

  // Getters
  List<JournalEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get statistics => _statistics;

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Load journal entries for a user
  Future<void> loadJournalEntries(
    String userId, {
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📖 Loading journal entries for user: $userId');
      
      final entries = await JournalService.getUserJournalEntries(
        userId,
        limit: limit ?? 50,
        startDate: startDate,
        endDate: endDate,
      );
      
      _entries = entries;
      debugPrint('✅ Loaded ${entries.length} journal entries');
      
      // Also load statistics
      await _loadStatistics(userId);
      
    } catch (e) {
      _setError('Failed to load journal entries: $e');
      debugPrint('❌ Error loading journal entries: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new journal entry
  Future<String?> createJournalEntry({
    required String userId,
    required String title,
    required String content,
    required JournalEntryType type,
    List<String> tags = const [],
    String? moodId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📝 Creating journal entry for user: $userId');
      
      final entryId = await JournalService.saveJournalEntry(
        userId: userId,
        title: title,
        content: content,
        type: type,
        tags: tags,
        moodId: moodId,
      );
      
      // Reload entries to get the new one
      await loadJournalEntries(userId);
      debugPrint('✅ Journal entry created with ID: $entryId');
      
      return entryId;
    } catch (e) {
      _setError('Failed to create journal entry: $e');
      debugPrint('❌ Error creating journal entry: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing journal entry
  Future<bool> updateJournalEntry({
    required String userId,
    required String entryId,
    required String title,
    required String content,
    required JournalEntryType type,
    List<String> tags = const [],
    String? moodId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📝 Updating journal entry: $entryId');
      
      await JournalService.saveJournalEntry(
        userId: userId,
        title: title,
        content: content,
        type: type,
        tags: tags,
        moodId: moodId,
        existingEntryId: entryId,
      );
      
      // Reload entries to get the updated one
      await loadJournalEntries(userId);
      debugPrint('✅ Journal entry updated: $entryId');
      return true;
    } catch (e) {
      _setError('Failed to update journal entry: $e');
      debugPrint('❌ Error updating journal entry: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a journal entry
  Future<bool> deleteJournalEntry(String userId, String entryId) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🗑️ Deleting journal entry: $entryId');
      
      final success = await JournalService.deleteJournalEntry(userId, entryId);
      
      if (success) {
        // Remove from local list
        _entries.removeWhere((entry) => entry.id == entryId);
        notifyListeners();
        debugPrint('✅ Journal entry deleted: $entryId');
      }
      
      return success;
    } catch (e) {
      _setError('Failed to delete journal entry: $e');
      debugPrint('❌ Error deleting journal entry: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Search journal entries
  Future<List<JournalEntry>> searchJournalEntries(
    String userId,
    String query, {
    List<String>? tags,
    JournalEntryType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🔍 Searching journal entries: $query');
      
      final results = await JournalService.searchJournalEntries(
        userId,
        query,
        limit: 50,
      );
      
      debugPrint('✅ Found ${results.length} matching entries');
      return results;
    } catch (e) {
      debugPrint('❌ Error searching journal entries: $e');
      return [];
    }
  }

  /// Load journal statistics
  Future<void> _loadStatistics(String userId) async {
    try {
      final stats = await JournalService.getJournalStatistics(userId);
      _statistics = {
        'totalEntries': stats.totalEntries,
        'totalWords': stats.totalWords,
        'averageWordsPerEntry': stats.averageWordsPerEntry,
        'longestStreak': stats.longestStreak,
        'currentStreak': stats.currentStreak,
        'entriesThisWeek': stats.entriesThisWeek,
        'entriesThisMonth': stats.entriesThisMonth,
        'favoriteWritingTime': stats.favoriteWritingTime,
        'mostUsedTags': stats.mostUsedTags,
        'moodDistribution': stats.moodDistribution,
      };
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading journal statistics: $e');
    }
  }

  /// Get entries by mood
  List<JournalEntry> getEntriesByMood(String mood) {
    return _entries.where((entry) => entry.mood == mood).toList();
  }

  /// Get entries by tag
  List<JournalEntry> getEntriesByTag(String tag) {
    return _entries.where((entry) => entry.tags.contains(tag)).toList();
  }

  /// Get entries by type
  List<JournalEntry> getEntriesByType(JournalEntryType type) {
    return _entries.where((entry) => entry.type == type).toList();
  }

  /// Get recent entries (last 7 days)
  List<JournalEntry> get recentEntries {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _entries.where((entry) => entry.createdAt.isAfter(weekAgo)).toList();
  }

  /// Get entries for today
  List<JournalEntry> get todayEntries {
    final today = DateTime.now();
    return _entries.where((entry) => 
      entry.createdAt.year == today.year &&
      entry.createdAt.month == today.month &&
      entry.createdAt.day == today.day
    ).toList();
  }

  /// Clear all data (for logout)
  void clear() {
    _entries.clear();
    _statistics = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Refresh entries
  Future<void> refresh(String userId) async {
    await loadJournalEntries(userId);
  }
}
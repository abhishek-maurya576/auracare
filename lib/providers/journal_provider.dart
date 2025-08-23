import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';

class JournalProvider with ChangeNotifier {
  final JournalService _journalService = JournalService();
  
  List<JournalEntry> _entries = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _statistics;

  // Getters
  List<JournalEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get statistics => _statistics;

  // Get entries count
  int get entriesCount => _entries.length;

  // Get recent entries (last 7 days)
  List<JournalEntry> get recentEntries {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _entries.where((entry) => entry.createdAt.isAfter(sevenDaysAgo)).toList();
  }

  // Get entries by mood
  List<JournalEntry> getEntriesByMood(String mood) {
    return _entries.where((entry) => entry.mood == mood).toList();
  }

  // Get entries by tag
  List<JournalEntry> getEntriesByTag(String tag) {
    return _entries.where((entry) => entry.tags.contains(tag)).toList();
  }

  // Load journal entries for a user
  Future<void> loadJournalEntries(String userId, {
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📖 Loading journal entries for user: $userId');
      
      final entries = await _journalService.getUserJournalEntries(
        userId,
        limit: limit,
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

  // Create a new journal entry
  Future<String?> createJournalEntry({
    required String userId,
    required String title,
    required String content,
    required String mood,
    required String emoji,
    required List<String> tags,
    bool isPrivate = true,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📝 Creating new journal entry: $title');
      
      final entry = JournalEntry(
        id: '', // Will be set by Firestore
        userId: userId,
        title: title.trim(),
        content: content.trim(),
        mood: mood,
        emoji: emoji,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPrivate: isPrivate,
      );

      final entryId = await _journalService.createJournalEntry(entry);
      
      // Add to local list with the new ID
      final createdEntry = entry.copyWith(id: entryId);
      _entries.insert(0, createdEntry); // Add to beginning (most recent first)
      
      debugPrint('✅ Journal entry created: $entryId');
      notifyListeners();
      
      // Refresh statistics
      await _loadStatistics(userId);
      
      return entryId;
    } catch (e) {
      _setError('Failed to create journal entry: $e');
      debugPrint('❌ Error creating journal entry: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing journal entry
  Future<bool> updateJournalEntry({
    required String entryId,
    required String userId,
    String? title,
    String? content,
    String? mood,
    String? emoji,
    List<String>? tags,
    bool? isPrivate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('📝 Updating journal entry: $entryId');
      
      // Find the entry in local list
      final entryIndex = _entries.indexWhere((entry) => entry.id == entryId);
      if (entryIndex == -1) {
        throw 'Journal entry not found locally';
      }

      final currentEntry = _entries[entryIndex];
      final updatedEntry = currentEntry.copyWith(
        title: title,
        content: content,
        mood: mood,
        emoji: emoji,
        tags: tags,
        isPrivate: isPrivate,
        updatedAt: DateTime.now(),
      );

      await _journalService.updateJournalEntry(updatedEntry);
      
      // Update local list
      _entries[entryIndex] = updatedEntry;
      
      debugPrint('✅ Journal entry updated: $entryId');
      notifyListeners();
      
      // Refresh statistics
      await _loadStatistics(userId);
      
      return true;
    } catch (e) {
      _setError('Failed to update journal entry: $e');
      debugPrint('❌ Error updating journal entry: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a journal entry
  Future<bool> deleteJournalEntry(String entryId, String userId) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🗑️ Deleting journal entry: $entryId');
      
      await _journalService.deleteJournalEntry(entryId);
      
      // Remove from local list
      _entries.removeWhere((entry) => entry.id == entryId);
      
      debugPrint('✅ Journal entry deleted: $entryId');
      notifyListeners();
      
      // Refresh statistics
      await _loadStatistics(userId);
      
      return true;
    } catch (e) {
      _setError('Failed to delete journal entry: $e');
      debugPrint('❌ Error deleting journal entry: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search journal entries
  Future<List<JournalEntry>> searchEntries(String userId, String query) async {
    _clearError();

    try {
      debugPrint('🔍 Searching journal entries: "$query"');
      
      final results = await _journalService.searchJournalEntries(userId, query);
      
      debugPrint('✅ Found ${results.length} matching entries');
      return results;
    } catch (e) {
      _setError('Failed to search journal entries: $e');
      debugPrint('❌ Error searching journal entries: $e');
      return [];
    }
  }

  // Load journal statistics
  Future<void> _loadStatistics(String userId) async {
    try {
      debugPrint('📊 Loading journal statistics');
      
      final stats = await _journalService.getJournalStatistics(userId);
      _statistics = stats;
      
      debugPrint('✅ Journal statistics loaded');
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Failed to load journal statistics: $e');
      // Don't set error for statistics as it's not critical
    }
  }

  // Get journal entry by ID
  JournalEntry? getEntryById(String entryId) {
    try {
      return _entries.firstWhere((entry) => entry.id == entryId);
    } catch (e) {
      return null;
    }
  }

  // Get mood distribution for charts
  Map<String, int> getMoodDistribution() {
    final distribution = <String, int>{};
    for (final entry in _entries) {
      distribution[entry.mood] = (distribution[entry.mood] ?? 0) + 1;
    }
    return distribution;
  }

  // Get tag frequency for insights
  Map<String, int> getTagFrequency() {
    final frequency = <String, int>{};
    for (final entry in _entries) {
      for (final tag in entry.tags) {
        frequency[tag] = (frequency[tag] ?? 0) + 1;
      }
    }
    return frequency;
  }

  // Get writing streak
  int getWritingStreak() {
    if (_entries.isEmpty) return 0;

    int streak = 0;
    DateTime? lastDate;
    
    final sortedEntries = List<JournalEntry>.from(_entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final entry in sortedEntries) {
      final entryDate = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );

      if (lastDate == null) {
        streak = 1;
        lastDate = entryDate;
      } else {
        final daysDifference = lastDate.difference(entryDate).inDays;
        
        if (daysDifference == 1) {
          streak++;
          lastDate = entryDate;
        } else if (daysDifference > 1) {
          break;
        }
      }
    }

    return streak;
  }

  // Clear all data
  void clearData() {
    _entries.clear();
    _statistics = null;
    _clearError();
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gemini_service.dart';

class ChatSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GeminiService _geminiService = GeminiService();
  
  String? get currentUserId => _auth.currentUser?.uid;

  // Save conversation history to Firestore for long-term persistence
  Future<void> saveConversationHistory(String sessionId, List<Map<String, String>> history) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId)
          .set({
        'history': history,
        'lastUpdated': FieldValue.serverTimestamp(),
        'messageCount': history.length,
      }, SetOptions(merge: true));
      debugPrint('Saved conversation history for user $userId, session $sessionId, history length: ${history.length}');
    } catch (e) {
      debugPrint('Error saving conversation history: $e');
    }
  }

  // Load conversation history from Firestore
  Future<List<Map<String, String>>> loadConversationHistory(String sessionId) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final history = data['history'] as List<dynamic>?;
        if (history != null) {
          return history.map((item) => Map<String, String>.from(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading conversation history: $e');
    }
    
    return [];
  }

  // Get or create a session with persistent memory
  Future<String> getOrCreateSession() async {
    final userId = currentUserId;
    if (userId == null) throw 'User not authenticated';

    // Check for existing active session (within last 24 hours)
    try {
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .where('lastUpdated', isGreaterThan: yesterday)
          .orderBy('lastUpdated', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final sessionId = snapshot.docs.first.id;
        
        // Load existing conversation history into memory
        final history = await loadConversationHistory(sessionId);
        for (final message in history) {
          _geminiService.addToSessionHistory(sessionId, message['role']!, message['content']!);
        }
        
        return sessionId;
      }
    } catch (e) {
      debugPrint('Error checking for existing session: $e');
    }

    // Create new session
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Send message with persistent memory
  Future<String> sendMessage(String sessionId, String userMessage) async {
    try {
      // Add user message to session history
      _geminiService.addToSessionHistory(sessionId, 'User', userMessage);
      
      // Generate AI response with full conversation context
      final aiResponse = await _geminiService.generateChatResponse(
        userMessage,
        sessionId: sessionId,
      );

      // Save updated conversation history to Firestore
      final currentHistory = _geminiService.getSessionHistory(sessionId);
      await saveConversationHistory(sessionId, currentHistory);

      return aiResponse;
    } catch (e) {
      debugPrint('Error in sendMessage: $e');
      rethrow;
    }
  }

  // Clear session history
  Future<void> clearSession(String sessionId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      // Clear from memory
      _geminiService.clearSessionHistory(sessionId);
      
      // Clear from Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId)
          .delete();
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }

  // Get session statistics
  Future<Map<String, dynamic>> getSessionStats(String sessionId) async {
    final userId = currentUserId;
    if (userId == null) return {};

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'messageCount': data['messageCount'] ?? 0,
          'lastUpdated': data['lastUpdated'],
          'sessionId': sessionId,
        };
      }
    } catch (e) {
      debugPrint('Error getting session stats: $e');
    }

    return {};
  }

  // Get all user sessions with enhanced filtering
  Future<List<Map<String, dynamic>>> getUserSessions({
    int limit = 10,
    String? searchQuery,
    List<String>? topics,
    String? mood,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .orderBy('lastUpdated', descending: true);

      // Apply filters
      if (mood != null) {
        query = query.where('mood', isEqualTo: mood);
      }

      final snapshot = await query.limit(limit).get();

      var sessions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['sessionId'] = doc.id;
        return data;
      }).toList();

      // Apply client-side filters for complex queries
      if (searchQuery != null && searchQuery.isNotEmpty) {
        sessions = sessions.where((session) {
          final title = (session['title'] ?? '').toString().toLowerCase();
          final sessionTopics = (session['topics'] as List<dynamic>? ?? [])
              .map((t) => t.toString().toLowerCase())
              .join(' ');
          return title.contains(searchQuery.toLowerCase()) ||
                 sessionTopics.contains(searchQuery.toLowerCase());
        }).toList();
      }

      if (topics != null && topics.isNotEmpty) {
        sessions = sessions.where((session) {
          final sessionTopics = (session['topics'] as List<dynamic>? ?? [])
              .map((t) => t.toString().toLowerCase())
              .toList();
          return topics.any((topic) => sessionTopics.contains(topic.toLowerCase()));
        }).toList();
      }

      debugPrint('Fetched ${sessions.length} sessions for user $userId');
      return sessions;
    } catch (e) {
      debugPrint('Error getting user sessions: $e');
      return [];
    }
  }

  // Get session analytics
  Future<Map<String, dynamic>> getSessionAnalytics() async {
    final userId = currentUserId;
    if (userId == null) return {};

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .get();

      final sessions = snapshot.docs.map((doc) => doc.data()).toList();
      
      // Calculate analytics
      final totalSessions = sessions.length;
      final totalMessages = sessions.fold<int>(0, (sum, session) => 
          sum + (session['messageCount'] as int? ?? 0));
      
      // Most discussed topics
      final topicCounts = <String, int>{};
      for (final session in sessions) {
        final topics = session['topics'] as List<dynamic>? ?? [];
        for (final topic in topics) {
          topicCounts[topic.toString()] = (topicCounts[topic.toString()] ?? 0) + 1;
        }
      }
      
      final sortedTopics = topicCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Mood distribution
      final moodCounts = <String, int>{};
      for (final session in sessions) {
        final mood = session['mood']?.toString();
        if (mood != null) {
          moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
        }
      }

      return {
        'totalSessions': totalSessions,
        'totalMessages': totalMessages,
        'averageMessagesPerSession': totalSessions > 0 ? totalMessages / totalSessions : 0,
        'topTopics': sortedTopics.take(5).map((e) => {
          'topic': e.key,
          'count': e.value,
        }).toList(),
        'moodDistribution': moodCounts,
        'lastSessionDate': sessions.isNotEmpty 
            ? sessions.first['lastUpdated']
            : null,
      };
    } catch (e) {
      debugPrint('Error getting session analytics: $e');
      return {};
    }
  }

  // Archive old sessions (older than specified days)
  Future<void> archiveOldSessions({int olderThanDays = 30}) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .where('lastUpdated', isLessThan: cutoffDate)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isActive': false, 'archived': true});
      }

      await batch.commit();
      debugPrint('Archived ${snapshot.docs.length} old sessions');
    } catch (e) {
      debugPrint('Error archiving old sessions: $e');
    }
  }

  // Export session data
  Future<Map<String, dynamic>> exportSessionData(String sessionId) async {
    final userId = currentUserId;
    if (userId == null) return {};

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .doc(sessionId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'sessionId': sessionId,
          'exportDate': DateTime.now().toIso8601String(),
          'sessionData': data,
        };
      }
    } catch (e) {
      debugPrint('Error exporting session data: $e');
    }

    return {};
  }
}

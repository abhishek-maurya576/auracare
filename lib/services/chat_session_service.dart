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

  // Get all user sessions
  Future<List<Map<String, dynamic>>> getUserSessions({int limit = 10}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .orderBy('lastUpdated', descending: true)
          .limit(limit)
          .get();

      debugPrint('Fetched ${snapshot.docs.length} sessions for user $userId');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['sessionId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting user sessions: $e');
      return [];
    }
  }
}

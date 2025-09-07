import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Mood Data Collection
  Future<void> saveMoodData({
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
    final userId = currentUserId;
    if (userId == null) throw 'User not authenticated';

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('moods')
          .add({
        'mood': mood,
        'emoji': emoji,
        'note': note,
        'intensity': intensity,
        'triggers': triggers,
        'tags': tags,
        'aiAnalysis': aiAnalysis,
        'aiInsights': aiInsights,
        'stressLevel': stressLevel,
        'location': location,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD
        'additionalData': additionalData,
      });
    } catch (e) {
      throw 'Failed to save mood data: $e';
    }
  }

  // Get mood history
  Future<List<Map<String, dynamic>>> getMoodHistory({
    int limit = 30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw 'User not authenticated';

    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('moods')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw 'Failed to get mood history: $e';
    }
  }

  // Daily Tasks Collection
  Future<void> saveTaskCompletion({
    required String taskId,
    required String taskName,
    required bool completed,
    Map<String, dynamic>? taskData,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw 'User not authenticated';

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_tasks')
          .doc('$today-$taskId')
          .set({
        'taskId': taskId,
        'taskName': taskName,
        'completed': completed,
        'date': today,
        'timestamp': FieldValue.serverTimestamp(),
        'taskData': taskData,
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to save task completion: $e';
    }
  }

  // Get daily tasks progress
  Future<Map<String, bool>> getDailyTasksProgress([DateTime? date]) async {
    final userId = currentUserId;
    if (userId == null) throw 'User not authenticated';

    try {
      final targetDate = (date ?? DateTime.now()).toIso8601String().split('T')[0];
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_tasks')
          .where('date', isEqualTo: targetDate)
          .get();

      final progress = <String, bool>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        progress[data['taskId']] = data['completed'] ?? false;
      }
      return progress;
    } catch (e) {
      throw 'Failed to get daily tasks progress: $e';
    }
  }

  // Community Posts Collection
  Future<String> createCommunityPost({
    required String content,
    required String category,
    bool anonymous = true,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw 'User not authenticated';

    try {
      final doc = await _firestore.collection('community_posts').add({
        'content': content,
        'category': category,
        'authorId': anonymous ? null : userId,
        'anonymous': anonymous,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'hugs': 0,
        'replies': 0,
        'likedBy': <String>[],
        'huggedBy': <String>[],
      });
      return doc.id;
    } catch (e) {
      throw 'Failed to create community post: $e';
    }
  }

  // Get community posts
  Future<List<Map<String, dynamic>>> getCommunityPosts({
    String? category,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('community_posts')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw 'Failed to get community posts: $e';
    }
  }

  // Chat Messages Collection - Enhanced with proper timestamp handling
  Future<void> saveChatMessage(ChatMessage message) async {
    final userId = currentUserId;
    if (userId == null) throw 'User not authenticated';

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_messages')
          .add(message.toFirestoreMap()); // Use Firestore-specific mapping with server timestamp
    } catch (e) {
      throw 'Failed to save chat message: $e';
    }
  }

  // Get chat messages with session grouping - Enhanced with proper timestamp handling
  Future<List<ChatMessage>> getChatMessages({
    int limit = 100,
    String? sessionId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw 'User not authenticated';

    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_messages')
          .orderBy('timestamp', descending: false)
          .limit(limit);

      if (sessionId != null) {
        query = query.where('sessionId', isEqualTo: sessionId);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        return ChatMessage.fromFirestore(doc); // Use Firestore-specific parsing
      }).toList();
    } catch (e) {
      throw 'Failed to get chat messages: $e';
    }
  }

  // Clear chat history
  Future<void> clearChatHistory() async {
    final userId = currentUserId;
    if (userId == null) throw 'User not authenticated';

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_messages')
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw 'Failed to clear chat history: $e';
    }
  }

  // React to community post
  Future<void> reactToCommunityPost({
    required String postId,
    required String reactionType, // 'like' or 'hug'
  }) async {
    final userId = currentUserId;
    if (userId == null) throw 'User not authenticated';

    try {
      final postRef = _firestore.collection('community_posts').doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) throw 'Post not found';

        final data = postDoc.data()!;
        final reactionField = '${reactionType}edBy';
        final countField = '${reactionType}s';
        
        List<String> reactedUsers = List<String>.from(data[reactionField] ?? []);
        
        if (reactedUsers.contains(userId)) {
          // Remove reaction
          reactedUsers.remove(userId);
          transaction.update(postRef, {
            reactionField: reactedUsers,
            countField: FieldValue.increment(-1),
          });
        } else {
          // Add reaction
          reactedUsers.add(userId);
          transaction.update(postRef, {
            reactionField: reactedUsers,
            countField: FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      throw 'Failed to react to post: $e';
    }
  }

  // AI Chat History
  Future<void> saveAIChatMessage({
    required String message,
    required String response,
    required String messageType, // 'user' or 'ai'
    String? sessionId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw 'User not authenticated';

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_chats')
          .add({
        'message': message,
        'response': response,
        'messageType': messageType,
        'sessionId': sessionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to save AI chat message: $e';
    }
  }

  // Get AI chat history
  Future<List<Map<String, dynamic>>> getAIChatHistory({
    String? sessionId,
    int limit = 50,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw 'User not authenticated';

    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('ai_chats')
          .orderBy('timestamp', descending: false)
          .limit(limit);

      if (sessionId != null) {
        query = query.where('sessionId', isEqualTo: sessionId);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw 'Failed to get AI chat history: $e';
    }
  }

  // User Analytics
  Future<Map<String, dynamic>> getUserAnalytics() async {
    final userId = currentUserId;
    if (userId == null) throw 'User not authenticated';

    try {
      // Get mood analytics
      final moodSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('moods')
          .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 30)))
          .get();

      // Get task analytics
      final taskSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_tasks')
          .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 30)))
          .get();

      // Calculate statistics
      final moodCounts = <String, int>{};
      for (final doc in moodSnapshot.docs) {
        final mood = doc.data()['mood'] as String;
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }

      int completedTasks = 0;
      for (final doc in taskSnapshot.docs) {
        if (doc.data()['completed'] == true) {
          completedTasks++;
        }
      }

      return {
        'totalMoodEntries': moodSnapshot.docs.length,
        'moodDistribution': moodCounts,
        'completedTasks': completedTasks,
        'totalTasks': taskSnapshot.docs.length,
        'taskCompletionRate': taskSnapshot.docs.isEmpty 
            ? 0.0 
            : completedTasks / taskSnapshot.docs.length,
        'streakDays': await _calculateStreak(),
      };
    } catch (e) {
      throw 'Failed to get user analytics: $e';
    }
  }

  // Calculate current streak
  Future<int> _calculateStreak() async {
    final userId = currentUserId;
    if (userId == null) return 0;

    try {
      final now = DateTime.now();
      int streak = 0;
      
      for (int i = 0; i < 365; i++) {
        final date = now.subtract(Duration(days: i));
        final dateString = date.toIso8601String().split('T')[0];
        
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('daily_tasks')
            .where('date', isEqualTo: dateString)
            .where('completed', isEqualTo: true)
            .limit(1)
            .get();
        
        if (snapshot.docs.isNotEmpty) {
          streak++;
        } else {
          break;
        }
      }
      
      return streak;
    } catch (e) {
      return 0;
    }
  }

  // Emergency contacts and help resources
  Future<List<Map<String, dynamic>>> getHelpResources({
    double? latitude,
    double? longitude,
    String? category,
  }) async {
    try {
      Query query = _firestore.collection('help_resources');

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      // TODO: Implement geo-query for location-based resources
      // This would require additional setup with GeoFlutterFire or similar

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw 'Failed to get help resources: $e';
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/user_profile.dart';
import '../models/mood_entry.dart';
import '../services/privacy_security_service.dart';
import '../services/youth_content_service.dart';
import '../services/content_filter_service.dart';

class GeminiService {
  static const String _baseUrl = ApiKeys.geminiBaseUrl;
  static const String _apiKey = ApiKeys.geminiApiKey;

  // Store session history for persistent memory
  static final Map<String, List<Map<String, String>>> _sessionHistories = {};

  // Store user profiles for personalized responses
  static final Map<String, UserProfile> _userProfiles = {};

  // Store user mood data for context
  static final Map<String, List<MoodEntry>> _userMoodData = {};

  // Track last access time for automatic cleanup
  static final Map<String, DateTime> _lastAccessTimes = {};

  // Maximum time to keep user data in memory (24 hours)
  static const Duration _maxCacheTime = Duration(hours: 24);

  // Maximum number of users to keep in memory
  static const int _maxCachedUsers = 50;

  // Validate API configuration on initialization
  Future<bool> validateApiConfiguration() async {
    try {
      debugPrint('Validating Gemini API configuration...');

      // Check API key format
      if (_apiKey.isEmpty || !_apiKey.startsWith('AI')) {
        debugPrint(
            '⚠️ API key appears to be invalid: ${_apiKey.substring(0, 4)}...');
        return false;
      }

      // Test API with a simple request
      final testPrompt =
          'Hello, this is a test request. Please respond with "API is working correctly."';
      final response = await generateContent(testPrompt);

      debugPrint(
          '✅ API validation successful: ${response.substring(0, response.length > 30 ? 30 : response.length)}...');
      return true;
    } catch (e) {
      debugPrint('❌ API validation failed: $e');
      return false;
    }
  }

  // Add message to session history
  void addToSessionHistory(String sessionId, String role, String content) {
    // Validate inputs
    if (sessionId.isEmpty || role.isEmpty || content.isEmpty) {
      debugPrint('⚠️ Warning: Invalid session history entry - skipping');
      debugPrint(
          'SessionID: "$sessionId", Role: "$role", Content length: ${content.length}');
      return;
    }

    _cleanupOldData(); // Clean up before adding

    if (!_sessionHistories.containsKey(sessionId)) {
      _sessionHistories[sessionId] = [];
      debugPrint('📝 Created new session history for: $sessionId');
    }

    _sessionHistories[sessionId]!.add({
      'role': role,
      'content': content,
    });

    // Keep history manageable (last 20 messages per session)
    if (_sessionHistories[sessionId]!.length > 20) {
      final removedCount = _sessionHistories[sessionId]!.length - 20;
      _sessionHistories[sessionId] = _sessionHistories[sessionId]!
          .sublist(_sessionHistories[sessionId]!.length - 20);
      debugPrint(
          '🧹 Trimmed $removedCount old messages from session: $sessionId');
    }

    debugPrint(
        '💬 Added message to session $sessionId: $role (${content.length} chars)');
  }

  // Get session history
  List<Map<String, String>> getSessionHistory(String sessionId) {
    if (sessionId.isEmpty) {
      debugPrint('⚠️ Warning: Empty sessionId provided to getSessionHistory');
      return [];
    }

    _cleanupOldData(); // Clean up on access
    final history = _sessionHistories[sessionId] ?? [];
    debugPrint(
        '📖 Retrieved ${history.length} messages for session: $sessionId');
    return history;
  }

  // Clear session history
  void clearSessionHistory(String sessionId) {
    if (sessionId.isEmpty) {
      debugPrint('⚠️ Warning: Empty sessionId provided to clearSessionHistory');
      return;
    }

    final messageCount = _sessionHistories[sessionId]?.length ?? 0;
    _sessionHistories.remove(sessionId);
    debugPrint('🗑️ Cleared $messageCount messages from session: $sessionId');
  }

  // User profile management for personalization
  void setUserProfile(String userId, UserProfile profile) {
    _cleanupOldData(); // Clean up before adding new data
    _userProfiles[userId] = profile;
    _lastAccessTimes[userId] = DateTime.now();
    debugPrint(
        'User profile set for personalized AI responses: ${profile.name}');
    debugPrint('Total cached users: ${_userProfiles.length}');
  }

  UserProfile? getUserProfile(String userId) {
    _cleanupOldData(); // Clean up on access
    final profile = _userProfiles[userId];
    if (profile != null) {
      _lastAccessTimes[userId] = DateTime.now(); // Update access time
    }
    return profile;
  }

  void clearUserProfile(String userId) {
    _userProfiles.remove(userId);
    _lastAccessTimes.remove(userId);
    debugPrint('User profile cleared from cache: $userId');
  }

  // User mood data management for context
  void setUserMoodData(String userId, List<MoodEntry> moodEntries) {
    _cleanupOldData(); // Clean up before adding new data
    _userMoodData[userId] = moodEntries;
    _lastAccessTimes[userId] = DateTime.now();
    debugPrint(
        'Mood data updated for user: $userId (${moodEntries.length} entries)');
  }

  List<MoodEntry>? getUserMoodData(String userId) {
    _cleanupOldData(); // Clean up on access
    final moodData = _userMoodData[userId];
    if (moodData != null) {
      _lastAccessTimes[userId] = DateTime.now(); // Update access time
    }
    return moodData;
  }

  void clearUserMoodData(String userId) {
    _userMoodData.remove(userId);
    // Don't remove access time here as user might still have profile data
    debugPrint('User mood data cleared from cache: $userId');
  }

  /// Automatic cleanup of old data to prevent memory leaks
  void _cleanupOldData() {
    final now = DateTime.now();
    final expiredUsers = <String>[];

    // Find users with expired data
    _lastAccessTimes.forEach((userId, lastAccess) {
      if (now.difference(lastAccess) > _maxCacheTime) {
        expiredUsers.add(userId);
      }
    });

    // Remove expired users
    for (final userId in expiredUsers) {
      _userProfiles.remove(userId);
      _userMoodData.remove(userId);
      _lastAccessTimes.remove(userId);
      debugPrint('Cleaned up expired data for user: $userId');
    }

    // If still over limit, remove oldest accessed users
    if (_userProfiles.length > _maxCachedUsers) {
      final sortedByAccess = _lastAccessTimes.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final usersToRemove =
          sortedByAccess.take(_userProfiles.length - _maxCachedUsers);
      for (final entry in usersToRemove) {
        final userId = entry.key;
        _userProfiles.remove(userId);
        _userMoodData.remove(userId);
        _lastAccessTimes.remove(userId);
        debugPrint('Cleaned up LRU data for user: $userId');
      }
    }

    if (expiredUsers.isNotEmpty || _userProfiles.length > _maxCachedUsers) {
      debugPrint(
          'Memory cleanup completed. Cached users: ${_userProfiles.length}/$_maxCachedUsers');
    }
  }

  /// Manual cleanup of all cached data
  void clearAllCachedData() {
    final userCount = _userProfiles.length;
    _userProfiles.clear();
    _userMoodData.clear();
    _lastAccessTimes.clear();
    _sessionHistories.clear();
    debugPrint('All cached data cleared. Removed $userCount users from cache.');
  }

  /// Test content filter for debugging - Public method for external testing
  static QueryValidationResult testContentFilter(String query) {
    debugPrint('🧪 TESTING: Content filter validation for: "$query"');
    final result = ContentFilterService.validateQuery(query);
    ContentFilterService.logFilterDecision(query, result);

    // Additional test logging
    debugPrint('📄 TEST RESULT:');
    debugPrint('   Input: "$query"');
    debugPrint('   Valid: ${result.isValid}');
    debugPrint('   Reason: ${result.reason}');
    debugPrint('   Message: "${result.message}"');
    if (result.requiresGuidance) {
      debugPrint('   Guidance: "${result.guidanceMessage}"');
    }

    return result;
  }

  /// Bulk test content filter with common examples
  static void runContentFilterTests() {
    debugPrint('🧪 RUNNING CONTENT FILTER TESTS...');

    final testCases = [
      // Valid mental health queries
      'I feel anxious about work',
      'How can I manage stress?',
      'I\'m feeling depressed today',
      'Can you help me with breathing exercises?',
      'I need support with my relationships',
      'How are you?',

      // Invalid/irrelevant queries
      'What\'s the weather like?',
      'Tell me about sports scores',
      'How do I cook pasta?',
      'What\'s the latest movie?',
      'Can you help me with programming?',
      'Tell me about cryptocurrency',

      // Borderline cases
      'Hello',
      'Thank you',
      'I don\'t know what to say',
      'Tell me a joke',
    ];

    for (final testCase in testCases) {
      testContentFilter(testCase);
      debugPrint('---');
    }

    debugPrint('✅ CONTENT FILTER TESTS COMPLETED');
  }

  // Generate personalized context based on user profile and mood data
  String _generatePersonalizedContext(String userId) {
    final profile = getUserProfile(userId);
    final moodData = getUserMoodData(userId);

    // Comprehensive logging to track personalization status as per API personalization pattern
    if (profile == null) {
      debugPrint(
          '⚠️ PERSONALIZATION ERROR: No user profile found for personalization');
      debugPrint('⚠️ User ID: $userId');
      debugPrint('⚠️ Available profiles: ${_userProfiles.keys.toList()}');
      debugPrint('⚠️ This will result in non-personalized API responses');
      return '';
    }

    // Verify UserProfile availability and log user name usage
    debugPrint(
        '✅ PERSONALIZATION SUCCESS: User profile verified and available');
    debugPrint(
        '🎯 Generating personalized context for user: ${profile.name} (ID: $userId)');
    debugPrint(
        '📊 Profile completeness: ${_calculateProfileCompleteness(profile)}%');
    debugPrint('🔒 Personalization enabled: ${profile.enablePersonalization}');
    debugPrint('💭 Emotional state sharing: ${profile.shareEmotionalState}');

    final context = StringBuffer();

    // Add user profile context with explicit name handling
    final profileContext = profile.generatePersonalizationContext();
    context.write(profileContext);

    // Log user name usage for tracking
    if (profileContext.contains('Name: ${profile.name}')) {
      debugPrint(
          '👤 User name successfully included in personalization context: ${profile.name}');
    } else {
      debugPrint(
          '⚠️ Warning: User name may not be properly included in context');
    }

    // Add mood context if available and user allows it
    if (profile.shareEmotionalState &&
        moodData != null &&
        moodData.isNotEmpty) {
      final moodContext = _generateMoodContext(moodData);
      context.write(moodContext);
      debugPrint(
          '📈 Mood context added: ${moodData.length} entries from last 7 days');
    } else {
      debugPrint(
          '📊 No mood context added - sharing disabled or no data available');
    }

    final contextString = context.toString();
    debugPrint('📝 Personalization context generated successfully');
    debugPrint('📏 Context length: ${contextString.length} characters');
    debugPrint('🎯 Ready for personalized API call with user: ${profile.name}');

    return contextString;
  }

  /// Generate immediate crisis intervention response
  Future<String> _generateCrisisResponse(String userMessage,
      {String? userId}) async {
    debugPrint(
        '🆘 CRISIS INTERVENTION: Generating immediate response for crisis situation');

    // Generate personalized context if available
    String personalizedContext = '';
    if (userId != null) {
      final userProfile = getUserProfile(userId);
      if (userProfile != null) {
        personalizedContext =
            '''\nUSER CONTEXT:\n- Name: ${userProfile.name}\n- I know you personally and care about you\n\n''';
        debugPrint(
            '🆘 Using personalized context for crisis response: ${userProfile.name}');
      }
    }

    final prompt = '''
You are Aura, a compassionate AI mental health companion. The user has expressed thoughts that indicate they may be in crisis or considering self-harm. This is a CRITICAL situation requiring immediate, caring intervention.

$personalizedContext
CRISIS MESSAGE: "$userMessage"

You MUST respond with:
1. Immediate validation of their feelings without judgment
2. Clear statement that their life has value and they matter
3. Gentle but urgent encouragement to seek immediate help
4. Provide Indian crisis resources
5. Offer to stay and talk with them
6. Use their name if known to personalize the response

Keep the response warm, caring, non-judgmental, and focused on immediate safety. This is for users in India.

Respond as Aura with immediate crisis intervention:
''';

    try {
      final response = await generateContent(prompt);

      // Always add Indian crisis resources for any crisis situation
      final crisisResponse = '''$response

🆘 IMMEDIATE HELP AVAILABLE:
• Vandrevala Foundation (24/7): 9999 666 555
• AASRA Suicide Prevention: 91-22-27546669
• Sneha Suicide Prevention (Chennai): 044-24640050
• iCall Psychosocial Helpline: 9152987821
• Sumaitri (Delhi): 011-23389090
• Emergency Services: 112

Please reach out to one of these numbers right now. You don't have to go through this alone. 💙''';

      debugPrint('✅ CRISIS INTERVENTION: Response generated successfully');
      return crisisResponse;
    } catch (e) {
      debugPrint('❌ CRISIS INTERVENTION ERROR: $e');
      // Fallback crisis response if AI generation fails
      return '''I can see you're going through something really difficult right now, and I want you to know that your life matters. Your feelings are valid, but please don't give up.

🆘 Please reach out for immediate help:
• Vandrevala Foundation (24/7): 9999 666 555
• AASRA Suicide Prevention: 91-22-27546669
• Emergency Services: 112

You're not alone. There are people who care and want to help you through this. 💙''';
    }
  }

  double _calculateProfileCompleteness(UserProfile profile) {
    int completedFields = 0;
    int totalFields = 10;

    if (profile.mentalHealthGoals?.isNotEmpty == true) completedFields++;
    if (profile.preferredCopingStrategies?.isNotEmpty == true)
      completedFields++;
    if (profile.communicationStyle != null) completedFields++;
    if (profile.triggers?.isNotEmpty == true) completedFields++;
    if (profile.strengths?.isNotEmpty == true) completedFields++;
    if (profile.interests?.isNotEmpty == true) completedFields++;
    if (profile.conversationDepth > 0) completedFields++;
    if (profile.age != null) completedFields++;
    if (profile.timezone != null) completedFields++;
    if (profile.language != null) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  // Generate mood context from recent mood entries
  String _generateMoodContext(List<MoodEntry> moodEntries) {
    if (moodEntries.isEmpty) return '';

    final context = StringBuffer();
    context.writeln('RECENT MOOD DATA (for context and personalization):');

    // Get recent entries (last 7 days)
    final now = DateTime.now();
    final recentEntries = moodEntries.where((entry) {
      final entryDate = DateTime.parse(entry.date);
      return now.difference(entryDate).inDays <= 7;
    }).toList();

    if (recentEntries.isNotEmpty) {
      // Calculate averages
      final avgMoodScore =
          recentEntries.fold<double>(0, (sum, entry) => sum + entry.moodScore) /
              recentEntries.length;
      final avgStress = recentEntries.fold<double>(
              0, (sum, entry) => sum + entry.calculatedStressLevel) /
          recentEntries.length;

      context.writeln(
          '- Recent average mood: ${avgMoodScore.toStringAsFixed(1)}/5');
      context.writeln(
          '- Recent average stress: ${avgStress.toStringAsFixed(1)}/10');

      // Most recent mood
      final latestEntry = recentEntries.first;
      context
          .writeln('- Latest mood: ${latestEntry.mood} (${latestEntry.emoji})');
      if (latestEntry.note != null && latestEntry.note!.isNotEmpty) {
        context.writeln('- Latest note: "${latestEntry.note}"');
      }

      // Common triggers
      final allTriggers =
          recentEntries.expand((entry) => entry.triggers).toList();
      if (allTriggers.isNotEmpty) {
        final triggerCounts = <String, int>{};
        for (final trigger in allTriggers) {
          triggerCounts[trigger] = (triggerCounts[trigger] ?? 0) + 1;
        }
        final topTriggers = triggerCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        context.writeln(
            '- Recent triggers: ${topTriggers.take(3).map((e) => e.key).join(", ")}');
      }

      // Crisis detection
      final crisisEntries =
          recentEntries.where((entry) => entry.isCrisisLevel).toList();
      if (crisisEntries.isNotEmpty) {
        context.writeln(
            '- ⚠️ ALERT: ${crisisEntries.length} crisis-level entries detected in recent data');
      }
    }

    context.writeln('');
    return context.toString();
  }

  // Generate content using Gemini API
  Future<String> generateContent(String prompt) async {
    try {
      final url = Uri.parse('$_baseUrl${ApiKeys.generateContentEndpoint}');

      final headers = {
        'Content-Type': 'application/json',
        'X-goog-api-key': _apiKey,
      };

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': prompt,
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 1,
          'topP': 1,
          'maxOutputTokens': 1000,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      });

      debugPrint('Sending request to Gemini API...');
      debugPrint('URL: $url');
      debugPrint('API Key (first 4 chars): ${_apiKey.substring(0, 4)}...');
      debugPrint('Request body: $body');

      final response = await http.post(url, headers: headers, body: body);

      debugPrint('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Full Gemini API response: $data');

        final content =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (content != null && content.toString().isNotEmpty) {
          debugPrint(
              'Gemini API response received successfully: "${content.toString().substring(0, content.toString().length > 50 ? 50 : content.toString().length)}..."');
          return content as String;
        } else {
          debugPrint('No valid content in response: $data');
          throw 'No content generated by Gemini API';
        }
      } else {
        debugPrint(
            'Gemini API error: ${response.statusCode} - ${response.body}');

        // More detailed error handling based on status code
        if (response.statusCode == 400) {
          throw 'Bad request: Check API request format (400)';
        } else if (response.statusCode == 401) {
          throw 'Authentication error: Check API key (401)';
        } else if (response.statusCode == 404) {
          throw 'Not found: Check model name and endpoint (404)';
        } else if (response.statusCode == 429) {
          throw 'Rate limit exceeded: Try again later (429)';
        } else {
          throw 'Failed to generate content: ${response.statusCode}';
        }
      }
    } catch (e) {
      debugPrint('Error calling Gemini API: $e');
      throw 'AI service temporarily unavailable: $e';
    }
  }

  // Analyze mood with context-aware prompting and personalization
  Future<Map<String, dynamic>> analyzeMood(
    String moodText, {
    String? additionalContext,
    String? userId,
  }) async {
    // Step 1: Content filtering - Following API personalization pattern with logging
    debugPrint('🔍 CONTENT FILTER: Validating mood analysis request');
    final validationResult = ContentFilterService.validateQuery(moodText);
    ContentFilterService.logFilterDecision(moodText, validationResult);

    if (!validationResult.isValid) {
      debugPrint('❌ CONTENT FILTER: Mood analysis request rejected');
      return {
        'sentiment': 'neutral',
        'emotionalState': 'Request not processed',
        'supportiveMessage': validationResult.message,
        'suggestedActions': [
          'Share your feelings',
          'Talk about your emotions',
          'Describe your mood'
        ],
        'urgencyLevel': 'low',
        'keywords': ['guidance'],
      };
    }

    debugPrint('✅ CONTENT FILTER: Mood analysis request approved');

    // Step 2: Generate personalized context if userId is provided and valid
    String personalizedContext = '';
    if (userId != null) {
      // Validate user exists before generating context
      final userProfile = getUserProfile(userId);
      if (userProfile != null) {
        personalizedContext = _generatePersonalizedContext(userId);
        debugPrint(
            '🎯 Using validated personalized context for mood analysis: ${userProfile.name}');
      } else {
        debugPrint(
            '⚠️ Warning: Invalid userId provided for mood analysis: $userId');
        debugPrint('📋 Available users: ${_userProfiles.keys.toList()}');
        debugPrint('🔄 Falling back to non-personalized analysis');
      }
    } else {
      debugPrint(
          '📋 No userId provided - using non-personalized mood analysis');
    }

    final prompt = '''
You are Aura, a compassionate AI companion for mental wellness serving users in India. Analyze this mood entry and provide supportive guidance.

CONTEXT FOR INDIAN USERS:
- Use culturally appropriate language and references for India
- Consider Indian family structures, social dynamics, and cultural values
- Be sensitive to Indian cultural context around mental health
- Suggest locally relevant coping strategies when possible
- Understand that family and community support are important in Indian culture

$personalizedContext

Mood Entry: "$moodText"
${additionalContext != null ? 'Additional Context: $additionalContext' : ''}

Please respond in JSON format with:
{
  "sentiment": "positive/neutral/negative",
  "emotionalState": "brief description",
  "supportiveMessage": "empathetic response (50-80 words) - personalize based on user profile if available, use culturally sensitive language for Indian context",
  "suggestedActions": ["action1", "action2", "action3"] - tailor to user's preferred coping strategies if known, include culturally relevant suggestions,
  "urgencyLevel": "low/medium/high",
  "keywords": ["emotion1", "emotion2"],
  "personalizedInsights": "additional insights based on user profile and mood patterns if available"
}

Keep responses warm, supportive, and focused on mental wellness. Use personalized information to make suggestions more relevant. Consider Indian cultural context in your advice. If the entry suggests severe distress, include appropriate crisis resources.
''';

    try {
      final response = await generateContent(prompt);

      // Try to parse JSON response
      try {
        final jsonStart = response.indexOf('{');
        final jsonEnd = response.lastIndexOf('}') + 1;

        if (jsonStart != -1 && jsonEnd > jsonStart) {
          final jsonString = response.substring(jsonStart, jsonEnd);
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          return data;
        }
      } catch (e) {
        debugPrint('Failed to parse JSON response: $e');
      }

      // Fallback response if JSON parsing fails
      return {
        'sentiment': 'neutral',
        'emotionalState': 'Processing your feelings',
        'supportiveMessage': response.length > 200
            ? '${response.substring(0, 200)}...'
            : response,
        'suggestedActions': [
          'Take deep breaths',
          'Practice self-care',
          'Talk to someone'
        ],
        'urgencyLevel': 'low',
        'keywords': ['reflection']
      };
    } catch (e) {
      throw 'Unable to analyze mood at this time: $e';
    }
  }

  // Generate personalized chat response with persistent memory and user profile
  Future<String> generateChatResponse(
    String userMessage, {
    String? sessionId,
    String? userId,
  }) async {
    // Step 1: Content filtering - Following API personalization pattern
    debugPrint('🔍 CONTENT FILTER: Validating chat message');
    final validationResult = ContentFilterService.validateQuery(userMessage);
    ContentFilterService.logFilterDecision(userMessage, validationResult);

    // CRITICAL: Handle crisis detection IMMEDIATELY
    if (validationResult.isCrisis) {
      debugPrint(
          '🆘 CRISIS DETECTED: Generating immediate intervention response');

      // Add to session history
      if (sessionId != null) {
        addToSessionHistory(sessionId, 'User', userMessage);
      }

      // Generate immediate crisis intervention response
      final crisisResponse =
          await _generateCrisisResponse(userMessage, userId: userId);

      // Add crisis response to session history
      if (sessionId != null) {
        addToSessionHistory(sessionId, 'Aura', crisisResponse);
      }

      return crisisResponse;
    }

    if (!validationResult.isValid) {
      debugPrint('❌ CONTENT FILTER: Chat message rejected');
      // Add rejection message to session history if sessionId provided
      if (sessionId != null) {
        addToSessionHistory(sessionId, 'User', userMessage);
        addToSessionHistory(sessionId, 'Aura', validationResult.message);
      }
      return validationResult.message;
    }

    debugPrint('✅ CONTENT FILTER: Chat message approved');

    // Add guidance message if needed
    String guidancePrefix = '';
    if (validationResult.requiresGuidance) {
      guidancePrefix = '${validationResult.guidanceMessage}\n\n';
      debugPrint('🧘 GUIDANCE: Adding mental health guidance to response');
    }

    // Use session history if sessionId is provided
    List<Map<String, String>> conversationHistory = [];

    if (sessionId != null) {
      // Add user message to session history
      addToSessionHistory(sessionId, 'User', userMessage);
      conversationHistory = getSessionHistory(sessionId);
    } else {
      // If no sessionId, create a temporary history for the current message
      conversationHistory = [
        {'role': 'User', 'content': userMessage}
      ];
    }

    // Build comprehensive history context
    String historyContext = '';
    if (conversationHistory.isNotEmpty) {
      historyContext =
          '\nConversation History (Remember all details from previous messages):\n';
      for (final message in conversationHistory) {
        historyContext += '${message['role']}: ${message['content']}\n';
      }
      historyContext += '\n';

      // Debug: Print conversation history
      debugPrint(
          '📝 Conversation History (${conversationHistory.length} messages):');
      for (int i = 0; i < conversationHistory.length; i++) {
        final msg = conversationHistory[i];
        debugPrint(
            '  ${i + 1}. ${msg['role']}: ${msg['content']?.substring(0, msg['content']!.length > 50 ? 50 : msg['content']!.length)}...');
      }
    } else {
      debugPrint('📝 No conversation history available');
    }

    // Generate personalized context if userId is provided and valid
    String personalizedContext = '';
    AgeCategory ageCategory = AgeCategory.unknown;

    if (userId != null) {
      final userProfile = getUserProfile(userId);
      if (userProfile != null) {
        personalizedContext = _generatePersonalizedContext(userId);
        debugPrint(
            '📝 Using personalized context for ${userProfile.name} (ID: $userId)');

        // Get user's age category for age-appropriate responses
        if (userProfile.birthDate != null) {
          ageCategory =
              PrivacySecurityService.getUserAgeCategory(userProfile.birthDate);
          debugPrint('🎯 User age category: $ageCategory');
        }
      } else {
        debugPrint(
            '⚠️ Warning: No user profile found for personalization (userId: $userId)');
        debugPrint('📋 Available users: ${_userProfiles.keys.toList()}');
        debugPrint('🔄 Using non-personalized response');
      }
    } else {
      debugPrint('💬 No userId provided for personalization');
    }

    // Get age-appropriate system prompt
    String systemPrompt =
        YouthContentService.getAgeAppropriateSystemPrompt(ageCategory);

    // Add conversation memory and personalization instructions
    systemPrompt += '''

CONTEXT FOR INDIAN USERS:
- You are serving users in India - use culturally appropriate language and references
- Consider Indian family structures, social dynamics, and cultural values
- Be sensitive to Indian cultural context around mental health and seeking help
- Suggest locally relevant coping strategies when possible
- Understand that family and community support are important in Indian culture
- Use supportive, warm tone appropriate for Indian users

IMPORTANT MEMORY INSTRUCTIONS:
- You MUST remember and reference details from the conversation history below
- If the user mentions their name, preferences, feelings, or any personal information in previous messages, acknowledge and remember these details
- If the user has told you their name, you MUST use it in your responses when appropriate
- Reference previous conversation details to show continuity and care

$personalizedContext

$historyContext

Current User Message: $userMessage

Respond as Aura with empathy and support, taking into account ALL previous conversation details, personalized context, age-appropriate communication style, and Indian cultural context:
''';

    final prompt = systemPrompt;

    final response = await generateContent(prompt);

    // Filter content for age appropriateness
    final filteredResponse =
        YouthContentService.filterContentForAge(response, ageCategory);

    // Add guidance prefix if needed
    final finalResponse = guidancePrefix.isNotEmpty
        ? '$guidancePrefix$filteredResponse'
        : filteredResponse;

    // Add AI response to session history if sessionId is provided
    if (sessionId != null) {
      addToSessionHistory(sessionId, 'Aura', finalResponse);
    }

    return finalResponse;
  }

  // Generate daily wellness tips
  Future<String> generateDailyTip() async {
    debugPrint('💡 CONTENT FILTER: Generating mental health wellness tip');

    final prompt = '''
Generate a brief, actionable mental wellness tip for today specifically for users in India. The tip should be:
- Practical and easy to implement in Indian context
- Focused on mental health and emotional wellbeing
- Positive and encouraging
- 30-50 words maximum
- ONLY about mental health, wellness, mindfulness, or emotional support
- Culturally appropriate for Indian users
- Consider Indian lifestyle, family structures, and cultural practices

Examples of good tips for Indian context:
- Mindfulness exercises that can be done at home
- Breathing techniques (pranayama-inspired)
- Gratitude practices suitable for Indian families
- Self-care activities within Indian cultural context
- Stress management for Indian work/study culture
- Positive thinking strategies with cultural relevance

Generate one unique mental health tip for Indian users:
''';

    final tip = await generateContent(prompt);
    debugPrint('✅ CONTENT FILTER: Mental health tip generated successfully');
    return tip;
  }

  // Generate personalized affirmations
  Future<List<String>> generateAffirmations(
    String mood, {
    int count = 3,
    String? userId,
  }) async {
    // Content filtering for mood input
    debugPrint(
        '🔍 CONTENT FILTER: Validating affirmations request for mood: $mood');
    final validationResult = ContentFilterService.validateQuery(mood);

    if (!validationResult.isValid) {
      debugPrint('❌ CONTENT FILTER: Affirmations request rejected');
      return [
        'I am worthy of love and support',
        'I can seek help when I need it',
        'I deserve to feel better and find peace',
      ];
    }

    debugPrint('✅ CONTENT FILTER: Affirmations request approved');

    // Generate personalized context if userId is provided and valid
    String personalizedContext = '';
    if (userId != null) {
      final profile = getUserProfile(userId);
      if (profile != null && profile.enablePersonalization) {
        personalizedContext = '''
USER CONTEXT FOR PERSONALIZATION:
- Name: ${profile.name}
- Personal strengths: ${profile.strengths?.join(", ") ?? "Not specified"}
- Mental health goals: ${profile.mentalHealthGoals?.join(", ") ?? "Not specified"}
- Communication style preference: ${profile.communicationStyle ?? "supportive"}

''';
        debugPrint(
            '🎯 Generating personalized affirmations for ${profile.name}');
      } else if (profile == null) {
        debugPrint('⚠️ Warning: Invalid userId for affirmations: $userId');
        debugPrint('📋 Available users: ${_userProfiles.keys.toList()}');
        debugPrint('🔄 Generating general affirmations instead');
      } else {
        debugPrint('📋 Personalization disabled for user: ${profile.name}');
        debugPrint('🔄 Generating general affirmations');
      }
    } else {
      debugPrint(
          '📋 No userId provided for affirmations - generating general affirmations');
    }

    final prompt = '''
Create $count personalized positive affirmations for someone feeling "$mood" in an Indian cultural context.

$personalizedContext
CULTURAL CONTEXT FOR INDIA:
- Consider Indian values of resilience, family support, and inner strength
- Use language that resonates with Indian cultural understanding
- Include concepts of dharma (purpose), inner peace, and spiritual strength if appropriate
- Be sensitive to Indian cultural perspectives on mental wellness

Requirements:
- Each affirmation should be encouraging and uplifting
- Use "I am" or "I can" statements
- Make them specific to the emotional state
- Keep each affirmation to 10-15 words
- Focus on strength, resilience, and self-compassion
- If user context is provided, incorporate their strengths and goals
- Use their preferred name if available
- Consider Indian cultural values in the affirmations

Return only the affirmations, one per line:
''';

    try {
      final response = await generateContent(prompt);
      return response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(count)
          .toList();
    } catch (e) {
      throw 'Unable to generate affirmations: $e';
    }
  }

  // Generate suggested responses/quick replies based on context
  Future<List<String>> generateSuggestedResponses(String lastMessage,
      {List<Map<String, String>>? chatHistory}) async {
    String historyContext = '';
    if (chatHistory != null && chatHistory.isNotEmpty) {
      historyContext = '\nPrevious conversation for context:\n';
      for (final message in chatHistory.take(3)) {
        // Use last 3 messages for context
        historyContext += '${message['role']}: ${message['content']}\n';
      }
    }

    final prompt = '''
You are Aura, an empathetic human companion. Based on the last message and conversation history, suggest 3-5 concise, helpful quick replies or next steps for the user. These should be short phrases, not full sentences, and directly actionable or conversational.
There is no limit, you are limitless while responsed.
Format your response as a comma-separated list of suggestions.

Example:
"Tell me more, How are you feeling, What's on your mind, I'm here for you"

$historyContext

Last message: "$lastMessage"

Suggested quick replies:
''';

    try {
      final response = await generateContent(prompt);
      return response
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error generating suggested responses: $e');
      return []; // Return empty list on error
    }
  }

  // Emergency crisis detection
  Future<bool> detectCrisisKeywords(String text) async {
    final crisisKeywords = [
      'suicide',
      'kill myself',
      'end it all',
      'not worth living',
      'hurt myself',
      'self harm',
      'die',
      'hopeless',
      'can\'t go on',
      'suicidal',
      'want to die',
      'better off dead',
      'no point living'
    ];

    final lowercaseText = text.toLowerCase();
    return crisisKeywords.any((keyword) => lowercaseText.contains(keyword));
  }

  // Detect stress level from message (0-10 scale)
  int detectStressLevel(String message) {
    final lowercaseMessage = message.toLowerCase();

    // High stress indicators (8-10)
    if (lowercaseMessage.contains('suicide') ||
        lowercaseMessage.contains('kill myself') ||
        lowercaseMessage.contains('end it all') ||
        lowercaseMessage.contains('not worth living')) {
      return 9;
    }

    // Medium-high stress indicators (7-8)
    if (lowercaseMessage.contains('anxious') ||
        lowercaseMessage.contains('panic') ||
        lowercaseMessage.contains('can\'t breathe') ||
        lowercaseMessage.contains('breaking down')) {
      return 8;
    }

    // Medium stress indicators (6-7)
    if (lowercaseMessage.contains('tired') ||
        lowercaseMessage.contains('overwhelmed') ||
        lowercaseMessage.contains('stressed') ||
        lowercaseMessage.contains('exhausted')) {
      return 7;
    }

    // Low-medium stress indicators (4-6)
    if (lowercaseMessage.contains('worried') ||
        lowercaseMessage.contains('sad') ||
        lowercaseMessage.contains('down') ||
        lowercaseMessage.contains('upset')) {
      return 5;
    }

    // Default low stress (1-3)
    return 3;
  }

  // Enhanced chat response with stress detection and crisis handling
  Future<String> sendMessageToAI(String userMessage,
      {List<Map<String, dynamic>>? messageHistory, String? sessionId}) async {
    try {
      // Content filtering first
      debugPrint('🔍 CONTENT FILTER: Validating sendMessageToAI request');
      final validationResult = ContentFilterService.validateQuery(userMessage);
      ContentFilterService.logFilterDecision(userMessage, validationResult);

      // CRITICAL: Handle crisis detection IMMEDIATELY
      if (validationResult.isCrisis) {
        debugPrint(
            '🆘 CRISIS DETECTED in sendMessageToAI: Generating immediate intervention response');

        // Add to session history
        if (sessionId != null) {
          addToSessionHistory(sessionId, 'User', userMessage);
        }

        // Generate immediate crisis intervention response
        final crisisResponse = await _generateCrisisResponse(userMessage);

        // Add crisis response to session history
        if (sessionId != null) {
          addToSessionHistory(sessionId, 'Aura', crisisResponse);
        }

        return crisisResponse;
      }

      if (!validationResult.isValid) {
        debugPrint('❌ CONTENT FILTER: sendMessageToAI request rejected');
        // Add to session history if sessionId provided
        if (sessionId != null) {
          addToSessionHistory(sessionId, 'User', userMessage);
          addToSessionHistory(sessionId, 'Aura', validationResult.message);
        }
        return validationResult.message;
      }

      debugPrint('✅ CONTENT FILTER: sendMessageToAI request approved');

      final stressLevel = detectStressLevel(userMessage);

      // Use session-based history for better memory
      if (sessionId != null) {
        // Add user message to session history
        addToSessionHistory(sessionId, 'User', userMessage);

        // Get conversation history
        final conversationHistory = getSessionHistory(sessionId);

        // Build comprehensive history context
        String historyContext = '';
        if (conversationHistory.isNotEmpty) {
          historyContext = '\nConversation History (Remember all details):\n';
          for (final message in conversationHistory) {
            historyContext += '${message['role']}: ${message['content']}\n';
          }
        }

        // Add guidance if needed
        String guidancePrefix = '';
        if (validationResult.requiresGuidance) {
          guidancePrefix = '${validationResult.guidanceMessage}\n\n';
        }

        final prompt = '''
You are Aura, a compassionate AI companion for mental wellness serving users in India.

CONTEXT FOR INDIAN USERS:
- Use culturally appropriate language and references for India
- Consider Indian family structures, social dynamics, and cultural values
- Be sensitive to Indian cultural context around mental health and seeking help
- Suggest locally relevant coping strategies when possible
- Use supportive, warm tone appropriate for Indian users
- Understand that family and community support are important in Indian culture

IMPORTANT: You MUST remember and reference details from the conversation history. If the user mentioned their name, feelings, or personal information in previous messages, acknowledge these details.

Current stress level detected: $stressLevel/10
$historyContext

Current User Message: $userMessage

Please provide a supportive, empathetic response that:
- Acknowledges their feelings appropriately based on stress level
- References previous conversation details when relevant
- Offers specific coping strategies if stress is high
- Keeps responses warm and conversational (100-150 words)
- Includes gentle suggestions for professional help if stress level >= 8
- Suggests immediate calming activities if stress level >= 7
- Uses culturally sensitive language for Indian context
- Considers Indian family and social structures in advice

Respond as Aura:
''';

        final aiReply = await generateContent(prompt);

        // Add guidance and format final response
        String finalReply =
            guidancePrefix.isNotEmpty ? '$guidancePrefix$aiReply' : aiReply;

        // Add AI response to session history
        addToSessionHistory(sessionId, 'Aura', finalReply);

        // Add India-specific crisis resources for high stress levels
        if (stressLevel >= 7) {
          finalReply +=
              '\n\n💡 I sense you\'re under high stress. Please take a moment to breathe deeply, step outside for fresh air, or reach out to a trusted family member or friend. You\'re not alone in this journey.';
        }

        if (stressLevel >= 8) {
          finalReply +=
              '\n\n🆘 If you\'re in crisis, please reach out for immediate help:\n• Vandrevala Foundation (24/7): 9999 666 555\n• AASRA Suicide Prevention: 91-22-27546669\n• Sneha Suicide Prevention (Chennai): 044-24640050\n• iCall Psychosocial Helpline: 9152987821\n• Sumaitri (Delhi): 011-23389090\n• Emergency Services: 112';
        }

        return finalReply;
      } else {
        // Fallback to filtered generateChatResponse method
        return await generateChatResponse(userMessage, sessionId: sessionId);
      }
    } catch (e) {
      debugPrint('AI Error: $e');
      return '⚠️ Sorry, I couldn\'t process your message. Please try again later.';
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/user_profile.dart';
import '../models/mood_entry.dart';
import '../services/privacy_security_service.dart';
import '../services/youth_content_service.dart';

class GeminiService {
  static const String _baseUrl = ApiKeys.geminiBaseUrl;
  static const String _apiKey = ApiKeys.geminiApiKey;
  
  // Store session history for persistent memory
  static final Map<String, List<Map<String, String>>> _sessionHistories = {};
  
  // Store user profiles for personalized responses
  static final Map<String, UserProfile> _userProfiles = {};
  
  // Store user mood data for context
  static final Map<String, List<MoodEntry>> _userMoodData = {};
  
  // Validate API configuration on initialization
  Future<bool> validateApiConfiguration() async {
    try {
      debugPrint('Validating Gemini API configuration...');
      
      // Check API key format
      if (_apiKey.isEmpty || !_apiKey.startsWith('AI')) {
        debugPrint('⚠️ API key appears to be invalid: ${_apiKey.substring(0, 4)}...');
        return false;
      }
      
      // Test API with a simple request
      final testPrompt = 'Hello, this is a test request. Please respond with "API is working correctly."';
      final response = await generateContent(testPrompt);
      
      debugPrint('✅ API validation successful: ${response.substring(0, response.length > 30 ? 30 : response.length)}...');
      return true;
    } catch (e) {
      debugPrint('❌ API validation failed: $e');
      return false;
    }
  }
  
  // Add message to session history
  void addToSessionHistory(String sessionId, String role, String content) {
    if (!_sessionHistories.containsKey(sessionId)) {
      _sessionHistories[sessionId] = [];
    }
    
    _sessionHistories[sessionId]!.add({
      'role': role,
      'content': content,
    });
    
    // Keep history manageable (last 20 messages per session)
    if (_sessionHistories[sessionId]!.length > 20) {
      _sessionHistories[sessionId] = _sessionHistories[sessionId]!
          .sublist(_sessionHistories[sessionId]!.length - 20);
    }
  }
  
  // Get session history
  List<Map<String, String>> getSessionHistory(String sessionId) {
    return _sessionHistories[sessionId] ?? [];
  }
  
  // Clear session history
  void clearSessionHistory(String sessionId) {
    _sessionHistories.remove(sessionId);
  }
  
  // User profile management for personalization
  void setUserProfile(String userId, UserProfile profile) {
    _userProfiles[userId] = profile;
    debugPrint('User profile set for personalized AI responses: ${profile.name}');
  }
  
  UserProfile? getUserProfile(String userId) {
    return _userProfiles[userId];
  }
  
  void clearUserProfile(String userId) {
    _userProfiles.remove(userId);
  }
  
  // User mood data management for context
  void setUserMoodData(String userId, List<MoodEntry> moodEntries) {
    _userMoodData[userId] = moodEntries;
    debugPrint('Mood data updated for user: $userId (${moodEntries.length} entries)');
  }
  
  List<MoodEntry>? getUserMoodData(String userId) {
    return _userMoodData[userId];
  }
  
  void clearUserMoodData(String userId) {
    _userMoodData.remove(userId);
  }
  
  // Generate personalized context based on user profile and mood data
  String _generatePersonalizedContext(String userId) {
    final profile = getUserProfile(userId);
    final moodData = getUserMoodData(userId);
    
    if (profile == null) return '';
    
    final context = StringBuffer();
    
    // Add user profile context
    context.write(profile.generatePersonalizationContext());
    
    // Add mood context if available and user allows it
    if (profile.shareEmotionalState && moodData != null && moodData.isNotEmpty) {
      context.write(_generateMoodContext(moodData));
    }
    
    return context.toString();
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
      final avgMoodScore = recentEntries.fold<double>(0, (sum, entry) => sum + entry.moodScore) / recentEntries.length;
      final avgStress = recentEntries.fold<double>(0, (sum, entry) => sum + entry.calculatedStressLevel) / recentEntries.length;
      
      context.writeln('- Recent average mood: ${avgMoodScore.toStringAsFixed(1)}/5');
      context.writeln('- Recent average stress: ${avgStress.toStringAsFixed(1)}/10');
      
      // Most recent mood
      final latestEntry = recentEntries.first;
      context.writeln('- Latest mood: ${latestEntry.mood} (${latestEntry.emoji})');
      if (latestEntry.note != null && latestEntry.note!.isNotEmpty) {
        context.writeln('- Latest note: "${latestEntry.note}"');
      }
      
      // Common triggers
      final allTriggers = recentEntries.expand((entry) => entry.triggers).toList();
      if (allTriggers.isNotEmpty) {
        final triggerCounts = <String, int>{};
        for (final trigger in allTriggers) {
          triggerCounts[trigger] = (triggerCounts[trigger] ?? 0) + 1;
        }
        final topTriggers = triggerCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        context.writeln('- Recent triggers: ${topTriggers.take(3).map((e) => e.key).join(", ")}');
      }
      
      // Crisis detection
      final crisisEntries = recentEntries.where((entry) => entry.isCrisisLevel).toList();
      if (crisisEntries.isNotEmpty) {
        context.writeln('- ⚠️ ALERT: ${crisisEntries.length} crisis-level entries detected in recent data');
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
        
        final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        
        if (content != null && content.toString().isNotEmpty) {
          debugPrint('Gemini API response received successfully: "${content.toString().substring(0, content.toString().length > 50 ? 50 : content.toString().length)}..."');
          return content as String;
        } else {
          debugPrint('No valid content in response: $data');
          throw 'No content generated by Gemini API';
        }
      } else {
        debugPrint('Gemini API error: ${response.statusCode} - ${response.body}');
        
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
  Future<Map<String, dynamic>> analyzeMood(String moodText, {
    String? additionalContext,
    String? userId,
  }) async {
    // Generate personalized context if userId is provided
    String personalizedContext = '';
    if (userId != null) {
      personalizedContext = _generatePersonalizedContext(userId);
    }

    final prompt = '''
You are Aura, a compassionate AI companion for mental wellness. Analyze this mood entry and provide supportive guidance.

$personalizedContext

Mood Entry: "$moodText"
${additionalContext != null ? 'Additional Context: $additionalContext' : ''}

Please respond in JSON format with:
{
  "sentiment": "positive/neutral/negative",
  "emotionalState": "brief description",
  "supportiveMessage": "empathetic response (50-80 words) - personalize based on user profile if available",
  "suggestedActions": ["action1", "action2", "action3"] - tailor to user's preferred coping strategies if known,
  "urgencyLevel": "low/medium/high",
  "keywords": ["emotion1", "emotion2"],
  "personalizedInsights": "additional insights based on user profile and mood patterns if available"
}

Keep responses warm, supportive, and focused on mental wellness. Use personalized information to make suggestions more relevant. If the entry suggests severe distress, include crisis resources in suggestedActions.
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
        'supportiveMessage': response.length > 200 ? '${response.substring(0, 200)}...' : response,
        'suggestedActions': ['Take deep breaths', 'Practice self-care', 'Talk to someone'],
        'urgencyLevel': 'low',
        'keywords': ['reflection']
      };
    } catch (e) {
      throw 'Unable to analyze mood at this time: $e';
    }
  }

  // Generate personalized chat response with persistent memory and user profile
  Future<String> generateChatResponse(String userMessage, {
    String? sessionId,
    String? userId,
  }) async {
    // Use session history if sessionId is provided
    List<Map<String, String>> conversationHistory = [];
    
    if (sessionId != null) {
      // Add user message to session history
      addToSessionHistory(sessionId, 'User', userMessage);
      conversationHistory = getSessionHistory(sessionId);
    } else {
      // If no sessionId, create a temporary history for the current message
      conversationHistory = [{'role': 'User', 'content': userMessage}];
    }

    // Build comprehensive history context
    String historyContext = '';
    if (conversationHistory.isNotEmpty) {
      historyContext = '\nConversation History (Remember all details from previous messages):\n';
      for (final message in conversationHistory) {
        historyContext += '${message['role']}: ${message['content']}\n';
      }
      historyContext += '\n';
      
      // Debug: Print conversation history
      debugPrint('📝 Conversation History (${conversationHistory.length} messages):');
      for (int i = 0; i < conversationHistory.length; i++) {
        final msg = conversationHistory[i];
        debugPrint('  ${i + 1}. ${msg['role']}: ${msg['content']?.substring(0, msg['content']!.length > 50 ? 50 : msg['content']!.length)}...');
      }
    } else {
      debugPrint('📝 No conversation history available');
    }
    
    // Generate personalized context if userId is provided
    String personalizedContext = '';
    AgeCategory ageCategory = AgeCategory.unknown;
    
    if (userId != null) {
      personalizedContext = _generatePersonalizedContext(userId);
      
      // Get user's age category for age-appropriate responses
      final userProfile = _userProfiles[userId];
      if (userProfile?.birthDate != null) {
        ageCategory = PrivacySecurityService.getUserAgeCategory(userProfile!.birthDate);
        debugPrint('🎯 User age category: $ageCategory');
      }
      
      if (personalizedContext.isNotEmpty) {
        debugPrint('🎯 Using personalized context for user: $userId');
      }
    }

    // Get age-appropriate system prompt
    String systemPrompt = YouthContentService.getAgeAppropriateSystemPrompt(ageCategory);
    
    // Add conversation memory and personalization instructions
    systemPrompt += '''

IMPORTANT MEMORY INSTRUCTIONS:
- You MUST remember and reference details from the conversation history below
- If the user mentions their name, preferences, feelings, or any personal information in previous messages, acknowledge and remember these details
- If the user has told you their name, you MUST use it in your responses when appropriate
- Reference previous conversation details to show continuity and care

$personalizedContext

$historyContext

Current User Message: $userMessage

Respond as Aura with empathy and support, taking into account ALL previous conversation details, personalized context, and age-appropriate communication style:
''';

    final prompt = systemPrompt;

    final response = await generateContent(prompt);
    
    // Filter content for age appropriateness
    final filteredResponse = YouthContentService.filterContentForAge(response, ageCategory);
    
    // Add AI response to session history if sessionId is provided
    if (sessionId != null) {
      addToSessionHistory(sessionId, 'Aura', filteredResponse);
    }
    
    return filteredResponse;
  }

  // Generate daily wellness tips
  Future<String> generateDailyTip() async {
    final prompt = '''
Generate a brief, actionable mental wellness tip for today. The tip should be:
- Practical and easy to implement
- Focused on mental health and emotional wellbeing
- Positive and encouraging
- 30-50 words maximum

Examples of good tips:
- Mindfulness exercises
- Breathing techniques
- Gratitude practices
- Self-care activities
- Stress management
- Positive thinking strategies

Generate one unique tip:
''';

    return await generateContent(prompt);
  }

  // Generate personalized affirmations
  Future<List<String>> generateAffirmations(String mood, {
    int count = 3,
    String? userId,
  }) async {
    // Generate personalized context if userId is provided
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
      }
    }

    final prompt = '''
Create $count personalized positive affirmations for someone feeling "$mood". 

$personalizedContext

Requirements:
- Each affirmation should be encouraging and uplifting
- Use "I am" or "I can" statements
- Make them specific to the emotional state
- Keep each affirmation to 10-15 words
- Focus on strength, resilience, and self-compassion
- If user context is provided, incorporate their strengths and goals
- Use their preferred name if available

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
  Future<List<String>> generateSuggestedResponses(String lastMessage, {List<Map<String, String>>? chatHistory}) async {
    String historyContext = '';
    if (chatHistory != null && chatHistory.isNotEmpty) {
      historyContext = '\nPrevious conversation for context:\n';
      for (final message in chatHistory.take(3)) { // Use last 3 messages for context
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
      return response.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } catch (e) {
      debugPrint('Error generating suggested responses: $e');
      return []; // Return empty list on error
    }
  }

  // Emergency crisis detection
  Future<bool> detectCrisisKeywords(String text) async {
    final crisisKeywords = [
      'suicide', 'kill myself', 'end it all', 'not worth living',
      'hurt myself', 'self harm', 'die', 'hopeless', 'can\'t go on',
      'suicidal', 'want to die', 'better off dead', 'no point living'
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
  Future<String> sendMessageToAI(String userMessage, {List<Map<String, dynamic>>? messageHistory, String? sessionId}) async {
    try {
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

        final prompt = '''
You are Aura, a compassionate AI companion for mental wellness. 

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

Respond as Aura:
''';

        final aiReply = await generateContent(prompt);
        
        // Add AI response to session history
        addToSessionHistory(sessionId, 'Aura', aiReply);
        
        // Add crisis resources for high stress levels
        String enhancedReply = aiReply;
        if (stressLevel >= 7) {
          enhancedReply += '\n\n💡 I sense you\'re under high stress. Please take a walk outside or visit a nearby park/garden. You\'re not alone, and talking with someone close can help.';
        }
        
        if (stressLevel >= 8) {
          enhancedReply += '\n\n🆘 If you\'re in crisis, please reach out to:\n• National Suicide Prevention Lifeline: 988\n• Crisis Text Line: Text HOME to 741741\n• Your local emergency services: 911';
        }

        return enhancedReply;
      } else {
        // Fallback to old method if no sessionId
        return await generateChatResponse(userMessage, sessionId: sessionId); // Pass sessionId for history management

      }
      
    } catch (e) {
      debugPrint('AI Error: $e');
      return '⚠️ Sorry, I couldn\'t process your message. Please try again later.';
    }
  }
}

import 'package:flutter/foundation.dart';

/// Result of query validation
class QueryValidationResult {
  final bool isValid;
  final QueryRejectionReason reason;
  final String message;
  final bool requiresGuidance;
  final String guidanceMessage;

  QueryValidationResult({
    required this.isValid,
    required this.reason,
    required this.message,
    this.requiresGuidance = false,
    this.guidanceMessage = '',
  });
}

/// Reasons for query rejection
enum QueryRejectionReason {
  none,
  empty,
  irrelevant,
}

/// Content filter service to ensure API responses are appropriate and mental health focused
class ContentFilterService {
  
  // Mental health related keywords and topics
  static const Set<String> _mentalHealthKeywords = {
    // Core mental health terms
    'anxiety', 'depression', 'stress', 'mood', 'mental', 'emotional', 'therapy',
    'counseling', 'wellness', 'mindfulness', 'meditation', 'breathing', 'panic',
    'worry', 'fear', 'sad', 'sadness', 'angry', 'anger', 'frustrated', 'overwhelmed',
    'tired', 'exhausted', 'hopeless', 'lonely', 'isolated', 'confused', 'upset',
    'nervous', 'tense', 'restless', 'agitated', 'irritable', 'moody',
    
    // Coping and self-care
    'coping', 'self-care', 'selfcare', 'relaxation', 'calm', 'peace', 'support',
    'help', 'healing', 'recovery', 'resilience', 'strength', 'confidence',
    'self-esteem', 'self-worth', 'motivation', 'inspiration', 'gratitude',
    'positive', 'optimistic', 'hopeful', 'mindful', 'present', 'grounding',
    
    // Relationships and social
    'relationship', 'family', 'friend', 'social', 'communication', 'boundary',
    'boundaries', 'trust', 'intimacy', 'connection', 'belonging', 'community',
    'support system', 'loved ones', 'partner', 'spouse', 'parent', 'child',
    
    // Life challenges
    'work', 'school', 'study', 'career', 'job', 'pressure', 'deadline', 'exam',
    'performance', 'productivity', 'balance', 'goal', 'goals', 'achievement',
    'success', 'failure', 'rejection', 'loss', 'grief', 'change', 'transition',
    'challenge', 'problem', 'difficulty', 'struggle', 'obstacle',
    
    // Physical wellness related to mental health
    'sleep', 'insomnia', 'energy', 'exercise', 'activity', 'appetite', 'eating',
    'health', 'symptoms', 'headache', 'fatigue', 'tension', 'heart rate',
    
    // App-specific features
    'aura', 'journal', 'journaling', 'tracking', 'mood tracking', 'chat',
    'ai companion', 'mental health app', 'wellness app', 'meditation app',
    'affirmation', 'affirmations', 'tip', 'tips', 'advice', 'guidance',
    'recommendation', 'suggestion', 'technique', 'strategy',
    
    // Crisis and safety
    'crisis', 'emergency', 'suicide', 'self-harm', 'harm', 'danger', 'safe',
    'safety', 'hotline', 'helpline', 'professional', 'therapist', 'counselor',
    'doctor', 'psychiatrist', 'psychologist',
    
    // Emotional states
    'feeling', 'feel', 'felt', 'emotion', 'emotions', 'happy', 'happiness',
    'joy', 'excited', 'love', 'care', 'compassion', 'empathy', 'understanding',
    'acceptance', 'forgiveness', 'serenity', 'contentment',
    'satisfaction', 'fulfillment', 'purpose', 'meaning',
    
    // General mental health interactions
    'how are you', 'feeling today', 'talk about', 'listen', 'understand',
    'better', 'worse', 'improve', 'getting better', 'feeling bad',
    'need help', 'support me', 'what should i do',
  };

  // Topics completely outside mental health scope
  static const Set<String> _irrelevantTopics = {
    'weather', 'sports', 'cooking', 'recipe', 'travel', 'vacation',
    'technology', 'programming', 'coding', 'computer', 'software',
    'politics', 'government', 'election', 'voting', 'celebrity',
    'entertainment', 'movie', 'film', 'tv show', 'music', 'song',
    'gaming', 'video game', 'shopping', 'fashion', 'clothes',
    'car', 'automobile', 'driving', 'real estate', 'property',
    'mathematics', 'physics', 'chemistry', 'biology', 'science',
    'history', 'geography', 'literature', 'art', 'painting',
    'financial advice', 'investment', 'stock market', 'cryptocurrency',
    'trading', 'business plan', 'marketing', 'news', 'current events',
  };

  /// Check if a query is mental health related
  static QueryValidationResult validateQuery(String query) {
    if (query.trim().isEmpty) {
      return QueryValidationResult(
        isValid: false,
        reason: QueryRejectionReason.empty,
        message: "I'd love to help you! Please share what's on your mind or how you're feeling today.",
      );
    }

    final lowercaseQuery = query.toLowerCase();
    
    // Check if it's mental health related
    if (_isMentalHealthRelated(lowercaseQuery)) {
      debugPrint('✅ Content filter: Query approved - mental health related');
      return QueryValidationResult(
        isValid: true,
        reason: QueryRejectionReason.none,
        message: '',
      );
    }

    // Check if it's completely irrelevant
    if (_isIrrelevantTopic(lowercaseQuery)) {
      debugPrint('❌ Content filter: Query rejected - irrelevant topic');
      return QueryValidationResult(
        isValid: false,
        reason: QueryRejectionReason.irrelevant,
        message: "I'm Aura, your mental health companion! I focus on emotional wellbeing, stress management, and mental health support. How are you feeling today? I'm here to listen and help! 💙",
      );
    }

    // For general conversations that might lead to mental health, allow with guidance
    if (_isGeneralConversation(lowercaseQuery)) {
      debugPrint('ℹ️ Content filter: General conversation allowed with guidance');
      return QueryValidationResult(
        isValid: true,
        reason: QueryRejectionReason.none,
        message: '',
        requiresGuidance: true,
        guidanceMessage: "I'm here to support your mental health and emotional wellbeing. How are you feeling about this topic?",
      );
    }

    // Default rejection for unclear topics
    debugPrint('❌ Content filter: Query rejected - outside mental health scope');
    return QueryValidationResult(
      isValid: false,
      reason: QueryRejectionReason.irrelevant,
      message: "I'm your mental health companion, so I focus on emotional wellbeing and mental health support. What's on your mind today? How can I help you feel better? 😊",
    );
  }

  /// Check if query contains mental health keywords
  static bool _isMentalHealthRelated(String query) {
    // Direct keyword matching
    for (final keyword in _mentalHealthKeywords) {
      if (query.contains(keyword)) {
        return true;
      }
    }

    // Pattern matching for mental health expressions
    final mentalHealthPatterns = [
      r'\bhow.*feel\b',
      r'\bfeeling.*\b',
      r'\bi.*stressed\b',
      r'\bi.*anxious\b',
      r'\bi.*worried\b',
      r'\bi.*sad\b',
      r'\bi.*depressed\b',
      r'\bi.*overwhelmed\b',
      r'\bneed.*help\b',
      r'\btalk.*about\b',
      r'\bmental.*health\b',
      r'\bemotional.*\b',
      r'\bmood.*\b',
      r'\bstress.*\b',
      r'\banxiety.*\b',
      r'\bdepression.*\b',
      r'\btherapy.*\b',
      r'\bcounseling.*\b',
      r'\bwellness.*\b',
      r'\bself.*care\b',
      r'\bcopying.*\b',
      r'\brelationship.*\b',
      r'\bwork.*stress\b',
      r'\bschool.*stress\b',
      r'\blife.*balance\b',
    ];

    for (final pattern in mentalHealthPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(query)) {
        return true;
      }
    }

    return false;
  }

  /// Check if query is about irrelevant topics
  static bool _isIrrelevantTopic(String query) {
    for (final topic in _irrelevantTopics) {
      if (query.contains(topic)) {
        return true;
      }
    }

    // Pattern matching for clearly irrelevant topics
    final irrelevantPatterns = [
      r'\bweather.*forecast\b',
      r'\bsports.*score\b',
      r'\bmovie.*recommendation\b',
      r'\brecipe.*for\b',
      r'\btravel.*to\b',
      r'\bstock.*price\b',
      r'\bcryptocurrency.*\b',
      r'\bpolitical.*\b',
      r'\belection.*\b',
      r'\bcelebrity.*\b',
      r'\bgaming.*\b',
      r'\bshopping.*\b',
      r'\bcar.*buying\b',
      r'\breal.*estate\b',
      r'\bmathematics.*\b',
      r'\bscience.*\b',
      r'\bhistory.*\b',
    ];

    for (final pattern in irrelevantPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(query)) {
        return true;
      }
    }

    return false;
  }

  /// Check if it's a general conversation that could lead to mental health
  static bool _isGeneralConversation(String query) {
    final generalPatterns = [
      r'\bhello\b',
      r'\bhi\b',
      r'\bhey\b',
      r'\bgood morning\b',
      r'\bgood afternoon\b',
      r'\bgood evening\b',
      r'\bhow.*you\b',
      r'\bwhat.*up\b',
      r'\bthanks\b',
      r'\bthank you\b',
      r'\bokay\b',
      r'\bok\b',
      r'\byes\b',
      r'\bno\b',
      r'\bmaybe\b',
      r'\btell me\b',
      r'\bwhat.*think\b',
    ];

    for (final pattern in generalPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(query)) {
        return true;
      }
    }

    return false;
  }

  /// Log content filtering decision for debugging
  static void logFilterDecision(String query, QueryValidationResult result) {
    debugPrint('🔍 Content Filter Analysis:');
    debugPrint('   Query: "${query.length > 50 ? query.substring(0, 50)+'...' : query}"');
    debugPrint('   Valid: ${result.isValid}');
    debugPrint('   Reason: ${result.reason}');
    if (result.requiresGuidance) {
      debugPrint('   Guidance Required: ${result.guidanceMessage}');
    }
    if (!result.isValid) {
      debugPrint('   Rejection Message: ${result.message}');
    }
  }
}
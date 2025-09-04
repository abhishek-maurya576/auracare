import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/crisis_alert.dart';
import '../models/user_profile.dart';
import 'gemini_service.dart';

/// Crisis Intervention Service for real-time monitoring and response
/// Implements youth-focused crisis detection and immediate support protocols
class CrisisInterventionService {
  static final CrisisInterventionService _instance = CrisisInterventionService._internal();
  factory CrisisInterventionService() => _instance;
  CrisisInterventionService._internal();

  final GeminiService _geminiService = GeminiService();
  
  // Crisis detection keywords organized by severity and age group
  static const Map<String, List<String>> _crisisKeywords = {
    'suicide_high': [
      'want to die', 'kill myself', 'end it all', 'suicide', 'take my own life',
      'better off dead', 'not worth living', 'end my life', 'hurt myself badly',
      'overdose', 'jump off', 'hang myself', 'cut deep', 'bleed out'
    ],
    'suicide_medium': [
      'wish I was dead', 'disappear forever', 'stop existing', 'give up on life',
      'no point in living', 'tired of living', 'want to sleep forever',
      'everyone would be better without me', 'burden to everyone'
    ],
    'self_harm_high': [
      'cut myself', 'hurt myself', 'self-harm', 'burn myself', 'hit myself',
      'scratch until bleeding', 'pull my hair out', 'starve myself',
      'make myself throw up', 'punish myself physically'
    ],
    'self_harm_medium': [
      'want to hurt myself', 'deserve pain', 'need to feel something',
      'punish myself', 'hate my body', 'ugly and worthless'
    ],
    'youth_specific_high': [
      'can\'t handle school anymore', 'parents hate me', 'bullied every day',
      'no friends care', 'failing everything', 'disappointed everyone',
      'kicked out of home', 'nowhere to go', 'abuse at home'
    ],
    'youth_specific_medium': [
      'school is too much', 'parents don\'t understand', 'being bullied',
      'feel so alone', 'stressed about grades', 'pressure from family',
      'don\'t fit in anywhere', 'social anxiety is killing me'
    ],
    'crisis_indicators': [
      'emergency', 'help me please', 'crisis', 'urgent', 'desperate',
      'can\'t take it anymore', 'breaking point', 'losing control',
      'scared of myself', 'dangerous thoughts'
    ]
  };

  // Emergency resources organized by type and age group
  static const Map<String, Map<String, dynamic>> _emergencyResources = {
    'suicide_prevention': {
      'name': '988 Suicide & Crisis Lifeline',
      'phone': '988',
      'text': 'Text HOME to 741741',
      'chat': 'https://suicidepreventionlifeline.org/chat/',
      'description': '24/7 free and confidential support',
      'age_appropriate': [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]
    },
    'crisis_text_line': {
      'name': 'Crisis Text Line',
      'phone': null,
      'text': 'Text HOME to 741741',
      'chat': 'https://www.crisistextline.org/',
      'description': 'Free 24/7 crisis support via text',
      'age_appropriate': [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]
    },
    'trevor_project': {
      'name': 'The Trevor Project (LGBTQ+ Youth)',
      'phone': '1-866-488-7386',
      'text': 'Text START to 678-678',
      'chat': 'https://www.thetrevorproject.org/get-help/',
      'description': 'Crisis support for LGBTQ+ young people',
      'age_appropriate': [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]
    },
    'teen_line': {
      'name': 'Teen Line',
      'phone': '1-800-852-8336',
      'text': 'Text TEEN to 839863',
      'chat': 'https://teenlineonline.org/',
      'description': 'Teens helping teens',
      'age_appropriate': [13, 14, 15, 16, 17, 18, 19]
    },
    'national_domestic_violence': {
      'name': 'National Domestic Violence Hotline',
      'phone': '1-800-799-7233',
      'text': 'Text START to 88788',
      'chat': 'https://www.thehotline.org/',
      'description': 'Support for domestic violence situations',
      'age_appropriate': [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]
    },
    'eating_disorder': {
      'name': 'National Eating Disorders Association',
      'phone': '1-800-931-2237',
      'text': 'Text NEDA to 741741',
      'chat': 'https://www.nationaleatingdisorders.org/help-support/contact-helpline',
      'description': 'Support for eating disorders',
      'age_appropriate': [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]
    }
  };

  // Real-time crisis monitoring
  final StreamController<CrisisAlert> _crisisAlertController = StreamController<CrisisAlert>.broadcast();
  Stream<CrisisAlert> get crisisAlertStream => _crisisAlertController.stream;

  /// Analyze message for crisis indicators with real-time response
  Future<CrisisAnalysisResult> analyzeCrisisLevel(
    String message, {
    String? userId,
    UserProfile? userProfile,
    List<String>? conversationHistory,
  }) async {
    try {
      debugPrint('🚨 Analyzing message for crisis indicators...');
      
      // Step 1: Keyword-based rapid detection (< 1 second)
      final keywordResult = _performKeywordAnalysis(message);
      
      // Step 2: AI-powered sentiment analysis for context (< 5 seconds)
      final aiResult = await _performAIAnalysis(message, userId, userProfile, conversationHistory);
      
      // Step 3: Combine results for final assessment
      final finalResult = _combineAnalysisResults(keywordResult, aiResult, userProfile);
      
      // Step 4: Trigger immediate response if crisis detected
      if (finalResult.severityLevel >= 7) {
        await _triggerCrisisResponse(finalResult, userId, userProfile);
      }
      
      debugPrint('🚨 Crisis analysis complete: Severity ${finalResult.severityLevel}/10');
      return finalResult;
      
    } catch (e) {
      debugPrint('❌ Error in crisis analysis: $e');
      // Return safe default in case of error
      return CrisisAnalysisResult(
        severityLevel: 5,
        crisisType: CrisisType.unknown,
        confidence: 0.5,
        immediateAction: true,
        suggestedResources: _getAgeAppropriateResources(userProfile?.age),
        supportMessage: 'I\'m here to support you. If you\'re in crisis, please reach out to a professional.',
        detectedKeywords: [],
        aiInsights: 'Analysis temporarily unavailable - defaulting to safe response',
      );
    }
  }

  /// Rapid keyword-based crisis detection (< 1 second response time)
  CrisisAnalysisResult _performKeywordAnalysis(String message) {
    final lowerMessage = message.toLowerCase();
    final detectedKeywords = <String>[];
    int maxSeverity = 0;
    CrisisType primaryType = CrisisType.none;

    // Check each category of crisis keywords
    _crisisKeywords.forEach((category, keywords) {
      for (final keyword in keywords) {
        if (lowerMessage.contains(keyword.toLowerCase())) {
          detectedKeywords.add(keyword);
          
          // Assign severity based on category
          int severity = 0;
          CrisisType type = CrisisType.none;
          
          switch (category) {
            case 'suicide_high':
              severity = 10;
              type = CrisisType.suicide;
              break;
            case 'suicide_medium':
              severity = 8;
              type = CrisisType.suicide;
              break;
            case 'self_harm_high':
              severity = 9;
              type = CrisisType.selfHarm;
              break;
            case 'self_harm_medium':
              severity = 7;
              type = CrisisType.selfHarm;
              break;
            case 'youth_specific_high':
              severity = 8;
              type = CrisisType.youthCrisis;
              break;
            case 'youth_specific_medium':
              severity = 6;
              type = CrisisType.youthCrisis;
              break;
            case 'crisis_indicators':
              severity = 7;
              type = CrisisType.general;
              break;
          }
          
          if (severity > maxSeverity) {
            maxSeverity = severity;
            primaryType = type;
          }
        }
      }
    });

    return CrisisAnalysisResult(
      severityLevel: maxSeverity,
      crisisType: primaryType,
      confidence: detectedKeywords.isNotEmpty ? 0.8 : 0.0,
      immediateAction: maxSeverity >= 7,
      suggestedResources: [],
      supportMessage: '',
      detectedKeywords: detectedKeywords,
      aiInsights: '',
    );
  }

  /// AI-powered contextual analysis for nuanced crisis detection
  Future<CrisisAnalysisResult> _performAIAnalysis(
    String message,
    String? userId,
    UserProfile? userProfile,
    List<String>? conversationHistory,
  ) async {
    try {
      // Build context for AI analysis
      String context = '';
      if (userProfile != null) {
        context += 'User age: ${userProfile.age}\n';
        context += 'Communication style: ${userProfile.communicationStyle}\n';
        if (userProfile.mentalHealthChallenges?.isNotEmpty == true) {
          context += 'Known challenges: ${userProfile.mentalHealthChallenges!.join(", ")}\n';
        }
      }
      
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        context += 'Recent conversation context:\n';
        context += conversationHistory.take(3).join('\n');
        context += '\n';
      }

      final prompt = '''
You are a crisis intervention AI analyzing a message for mental health crisis indicators. 

CONTEXT:
$context

MESSAGE TO ANALYZE: "$message"

Analyze this message and respond in JSON format:
{
  "severityLevel": 0-10 (0=no concern, 10=immediate danger),
  "crisisType": "suicide|self_harm|youth_crisis|eating_disorder|abuse|general|none",
  "confidence": 0.0-1.0,
  "immediateAction": true/false,
  "aiInsights": "brief analysis of emotional state and context",
  "supportMessage": "immediate supportive response (50-80 words)",
  "recommendedActions": ["action1", "action2", "action3"]
}

CRISIS DETECTION GUIDELINES:
- Severity 8-10: Direct threats, specific plans, immediate danger
- Severity 6-7: Strong distress, concerning thoughts, needs support
- Severity 4-5: Moderate distress, general sadness
- Severity 1-3: Mild concerns, normal emotional expression
- Severity 0: No mental health concerns

Focus on youth-specific language and situations. Be sensitive to developmental stages.
''';

      final response = await _geminiService.generateContent(prompt);
      
      // Parse AI response
      try {
        final jsonStart = response.indexOf('{');
        final jsonEnd = response.lastIndexOf('}') + 1;
        
        if (jsonStart != -1 && jsonEnd > jsonStart) {
          final jsonString = response.substring(jsonStart, jsonEnd);
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          
          return CrisisAnalysisResult(
            severityLevel: (data['severityLevel'] as num?)?.toInt() ?? 0,
            crisisType: _parseCrisisType(data['crisisType'] as String?),
            confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
            immediateAction: data['immediateAction'] as bool? ?? false,
            suggestedResources: [],
            supportMessage: data['supportMessage'] as String? ?? '',
            detectedKeywords: [],
            aiInsights: data['aiInsights'] as String? ?? '',
            recommendedActions: (data['recommendedActions'] as List?)?.cast<String>() ?? [],
          );
        }
      } catch (e) {
        debugPrint('Failed to parse AI crisis analysis: $e');
      }
      
      // Fallback if parsing fails
      return CrisisAnalysisResult(
        severityLevel: 3,
        crisisType: CrisisType.general,
        confidence: 0.3,
        immediateAction: false,
        suggestedResources: [],
        supportMessage: 'I hear that you\'re going through a difficult time. I\'m here to support you.',
        detectedKeywords: [],
        aiInsights: 'AI analysis partially available',
      );
      
    } catch (e) {
      debugPrint('Error in AI crisis analysis: $e');
      return CrisisAnalysisResult(
        severityLevel: 0,
        crisisType: CrisisType.none,
        confidence: 0.0,
        immediateAction: false,
        suggestedResources: [],
        supportMessage: '',
        detectedKeywords: [],
        aiInsights: '',
      );
    }
  }

  /// Combine keyword and AI analysis results
  CrisisAnalysisResult _combineAnalysisResults(
    CrisisAnalysisResult keywordResult,
    CrisisAnalysisResult aiResult,
    UserProfile? userProfile,
  ) {
    // Take the higher severity level as primary indicator
    final finalSeverity = (keywordResult.severityLevel > aiResult.severityLevel) 
        ? keywordResult.severityLevel 
        : aiResult.severityLevel;
    
    // Combine crisis types (keyword detection takes precedence for specific types)
    final finalCrisisType = keywordResult.crisisType != CrisisType.none 
        ? keywordResult.crisisType 
        : aiResult.crisisType;
    
    // Average confidence scores
    final finalConfidence = (keywordResult.confidence + aiResult.confidence) / 2;
    
    // Immediate action if either analysis suggests it
    final immediateAction = keywordResult.immediateAction || aiResult.immediateAction;
    
    // Get age-appropriate resources
    final resources = _getAgeAppropriateResources(userProfile?.age);
    
    // Combine support messages
    String supportMessage = '';
    if (aiResult.supportMessage.isNotEmpty) {
      supportMessage = aiResult.supportMessage;
    } else if (finalSeverity >= 7) {
      supportMessage = _generateCrisisSupportMessage(finalCrisisType, userProfile);
    }

    return CrisisAnalysisResult(
      severityLevel: finalSeverity,
      crisisType: finalCrisisType,
      confidence: finalConfidence,
      immediateAction: immediateAction,
      suggestedResources: resources,
      supportMessage: supportMessage,
      detectedKeywords: keywordResult.detectedKeywords,
      aiInsights: aiResult.aiInsights,
      recommendedActions: aiResult.recommendedActions,
    );
  }

  /// Trigger immediate crisis response protocol
  Future<void> _triggerCrisisResponse(
    CrisisAnalysisResult result,
    String? userId,
    UserProfile? userProfile,
  ) async {
    debugPrint('🚨 CRISIS DETECTED - Triggering immediate response protocol');
    
    // Create crisis alert
    final alert = CrisisAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId ?? 'anonymous',
      severityLevel: result.severityLevel,
      crisisType: result.crisisType,
      timestamp: DateTime.now(),
      message: result.supportMessage,
      resources: result.suggestedResources,
      resolved: false,
    );
    
    // Broadcast crisis alert to listeners
    _crisisAlertController.add(alert);
    
    // Log crisis event (for monitoring and follow-up)
    await _logCrisisEvent(alert, userProfile);
    
    // Schedule follow-up check (24 hours later)
    _scheduleFollowUp(alert);
  }

  /// Get age-appropriate emergency resources
  List<EmergencyResource> _getAgeAppropriateResources(int? userAge) {
    final age = userAge ?? 18; // Default to 18 if age unknown
    final resources = <EmergencyResource>[];
    
    _emergencyResources.forEach((key, resourceData) {
      final ageRange = resourceData['age_appropriate'] as List<int>;
      if (ageRange.contains(age)) {
        resources.add(EmergencyResource(
          name: resourceData['name'] as String,
          phone: resourceData['phone'] as String?,
          text: resourceData['text'] as String?,
          chat: resourceData['chat'] as String?,
          description: resourceData['description'] as String,
          priority: _getResourcePriority(key),
        ));
      }
    });
    
    // Sort by priority (highest first)
    resources.sort((a, b) => b.priority.compareTo(a.priority));
    
    return resources.take(3).toList(); // Return top 3 most relevant resources
  }

  /// Get resource priority based on type
  int _getResourcePriority(String resourceType) {
    switch (resourceType) {
      case 'suicide_prevention':
        return 10;
      case 'crisis_text_line':
        return 9;
      case 'trevor_project':
        return 8;
      case 'teen_line':
        return 7;
      case 'national_domestic_violence':
        return 6;
      case 'eating_disorder':
        return 5;
      default:
        return 1;
    }
  }

  /// Generate crisis-specific support message
  String _generateCrisisSupportMessage(CrisisType crisisType, UserProfile? userProfile) {
    final name = userProfile?.name ?? 'friend';
    
    switch (crisisType) {
      case CrisisType.suicide:
        return 'I\'m really concerned about you, $name. Your life has value and meaning. Please reach out to a crisis counselor who can provide immediate support. You don\'t have to go through this alone.';
      
      case CrisisType.selfHarm:
        return 'I hear that you\'re in pain, $name. Hurting yourself isn\'t the answer, and there are people who want to help you find healthier ways to cope. Please consider reaching out to a counselor.';
      
      case CrisisType.youthCrisis:
        return 'I understand that things feel overwhelming right now, $name. Many young people face similar challenges, and there are resources specifically designed to help. You\'re not alone in this.';
      
      case CrisisType.general:
        return 'I can see you\'re going through a really difficult time, $name. It takes courage to reach out. Please consider talking to a professional who can provide the support you deserve.';
      
      default:
        return 'I\'m here to support you, $name. If you\'re in crisis, please don\'t hesitate to reach out to a professional who can help.';
    }
  }

  /// Parse crisis type from string
  CrisisType _parseCrisisType(String? typeString) {
    switch (typeString?.toLowerCase()) {
      case 'suicide':
        return CrisisType.suicide;
      case 'self_harm':
        return CrisisType.selfHarm;
      case 'youth_crisis':
        return CrisisType.youthCrisis;
      case 'eating_disorder':
        return CrisisType.eatingDisorder;
      case 'abuse':
        return CrisisType.abuse;
      case 'general':
        return CrisisType.general;
      default:
        return CrisisType.none;
    }
  }

  /// Log crisis event for monitoring and follow-up
  Future<void> _logCrisisEvent(CrisisAlert alert, UserProfile? userProfile) async {
    try {
      // In a production app, this would log to a secure database
      // For now, we'll use debug logging
      debugPrint('📊 CRISIS EVENT LOGGED:');
      debugPrint('  - User: ${alert.userId}');
      debugPrint('  - Severity: ${alert.severityLevel}/10');
      debugPrint('  - Type: ${alert.crisisType}');
      debugPrint('  - Timestamp: ${alert.timestamp}');
      debugPrint('  - Age: ${userProfile?.age ?? 'unknown'}');
      
      // TODO: Implement secure logging to Firebase with proper encryption
      // TODO: Implement professional notification system for high-severity cases
      
    } catch (e) {
      debugPrint('Error logging crisis event: $e');
    }
  }

  /// Schedule follow-up check after crisis intervention
  void _scheduleFollowUp(CrisisAlert alert) {
    Timer(const Duration(hours: 24), () {
      debugPrint('⏰ Scheduled follow-up for crisis alert: ${alert.id}');
      // TODO: Implement follow-up notification system
      // TODO: Send gentle check-in message to user
    });
  }

  /// Generate immediate crisis response with resources
  Future<CrisisResponse> generateCrisisResponse(
    CrisisAnalysisResult analysis,
    UserProfile? userProfile,
  ) async {
    try {
      // Generate personalized crisis response using AI
      final context = userProfile != null ? '''
User context:
- Name: ${userProfile.name}
- Age: ${userProfile.age}
- Communication style: ${userProfile.communicationStyle}
- Preferred coping strategies: ${userProfile.copingStrategies?.join(", ") ?? "Not specified"}
''' : '';

      final prompt = '''
Generate an immediate, compassionate crisis response for someone experiencing ${analysis.crisisType} with severity level ${analysis.severityLevel}/10.

$context

Crisis insights: ${analysis.aiInsights}

Create a response that:
1. Validates their feelings without judgment
2. Provides immediate comfort and hope
3. Gently encourages professional help
4. Uses age-appropriate language for youth (13-25)
5. Is 80-120 words
6. Includes a specific call-to-action

Focus on:
- Immediate safety and support
- Hope and connection
- Professional resources
- Youth-friendly language
- Cultural sensitivity
''';

      final aiResponse = await _geminiService.generateContent(prompt);
      
      return CrisisResponse(
        immediateMessage: aiResponse,
        resources: analysis.suggestedResources,
        followUpActions: [
          'Connect with a crisis counselor immediately',
          'Reach out to a trusted adult or friend',
          'Create a safety plan with professional help',
          'Consider ongoing mental health support',
        ],
        safetyPlan: _generateBasicSafetyPlan(analysis.crisisType),
        urgencyLevel: analysis.severityLevel >= 8 ? 'IMMEDIATE' : 'HIGH',
      );
      
    } catch (e) {
      debugPrint('Error generating crisis response: $e');
      
      // Fallback crisis response
      return CrisisResponse(
        immediateMessage: 'I\'m really concerned about you and want to help. Please reach out to a crisis counselor immediately - they have the training and resources to support you through this difficult time. Your life matters.',
        resources: analysis.suggestedResources,
        followUpActions: [
          'Call 988 (Suicide & Crisis Lifeline) immediately',
          'Text HOME to 741741 (Crisis Text Line)',
          'Go to your nearest emergency room if in immediate danger',
          'Call 911 if you are in immediate danger',
        ],
        safetyPlan: _generateBasicSafetyPlan(analysis.crisisType),
        urgencyLevel: 'IMMEDIATE',
      );
    }
  }

  /// Generate basic safety plan based on crisis type
  List<String> _generateBasicSafetyPlan(CrisisType crisisType) {
    switch (crisisType) {
      case CrisisType.suicide:
        return [
          'Remove or secure any means of self-harm',
          'Stay with trusted friends or family',
          'Call crisis hotline when feeling unsafe',
          'Go to emergency room if thoughts become overwhelming',
          'Create list of reasons to live',
          'Identify warning signs and triggers',
        ];
      
      case CrisisType.selfHarm:
        return [
          'Remove sharp objects and harmful items',
          'Use ice cubes or rubber band as alternatives',
          'Call a friend or crisis line when urges arise',
          'Practice deep breathing or grounding techniques',
          'Engage in physical activity or creative expression',
          'Seek professional help for coping strategies',
        ];
      
      case CrisisType.youthCrisis:
        return [
          'Talk to a trusted adult (parent, teacher, counselor)',
          'Reach out to school counseling services',
          'Connect with peer support groups',
          'Practice stress management techniques',
          'Create a daily routine for stability',
          'Consider family or individual therapy',
        ];
      
      default:
        return [
          'Reach out to trusted friends or family',
          'Contact mental health professionals',
          'Use crisis hotlines when needed',
          'Practice self-care and coping strategies',
          'Create a support network',
          'Develop healthy daily routines',
        ];
    }
  }

  /// Dispose of resources
  void dispose() {
    _crisisAlertController.close();
  }
}

/// Crisis analysis result containing all assessment data
class CrisisAnalysisResult {
  final int severityLevel; // 0-10 scale
  final CrisisType crisisType;
  final double confidence; // 0.0-1.0
  final bool immediateAction;
  final List<EmergencyResource> suggestedResources;
  final String supportMessage;
  final List<String> detectedKeywords;
  final String aiInsights;
  final List<String> recommendedActions;

  CrisisAnalysisResult({
    required this.severityLevel,
    required this.crisisType,
    required this.confidence,
    required this.immediateAction,
    required this.suggestedResources,
    required this.supportMessage,
    required this.detectedKeywords,
    required this.aiInsights,
    this.recommendedActions = const [],
  });
}

/// Crisis response with immediate support and resources
class CrisisResponse {
  final String immediateMessage;
  final List<EmergencyResource> resources;
  final List<String> followUpActions;
  final List<String> safetyPlan;
  final String urgencyLevel;

  CrisisResponse({
    required this.immediateMessage,
    required this.resources,
    required this.followUpActions,
    required this.safetyPlan,
    required this.urgencyLevel,
  });
}

/// Emergency resource information
class EmergencyResource {
  final String name;
  final String? phone;
  final String? text;
  final String? chat;
  final String description;
  final int priority;

  EmergencyResource({
    required this.name,
    this.phone,
    this.text,
    this.chat,
    required this.description,
    required this.priority,
  });
}

/// Types of mental health crises
enum CrisisType {
  none,
  suicide,
  selfHarm,
  youthCrisis,
  eatingDisorder,
  abuse,
  general,
  unknown,
}
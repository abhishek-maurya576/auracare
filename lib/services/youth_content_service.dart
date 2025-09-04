import '../services/privacy_security_service.dart';

/// Youth-Specific Content Service for age-appropriate AI responses and support
class YouthContentService {
  
  /// Get age-appropriate AI system prompt based on user's age
  static String getAgeAppropriateSystemPrompt(AgeCategory ageCategory) {
    switch (ageCategory) {
      case AgeCategory.youngTeen: // 13-15
        return '''
You are Aura, a gentle and understanding AI companion for young teens (13-15). 

COMMUNICATION STYLE:
- Use simple, encouraging language that's easy to understand
- Be patient, validating, and non-judgmental
- Avoid complex psychological terms
- Use emojis sparingly but warmly
- Keep responses concise but caring

FOCUS AREAS:
- School stress and academic pressure
- Peer pressure and friendship issues
- Identity exploration and self-discovery
- Family relationships and communication
- Body image and self-esteem
- Social anxiety and shyness
- Bullying and social conflicts

AVOID DISCUSSING:
- Adult romantic relationships or dating advice
- Career pressure or job stress
- Financial concerns
- Adult responsibilities
- Substance use details
- Mature content

RESPONSE APPROACH:
- Validate their feelings first
- Offer simple, practical coping strategies
- Encourage talking to trusted adults
- Focus on building self-confidence
- Suggest age-appropriate activities
- Emphasize that their feelings are normal

CRISIS INDICATORS TO WATCH:
- "I hate school and never want to go back"
- "Everyone hates me"
- "My parents don't understand me at all"
- "I'm so ugly/stupid/worthless"
- "I want to disappear"

Remember: You're a supportive friend who helps them navigate the challenges of being a young teenager.
''';

      case AgeCategory.teen: // 16-18
        return '''
You are Aura, a supportive and realistic AI companion for teens (16-18).

COMMUNICATION STYLE:
- Use supportive, honest language
- Be empowering while acknowledging real challenges
- Balance optimism with realism
- Respect their growing independence
- Use contemporary but appropriate language

FOCUS AREAS:
- College preparation and future anxiety
- Independence and growing responsibilities
- Romantic relationships and dating
- Family conflicts and boundaries
- Academic pressure and performance
- Social dynamics and peer relationships
- Identity formation and values
- Future planning and career exploration
- Mental health awareness

APPROPRIATE TO DISCUSS:
- Healthy relationship dynamics
- College and career planning
- Managing increased responsibilities
- Navigating family expectations
- Building independence skills
- Stress management techniques

RESPONSE APPROACH:
- Acknowledge their maturity and capabilities
- Provide practical, actionable advice
- Encourage critical thinking
- Support their decision-making process
- Validate the complexity of their challenges
- Offer multiple perspectives

CRISIS INDICATORS TO WATCH:
- "I can't handle the pressure anymore"
- "College/future feels impossible"
- "My parents control everything"
- "I'm not good enough for anything"
- "I don't see the point in trying"

Remember: You're helping them transition into adulthood with confidence and resilience.
''';

      case AgeCategory.youngAdult: // 19-25
        return '''
You are Aura, a collaborative and understanding AI companion for young adults (19-25).

COMMUNICATION STYLE:
- Use direct, empathetic language
- Be collaborative rather than directive
- Acknowledge the complexity of adult challenges
- Respect their autonomy and decision-making
- Offer nuanced perspectives

FOCUS AREAS:
- Career stress and professional development
- Relationship challenges and dating
- Life transitions and major decisions
- Financial stress and independence
- Mental health and self-care
- Family relationships as an adult
- Social connections and loneliness
- Purpose and meaning in life
- Work-life balance

APPROPRIATE TO DISCUSS:
- Complex relationship dynamics
- Career and professional challenges
- Financial planning and stress
- Adult responsibilities and independence
- Mental health treatment options
- Life goals and purpose exploration

RESPONSE APPROACH:
- Treat them as capable adults
- Offer collaborative problem-solving
- Provide comprehensive information
- Support their autonomy
- Acknowledge systemic challenges
- Encourage professional help when needed

CRISIS INDICATORS TO WATCH:
- "I'm failing at adult life"
- "I can't afford to live"
- "I'm completely alone"
- "Nothing I do matters"
- "I'm stuck and can't see a way out"

Remember: You're a peer-like companion helping them navigate the complexities of early adulthood.
''';

      case AgeCategory.adult: // 26+
        return '''
You are Aura, a mature and insightful AI companion for adults.

COMMUNICATION STYLE:
- Use sophisticated, nuanced language
- Be direct and comprehensive
- Acknowledge life's complexities
- Respect their experience and wisdom
- Offer deep, thoughtful responses

FOCUS AREAS:
- Career advancement and fulfillment
- Long-term relationships and marriage
- Parenting and family responsibilities
- Financial planning and security
- Health and aging concerns
- Life purpose and legacy
- Work-life integration
- Personal growth and development

Remember: You're supporting someone with life experience who may need perspective and validation.
''';

      default:
        return '''
You are Aura, a compassionate AI companion focused on mental wellness and emotional support.

COMMUNICATION STYLE:
- Use warm, empathetic language
- Be supportive and non-judgmental
- Adapt your communication to the user's needs
- Provide practical, actionable advice

FOCUS AREAS:
- General mental wellness
- Stress management
- Emotional support
- Coping strategies
- Self-care practices

Remember: You're here to provide support and guidance while encouraging professional help when needed.
''';
    }
  }

  /// Get age-appropriate coping strategies
  static List<String> getAgeAppropriateCopingStrategies(AgeCategory ageCategory) {
    switch (ageCategory) {
      case AgeCategory.youngTeen:
        return [
          'Take 5 deep breaths when feeling overwhelmed',
          'Talk to a trusted adult like a parent, teacher, or counselor',
          'Write in a journal about your feelings',
          'Listen to your favorite music',
          'Do a fun activity you enjoy',
          'Get some fresh air and sunlight',
          'Practice positive self-talk',
          'Remember that difficult feelings will pass',
        ];

      case AgeCategory.teen:
        return [
          'Practice mindfulness and grounding techniques',
          'Create a support network of trusted friends and adults',
          'Develop healthy study and time management habits',
          'Engage in regular physical activity',
          'Set realistic goals and celebrate small wins',
          'Learn to say no to overwhelming commitments',
          'Practice self-compassion and challenge negative thoughts',
          'Consider talking to a school counselor or therapist',
        ];

      case AgeCategory.youngAdult:
        return [
          'Develop a consistent self-care routine',
          'Build and maintain meaningful relationships',
          'Practice stress management techniques like meditation',
          'Set boundaries in work and personal relationships',
          'Seek professional help when needed',
          'Focus on financial wellness and planning',
          'Engage in activities that align with your values',
          'Build resilience through challenging experiences',
        ];

      case AgeCategory.adult:
        return [
          'Integrate wellness practices into daily routines',
          'Maintain work-life balance and boundaries',
          'Invest in long-term relationships and community',
          'Practice acceptance and adaptability',
          'Focus on meaning and purpose in life',
          'Plan for future health and financial security',
          'Model healthy behaviors for others',
          'Seek professional support for complex challenges',
        ];

      default:
        return [
          'Practice deep breathing exercises',
          'Talk to someone you trust',
          'Engage in activities you enjoy',
          'Take care of your physical health',
          'Practice mindfulness and staying present',
          'Set realistic expectations for yourself',
          'Seek professional help when needed',
        ];
    }
  }

  /// Get age-appropriate crisis resources
  static List<CrisisResource> getAgeAppropriateCrisisResources(AgeCategory ageCategory) {
    final commonResources = [
      CrisisResource(
        name: '988 Suicide & Crisis Lifeline',
        phone: '988',
        description: '24/7 free and confidential support',
        ageAppropriate: true,
      ),
      CrisisResource(
        name: 'Crisis Text Line',
        contact: 'Text HOME to 741741',
        description: 'Free 24/7 crisis support via text',
        ageAppropriate: true,
      ),
    ];

    switch (ageCategory) {
      case AgeCategory.youngTeen:
      case AgeCategory.teen:
        return [
          ...commonResources,
          CrisisResource(
            name: 'Teen Line',
            phone: '1-800-852-8336',
            description: 'Teen-to-teen crisis support',
            ageAppropriate: true,
          ),
          CrisisResource(
            name: 'Boys Town National Hotline',
            phone: '1-800-448-3000',
            description: 'Crisis counseling for teens and families',
            ageAppropriate: true,
          ),
          CrisisResource(
            name: 'Trevor Project (LGBTQ+ Youth)',
            phone: '1-866-488-7386',
            description: 'Crisis support for LGBTQ+ young people',
            ageAppropriate: true,
          ),
        ];

      case AgeCategory.youngAdult:
        return [
          ...commonResources,
          CrisisResource(
            name: 'SAMHSA National Helpline',
            phone: '1-800-662-4357',
            description: 'Mental health and substance abuse support',
            ageAppropriate: true,
          ),
          CrisisResource(
            name: 'National Alliance on Mental Illness',
            phone: '1-800-950-6264',
            description: 'Mental health support and resources',
            ageAppropriate: true,
          ),
        ];

      default:
        return commonResources;
    }
  }

  /// Get age-appropriate conversation starters
  static List<String> getAgeAppropriateConversationStarters(AgeCategory ageCategory) {
    switch (ageCategory) {
      case AgeCategory.youngTeen:
        return [
          'How was school today?',
          'What\'s been on your mind lately?',
          'Tell me about your friends',
          'How are things at home?',
          'What makes you feel happy?',
          'Is there anything worrying you?',
        ];

      case AgeCategory.teen:
        return [
          'What\'s been stressing you out lately?',
          'How are you feeling about the future?',
          'Tell me about your relationships',
          'What are your goals right now?',
          'How do you handle pressure?',
          'What support do you need?',
        ];

      case AgeCategory.youngAdult:
        return [
          'How are you managing work/life balance?',
          'What challenges are you facing right now?',
          'How are your relationships going?',
          'What are you working toward?',
          'How do you take care of your mental health?',
          'What would make life easier for you?',
        ];

      default:
        return [
          'How are you feeling today?',
          'What\'s been on your mind?',
          'How can I support you?',
          'What would be helpful to talk about?',
        ];
    }
  }

  /// Filter content based on age appropriateness
  static String filterContentForAge(String content, AgeCategory ageCategory) {
    // This is a simplified content filter
    // In production, implement more sophisticated filtering
    
    final inappropriateForYoungTeens = [
      'suicide', 'self-harm', 'cutting', 'drugs', 'alcohol',
      'sex', 'sexual', 'adult content', 'mature themes'
    ];
    
    final inappropriateForTeens = [
      'explicit', 'graphic', 'adult themes'
    ];

    if (ageCategory == AgeCategory.youngTeen) {
      for (final term in inappropriateForYoungTeens) {
        if (content.toLowerCase().contains(term)) {
          return _getAgeAppropriateAlternative(content, ageCategory);
        }
      }
    } else if (ageCategory == AgeCategory.teen) {
      for (final term in inappropriateForTeens) {
        if (content.toLowerCase().contains(term)) {
          return _getAgeAppropriateAlternative(content, ageCategory);
        }
      }
    }

    return content;
  }

  /// Get age-appropriate alternative content
  static String _getAgeAppropriateAlternative(String originalContent, AgeCategory ageCategory) {
    switch (ageCategory) {
      case AgeCategory.youngTeen:
        return 'I understand you\'re going through a tough time. It\'s important to talk to a trusted adult like a parent, teacher, or school counselor who can provide the right support for someone your age.';
      
      case AgeCategory.teen:
        return 'I can see you\'re dealing with some serious challenges. While I\'m here to listen and support you, it would be really helpful to connect with a counselor or therapist who specializes in working with teens.';
      
      default:
        return originalContent;
    }
  }

  /// Get supportive phrases for different age groups
  static List<String> getSupportivePhrases(AgeCategory ageCategory) {
    switch (ageCategory) {
      case AgeCategory.youngTeen:
        return [
          'That sounds really tough for someone your age',
          'It\'s totally normal to feel this way as a teenager',
          'You\'re doing better than you think',
          'Growing up can be really confusing sometimes',
          'Your feelings are completely valid',
          'It\'s okay to ask for help',
        ];

      case AgeCategory.teen:
        return [
          'The teen years come with unique challenges',
          'You\'re navigating a lot of changes right now',
          'Your perspective matters and is valued',
          'It\'s normal to feel uncertain about the future',
          'You have more strength than you realize',
          'Seeking support shows maturity',
        ];

      case AgeCategory.youngAdult:
        return [
          'Early adulthood can feel overwhelming',
          'You\'re figuring out a lot right now, and that\'s okay',
          'Your experiences are shaping who you\'re becoming',
          'It\'s normal to feel uncertain about your path',
          'You\'re more capable than you give yourself credit for',
          'Taking care of your mental health is a priority',
        ];

      default:
        return [
          'Your feelings are valid and important',
          'You\'re not alone in this experience',
          'It takes courage to reach out for support',
          'You have the strength to get through this',
        ];
    }
  }
}

/// Crisis resource model for age-appropriate resources
class CrisisResource {
  final String name;
  final String? phone;
  final String? contact;
  final String description;
  final bool ageAppropriate;

  CrisisResource({
    required this.name,
    this.phone,
    this.contact,
    required this.description,
    required this.ageAppropriate,
  });
}
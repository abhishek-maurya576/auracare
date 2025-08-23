# AuraCare Personalization Guide

## Overview
AuraCare now includes advanced personalization features that allow the Gemini AI to provide more tailored and relevant responses based on user profiles and mood patterns.

## Features Implemented

### 1. User Profile Model (`UserProfile`)
- **Personal Information**: Name, age, email, photo
- **Mental Health Goals**: User-defined objectives (e.g., "Reduce anxiety", "Improve sleep")
- **Preferred Coping Strategies**: Methods that work for the user (e.g., "Deep breathing", "Meditation")
- **Communication Style**: How the user prefers to be addressed ("supportive", "direct", "gentle", "motivational")
- **Known Triggers**: Stress/anxiety triggers to be mindful of
- **Personal Strengths**: Positive attributes to reinforce
- **Mood Patterns**: Historical mood and stress data
- **AI Interaction Preferences**: Personalization settings and conversation depth

### 2. Enhanced Gemini Service
The `GeminiService` now includes:
- **User Profile Integration**: Stores and uses user profiles for context
- **Mood Data Context**: Incorporates recent mood entries into responses
- **Personalized Prompts**: Generates context-aware prompts based on user data
- **Crisis Detection**: Enhanced with user-specific information

### 3. User Profile Service
- **Profile Management**: Save, load, and update user profiles in Firestore
- **Mood Pattern Analysis**: Calculate and store mood trends
- **Personalization Setup**: Configure user preferences
- **Data Synchronization**: Keep Gemini service updated with latest user data

### 4. Personalization Setup Screen
A comprehensive onboarding flow that collects:
1. Mental health goals
2. Preferred coping strategies
3. Communication style preferences
4. Known triggers (optional)
5. Personal strengths

## How It Works

### 1. User Profile Creation
When a user signs up or first uses the app:
```dart
// Automatically creates a basic profile
await _profileService.initializeUserProfile(
  userId: user.uid,
  name: user.displayName,
  email: user.email,
);
```

### 2. Personalization Setup
Users can complete a setup process to provide detailed preferences:
```dart
await profileProvider.quickSetup(
  selectedGoals: ['Reduce anxiety', 'Improve sleep'],
  selectedCopingStrategies: ['Deep breathing', 'Meditation'],
  selectedCommunicationStyle: 'supportive',
  selectedStrengths: ['Resilient', 'Creative'],
);
```

### 3. AI Response Generation
When generating responses, the Gemini service now includes personalized context:
```dart
final response = await _geminiService.generateChatResponse(
  userMessage,
  sessionId: sessionId,
  userId: userId, // Enables personalization
);
```

### 4. Mood Data Integration
Mood entries are automatically used to update user patterns:
```dart
// After saving a mood entry
await _profileService.updateMoodPatterns(userId, moodEntries);
```

## Example Personalized Response

### Without Personalization:
**User**: "I'm feeling really anxious about work"
**Aura**: "I understand you're feeling anxious. Try some deep breathing exercises or take a short walk to help calm your mind."

### With Personalization:
**User**: "I'm feeling really anxious about work"
**Aura**: "Hi Sarah, I can see you're dealing with work anxiety again - I know this has been a challenge for you lately. Since meditation has worked well for you before, would you like to try a 5-minute guided session? I also remember you mentioned your resilience as one of your strengths - you've overcome work stress before and you can do it again."

## Benefits

1. **More Relevant Responses**: AI considers user's specific goals and preferences
2. **Consistent Support**: Remembers what works for each individual user
3. **Mindful Communication**: Avoids known triggers and uses preferred communication style
4. **Strength-Based Approach**: Reinforces user's personal strengths and past successes
5. **Progressive Learning**: Gets better over time as more data is collected

## Privacy & Security

- All personalization data is stored securely in Firestore
- Users can control what information is shared with the AI
- Personalization can be disabled at any time
- Crisis detection is enhanced but maintains appropriate safeguards

## Usage in Code

### Setting Up Personalization
```dart
// In your widget
Consumer<UserProfileProvider>(
  builder: (context, profileProvider, child) {
    if (!profileProvider.hasProfile) {
      return PersonalizationSetupScreen();
    }
    return YourMainWidget();
  },
)
```

### Using Personalized AI Responses
```dart
// Get current user ID
final authProvider = Provider.of<AuthProvider>(context, listen: false);
final userId = authProvider.currentUserId;

// Generate personalized response
final response = await geminiService.generateChatResponse(
  message,
  sessionId: sessionId,
  userId: userId,
);
```

### Updating Mood Patterns
```dart
// This happens automatically when saving mood entries
await moodProvider.saveMoodEntry(
  mood: 'anxious',
  emoji: '😰',
  note: 'Work deadline stress',
  // ... other parameters
);
// User profile is automatically updated with new patterns
```

## Future Enhancements

1. **Proactive Support**: AI can initiate conversations based on patterns
2. **Community Integration**: Anonymous sharing of successful strategies
3. **Professional Integration**: Connect with therapists while maintaining privacy
4. **Advanced Analytics**: More sophisticated pattern recognition
5. **Voice Personalization**: Adapt tone and language style further

## Testing Personalization

To test the personalization features:

1. Create a new user account
2. Complete the personalization setup
3. Add some mood entries with different patterns
4. Chat with Aura and notice how responses reference your profile
5. Update your preferences and see how responses adapt

The system learns and adapts over time, providing increasingly personalized and helpful support.
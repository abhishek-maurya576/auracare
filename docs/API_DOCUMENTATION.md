# 🔌 MindMate (AuraCare) API Documentation

## 📋 **Table of Contents**
- [Overview](#overview)
- [Authentication APIs](#authentication-apis)
- [Firebase Firestore APIs](#firebase-firestore-apis)
- [Google Gemini AI APIs](#google-gemini-ai-apis)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [Security](#security)

---

## 🎯 **Overview**

MindMate (AuraCare) integrates with multiple APIs to provide comprehensive mental wellness features. This document outlines all API integrations, request/response formats, and implementation details.

### **API Endpoints Summary**
| Service | Purpose | Base URL |
|---------|---------|----------|
| **Firebase Auth** | User authentication | `https://identitytoolkit.googleapis.com/v1` |
| **Cloud Firestore** | Database operations | `https://firestore.googleapis.com/v1` |
| **Google Gemini** | AI chat functionality | `https://generativelanguage.googleapis.com/v1beta` |
| **Firebase Analytics** | User behavior tracking | SDK-based |

---

## 🔐 **Authentication APIs**

### **Firebase Authentication Service**

#### **Sign In with Google**
```dart
// Service Implementation
class AuthService {
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      throw AuthException('Google sign-in failed: $e');
    }
  }
}
```

**Request Flow:**
1. User initiates Google Sign-In
2. Google OAuth flow completes
3. Exchange tokens for Firebase credential
4. Sign in to Firebase Auth

**Response:**
```dart
UserCredential {
  user: User {
    uid: "user_unique_id",
    email: "user@example.com",
    displayName: "User Name",
    photoURL: "https://profile-photo-url"
  },
  credential: AuthCredential,
  additionalUserInfo: AdditionalUserInfo
}
```

#### **Email/Password Authentication**
```dart
// Sign Up
Future<UserCredential?> signUpWithEmailPassword(String email, String password) async {
  try {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  } catch (e) {
    throw AuthException('Sign up failed: $e');
  }
}

// Sign In
Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
  try {
    return await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  } catch (e) {
    throw AuthException('Sign in failed: $e');
  }
}
```

#### **Authentication State Management**
```dart
// Listen to auth state changes
Stream<User?> get authStateChanges => FirebaseAuth.instance.authStateChanges();

// Get current user
User? get currentUser => FirebaseAuth.instance.currentUser;

// Sign out
Future<void> signOut() async {
  await GoogleSignIn().signOut();
  await FirebaseAuth.instance.signOut();
}
```

---

## 🗄️ **Firebase Firestore APIs**

### **Database Structure**
```
users/{userId}/
├── user_data (document)
├── moods/{moodId} (subcollection)
├── chat_sessions/{sessionId} (subcollection)
├── journal_entries/{entryId} (subcollection)
└── meditation_sessions/{sessionId} (subcollection)
```

### **User Data Operations**

#### **Create User Profile**
```dart
Future<void> createUser(UserModel user) async {
  try {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'preferences': user.preferences,
      'onboardingCompleted': user.onboardingCompleted,
    });
  } catch (e) {
    throw DatabaseException('Failed to create user: $e');
  }
}
```

#### **Get User Profile**
```dart
Future<UserModel?> getUser(String uid) async {
  try {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    
    final data = doc.data()!;
    return UserModel(
      uid: uid,
      email: data['email'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      onboardingCompleted: data['onboardingCompleted'] ?? false,
    );
  } catch (e) {
    throw DatabaseException('Failed to get user: $e');
  }
}
```

### **Mood Tracking Operations**

#### **Save Mood Entry**
```dart
Future<void> saveMoodEntry(MoodEntry entry) async {
  try {
    await _firestore
        .collection('users')
        .doc(entry.userId)
        .collection('moods')
        .doc(entry.id)
        .set({
      'mood': entry.mood,
      'intensity': entry.intensity,
      'note': entry.note,
      'triggers': entry.triggers,
      'timestamp': Timestamp.fromDate(entry.timestamp),
      'aiAnalysis': entry.aiAnalysis,
    });
  } catch (e) {
    throw DatabaseException('Failed to save mood entry: $e');
  }
}
```

#### **Get Mood History**
```dart
Future<List<MoodEntry>> getMoodHistory(String userId, {int limit = 50}) async {
  try {
    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    
    return query.docs.map((doc) {
      final data = doc.data();
      return MoodEntry(
        id: doc.id,
        userId: userId,
        mood: data['mood'],
        intensity: data['intensity'],
        note: data['note'],
        triggers: List<String>.from(data['triggers'] ?? []),
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        aiAnalysis: data['aiAnalysis'],
      );
    }).toList();
  } catch (e) {
    throw DatabaseException('Failed to get mood history: $e');
  }
}
```

### **Chat Session Operations**

#### **Create Chat Session**
```dart
Future<String> createChatSession(String userId, String title) async {
  try {
    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_sessions')
        .add({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    
    return docRef.id;
  } catch (e) {
    throw DatabaseException('Failed to create chat session: $e');
  }
}
```

#### **Save Chat Message**
```dart
Future<void> saveChatMessage(ChatMessage message) async {
  try {
    // Save message to subcollection
    await _firestore
        .collection('users')
        .doc(message.userId)
        .collection('chat_sessions')
        .doc(message.sessionId)
        .collection('messages')
        .doc(message.id)
        .set({
      'content': message.content,
      'role': message.role,
      'timestamp': Timestamp.fromDate(message.timestamp),
      'metadata': message.metadata,
    });
    
    // Update session last message time
    await _firestore
        .collection('users')
        .doc(message.userId)
        .collection('chat_sessions')
        .doc(message.sessionId)
        .update({
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    throw DatabaseException('Failed to save chat message: $e');
  }
}
```

---

## 🤖 **Google Gemini AI APIs**

### **Service Configuration**
```dart
class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _apiKey = ApiKeys.geminiApiKey;
  static const String _model = 'gemini-2.0-flash';
  
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };
}
```

### **Generate AI Response**

#### **Request Format**
```dart
Future<String> generateResponse(String prompt, List<ChatMessage> history) async {
  final url = '$_baseUrl/models/$_model:generateContent?key=$_apiKey';
  
  // Build conversation context
  final List<Map<String, dynamic>> contents = [];
  
  // Add system prompt
  contents.add({
    'role': 'user',
    'parts': [{'text': _buildSystemPrompt()}]
  });
  
  // Add conversation history
  for (final message in history) {
    contents.add({
      'role': message.role == 'user' ? 'user' : 'model',
      'parts': [{'text': message.content}]
    });
  }
  
  // Add current user message
  contents.add({
    'role': 'user',
    'parts': [{'text': prompt}]
  });
  
  final requestBody = {
    'contents': contents,
    'generationConfig': {
      'temperature': 0.7,
      'topK': 40,
      'topP': 0.95,
      'maxOutputTokens': 1024,
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
  };
  
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: json.encode(requestBody),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw ApiException('Gemini API error: ${response.statusCode}');
    }
  } catch (e) {
    throw ApiException('Failed to generate response: $e');
  }
}
```

#### **System Prompt Configuration**
```dart
String _buildSystemPrompt() {
  return '''
You are MindMate, an empathetic AI companion for mental wellness and emotional support.

PERSONALITY:
- Warm, understanding, and non-judgmental
- Professional yet approachable
- Focused on mental health and emotional wellbeing
- Encouraging and supportive

CAPABILITIES:
- Provide emotional support and active listening
- Suggest coping strategies and mindfulness techniques
- Offer breathing exercises and meditation guidance
- Help with mood tracking and self-reflection
- Provide crisis resources when needed

GUIDELINES:
- Always prioritize user safety and wellbeing
- Encourage professional help for serious mental health concerns
- Use empathetic language and validate emotions
- Provide practical, actionable advice
- Maintain appropriate boundaries as an AI assistant

CRISIS DETECTION:
If you detect signs of self-harm, suicide ideation, or severe mental health crisis:
1. Express immediate concern and support
2. Strongly encourage contacting emergency services or crisis hotlines
3. Provide relevant crisis resources
4. Continue to offer support while emphasizing professional help

Remember: You are a supportive companion, not a replacement for professional mental health care.
''';
}
```

### **Mood Analysis API**
```dart
Future<String> analyzeMood(String mood, String note) async {
  final prompt = '''
Analyze this mood entry and provide supportive insights:

Mood: $mood
Note: $note

Please provide:
1. Acknowledgment of their feelings
2. Brief insight about this mood
3. One practical suggestion for improvement
4. Encouraging words

Keep response under 150 words and maintain a supportive tone.
''';
  
  return await generateResponse(prompt, []);
}
```

### **Crisis Detection**
```dart
bool detectCrisisKeywords(String message) {
  final crisisKeywords = [
    'suicide', 'kill myself', 'end it all', 'not worth living',
    'self harm', 'hurt myself', 'want to die', 'hopeless',
    'can\'t go on', 'better off dead', 'no point', 'give up'
  ];
  
  final lowerMessage = message.toLowerCase();
  return crisisKeywords.any((keyword) => lowerMessage.contains(keyword));
}

String getCrisisResponse() {
  return '''
I'm really concerned about what you're sharing with me. Your feelings are valid, but I want you to know that you don't have to face this alone.

🆘 IMMEDIATE HELP:
• National Suicide Prevention Lifeline: 988
• Crisis Text Line: Text HOME to 741741
• Emergency Services: 911

Please reach out to one of these resources right now. There are people who want to help you through this difficult time.

You matter, and there is hope. Professional counselors are trained to help with exactly what you're experiencing.

Would you like me to help you find local mental health resources?
''';
}
```

---

## ⚠️ **Error Handling**

### **Custom Exception Classes**
```dart
// Base exception class
abstract class AppException implements Exception {
  final String message;
  final String? code;
  
  AppException(this.message, [this.code]);
  
  @override
  String toString() => 'AppException: $message';
}

// Authentication exceptions
class AuthException extends AppException {
  AuthException(String message, [String? code]) : super(message, code);
}

// Database exceptions
class DatabaseException extends AppException {
  DatabaseException(String message, [String? code]) : super(message, code);
}

// API exceptions
class ApiException extends AppException {
  final int? statusCode;
  
  ApiException(String message, [this.statusCode, String? code]) 
      : super(message, code);
}

// Network exceptions
class NetworkException extends AppException {
  NetworkException(String message, [String? code]) : super(message, code);
}
```

### **Error Handling Patterns**
```dart
// Service layer error handling
Future<T> handleServiceCall<T>(Future<T> Function() serviceCall) async {
  try {
    return await serviceCall();
  } on FirebaseAuthException catch (e) {
    throw AuthException(_getAuthErrorMessage(e.code), e.code);
  } on FirebaseException catch (e) {
    throw DatabaseException(_getFirebaseErrorMessage(e.code), e.code);
  } on SocketException catch (e) {
    throw NetworkException('No internet connection');
  } catch (e) {
    throw AppException('An unexpected error occurred: $e');
  }
}

// UI layer error handling
void handleError(BuildContext context, dynamic error) {
  String message = 'An unexpected error occurred';
  
  if (error is AuthException) {
    message = error.message;
  } else if (error is DatabaseException) {
    message = 'Database error: ${error.message}';
  } else if (error is NetworkException) {
    message = 'Network error: ${error.message}';
  } else if (error is ApiException) {
    message = 'API error: ${error.message}';
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 3),
    ),
  );
}
```

---

## 🚦 **Rate Limiting**

### **Gemini API Rate Limits**
- **Requests per minute**: 60
- **Requests per day**: 1,500
- **Tokens per minute**: 32,000
- **Tokens per day**: 50,000

### **Rate Limiting Implementation**
```dart
class RateLimiter {
  final Map<String, List<DateTime>> _requestHistory = {};
  final int maxRequestsPerMinute;
  final Duration timeWindow;
  
  RateLimiter({
    this.maxRequestsPerMinute = 60,
    this.timeWindow = const Duration(minutes: 1),
  });
  
  bool canMakeRequest(String identifier) {
    final now = DateTime.now();
    final history = _requestHistory[identifier] ?? [];
    
    // Remove old requests outside time window
    history.removeWhere((time) => now.difference(time) > timeWindow);
    
    // Check if under limit
    if (history.length >= maxRequestsPerMinute) {
      return false;
    }
    
    // Add current request
    history.add(now);
    _requestHistory[identifier] = history;
    
    return true;
  }
}

// Usage in service
class GeminiService {
  static final _rateLimiter = RateLimiter();
  
  Future<String> generateResponse(String prompt, List<ChatMessage> history) async {
    if (!_rateLimiter.canMakeRequest('gemini_api')) {
      throw ApiException('Rate limit exceeded. Please try again later.');
    }
    
    // Proceed with API call
    return await _makeApiCall(prompt, history);
  }
}
```

---

## 🔒 **Security**

### **API Key Management**
```dart
// Development configuration
class ApiKeys {
  static const String geminiApiKey = 'your-development-key';
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
}

// Production configuration (use environment variables)
class ApiKeys {
  static String get geminiApiKey => 
      const String.fromEnvironment('GEMINI_API_KEY');
  static String get geminiBaseUrl => 
      const String.fromEnvironment('GEMINI_BASE_URL', 
          defaultValue: 'https://generativelanguage.googleapis.com/v1beta');
}
```

### **Request Validation**
```dart
class RequestValidator {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static bool isValidPassword(String password) {
    return password.length >= 8 && 
           password.contains(RegExp(r'[A-Z]')) &&
           password.contains(RegExp(r'[a-z]')) &&
           password.contains(RegExp(r'[0-9]'));
  }
  
  static String sanitizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'[<>]'), '');
  }
}
```

### **Data Encryption**
```dart
class EncryptionService {
  static final _key = encrypt.Key.fromSecureRandom(32);
  static final _iv = encrypt.IV.fromSecureRandom(16);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  
  static String encryptText(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }
  
  static String decryptText(String encryptedText) {
    final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }
}
```

---

## 📊 **API Monitoring**

### **Performance Tracking**
```dart
class ApiMonitor {
  static void trackApiCall(String endpoint, Duration duration, bool success) {
    FirebaseAnalytics.instance.logEvent(
      name: 'api_call',
      parameters: {
        'endpoint': endpoint,
        'duration_ms': duration.inMilliseconds,
        'success': success,
      },
    );
  }
  
  static void trackError(String endpoint, String error) {
    FirebaseCrashlytics.instance.recordError(
      error,
      null,
      information: ['API Endpoint: $endpoint'],
    );
  }
}
```

### **Health Checks**
```dart
class HealthChecker {
  static Future<bool> checkFirebaseHealth() async {
    try {
      await FirebaseFirestore.instance.collection('health').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> checkGeminiHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiKeys.geminiBaseUrl}/models'),
        headers: {'Authorization': 'Bearer ${ApiKeys.geminiApiKey}'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
```

---

This API documentation provides comprehensive coverage of all external integrations used in MindMate (AuraCare), including authentication, database operations, AI services, and security considerations.
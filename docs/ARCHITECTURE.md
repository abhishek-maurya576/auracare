# 🏗️ MindMate (AuraCare) Architecture Documentation

## 📋 **Table of Contents**
- [System Overview](#system-overview)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Data Architecture](#data-architecture)
- [UI/UX Architecture](#uiux-architecture)
- [Security Architecture](#security-architecture)
- [API Integration](#api-integration)
- [State Management](#state-management)
- [Performance Considerations](#performance-considerations)

---

## 🎯 **System Overview**

MindMate (AuraCare) follows a **client-server architecture** with Flutter as the frontend and Firebase as the backend infrastructure. The app implements a **modular design pattern** with clear separation of concerns.

### **Architecture Principles**
- **Modularity**: Each feature is self-contained with clear interfaces
- **Scalability**: Designed to handle growing user base and feature set
- **Security**: End-to-end encryption for sensitive data
- **Performance**: Optimized for smooth user experience
- **Maintainability**: Clean code structure with comprehensive documentation

### **High-Level Architecture**
```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Frontend                         │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (Screens & Widgets)                    │
│  ├── Authentication Screens                                │
│  ├── Home Dashboard                                        │
│  ├── Mood Tracking Interface                               │
│  ├── AI Chat Interface                                     │
│  ├── Meditation & Breathing                                │
│  └── Journaling Interface                                  │
├─────────────────────────────────────────────────────────────┤
│  Business Logic Layer (Providers & Services)               │
│  ├── AuthProvider (User Management)                        │
│  ├── MoodProvider (Mood Data)                              │
│  ├── ChatSessionService (AI Conversations)                 │
│  ├── FirebaseService (Database Operations)                 │
│  └── GeminiService (AI Integration)                        │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (Models & Storage)                             │
│  ├── User Model                                            │
│  ├── Mood Entry Model                                      │
│  ├── Chat Message Model                                    │
│  └── Local Storage (Hive)                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Backend Services                         │
├─────────────────────────────────────────────────────────────┤
│  Firebase Authentication                                    │
│  ├── Google Sign-In                                        │
│  ├── Email/Password Auth                                   │
│  └── User Session Management                               │
├─────────────────────────────────────────────────────────────┤
│  Cloud Firestore Database                                  │
│  ├── Users Collection                                      │
│  ├── Moods Subcollection                                   │
│  ├── Chat Sessions Subcollection                           │
│  └── User Preferences                                      │
├─────────────────────────────────────────────────────────────┤
│  External APIs                                             │
│  ├── Google Gemini AI                                      │
│  ├── Google Maps (Future)                                  │
│  └── Push Notifications                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ **Technology Stack**

### **Frontend Technologies**
| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| **Framework** | Flutter | 3.27.4 | Cross-platform mobile development |
| **Language** | Dart | 3.6.2 | Programming language |
| **State Management** | Provider | 6.1.2 | Application state management |
| **UI Components** | Material 3 | Latest | Design system foundation |
| **Typography** | Google Fonts | 6.2.1 | Custom font integration |
| **Charts** | FL Chart | 0.68.0 | Data visualization |
| **Animations** | Lottie | 3.1.2 | Complex animations |
| **Local Storage** | Hive | 2.2.3 | Local data persistence |

### **Backend Technologies**
| Component | Technology | Purpose |
|-----------|------------|---------|
| **Authentication** | Firebase Auth | User management and security |
| **Database** | Cloud Firestore | NoSQL document database |
| **Analytics** | Firebase Analytics | User behavior tracking |
| **AI Service** | Google Gemini | Conversational AI |
| **Push Notifications** | Firebase Messaging | User engagement |
| **Hosting** | Firebase Hosting | Web app deployment |

### **Development Tools**
| Tool | Purpose |
|------|---------|
| **VS Code** | Primary IDE |
| **Android Studio** | Android development |
| **Xcode** | iOS development |
| **Firebase Console** | Backend management |
| **FlutterFire CLI** | Firebase configuration |

---

## 📁 **Project Structure**

### **Directory Organization**
```
lib/
├── config/                 # Configuration files
│   ├── api_keys.dart      # API keys and endpoints
│   └── app_config.dart    # App-wide configuration
├── models/                # Data models
│   ├── user_model.dart    # User data structure
│   ├── mood_entry.dart    # Mood tracking data
│   └── chat_message.dart  # Chat message structure
├── providers/             # State management
│   ├── auth_provider.dart # Authentication state
│   ├── mood_provider.dart # Mood tracking state
│   └── chat_provider.dart # Chat session state
├── screens/               # UI screens
│   ├── splash_screen.dart
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── mood_history_screen.dart
│   ├── ai_chat_screen.dart
│   ├── meditation_screen.dart
│   └── journaling_screen.dart
├── services/              # Business logic services
│   ├── auth_service.dart  # Authentication operations
│   ├── firebase_service.dart # Database operations
│   ├── gemini_service.dart   # AI integration
│   └── chat_session_service.dart # Chat management
├── utils/                 # Utility functions
│   ├── app_colors.dart    # Color constants
│   ├── constants.dart     # App constants
│   └── helpers.dart       # Helper functions
├── widgets/               # Reusable UI components
│   ├── glass_widgets.dart # Glass-morphic components
│   ├── aura_background.dart # Animated background
│   ├── mood_check_card.dart # Mood selection widget
│   └── chat_bubble.dart   # Chat message widget
└── main.dart              # App entry point
```

### **Asset Organization**
```
assets/
├── images/               # Static images
│   ├── auracare.png     # App logo
│   └── onboarding/      # Onboarding images
├── animations/          # Lottie animations
│   ├── breathing.json   # Breathing exercise
│   └── meditation.json  # Meditation animations
└── fonts/              # Custom fonts (if any)
```

---

## 🗄️ **Data Architecture**

### **Firestore Database Structure**
```
auracare-01 (Firebase Project)
├── users/{userId}
│   ├── user_data (document)
│   │   ├── email: string
│   │   ├── displayName: string
│   │   ├── photoURL: string
│   │   ├── createdAt: timestamp
│   │   ├── lastLoginAt: timestamp
│   │   ├── preferences: map
│   │   └── onboardingCompleted: boolean
│   ├── moods/{moodId} (subcollection)
│   │   ├── mood: string (happy, calm, neutral, sad, stressed)
│   │   ├── intensity: number (1-10)
│   │   ├── note: string
│   │   ├── triggers: array
│   │   ├── timestamp: timestamp
│   │   └── aiAnalysis: string
│   ├── chat_sessions/{sessionId} (subcollection)
│   │   ├── title: string
│   │   ├── createdAt: timestamp
│   │   ├── lastMessageAt: timestamp
│   │   └── messages/{messageId} (subcollection)
│   │       ├── content: string
│   │       ├── role: string (user/assistant)
│   │       ├── timestamp: timestamp
│   │       └── metadata: map
│   ├── journal_entries/{entryId} (subcollection)
│   │   ├── title: string
│   │   ├── content: string (encrypted)
│   │   ├── mood: string
│   │   ├── tags: array
│   │   ├── createdAt: timestamp
│   │   └── updatedAt: timestamp
│   └── meditation_sessions/{sessionId} (subcollection)
│       ├── type: string
│       ├── duration: number
│       ├── completedAt: timestamp
│       └── rating: number
```

### **Data Models**

#### **User Model**
```dart
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> preferences;
  final bool onboardingCompleted;
}
```

#### **Mood Entry Model**
```dart
class MoodEntry {
  final String id;
  final String userId;
  final String mood;
  final int intensity;
  final String? note;
  final List<String> triggers;
  final DateTime timestamp;
  final String? aiAnalysis;
}
```

#### **Chat Message Model**
```dart
class ChatMessage {
  final String id;
  final String sessionId;
  final String content;
  final String role; // 'user' or 'assistant'
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
}
```

---

## 🎨 **UI/UX Architecture**

### **Design System**

#### **Glass-morphism Components**
```dart
// Base glass widget with blur effects
class GlassWidget extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blurSigma;
  final Color? backgroundColor;
}

// Specialized glass card for content
class GlassCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? child;
  final IconData? leadingIcon;
  final VoidCallback? onTap;
}
```

#### **Color Palette**
```dart
class AppColors {
  // Primary colors
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color primaryTeal = Color(0xFF0E4F4F);
  
  // Accent colors
  static const Color accentLavender = Color(0xFF8B5CF6);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentPeach = Color(0xFFFF8A65);
  
  // Glass effects
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassShadow = Color(0x1A000000);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
}
```

#### **Typography System**
```dart
// Using Google Fonts - Inter family
TextTheme textTheme = GoogleFonts.interTextTheme(
  Theme.of(context).textTheme.apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  ),
);
```

### **Animation Architecture**

#### **Background Animation**
- **Morphing Blobs**: Continuous gradient animation
- **Breathing Dots**: Subtle pulsing effects
- **Particle System**: Floating elements for ambiance

#### **Transition Animations**
- **Page Transitions**: Smooth slide and fade effects
- **Card Animations**: Scale and blur transitions
- **Loading States**: Skeleton screens with shimmer

---

## 🔒 **Security Architecture**

### **Authentication Security**
```dart
// Firebase Auth with multiple providers
class AuthService {
  // Google Sign-In with secure token handling
  Future<UserCredential?> signInWithGoogle();
  
  // Email/password with validation
  Future<UserCredential?> signInWithEmailPassword(String email, String password);
  
  // Secure session management
  Stream<User?> get authStateChanges;
}
```

### **Data Security**

#### **Firestore Security Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Mood data security
      match /moods/{moodId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Chat session security
      match /chat_sessions/{sessionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

#### **Data Encryption**
```dart
// Journal entries encryption
class EncryptionService {
  static String encryptText(String plainText, String key) {
    // AES encryption implementation
  }
  
  static String decryptText(String encryptedText, String key) {
    // AES decryption implementation
  }
}
```

### **API Security**
- **API Key Management**: Environment variables for production
- **Rate Limiting**: Prevent API abuse
- **Input Validation**: Sanitize all user inputs
- **HTTPS Only**: All communications encrypted

---

## 🔌 **API Integration**

### **Google Gemini AI Integration**
```dart
class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.0-flash';
  
  // Generate AI response with context
  Future<String> generateResponse(String prompt, List<ChatMessage> history) {
    // Build context from chat history
    // Send request to Gemini API
    // Process and return response
  }
  
  // Analyze mood with AI
  Future<String> analyzeMood(String mood, String note) {
    // Generate mood analysis prompt
    // Get AI insights
    // Return personalized response
  }
}
```

### **Firebase Integration**
```dart
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // User data operations
  Future<void> createUser(UserModel user);
  Future<UserModel?> getUser(String uid);
  Future<void> updateUser(String uid, Map<String, dynamic> data);
  
  // Mood tracking operations
  Future<void> saveMoodEntry(MoodEntry entry);
  Future<List<MoodEntry>> getMoodHistory(String userId, {int limit = 50});
  
  // Chat session operations
  Future<String> createChatSession(String userId, String title);
  Future<void> saveChatMessage(ChatMessage message);
  Future<List<ChatMessage>> getChatHistory(String sessionId);
}
```

---

## 🔄 **State Management**

### **Provider Pattern Implementation**

#### **Authentication Provider**
```dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  
  // Authentication methods
  Future<void> signInWithGoogle();
  Future<void> signInWithEmail(String email, String password);
  Future<void> signOut();
  
  // State management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
```

#### **Mood Provider**
```dart
class MoodProvider extends ChangeNotifier {
  List<MoodEntry> _moodHistory = [];
  bool _isLoading = false;
  
  // Getters
  List<MoodEntry> get moodHistory => _moodHistory;
  bool get isLoading => _isLoading;
  
  // Mood operations
  Future<void> saveMoodEntry(MoodEntry entry);
  Future<void> loadMoodHistory(String userId);
  List<MoodEntry> getMoodsByDateRange(DateTime start, DateTime end);
  
  // Analytics
  Map<String, int> getMoodDistribution();
  double getAverageMoodScore();
}
```

### **State Flow Diagram**
```
User Action → Provider Method → Service Call → Firebase/API → 
Update State → Notify Listeners → UI Rebuild
```

---

## ⚡ **Performance Considerations**

### **Optimization Strategies**

#### **Database Optimization**
- **Pagination**: Load data in chunks to reduce memory usage
- **Indexing**: Proper Firestore indexes for efficient queries
- **Caching**: Local storage for frequently accessed data
- **Lazy Loading**: Load content only when needed

#### **UI Performance**
- **Widget Optimization**: Use const constructors where possible
- **Image Optimization**: Compressed images with proper sizing
- **Animation Performance**: 60fps animations with proper disposal
- **Memory Management**: Proper disposal of controllers and streams

#### **Network Optimization**
- **Request Batching**: Combine multiple API calls
- **Offline Support**: Local data persistence with sync
- **Compression**: Gzip compression for API responses
- **Connection Pooling**: Reuse HTTP connections

### **Performance Monitoring**
```dart
// Firebase Performance Monitoring
class PerformanceService {
  static void trackScreenView(String screenName) {
    FirebaseAnalytics.instance.logScreenView(screenName: screenName);
  }
  
  static void trackUserAction(String action, Map<String, dynamic> parameters) {
    FirebaseAnalytics.instance.logEvent(name: action, parameters: parameters);
  }
}
```

---

## 🚀 **Scalability Architecture**

### **Horizontal Scaling**
- **Microservices**: Separate services for different features
- **Load Balancing**: Distribute traffic across multiple instances
- **CDN Integration**: Global content delivery
- **Database Sharding**: Distribute data across multiple databases

### **Vertical Scaling**
- **Resource Optimization**: Efficient memory and CPU usage
- **Code Splitting**: Load only necessary code
- **Asset Optimization**: Compressed images and fonts
- **Bundle Size Reduction**: Tree shaking and dead code elimination

### **Future Architecture Considerations**
- **Multi-tenant Support**: Support for multiple organizations
- **Real-time Features**: WebSocket integration for live chat
- **Machine Learning**: On-device ML for privacy-focused features
- **Blockchain Integration**: Secure and decentralized data storage

---

## 📊 **Monitoring & Analytics**

### **Application Monitoring**
- **Crash Reporting**: Firebase Crashlytics
- **Performance Monitoring**: Firebase Performance
- **User Analytics**: Firebase Analytics
- **Custom Metrics**: Business-specific KPIs

### **Health Checks**
- **API Health**: Monitor external service availability
- **Database Health**: Track query performance
- **User Experience**: Monitor app responsiveness
- **Error Rates**: Track and alert on error spikes

---

This architecture documentation provides a comprehensive overview of the MindMate (AuraCare) system design, ensuring maintainability, scalability, and security as the application grows.
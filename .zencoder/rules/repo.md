---
description: Repository Information Overview
alwaysApply: true
---

# AuraCare (MindMate) Information

## Summary
AuraCare (MindMate) is a comprehensive mental wellness Flutter application that combines beautiful liquid glass-morphism UI with AI-driven features for mood tracking, emotional support, meditation, and community connection. The app focuses on psychological comfort and therapeutic aesthetics.

## Structure
- **lib/**: Core application code (models, providers, screens, services, utils, widgets)
- **assets/**: Images and animations for the application
- **android/**, **ios/**, **web/**, **windows/**, **macos/**, **linux/**: Platform-specific configurations
- **docs/**: Comprehensive documentation including architecture, API, and deployment guides
- **test/**: Testing configuration and test files

## Language & Runtime
**Language**: Dart
**Version**: SDK 3.6.2
**Framework**: Flutter 3.27.4
**Build System**: Flutter build system
**Package Manager**: pub (Flutter/Dart package manager)

## Dependencies
**Main Dependencies**:
- **UI & Design**: google_fonts (6.2.1), cupertino_icons (1.0.8)
- **Firebase**: firebase_core (2.32.0), firebase_auth (4.20.0), cloud_firestore (4.17.5)
- **Authentication**: google_sign_in (7.1.1)
- **State Management**: provider (6.1.2), flutter_riverpod (2.5.1)
- **Storage**: shared_preferences (2.2.3), hive (2.2.3), hive_flutter (1.1.0)
- **Charts**: fl_chart (0.68.0)
- **Animations**: lottie (3.1.2), flutter_animate (4.5.0)
- **API**: http (1.2.1), dio (5.4.3+1)

**Development Dependencies**:
- flutter_test, flutter_lints (5.0.0)
- hive_generator (2.0.1), build_runner (2.4.9)
- flutter_launcher_icons (0.13.1)

## Build & Installation
```bash
# Install dependencies
flutter pub get

# Configure Firebase
dart pub global activate flutterfire_cli
flutterfire configure --project=auracare-01-dev

# Setup API keys
cp lib/config/api_keys.dart.example lib/config/api_keys.dart
# Add Gemini API key to the file

# Run the application
flutter run
```

## Testing
**Framework**: Flutter Test
**Test Location**: test/
**Run Command**:
```bash
flutter test
```

## Firebase Integration
**Configuration**: Firebase is fully integrated with support for:
- Authentication (Email/Password, Google Sign-In)
- Cloud Firestore for data storage
- Analytics for user behavior tracking
- Multi-platform support (Android, iOS, Web, macOS, Windows)

## Features
**Core Systems**:
- **Glass-morphism UI**: Custom translucent components with blur effects
- **Authentication**: Firebase Auth with Google Sign-In and email/password
- **Mood Analytics**: Advanced tracking with AI-powered insights
- **AI Chat**: Gemini AI integration for mental health support
- **Real-time Database**: Secure Firestore integration with offline support

**Development Progress**:
- Phase 1 (100% Complete): Authentication, Home Dashboard, Mood Tracking, AI Chat with Personalization
- Phase 2 (25% Complete): Enhanced Mood Analytics, Meditation & Breathing, Journaling
- Phase 3 (Planned): Community Features, Nearby Help, Premium Features
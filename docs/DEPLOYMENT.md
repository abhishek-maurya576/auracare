# 🚀 MindMate (AuraCare) Deployment Guide

## 📋 **Table of Contents**
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Firebase Configuration](#firebase-configuration)
- [Build Configuration](#build-configuration)
- [Platform-Specific Deployment](#platform-specific-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring & Analytics](#monitoring--analytics)
- [Troubleshooting](#troubleshooting)

---

## ✅ **Prerequisites**

### **Development Environment**
- **Flutter SDK**: 3.27.4 or later
- **Dart SDK**: 3.6.2 or later
- **Android Studio**: Latest stable version
- **Xcode**: 15.0+ (for iOS deployment)
- **VS Code**: With Flutter and Dart extensions

### **Required Accounts**
- **Google Cloud Platform**: For Firebase services
- **Apple Developer Account**: For iOS App Store deployment
- **Google Play Console**: For Android Play Store deployment
- **GitHub/GitLab**: For version control and CI/CD

### **System Requirements**
```bash
# Verify Flutter installation
flutter doctor -v

# Expected output should show:
# ✓ Flutter (Channel stable, 3.27.4)
# ✓ Android toolchain
# ✓ Xcode (for iOS)
# ✓ Chrome (for web)
# ✓ VS Code
```

---

## 🔧 **Environment Setup**

### **Environment Variables**
Create environment-specific configuration files:

#### **Development Environment** (`.env.dev`)
```bash
# Firebase Configuration
FIREBASE_PROJECT_ID=auracare-01-dev
FIREBASE_API_KEY=your-dev-api-key
FIREBASE_AUTH_DOMAIN=auracare-01-dev.firebaseapp.com
FIREBASE_STORAGE_BUCKET=auracare-01-dev.appspot.com

# Gemini AI Configuration
GEMINI_API_KEY=your-dev-gemini-key
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta

# App Configuration
APP_NAME=AuraCare Dev
APP_BUNDLE_ID=com.auracare.dev
APP_VERSION=1.0.0+1
```

#### **Production Environment** (`.env.prod`)
```bash
# Firebase Configuration
FIREBASE_PROJECT_ID=auracare-01
FIREBASE_API_KEY=your-prod-api-key
FIREBASE_AUTH_DOMAIN=auracare-01.firebaseapp.com
FIREBASE_STORAGE_BUCKET=auracare-01.appspot.com

# Gemini AI Configuration
GEMINI_API_KEY=your-prod-gemini-key
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta

# App Configuration
APP_NAME=AuraCare
APP_BUNDLE_ID=com.auracare.app
APP_VERSION=1.0.0+1
```

### **Environment Configuration Class**
```dart
// lib/config/environment.dart
class Environment {
  static const String _environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
  
  static bool get isDevelopment => _environment == 'dev';
  static bool get isProduction => _environment == 'prod';
  
  // Firebase Configuration
  static String get firebaseProjectId => const String.fromEnvironment('FIREBASE_PROJECT_ID');
  static String get firebaseApiKey => const String.fromEnvironment('FIREBASE_API_KEY');
  static String get firebaseAuthDomain => const String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static String get firebaseStorageBucket => const String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  
  // Gemini AI Configuration
  static String get geminiApiKey => const String.fromEnvironment('GEMINI_API_KEY');
  static String get geminiBaseUrl => const String.fromEnvironment('GEMINI_BASE_URL');
  
  // App Configuration
  static String get appName => const String.fromEnvironment('APP_NAME');
  static String get appBundleId => const String.fromEnvironment('APP_BUNDLE_ID');
  static String get appVersion => const String.fromEnvironment('APP_VERSION');
}
```

---

## 🔥 **Firebase Configuration**

### **Project Setup**
1. **Create Firebase Projects**:
   - Development: `auracare-01-dev`
   - Production: `auracare-01`

2. **Enable Required Services**:
   ```bash
   # Authentication
   - Google Sign-In
   - Email/Password
   
   # Database
   - Cloud Firestore
   
   # Analytics
   - Firebase Analytics
   - Firebase Crashlytics
   
   # Hosting (for web)
   - Firebase Hosting
   ```

### **FlutterFire CLI Setup**
```bash
# Install FlutterFire CLI
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Configure Firebase for development
flutterfire configure --project=auracare-01-dev --out=lib/firebase_options_dev.dart

# Configure Firebase for production
flutterfire configure --project=auracare-01 --out=lib/firebase_options_prod.dart
```

### **Firebase Options Configuration**
```dart
// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'config/environment.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Environment.isProduction) {
      return prod.DefaultFirebaseOptions.currentPlatform;
    } else {
      return dev.DefaultFirebaseOptions.currentPlatform;
    }
  }
}
```

### **Firestore Security Rules**
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // User's mood data
      match /moods/{moodId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // User's chat sessions
      match /chat_sessions/{sessionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
        
        // Chat messages
        match /messages/{messageId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
        }
      }
      
      // User's journal entries
      match /journal_entries/{entryId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // User's meditation sessions
      match /meditation_sessions/{sessionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Public resources (read-only)
    match /help_resources/{resourceId} {
      allow read: if true;
    }
    
    match /meditation_content/{contentId} {
      allow read: if request.auth != null;
    }
  }
}
```

---

## 🔨 **Build Configuration**

### **Android Configuration**

#### **Build Gradle** (`android/app/build.gradle`)
```gradle
android {
    namespace "com.auracare.app"
    compileSdkVersion 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    defaultConfig {
        applicationId "com.auracare.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true
    }

    buildTypes {
        debug {
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
            signingConfig signingConfigs.debug
        }
        
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### **ProGuard Rules** (`android/app/proguard-rules.pro`)
```proguard
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
```

### **iOS Configuration**

#### **Info.plist** (`ios/Runner/Info.plist`)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>AuraCare</string>
    <key>CFBundleDisplayName</key>
    <string>AuraCare</string>
    <key>CFBundleIdentifier</key>
    <string>com.auracare.app</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    
    <!-- Privacy Permissions -->
    <key>NSCameraUsageDescription</key>
    <string>AuraCare needs camera access to take photos for journal entries.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>AuraCare needs photo library access to select images for journal entries.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>AuraCare uses location to find nearby mental health resources.</string>
    
    <!-- App Transport Security -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>
</dict>
</plist>
```

---

## 📱 **Platform-Specific Deployment**

### **Android Deployment**

#### **1. Generate Signing Key**
```bash
# Generate upload keystore
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Create key.properties file
echo "storePassword=your-store-password" > android/key.properties
echo "keyPassword=your-key-password" >> android/key.properties
echo "keyAlias=upload" >> android/key.properties
echo "storeFile=/path/to/upload-keystore.jks" >> android/key.properties
```

#### **2. Build Release APK**
```bash
# Build release APK
flutter build apk --release --dart-define=ENVIRONMENT=prod

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release --dart-define=ENVIRONMENT=prod
```

#### **3. Play Store Upload**
1. Open [Google Play Console](https://play.google.com/console)
2. Create new application
3. Upload App Bundle
4. Complete store listing
5. Submit for review

### **iOS Deployment**

#### **1. Xcode Configuration**
```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace

# Configure signing & capabilities:
# - Team: Select your Apple Developer team
# - Bundle Identifier: com.auracare.app
# - Signing Certificate: Distribution certificate
```

#### **2. Build Release IPA**
```bash
# Build iOS release
flutter build ios --release --dart-define=ENVIRONMENT=prod

# Archive in Xcode:
# Product > Archive > Distribute App > App Store Connect
```

#### **3. App Store Connect**
1. Open [App Store Connect](https://appstoreconnect.apple.com)
2. Create new app
3. Upload IPA via Xcode or Transporter
4. Complete app information
5. Submit for review

### **Web Deployment**

#### **1. Build Web Release**
```bash
# Build web release
flutter build web --release --dart-define=ENVIRONMENT=prod
```

#### **2. Firebase Hosting**
```bash
# Initialize Firebase hosting
firebase init hosting

# Deploy to Firebase
firebase deploy --only hosting
```

#### **3. Custom Domain Setup**
```bash
# Add custom domain in Firebase Console
# Update DNS records:
# A record: @ -> Firebase IP
# CNAME record: www -> your-project.web.app
```

---

## 🔄 **CI/CD Pipeline**

### **GitHub Actions Workflow**

#### **.github/workflows/deploy.yml**
```yaml
name: Deploy AuraCare

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.4'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test
      
      - name: Analyze code
        run: flutter analyze

  build-android:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.4'
      
      - name: Setup Android signing
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE }}" | base64 --decode > android/app/keystore.jks
          echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" >> android/key.properties
          echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
          echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties
          echo "storeFile=keystore.jks" >> android/key.properties
      
      - name: Build Android App Bundle
        run: flutter build appbundle --release --dart-define=ENVIRONMENT=prod
      
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: com.auracare.app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal

  build-ios:
    needs: test
    runs-on: macos-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.4'
      
      - name: Setup iOS signing
        run: |
          echo "${{ secrets.IOS_CERTIFICATE }}" | base64 --decode > certificate.p12
          echo "${{ secrets.IOS_PROVISIONING_PROFILE }}" | base64 --decode > profile.mobileprovision
          
          # Import certificate
          security create-keychain -p "" build.keychain
          security import certificate.p12 -k build.keychain -P "${{ secrets.IOS_CERTIFICATE_PASSWORD }}" -A
          security set-keychain-settings build.keychain
          security unlock-keychain -p "" build.keychain
          
          # Install provisioning profile
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
      
      - name: Build iOS
        run: flutter build ios --release --dart-define=ENVIRONMENT=prod --no-codesign
      
      - name: Archive and upload
        run: |
          xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive
          xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath build/ios -exportOptionsPlist ios/ExportOptions.plist
      
      - name: Upload to TestFlight
        run: xcrun altool --upload-app --type ios --file "build/ios/Runner.ipa" --username "${{ secrets.APPLE_ID }}" --password "${{ secrets.APPLE_PASSWORD }}"

  deploy-web:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.4'
      
      - name: Build web
        run: flutter build web --release --dart-define=ENVIRONMENT=prod
      
      - name: Deploy to Firebase Hosting
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: auracare-01
```

### **Required Secrets**
Configure these secrets in your repository settings:

```bash
# Android
ANDROID_KEYSTORE          # Base64 encoded keystore file
KEYSTORE_PASSWORD         # Keystore password
KEY_PASSWORD             # Key password
KEY_ALIAS               # Key alias
GOOGLE_PLAY_SERVICE_ACCOUNT  # Service account JSON

# iOS
IOS_CERTIFICATE          # Base64 encoded .p12 certificate
IOS_CERTIFICATE_PASSWORD # Certificate password
IOS_PROVISIONING_PROFILE # Base64 encoded provisioning profile
APPLE_ID                # Apple ID for uploads
APPLE_PASSWORD          # App-specific password

# Firebase
FIREBASE_SERVICE_ACCOUNT # Firebase service account JSON

# API Keys
GEMINI_API_KEY_PROD     # Production Gemini API key
```

---

## 📊 **Monitoring & Analytics**

### **Firebase Analytics Setup**
```dart
// lib/services/analytics_service.dart
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  // Track screen views
  static Future<void> trackScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }
  
  // Track user actions
  static Future<void> trackEvent(String eventName, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(name: eventName, parameters: parameters);
  }
  
  // Track mood entries
  static Future<void> trackMoodEntry(String mood, int intensity) async {
    await _analytics.logEvent(
      name: 'mood_entry',
      parameters: {
        'mood': mood,
        'intensity': intensity,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  // Track AI chat usage
  static Future<void> trackChatMessage(String sessionId, bool isUser) async {
    await _analytics.logEvent(
      name: 'chat_message',
      parameters: {
        'session_id': sessionId,
        'is_user': isUser,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
```

### **Crashlytics Setup**
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  runApp(const AuraCareApp());
}
```

### **Performance Monitoring**
```dart
// lib/services/performance_service.dart
class PerformanceService {
  static Future<T> trackPerformance<T>(
    String traceName,
    Future<T> Function() operation,
  ) async {
    final trace = FirebasePerformance.instance.newTrace(traceName);
    await trace.start();
    
    try {
      final result = await operation();
      trace.setMetric('success', 1);
      return result;
    } catch (e) {
      trace.setMetric('error', 1);
      rethrow;
    } finally {
      await trace.stop();
    }
  }
}
```

---

## 🔍 **Troubleshooting**

### **Common Build Issues**

#### **Android Build Failures**
```bash
# Clear build cache
flutter clean
flutter pub get

# Update Android SDK
sdkmanager --update

# Check Gradle version compatibility
cd android && ./gradlew --version
```

#### **iOS Build Failures**
```bash
# Clean iOS build
flutter clean
cd ios && rm -rf Pods Podfile.lock
flutter pub get
cd ios && pod install

# Update CocoaPods
sudo gem install cocoapods
pod repo update
```

#### **Firebase Configuration Issues**
```bash
# Regenerate Firebase configuration
flutterfire configure --project=your-project-id

# Verify Firebase services are enabled
firebase projects:list
firebase use your-project-id
```

### **Runtime Issues**

#### **API Key Errors**
```dart
// Verify API keys are properly configured
class ApiKeyValidator {
  static bool validateGeminiKey(String key) {
    return key.isNotEmpty && key.startsWith('AIza');
  }
  
  static bool validateFirebaseConfig() {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

#### **Network Connectivity Issues**
```dart
// Add network connectivity checks
class NetworkService {
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
```

### **Performance Issues**

#### **Memory Leaks**
```dart
// Proper disposal of resources
class ScreenWithController extends StatefulWidget {
  @override
  _ScreenWithControllerState createState() => _ScreenWithControllerState();
}

class _ScreenWithControllerState extends State<ScreenWithController> {
  late AnimationController _controller;
  late StreamSubscription _subscription;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _subscription = someStream.listen((data) {
      // Handle data
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _subscription.cancel();
    super.dispose();
  }
}
```

#### **Large Bundle Size**
```bash
# Analyze bundle size
flutter build apk --analyze-size
flutter build appbundle --analyze-size

# Enable code shrinking
# Add to android/app/build.gradle:
# minifyEnabled true
# shrinkResources true
```

---

## 📋 **Deployment Checklist**

### **Pre-Deployment**
- [ ] All tests passing
- [ ] Code analysis clean
- [ ] Environment variables configured
- [ ] API keys secured
- [ ] Firebase services enabled
- [ ] App icons and splash screens updated
- [ ] Privacy policy and terms of service ready

### **Android Deployment**
- [ ] Signing key generated and secured
- [ ] App Bundle built successfully
- [ ] Play Store listing completed
- [ ] Screenshots and descriptions added
- [ ] Content rating completed
- [ ] Release notes prepared

### **iOS Deployment**
- [ ] Apple Developer account active
- [ ] Certificates and provisioning profiles configured
- [ ] App Store Connect listing completed
- [ ] Screenshots for all device sizes
- [ ] App Review Guidelines compliance
- [ ] TestFlight testing completed

### **Web Deployment**
- [ ] Firebase Hosting configured
- [ ] Custom domain setup (if applicable)
- [ ] SSL certificate active
- [ ] PWA manifest configured
- [ ] Service worker implemented

### **Post-Deployment**
- [ ] Analytics tracking verified
- [ ] Crash reporting active
- [ ] Performance monitoring enabled
- [ ] User feedback channels established
- [ ] Support documentation updated

---

This comprehensive deployment guide ensures a smooth and successful launch of MindMate (AuraCare) across all platforms while maintaining security, performance, and reliability standards.
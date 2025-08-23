# 🤝 Contributing to MindMate (AuraCare)

Welcome to the MindMate (AuraCare) project! We're excited that you're interested in contributing to a mental wellness application that can make a real difference in people's lives.

## 📋 **Table of Contents**
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Community Guidelines](#community-guidelines)

---

## 🌟 **Code of Conduct**

### **Our Commitment**
MindMate (AuraCare) is dedicated to providing a safe, inclusive, and supportive environment for all contributors. We are committed to creating a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### **Expected Behavior**
- **Be Respectful**: Treat all community members with respect and kindness
- **Be Inclusive**: Welcome newcomers and help them feel included
- **Be Constructive**: Provide helpful feedback and suggestions
- **Be Patient**: Remember that everyone has different skill levels and backgrounds
- **Be Mindful**: Consider the mental health focus of this project in all interactions

### **Unacceptable Behavior**
- Harassment, discrimination, or offensive comments
- Personal attacks or trolling
- Publishing private information without consent
- Any behavior that could be harmful to users' mental health
- Spam or irrelevant content

### **Reporting**
If you experience or witness unacceptable behavior, please report it to the project maintainers immediately.

---

## 🚀 **Getting Started**

### **Prerequisites**
Before contributing, ensure you have:
- **Flutter SDK**: 3.27.4 or later
- **Dart SDK**: 3.6.2 or later
- **Git**: For version control
- **IDE**: VS Code or Android Studio with Flutter plugins
- **Firebase Account**: For backend services

### **Development Setup**
1. **Fork the Repository**
   ```bash
   # Fork the repo on GitHub, then clone your fork
   git clone https://github.com/abhishek-maurya576/auracare.git
   cd auracare
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Set Up Firebase**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase (use development project)
   flutterfire configure --project=auracare-01-dev
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

5. **Verify Setup**
   ```bash
   flutter doctor
   flutter analyze
   flutter test
   ```

---

## 🔄 **Development Workflow**

### **Branch Strategy**
We use **Git Flow** with the following branches:

- **`main`**: Production-ready code
- **`develop`**: Integration branch for features
- **`feature/*`**: New features (e.g., `feature/meditation-module`)
- **`bugfix/*`**: Bug fixes (e.g., `bugfix/auth-error`)
- **`hotfix/*`**: Critical production fixes

### **Creating a Feature Branch**
```bash
# Start from develop branch
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/your-feature-name

# Make your changes and commit
git add .
git commit -m "feat: add meditation breathing exercise"

# Push to your fork
git push origin feature/your-feature-name
```

### **Commit Message Convention**
We follow **Conventional Commits** specification:

```bash
# Format: type(scope): description
feat(auth): add Google Sign-In integration
fix(mood): resolve mood tracking data persistence
docs(api): update API documentation
style(ui): improve glass-morphism card styling
refactor(services): optimize Firebase queries
test(mood): add unit tests for mood provider
chore(deps): update Flutter dependencies
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

---

## 📝 **Coding Standards**

### **Dart/Flutter Guidelines**

#### **Code Style**
```dart
// Use descriptive variable names
final List<MoodEntry> userMoodHistory = [];

// Prefer const constructors
const GlassCard(
  title: 'Mood Tracker',
  subtitle: 'Track your daily emotions',
);

// Use proper null safety
String? getUserDisplayName(User? user) {
  return user?.displayName ?? 'Anonymous';
}

// Follow naming conventions
class MoodTrackingService {} // PascalCase for classes
final String apiEndpoint = ''; // camelCase for variables
const int MAX_RETRY_ATTEMPTS = 3; // UPPER_CASE for constants
```

#### **File Organization**
```
lib/
├── config/          # Configuration files
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── services/        # Business logic
├── utils/           # Utility functions
├── widgets/         # Reusable components
└── main.dart        # App entry point
```

#### **Import Organization**
```dart
// Dart imports
import 'dart:async';
import 'dart:convert';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// Local imports
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
```

### **UI/UX Guidelines**

#### **Glass-morphism Components**
```dart
// Always use the established glass-morphism system
class CustomCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard( // Use existing components
      title: 'Custom Feature',
      child: YourContent(),
    );
  }
}

// Follow color palette
Container(
  decoration: BoxDecoration(
    color: AppColors.glassWhite, // Use defined colors
    borderRadius: BorderRadius.circular(28), // Consistent radius
  ),
)
```

#### **Accessibility Requirements**
```dart
// Always provide semantic labels
Semantics(
  label: 'Select happy mood',
  hint: 'Tap to record that you are feeling happy',
  child: MoodButton(mood: 'happy'),
);

// Ensure sufficient color contrast
Text(
  'Important message',
  style: TextStyle(
    color: AppColors.textPrimary, // High contrast
    fontSize: 16,
  ),
);

// Support reduced motion
AnimatedContainer(
  duration: MediaQuery.of(context).disableAnimations 
      ? Duration.zero 
      : Duration(milliseconds: 300),
  child: content,
);
```

### **Mental Health Considerations**

#### **Sensitive Content Handling**
```dart
// Always validate and sanitize user input
String sanitizeUserInput(String input) {
  return input.trim().replaceAll(RegExp(r'[<>]'), '');
}

// Implement crisis detection
bool detectCrisisKeywords(String message) {
  final crisisKeywords = [
    'suicide', 'self harm', 'want to die', 'hopeless'
  ];
  return crisisKeywords.any((keyword) => 
      message.toLowerCase().contains(keyword));
}

// Provide appropriate responses
String getCrisisResponse() {
  return '''
I'm concerned about what you're sharing. Please reach out for help:
• National Suicide Prevention Lifeline: 988
• Crisis Text Line: Text HOME to 741741
• Emergency Services: 911
''';
}
```

---

## 🧪 **Testing Guidelines**

### **Testing Strategy**
- **Unit Tests**: Test individual functions and classes
- **Widget Tests**: Test UI components
- **Integration Tests**: Test complete user flows
- **Manual Testing**: Test on real devices

### **Writing Unit Tests**
```dart
// test/services/mood_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:auracare/services/mood_service.dart';
import 'package:auracare/models/mood_entry.dart';

void main() {
  group('MoodService', () {
    late MoodService moodService;
    
    setUp(() {
      moodService = MoodService();
    });
    
    test('should save mood entry successfully', () async {
      // Arrange
      final moodEntry = MoodEntry(
        id: 'test-id',
        userId: 'user-123',
        mood: 'happy',
        intensity: 8,
        timestamp: DateTime.now(),
      );
      
      // Act
      await moodService.saveMoodEntry(moodEntry);
      
      // Assert
      final savedEntry = await moodService.getMoodEntry('test-id');
      expect(savedEntry?.mood, equals('happy'));
      expect(savedEntry?.intensity, equals(8));
    });
    
    test('should handle invalid mood data', () {
      // Arrange
      final invalidEntry = MoodEntry(
        id: '',
        userId: '',
        mood: '',
        intensity: -1,
        timestamp: DateTime.now(),
      );
      
      // Act & Assert
      expect(
        () => moodService.saveMoodEntry(invalidEntry),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
```

### **Writing Widget Tests**
```dart
// test/widgets/mood_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auracare/widgets/mood_card.dart';

void main() {
  group('MoodCard Widget', () {
    testWidgets('should display mood information correctly', (tester) async {
      // Arrange
      const moodCard = MoodCard(
        mood: 'happy',
        emoji: '😊',
        intensity: 8,
      );
      
      // Act
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: moodCard)),
      );
      
      // Assert
      expect(find.text('😊'), findsOneWidget);
      expect(find.text('happy'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });
    
    testWidgets('should handle tap events', (tester) async {
      // Arrange
      bool tapped = false;
      final moodCard = MoodCard(
        mood: 'happy',
        emoji: '😊',
        onTap: () => tapped = true,
      );
      
      // Act
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: moodCard)),
      );
      await tester.tap(find.byType(MoodCard));
      
      // Assert
      expect(tapped, isTrue);
    });
  });
}
```

### **Running Tests**
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/mood_service_test.dart

# Run tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 🔍 **Pull Request Process**

### **Before Submitting**
1. **Code Quality**
   ```bash
   # Run analysis
   flutter analyze
   
   # Format code
   dart format .
   
   # Run tests
   flutter test
   ```

2. **Documentation**
   - Update relevant documentation
   - Add inline code comments for complex logic
   - Update API documentation if needed

3. **Testing**
   - Add tests for new features
   - Ensure existing tests pass
   - Test on multiple devices/screen sizes

### **Pull Request Template**
```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Manual testing completed
- [ ] Tested on multiple devices

## Mental Health Considerations
- [ ] Content is appropriate and supportive
- [ ] Crisis detection implemented (if applicable)
- [ ] Accessibility guidelines followed
- [ ] User privacy protected

## Screenshots (if applicable)
Add screenshots of UI changes.

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added and passing
- [ ] No breaking changes (or clearly documented)
```

### **Review Process**
1. **Automated Checks**: CI/CD pipeline runs tests and analysis
2. **Code Review**: Maintainers review code quality and design
3. **Mental Health Review**: Ensure content is appropriate and supportive
4. **Testing**: Verify functionality on different devices
5. **Approval**: At least one maintainer approval required
6. **Merge**: Squash and merge to maintain clean history

---

## 🐛 **Issue Reporting**

### **Bug Reports**
Use the bug report template:

```markdown
**Bug Description**
A clear description of the bug.

**Steps to Reproduce**
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected Behavior**
What you expected to happen.

**Actual Behavior**
What actually happened.

**Screenshots**
Add screenshots if applicable.

**Environment**
- Device: [e.g. iPhone 12, Pixel 5]
- OS: [e.g. iOS 15.0, Android 12]
- App Version: [e.g. 1.0.0]
- Flutter Version: [e.g. 3.27.4]

**Additional Context**
Any other context about the problem.

**Mental Health Impact**
If this bug could affect user mental health or safety, please describe how.
```

### **Feature Requests**
Use the feature request template:

```markdown
**Feature Description**
A clear description of the feature you'd like to see.

**Problem Statement**
What problem does this feature solve?

**Proposed Solution**
How would you like this feature to work?

**Mental Health Benefits**
How would this feature support user mental health and wellbeing?

**Alternatives Considered**
Other solutions you've considered.

**Additional Context**
Any other context, mockups, or examples.
```

### **Security Issues**
For security vulnerabilities:
1. **DO NOT** create a public issue
2. Email security concerns to the maintainers
3. Include detailed reproduction steps
4. Allow time for fix before public disclosure

---

## 👥 **Community Guidelines**

### **Communication Channels**
- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Pull Requests**: Code contributions and reviews

### **Getting Help**
- **Documentation**: Check existing docs first
- **Search Issues**: Look for similar problems
- **Ask Questions**: Use GitHub Discussions
- **Be Patient**: Maintainers are volunteers

### **Recognition**
Contributors will be recognized in:
- **README**: Contributors section
- **Release Notes**: Feature acknowledgments
- **GitHub**: Contributor badges

### **Mentorship**
New contributors can:
- **Start Small**: Look for "good first issue" labels
- **Ask for Help**: Maintainers are happy to guide
- **Pair Program**: Request code review sessions
- **Learn Together**: Join community discussions

---

## 🎯 **Contribution Areas**

### **High Priority**
- **Testing**: Add comprehensive test coverage
- **Accessibility**: Improve accessibility features
- **Performance**: Optimize app performance
- **Documentation**: Improve user and developer docs

### **Feature Development**
- **Meditation Module**: Complete breathing exercises
- **Journaling**: Implement encrypted journaling
- **Community Features**: Add peer support
- **Offline Mode**: Enable offline functionality

### **Design & UX**
- **UI Components**: Enhance glass-morphism system
- **Animations**: Add meaningful micro-interactions
- **Responsive Design**: Improve tablet/desktop layouts
- **Accessibility**: Ensure inclusive design

### **Infrastructure**
- **CI/CD**: Improve automation
- **Security**: Enhance data protection
- **Performance**: Optimize build and runtime
- **Monitoring**: Add better analytics

---

## 📚 **Resources**

### **Learning Materials**
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Guide](https://dart.dev/guides)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Mental Health First Aid](https://www.mentalhealthfirstaid.org/)

### **Design Resources**
- [Material Design 3](https://m3.material.io/)
- [Accessibility Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Glass-morphism Design](https://uxdesign.cc/glassmorphism-in-user-interfaces-1f39bb1308c9)

### **Development Tools**
- [VS Code Flutter Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
- [Android Studio](https://developer.android.com/studio)
- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)

---

## 🙏 **Thank You**

Thank you for contributing to MindMate (AuraCare)! Your efforts help create a supportive digital environment for mental wellness. Every contribution, no matter how small, makes a difference in someone's mental health journey.

Together, we're building more than just an app – we're creating a community of support, understanding, and healing.

**Happy Contributing! 💜**
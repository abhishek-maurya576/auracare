# 🎨 MindMate (AuraCare) UI/UX Design Guidelines

## 📋 **Table of Contents**
- [Design Philosophy](#design-philosophy)
- [Glass-morphism Design System](#glass-morphism-design-system)
- [Color Palette](#color-palette)
- [Typography](#typography)
- [Component Library](#component-library)
- [Animation Guidelines](#animation-guidelines)
- [Accessibility](#accessibility)
- [Responsive Design](#responsive-design)

---

## 🎯 **Design Philosophy**

### **Core Principles**
MindMate (AuraCare) follows a **liquid glass-morphism** design philosophy that prioritizes:

1. **Psychological Comfort**: Calming, non-intrusive interface that reduces cognitive load
2. **Emotional Safety**: Warm, welcoming design that encourages vulnerability and openness
3. **Mindful Interaction**: Smooth, intentional animations that promote mindfulness
4. **Accessibility First**: Inclusive design for users with diverse needs
5. **Therapeutic Aesthetics**: Visual elements that support mental wellness

### **Design Goals**
- Create a **sanctuary-like** digital environment
- Minimize **visual stress** and overwhelming elements
- Promote **focus and clarity** through clean layouts
- Encourage **regular engagement** through delightful interactions
- Support **emotional expression** through thoughtful UI patterns

---

## 🌊 **Glass-morphism Design System**

### **Visual Characteristics**
- **Translucency**: Semi-transparent surfaces with blur effects
- **Depth**: Layered elements with subtle shadows and highlights
- **Fluidity**: Organic shapes and smooth transitions
- **Luminosity**: Soft glows and light-based interactions

### **Glass Effect Implementation**
```dart
class GlassWidget extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  
  const GlassWidget({
    super.key,
    required this.child,
    this.radius = 28,
    this.blurSigma = 18,
    this.backgroundColor,
    this.borderColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.glassWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              width: 1,
              color: borderColor ?? AppColors.glassBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.glassShadow,
                blurRadius: 48,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
```

### **Glass Effect Variations**

#### **Primary Glass Card**
- **Opacity**: 10% white (`Color(0x1AFFFFFF)`)
- **Blur**: 18px
- **Border**: 20% white (`Color(0x33FFFFFF)`)
- **Shadow**: 10% black with 48px blur
- **Radius**: 28px

#### **Secondary Glass Card**
- **Opacity**: 8% white (`Color(0x14FFFFFF)`)
- **Blur**: 16px
- **Border**: 15% white (`Color(0x26FFFFFF)`)
- **Shadow**: 8% black with 32px blur
- **Radius**: 24px

#### **Accent Glass Card**
- **Opacity**: 12% white (`Color(0x1FFFFFFF)`)
- **Blur**: 20px
- **Border**: 25% white (`Color(0x40FFFFFF)`)
- **Shadow**: 12% black with 56px blur
- **Radius**: 32px

---

## 🎨 **Color Palette**

### **Primary Colors**
```dart
class AppColors {
  // Background gradients
  static const Color primaryNavy = Color(0xFF0F172A);      // Deep navy
  static const Color primaryTeal = Color(0xFF0E4F4F);      // Deep teal
  static const Color primaryIndigo = Color(0xFF1E1B4B);    // Deep indigo
  
  // Accent colors
  static const Color accentLavender = Color(0xFF8B5CF6);   // Calming lavender
  static const Color accentTeal = Color(0xFF14B8A6);       // Refreshing teal
  static const Color accentPeach = Color(0xFFFF8A65);      // Warm peach
  static const Color accentSoftBlue = Color(0xFF60A5FA);   // Gentle blue
  
  // Mood colors
  static const Color moodHappy = Color(0xFFFBBF24);        // Sunny yellow
  static const Color moodCalm = Color(0xFF14B8A6);         // Peaceful teal
  static const Color moodNeutral = Color(0xFF6B7280);      // Balanced gray
  static const Color moodSad = Color(0xFF3B82F6);          // Gentle blue
  static const Color moodStressed = Color(0xFF8B5CF6);     // Soothing purple
  
  // Glass effects
  static const Color glassWhite = Color(0x1AFFFFFF);       // 10% white
  static const Color glassBorder = Color(0x33FFFFFF);      // 20% white
  static const Color glassShadow = Color(0x1A000000);      // 10% black
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);      // Pure white
  static const Color textSecondary = Color(0xB3FFFFFF);    // 70% white
  static const Color textTertiary = Color(0x80FFFFFF);     // 50% white
  
  // Status colors
  static const Color success = Color(0xFF10B981);          // Success green
  static const Color warning = Color(0xFFF59E0B);          // Warning amber
  static const Color error = Color(0xFFEF4444);            // Error red
  static const Color info = Color(0xFF3B82F6);             // Info blue
}
```

### **Color Usage Guidelines**

#### **Background Gradients**
```dart
// Primary background gradient
static const LinearGradient primaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    AppColors.primaryNavy,
    AppColors.primaryTeal,
  ],
);

// Mood-based gradients
static const LinearGradient happyGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF0F172A),
    Color(0xFF1F2937),
    Color(0xFFFBBF24),
  ],
);
```

#### **Mood Color Mapping**
| Mood | Color | Hex | Usage |
|------|-------|-----|-------|
| **Happy** | Sunny Yellow | `#FBBF24` | Mood indicators, positive feedback |
| **Calm** | Peaceful Teal | `#14B8A6` | Meditation, breathing exercises |
| **Neutral** | Balanced Gray | `#6B7280` | Default states, neutral content |
| **Sad** | Gentle Blue | `#3B82F6` | Supportive messaging, empathy |
| **Stressed** | Soothing Purple | `#8B5CF6` | Stress relief, calming features |

---

## ✍️ **Typography**

### **Font Family**
**Primary**: Inter (Google Fonts)
- **Rationale**: Excellent readability, modern appearance, supports mental wellness apps
- **Fallback**: System default sans-serif

```dart
TextTheme textTheme = GoogleFonts.interTextTheme(
  Theme.of(context).textTheme.apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  ),
);
```

### **Typography Scale**

#### **Display Styles**
```dart
// Display Large - App titles, major headings
static const TextStyle displayLarge = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w700,
  height: 1.2,
  letterSpacing: -0.5,
  color: AppColors.textPrimary,
);

// Display Medium - Section headers
static const TextStyle displayMedium = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w600,
  height: 1.3,
  letterSpacing: -0.25,
  color: AppColors.textPrimary,
);

// Display Small - Card titles
static const TextStyle displaySmall = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  height: 1.3,
  color: AppColors.textPrimary,
);
```

#### **Headline Styles**
```dart
// Headline Large - Page titles
static const TextStyle headlineLarge = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w600,
  height: 1.4,
  color: AppColors.textPrimary,
);

// Headline Medium - Section titles
static const TextStyle headlineMedium = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w500,
  height: 1.4,
  color: AppColors.textPrimary,
);

// Headline Small - Subsection titles
static const TextStyle headlineSmall = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w500,
  height: 1.4,
  color: AppColors.textPrimary,
);
```

#### **Body Styles**
```dart
// Body Large - Primary content
static const TextStyle bodyLarge = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  height: 1.5,
  color: AppColors.textPrimary,
);

// Body Medium - Secondary content
static const TextStyle bodyMedium = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  height: 1.5,
  color: AppColors.textSecondary,
);

// Body Small - Captions, metadata
static const TextStyle bodySmall = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  height: 1.4,
  color: AppColors.textTertiary,
);
```

#### **Label Styles**
```dart
// Label Large - Button text
static const TextStyle labelLarge = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.3,
  letterSpacing: 0.1,
  color: AppColors.textPrimary,
);

// Label Medium - Form labels
static const TextStyle labelMedium = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  height: 1.3,
  letterSpacing: 0.1,
  color: AppColors.textSecondary,
);

// Label Small - Small buttons, tags
static const TextStyle labelSmall = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 1.3,
  letterSpacing: 0.1,
  color: AppColors.textTertiary,
);
```

---

## 🧩 **Component Library**

### **Glass Card Component**
```dart
class GlassCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? child;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final double? height;

  const GlassCard({
    super.key,
    this.title,
    this.subtitle,
    this.child,
    this.leadingIcon,
    this.trailingIcon = Icons.chevron_right_rounded,
    this.onTap,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GlassWidget(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: height,
          padding: padding ?? const EdgeInsets.all(20),
          child: child ?? _buildDefaultContent(),
        ),
      ),
    );
  }
}
```

### **Mood Pill Component**
```dart
class MoodPill extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const MoodPill({
    super.key,
    required this.emoji,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.accentLavender.withOpacity(0.3)
              : AppColors.glassWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppColors.accentLavender
                : AppColors.glassBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected 
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### **Glass Button Component**
```dart
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;

  const GlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassWidget(
      backgroundColor: backgroundColor ?? AppColors.accentTeal.withOpacity(0.2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textPrimary,
                      ),
                    ),
                  )
                else if (icon != null) ...[
                  Icon(
                    icon,
                    color: textColor ?? AppColors.textPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: textColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### **Animated Background Component**
```dart
class AuraBackground extends StatefulWidget {
  final Widget? child;
  
  const AuraBackground({super.key, this.child});

  @override
  State<AuraBackground> createState() => _AuraBackgroundState();
}

class _AuraBackgroundState extends State<AuraBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _controller2 = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    _controller3 = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Stack(
        children: [
          // Animated blobs
          _buildAnimatedBlob(_controller1, 0.3, 0.2, AppColors.accentLavender),
          _buildAnimatedBlob(_controller2, 0.7, 0.8, AppColors.accentTeal),
          _buildAnimatedBlob(_controller3, 0.1, 0.6, AppColors.accentPeach),
          
          // Content
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}
```

---

## 🎬 **Animation Guidelines**

### **Animation Principles**
1. **Purposeful**: Every animation should serve a functional purpose
2. **Calming**: Smooth, gentle movements that reduce anxiety
3. **Responsive**: Immediate feedback for user interactions
4. **Consistent**: Unified timing and easing across the app
5. **Accessible**: Respect user preferences for reduced motion

### **Timing Standards**
```dart
class AnimationDurations {
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 800);
  static const Duration ambient = Duration(seconds: 2);
}
```

### **Easing Curves**
```dart
class AnimationCurves {
  static const Curve gentle = Curves.easeInOutCubic;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.easeInOutQuart;
  static const Curve sharp = Curves.easeInOutExpo;
}
```

### **Common Animations**

#### **Page Transitions**
```dart
class GlassPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  
  GlassPageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: AnimationDurations.normal,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: AnimationCurves.gentle,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
}
```

#### **Card Hover Effects**
```dart
class HoverableGlassCard extends StatefulWidget {
  final Widget child;
  
  const HoverableGlassCard({super.key, required this.child});

  @override
  State<HoverableGlassCard> createState() => _HoverableGlassCardState();
}

class _HoverableGlassCardState extends State<HoverableGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationDurations.fast,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationCurves.gentle,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationCurves.gentle,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentLavender.withOpacity(_glowAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
```

---

## ♿ **Accessibility**

### **Accessibility Standards**
- **WCAG 2.1 AA Compliance**: Meet international accessibility standards
- **Screen Reader Support**: Semantic markup and proper labels
- **Keyboard Navigation**: Full app functionality without mouse
- **High Contrast**: Sufficient color contrast ratios
- **Reduced Motion**: Respect user motion preferences

### **Implementation Guidelines**

#### **Semantic Labels**
```dart
// Proper semantic labeling
Semantics(
  label: 'Select happy mood',
  hint: 'Tap to record that you are feeling happy',
  child: MoodPill(
    emoji: '😊',
    label: 'Happy',
    onTap: () => _selectMood('happy'),
  ),
);
```

#### **Color Contrast**
```dart
// Ensure sufficient contrast ratios
class AccessibilityColors {
  // Minimum 4.5:1 contrast ratio for normal text
  static const Color highContrastText = Color(0xFFFFFFFF);
  static const Color highContrastBackground = Color(0xFF000000);
  
  // Minimum 3:1 contrast ratio for large text
  static const Color mediumContrastText = Color(0xFFE5E5E5);
  static const Color mediumContrastBackground = Color(0xFF333333);
}
```

#### **Reduced Motion Support**
```dart
class MotionSettings {
  static bool get reduceMotions {
    return MediaQuery.of(context).disableAnimations;
  }
  
  static Duration getAnimationDuration(Duration defaultDuration) {
    return reduceMotions ? Duration.zero : defaultDuration;
  }
}
```

---

## 📱 **Responsive Design**

### **Breakpoints**
```dart
class Breakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;
}
```

### **Responsive Layout**
```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= Breakpoints.tablet) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
```

### **Adaptive Spacing**
```dart
class AdaptiveSpacing {
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= Breakpoints.desktop) return 32;
    if (width >= Breakpoints.tablet) return 24;
    return 16;
  }
  
  static double getVerticalSpacing(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    if (height >= 800) return 24;
    if (height >= 600) return 20;
    return 16;
  }
}
```

---

## 🎨 **Design Tokens**

### **Spacing System**
```dart
class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}
```

### **Border Radius**
```dart
class BorderRadius {
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 28;
  static const double pill = 999;
}
```

### **Elevation System**
```dart
class Elevation {
  static const List<BoxShadow> low = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> high = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
```

---

This comprehensive UI/UX guideline ensures consistent, accessible, and beautiful design throughout the MindMate (AuraCare) application, supporting the app's mission of providing a calming and supportive digital environment for mental wellness.
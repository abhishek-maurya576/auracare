import 'package:flutter/material.dart';

class AppColors {
  // Background gradients
  static const Color backgroundStart = Color(0xFF0F172A); // Deep navy
  static const Color backgroundMiddle = Color(0xFF0B2E3C); // Navy to teal
  static const Color backgroundEnd = Color(0xFF0E4F4F); // Teal

  // Accent colors (aura rings)
  static const Color accentYellow = Color(0xFFFFD66E);
  static const Color accentTeal = Color(0xFF7EE7D1);
  static const Color accentBlue = Color(0xFF60A5FA);

  // Mood emotion colors - updated to match the new UI design
  static const Color moodHappy = Color(0xFFE0E0E0); // Light gray for happy emoji
  static const Color moodCalm = Color(0xFFE0E0E0); // Light gray for calm emoji
  static const Color moodNeutral = Color(0xFFE0E0E0); // Light gray for neutral emoji
  static const Color moodSad = Color(0xFFE0E0E0); // Light gray for sad emoji
  static const Color moodStressed = Color(0xFFE0E0E0); // Light gray for stressed emoji
  static const Color moodAngry = Color(0xFFE0E0E0); // Light gray for angry emoji

  // Glass effect colors
  static const Color glassWhite = Color(0x1EFFFFFF); // White 12% opacity
  static const Color glassBorder = Color(0x33FFFFFF); // White 20% opacity for borders
  static const Color glassShadow = Color(0x3D000000); // Black 24% opacity

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xCCFFFFFF);
  static const Color textMuted = Color(0x99FFFFFF);

  // Gradient for glass borders
  static const LinearGradient glassBorderGradient = LinearGradient(
    colors: [
      Color(0x4DFFFFFF), // White 30%
      Color(0x4D9AE6B4), // Green 30%
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundStart, backgroundMiddle, backgroundEnd],
  );

  // Aura blob gradients
  static const RadialGradient auraGradient1 = RadialGradient(
    colors: [accentYellow, accentTeal],
  );

  static const RadialGradient auraGradient2 = RadialGradient(
    colors: [accentBlue, accentTeal],
  );
}


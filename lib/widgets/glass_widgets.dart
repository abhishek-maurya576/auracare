import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/mood_provider.dart';

/// Base glass widget with blur effect and translucent styling
class GlassWidget extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets? padding;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;

  const GlassWidget({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding,
    this.blurSigma = 18,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.borderRadius,
  });

  factory GlassWidget.circle({
    required Widget child,
    double blurSigma = 18,
  }) =>
      GlassWidget(
        radius: 999,
        blurSigma: blurSigma,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(radius);
    
    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.glassWhite,
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              width: 1,
              color: borderColor ?? AppColors.glassBorder,
            ),
            boxShadow: boxShadow ?? [
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

/// Glass card widget for main UI components
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
    Widget content = child ??
        ListTile(
          leading: leadingIcon != null
              ? Icon(
                  leadingIcon,
                  color: AppColors.textPrimary,
                  size: 28,
                )
              : null,
          title: title != null
              ? Text(
                  title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                )
              : null,
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                )
              : null,
          trailing: trailingIcon != null
              ? Icon(
                  trailingIcon,
                  color: AppColors.textSecondary,
                )
              : null,
          onTap: onTap,
        );

    if (height != null) {
      content = SizedBox(height: height, child: content);
    }

    return GlassWidget(
      padding: padding,
      child: content,
    );
  }
}

/// Mood pill widget for displaying current mood
class MoodPill extends StatelessWidget {
  final String emoji;
  final String label;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const MoodPill({
    super.key,
    required this.emoji,
    required this.label,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassWidget(
        radius: 999,
        backgroundColor: backgroundColor ?? AppColors.glassWhite,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dynamic mood pill that shows user's latest mood from mood provider
class DynamicMoodPill extends StatelessWidget {
  final VoidCallback? onTap;

  const DynamicMoodPill({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        final latestMood = moodProvider.latestMood;
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 400;
        
        // Default mood if no mood entry exists
        final emoji = latestMood?.emoji ?? '😊';
        final label = latestMood?.mood ?? 'Check In';
        final intensity = latestMood?.intensity ?? 5;
        
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Ultra-responsive design based on available width
                final availableWidth = constraints.maxWidth;
                final isUltraCompact = availableWidth < 60; // Less than 60px width
                final isTiny = availableWidth < 40; // Less than 40px width
                
                return GlassWidget(
                  radius: 999,
                  backgroundColor: _getMoodColor(label, intensity),
                  borderColor: _getMoodBorderColor(label),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTiny ? 4 : (isUltraCompact ? 6 : (isCompact ? 8 : 12)),
                      vertical: isTiny ? 4 : (isUltraCompact ? 5 : (isCompact ? 6 : 8)),
                    ),
                    child: _buildMoodContent(
                      emoji: emoji,
                      label: label,
                      intensity: intensity,
                      latestMood: latestMood,
                      availableWidth: availableWidth,
                      isCompact: isCompact,
                      isUltraCompact: isUltraCompact,
                      isTiny: isTiny,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodContent({
    required String emoji,
    required String label,
    required int intensity,
    required dynamic latestMood,
    required double availableWidth,
    required bool isCompact,
    required bool isUltraCompact,
    required bool isTiny,
  }) {
    // For extremely tight constraints, show only emoji
    if (isTiny || availableWidth < 35) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          emoji,
          key: ValueKey(emoji),
          style: TextStyle(
            fontSize: 12, // Very small emoji for tiny spaces
          ),
        ),
      );
    }

    // For ultra-compact spaces, show emoji with minimal or no text
    if (isUltraCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              emoji,
              key: ValueKey(emoji),
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          ),
          
          // Only show text if there's enough space AND no mood logged
          if (availableWidth > 45 && latestMood == null) ...[
            const SizedBox(width: 3),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '✓', // Just a checkmark for ultra-compact
                  key: const ValueKey('check'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Normal responsive layout for adequate space
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated emoji
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            emoji,
            key: ValueKey(emoji),
            style: TextStyle(
              fontSize: isCompact ? 14 : 16,
            ),
          ),
        ),
        
        if (!isCompact || latestMood == null) ...[
          const SizedBox(width: 6),
          // Animated label with overflow protection
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                label,
                key: ValueKey(label),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: isCompact ? 12 : 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
        
        // Show intensity indicator for logged moods
        if (latestMood != null && !isCompact && availableWidth > 80) ...[
          const SizedBox(width: 4),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _getIntensityColor(intensity),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  Color _getMoodColor(String mood, int intensity) {
    final baseColors = {
      'Happy': const Color(0xFFFEF3C7).withAlpha((255 * 0.6).toInt()),
      'Calm': const Color(0xFFDCFDF7).withAlpha((255 * 0.6).toInt()),
      'Neutral': AppColors.glassWhite,
      'Sad': const Color(0xFFDDD6FE).withAlpha((255 * 0.6).toInt()),
      'Stressed': const Color(0xFFFEE2E2).withAlpha((255 * 0.6).toInt()),
    };
    
    final baseColor = baseColors[mood] ?? AppColors.glassWhite;
    
    // Adjust opacity based on intensity
    final intensityFactor = (intensity / 10.0).clamp(0.3, 1.0);
    return Color.lerp(AppColors.glassWhite, baseColor, intensityFactor) ?? AppColors.glassWhite;
  }

  Color _getMoodBorderColor(String mood) {
    const borderColors = {
      'Happy': Color(0xFFFBBF24),
      'Calm': Color(0xFF10B981),
      'Neutral': AppColors.glassBorder,
      'Sad': Color(0xFF8B5CF6),
      'Stressed': Color(0xFFEF4444),
    };
    
    return (borderColors[mood] ?? AppColors.glassBorder).withAlpha((255 * 0.4).toInt());
  }

  Color _getIntensityColor(int intensity) {
    if (intensity <= 3) return const Color(0xFF10B981); // Green for low intensity
    if (intensity <= 7) return const Color(0xFFFBBF24); // Yellow for medium intensity
    return const Color(0xFFEF4444); // Red for high intensity
  }
}

/// Enhanced Glass app bar widget with user profile integration
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? trailing;
  final Widget? leading;
  final bool centerTitle;
  final bool showUserProfile;
  final String? userName;
  final String? userPhotoUrl;
  final VoidCallback? onProfileTap;
  final bool showNotificationBadge;
  final int notificationCount;

  const GlassAppBar({
    super.key,
    required this.title,
    this.trailing,
    this.leading,
    this.centerTitle = false,
    this.showUserProfile = false,
    this.userName,
    this.userPhotoUrl,
    this.onProfileTap,
    this.showNotificationBadge = false,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      leading: leading,
      toolbarHeight: 70,
      title: _buildResponsiveNavbar(context),
    );
  }

  Widget _buildResponsiveNavbar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final isVeryCompact = screenWidth < 350;
    
    return GlassWidget(
      padding: EdgeInsets.symmetric(
        horizontal: isVeryCompact ? 8 : (isCompact ? 12 : 16), 
        vertical: isCompact ? 10 : 12,
      ),
      child: Row(
        children: [
          // Left side - App branding (always flexible)
          Expanded(
            flex: isVeryCompact ? 1 : (isCompact ? 2 : 3),
            child: _buildAppBranding(context, isCompact),
          ),
          
          // Center spacer (minimal on small screens)
          SizedBox(width: isVeryCompact ? 4 : (isCompact ? 6 : 8)),
          
          // Right side - User profile and actions (always flexible)
          Expanded(
            flex: isVeryCompact ? 2 : (isCompact ? 3 : 2),
            child: _buildUserSection(context, isCompact),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBranding(BuildContext context, bool isCompact) {
    final greeting = _getTimeBasedGreeting();
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 350;
    
    return Row(
      children: [ // Remove mainAxisSize to allow proper expansion
        // App icon/logo - Make flexible for tiny screens
        if (!isVeryCompact) ...[
          Container(
            padding: EdgeInsets.all(isCompact ? 4 : 6),
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withAlpha((255 * 0.15).toInt()),
              borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentTeal.withAlpha((255 * 0.1).toInt()),
                  blurRadius: isCompact ? 4 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.psychology_rounded,
              color: AppColors.accentTeal,
              size: isCompact ? 16 : 20,
            ),
          ),
          SizedBox(width: isCompact ? 6 : 8),
        ],
        
        // Dynamic greeting and app name - Always flexible to prevent overflow
        Expanded( // Changed from Flexible to Expanded for better constraint handling
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCompact && !isVeryCompact && userName != null) ...[
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 1),
              ],
              Text(
                _getDisplayTitle(isCompact, isVeryCompact),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: _getTitleFontSize(isCompact, isVeryCompact),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getDisplayTitle(bool isCompact, bool isVeryCompact) {
    if (isVeryCompact) {
      return 'Aura'; // Ultra-short for tiny screens
    } else if (isCompact && userName == null) {
      return title;
    } else if (isCompact) {
      final greeting = _getTimeBasedGreeting();
      return greeting.split(' ')[0]; // Just "Good" from "Good morning"
    }
    return title;
  }
  
  double _getTitleFontSize(bool isCompact, bool isVeryCompact) {
    if (isVeryCompact) return 13;
    if (isCompact) return 15;
    return 17;
  }

  Widget _buildUserSection(BuildContext context, bool isCompact) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final screenWidth = MediaQuery.of(context).size.width;
        final isVeryCompact = screenWidth < 350 || availableWidth < 120;
        final isUltraCompact = availableWidth < 80; // Ultra-tight space
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Trailing widgets (mood pill, etc.) - Show only if enough space
            if (trailing != null && !isUltraCompact && availableWidth > 140) ...[
              Flexible(
                flex: 2,
                child: trailing!,
              ),
              SizedBox(width: isCompact ? 4 : 6),
            ],
            
            // Quick action button (notifications, etc.) - Prioritize over trailing
            if ((showNotificationBadge || notificationCount > 0) && availableWidth > 60)
              _buildNotificationButton(context, isCompact || isUltraCompact),
              
            if ((showNotificationBadge || notificationCount > 0) && availableWidth > 60) 
              SizedBox(width: isUltraCompact ? 2 : (isCompact ? 4 : 6)),
            
            // User profile section - Always show but adapt to available space
            Flexible(
              flex: isUltraCompact ? 1 : 2,
              child: showUserProfile && userName != null
                  ? _buildUserProfile(context, isCompact || isVeryCompact || isUltraCompact)
                  : _buildDefaultProfileButton(context, isCompact || isVeryCompact || isUltraCompact),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserProfile(BuildContext context, bool isCompact) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isUltraCompact = availableWidth < 80; // Less than 80px
        final isTiny = availableWidth < 50; // Less than 50px - critical threshold
        final isMicro = availableWidth < 35; // Less than 35px - minimal mode
        
        return GestureDetector(
          onTap: onProfileTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMicro ? 3 : (isTiny ? 5 : (isUltraCompact ? 6 : (isCompact ? 8 : 10))),
              vertical: isTiny ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.glassWhite.withAlpha((255 * 0.3).toInt()),
              borderRadius: BorderRadius.circular(isTiny ? 12 : 20),
              border: Border.all(
                color: AppColors.glassBorder.withAlpha((255 * 0.5).toInt()),
                width: 1,
              ),
            ),
            child: _buildProfileContent(
              availableWidth: availableWidth,
              isCompact: isCompact,
              isUltraCompact: isUltraCompact,
              isTiny: isTiny,
              isMicro: isMicro,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileContent({
    required double availableWidth,
    required bool isCompact,
    required bool isUltraCompact,
    required bool isTiny,
    required bool isMicro,
  }) {
    // Micro mode: Just a tiny profile indicator
    if (isMicro || availableWidth < 30) {
      return Icon(
        Icons.person_rounded,
        size: 16,
        color: AppColors.accentTeal,
      );
    }

    // Tiny mode: Just avatar, no text or dropdown
    if (isTiny) {
      return CircleAvatar(
        radius: 12, // Smaller radius for tight spaces
        backgroundColor: AppColors.accentTeal.withAlpha((255 * 0.2).toInt()),
        backgroundImage: userPhotoUrl != null 
            ? NetworkImage(userPhotoUrl!)
            : null,
        child: userPhotoUrl == null
            ? Icon(
                Icons.person_rounded,
                size: 14,
                color: AppColors.accentTeal,
              )
            : null,
      );
    }

    // Ultra-compact mode: Avatar + minimal dropdown, no text
    if (isUltraCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 13, // Slightly smaller
            backgroundColor: AppColors.accentTeal.withAlpha((255 * 0.2).toInt()),
            backgroundImage: userPhotoUrl != null 
                ? NetworkImage(userPhotoUrl!)
                : null,
            child: userPhotoUrl == null
                ? Icon(
                    Icons.person_rounded,
                    size: 15,
                    color: AppColors.accentTeal,
                  )
                : null,
          ),
          if (availableWidth > 65) ...[
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ],
      );
    }

    // Normal responsive mode: Full content with progressive enhancement
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // User avatar
        CircleAvatar(
          radius: isCompact ? 14 : 16,
          backgroundColor: AppColors.accentTeal.withAlpha((255 * 0.2).toInt()),
          backgroundImage: userPhotoUrl != null 
              ? NetworkImage(userPhotoUrl!)
              : null,
          child: userPhotoUrl == null
              ? Icon(
                  Icons.person_rounded,
                  size: isCompact ? 16 : 18,
                  color: AppColors.accentTeal,
                )
              : null,
        ),
        
        // Show text content only if there's adequate space
        if (!isCompact && availableWidth > 120) ...[
          const SizedBox(width: 8),
          // User greeting - with overflow protection
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hello,',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _getFirstName(userName!),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
        
        // Show dropdown indicator only if there's space
        if (availableWidth > 90) ...[
          SizedBox(width: isCompact ? 3 : 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: isCompact ? 14 : 16,
            color: AppColors.textSecondary,
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultProfileButton(BuildContext context, bool isCompact) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isUltraCompact = availableWidth < 40;
        final isTiny = availableWidth < 30;
        
        return GestureDetector(
          onTap: onProfileTap,
          child: Container(
            padding: EdgeInsets.all(
              isTiny ? 3 : (isUltraCompact ? 4 : (isCompact ? 6 : 8))
            ),
            decoration: BoxDecoration(
              color: AppColors.glassWhite.withAlpha((255 * 0.3).toInt()),
              borderRadius: BorderRadius.circular(isTiny ? 8 : 12),
              border: Border.all(
                color: AppColors.glassBorder.withAlpha((255 * 0.5).toInt()),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.account_circle_rounded,
              color: AppColors.textPrimary,
              size: isTiny ? 16 : (isUltraCompact ? 18 : (isCompact ? 20 : 24)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationButton(BuildContext context, bool isCompact) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isUltraCompact = constraints.maxWidth < 40;
        
        return Stack(
          children: [
            Container(
              padding: EdgeInsets.all(isUltraCompact ? 4 : (isCompact ? 6 : 8)),
              decoration: BoxDecoration(
                color: AppColors.glassWhite.withAlpha((255 * 0.3).toInt()),
                borderRadius: BorderRadius.circular(isUltraCompact ? 8 : 12),
                border: Border.all(
                  color: AppColors.glassBorder.withAlpha((255 * 0.5).toInt()),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
                size: isUltraCompact ? 14 : (isCompact ? 16 : 20),
              ),
            ),
            if (notificationCount > 0 && !isUltraCompact)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: isCompact ? 12 : 16,
                    minHeight: isCompact ? 12 : 16,
                  ),
                  child: Text(
                    notificationCount > 99 ? '99+' : notificationCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact ? 8 : 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening';
    } else {
      return 'Good night';
    }
  }

  String _getFirstName(String fullName) {
    return fullName.split(' ').first;
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

/// Floating action button with glass effect
class GlassFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;

  const GlassFloatingActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassWidget.circle(
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: AppColors.textPrimary,
          size: 28,
        ),
        tooltip: tooltip,
      ),
    );
  }
}


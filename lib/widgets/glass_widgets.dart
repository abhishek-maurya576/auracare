import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

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

/// Glass app bar widget
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? trailing;
  final Widget? leading;
  final bool centerTitle;

  const GlassAppBar({
    super.key,
    required this.title,
    this.trailing,
    this.leading,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      title: GlassWidget(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 20,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
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


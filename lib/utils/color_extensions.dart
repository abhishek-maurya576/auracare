import 'package:flutter/material.dart';

/// Extension to handle deprecated withOpacity method
extension ColorExtensions on Color {
  /// Safe opacity method that uses withValues when available, falls back to withOpacity
  Color withSafeOpacity(double opacity) {
    try {
      // Try to use the new withValues method if available
      return withValues(alpha: opacity);
    } catch (e) {
      // Fall back to withOpacity for older Flutter versions
      // ignore: deprecated_member_use
      return withOpacity(opacity);
    }
  }
}
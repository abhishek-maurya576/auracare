import 'package:flutter/material.dart';

/// Utility class for handling avatar-related operations
class AvatarUtils {
  /// Get all available avatar paths
  static List<String> getAvatarPaths() {
    return List.generate(9, (index) => 'assets/images/profile/avatar_${index + 1}_img.png');
  }

  /// Get avatar path by index (1-based)
  static String getAvatarPathByIndex(int index) {
    // Ensure index is between 1 and 9
    final safeIndex = index.clamp(1, 9);
    return 'assets/images/profile/avatar_${safeIndex}_img.png';
  }

  /// Get avatar index from path (returns 1-based index)
  static int getAvatarIndexFromPath(String? path) {
    if (path == null) return 1;
    
    // Extract index from path
    final regex = RegExp(r'avatar_(\d+)_img\.png$');
    final match = regex.firstMatch(path);
    
    if (match != null && match.groupCount >= 1) {
      final indexStr = match.group(1);
      if (indexStr != null) {
        final index = int.tryParse(indexStr);
        if (index != null && index >= 1 && index <= 9) {
          return index;
        }
      }
    }
    
    // Default to first avatar if path doesn't match expected format
    return 1;
  }

  /// Validate if a path is a valid avatar path
  static bool isValidAvatarPath(String? path) {
    if (path == null) return false;
    
    final avatarPaths = getAvatarPaths();
    return avatarPaths.contains(path);
  }

  /// Get a valid avatar path from any input
  /// If input is invalid, returns the first avatar path
  static String getValidAvatarPath(String? path) {
    if (isValidAvatarPath(path)) {
      return path!;
    }
    
    // Try to extract index from path
    final index = getAvatarIndexFromPath(path);
    return getAvatarPathByIndex(index);
  }

  /// Pre-cache all avatar images
  static Future<void> precacheAvatars(BuildContext context) async {
    final avatarPaths = getAvatarPaths();
    
    for (final path in avatarPaths) {
      try {
        await precacheImage(AssetImage(path), context);
        debugPrint('Precached avatar: $path');
      } catch (e) {
        debugPrint('Error precaching avatar: $path - $e');
      }
    }
  }

  /// Build avatar widget with error handling
  static Widget buildAvatarWidget({
    required String? photoUrl,
    double size = 100,
    Widget? placeholder,
  }) {
    final defaultPlaceholder = Icon(
      Icons.person,
      size: size * 0.5,
      color: Colors.white,
    );
    
    if (photoUrl == null) {
      return placeholder ?? defaultPlaceholder;
    }
    
    if (photoUrl.startsWith('http')) {
      // Network image
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading network avatar: $photoUrl - $error');
          return placeholder ?? defaultPlaceholder;
        },
      );
    } else {
      // Asset image (likely an avatar)
      final validPath = getValidAvatarPath(photoUrl);
      return Image.asset(
        validPath,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading asset avatar: $validPath - $error');
          return placeholder ?? defaultPlaceholder;
        },
      );
    }
  }
}
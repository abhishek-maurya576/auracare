import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/mood_entry.dart';
import '../services/gemini_service.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GeminiService _geminiService = GeminiService();

  /// Save user profile to Firestore and update Gemini service
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('user_profiles')
          .doc(profile.id)
          .set(profile.toJson());

      // Update Gemini service with the profile for personalization
      _geminiService.setUserProfile(profile.id, profile);

      debugPrint(
          'User profile saved and updated in Gemini service: ${profile.name}');
    } catch (e) {
      debugPrint('Error saving user profile: $e');
      throw 'Failed to save user profile: $e';
    }
  }

  /// Get user profile from Firestore (alias for loadUserProfile)
  Future<UserProfile?> getUserProfile(String userId) async {
    return await loadUserProfile(userId);
  }

  /// Load user profile from Firestore
  Future<UserProfile?> loadUserProfile(String userId) async {
    try {
      final doc =
          await _firestore.collection('user_profiles').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromJson(doc.data()!);

        // Update Gemini service with the loaded profile
        _geminiService.setUserProfile(userId, profile);

        debugPrint('User profile loaded: ${profile.name}');
        return profile;
      }

      return null;
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      throw 'Failed to load user profile: $e';
    }
  }

  /// Update user profile with new data
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
    try {
      // First update Firestore
      await _firestore.collection('user_profiles').doc(userId).update(updates);

      // Then atomically reload and update Gemini service
      final updatedProfile = await loadUserProfile(userId);
      if (updatedProfile != null) {
        // Ensure Gemini service is updated with the latest data
        _geminiService.setUserProfile(userId, updatedProfile);
        debugPrint('User profile updated atomically for user: $userId');
        debugPrint('Gemini service synchronized with latest profile data');
      } else {
        debugPrint('Warning: Failed to reload profile after update for user: $userId');
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw 'Failed to update user profile: $e';
    }
  }

  /// Initialize user profile for new users
  Future<UserProfile> initializeUserProfile({
    required String userId,
    required String name,
    required String email,
    int? age,
    String? photoUrl,
  }) async {
    try {
      // Ensure we get the most accurate name from Firebase Auth
      String finalName = name;
      final currentUser = _auth.currentUser;

      if (currentUser != null && currentUser.uid == userId) {
        // Reload to get latest data
        await currentUser.reload();
        final reloadedUser = _auth.currentUser;

        if (reloadedUser != null &&
            reloadedUser.displayName != null &&
            reloadedUser.displayName!.isNotEmpty &&
            reloadedUser.displayName != 'User') {
          finalName = reloadedUser.displayName!;
          debugPrint(
              'Using Firebase Auth display name for new profile: $finalName');
        } else {
          debugPrint('Using provided name for new profile: $finalName');
        }
      }

      final profile = UserProfile(
        id: userId,
        name: finalName,
        email: email,
        age: age,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        enablePersonalization: true,
        shareEmotionalState: true,
        allowMoodTracking: true,
        conversationDepth: 3,
        communicationStyle: 'supportive',
      );

      await saveUserProfile(profile);
      debugPrint('User profile initialized with name: ${profile.name}');
      return profile;
    } catch (e) {
      debugPrint('Error initializing user profile: $e');
      throw 'Failed to initialize user profile: $e';
    }
  }

  /// Update user mood patterns in profile
  Future<void> updateMoodPatterns(
      String userId, List<MoodEntry> moodEntries) async {
    try {
      if (moodEntries.isEmpty) return;

      // Calculate mood patterns
      final moodPatterns = _calculateMoodPatterns(moodEntries);
      final stressPatterns = _calculateStressPatterns(moodEntries);

      // Update profile with new patterns
      await updateUserProfile(userId, {
        'moodPatterns': moodPatterns,
        'stressPatterns': stressPatterns,
        'lastMoodUpdate': DateTime.now().toIso8601String(),
      });

      // Update Gemini service with mood data
      _geminiService.setUserMoodData(userId, moodEntries);

      debugPrint('Mood patterns updated for user: $userId');
    } catch (e) {
      debugPrint('Error updating mood patterns: $e');
    }
  }

  /// Calculate mood patterns from mood entries
  Map<String, dynamic> _calculateMoodPatterns(List<MoodEntry> entries) {
    if (entries.isEmpty) return {};

    // Calculate averages
    final avgMoodScore =
        entries.fold<double>(0, (total, entry) => total + entry.moodScore) /
            entries.length;

    // Determine trend
    String trend = 'stable';
    if (entries.length >= 3) {
      final recent = entries.take(3).map((e) => e.moodScore).toList();
      final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
      final previous = entries.skip(3).take(3).map((e) => e.moodScore).toList();

      if (previous.isNotEmpty) {
        final previousAvg = previous.reduce((a, b) => a + b) / previous.length;
        if (recentAvg > previousAvg + 0.5) {
          trend = 'improving';
        } else if (recentAvg < previousAvg - 0.5) {
          trend = 'declining';
        }
      }
    }

    // Most common mood
    final moodCounts = <String, int>{};
    for (final entry in entries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }
    final mostCommonMood = moodCounts.entries.isNotEmpty
        ? moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'unknown';

    // Common triggers
    final allTriggers = entries.expand((entry) => entry.triggers).toList();
    final triggerCounts = <String, int>{};
    for (final trigger in allTriggers) {
      triggerCounts[trigger] = (triggerCounts[trigger] ?? 0) + 1;
    }
    final commonTriggers = triggerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'averageMood': avgMoodScore,
      'trend': trend,
      'mostCommonMood': mostCommonMood,
      'commonTriggers': commonTriggers.take(5).map((e) => e.key).toList(),
      'totalEntries': entries.length,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Calculate stress patterns from mood entries
  Map<String, dynamic> _calculateStressPatterns(List<MoodEntry> entries) {
    if (entries.isEmpty) return {};

    final avgStress = entries.fold<double>(
            0, (total, entry) => total + entry.calculatedStressLevel) /
        entries.length;
    final crisisCount = entries.where((entry) => entry.isCrisisLevel).length;

    // Determine stress trend
    String trend = 'stable';
    if (entries.length >= 3) {
      final recent =
          entries.take(3).map((e) => e.calculatedStressLevel).toList();
      final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
      final previous =
          entries.skip(3).take(3).map((e) => e.calculatedStressLevel).toList();

      if (previous.isNotEmpty) {
        final previousAvg = previous.reduce((a, b) => a + b) / previous.length;
        if (recentAvg > previousAvg + 1) {
          trend = 'increasing';
        } else if (recentAvg < previousAvg - 1) {
          trend = 'decreasing';
        }
      }
    }

    return {
      'averageStress': avgStress,
      'trend': trend,
      'crisisCount': crisisCount,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Setup personalization preferences
  Future<void> setupPersonalizationPreferences(
    String userId, {
    List<String>? mentalHealthGoals,
    List<String>? preferredCopingStrategies,
    String? communicationStyle,
    List<String>? triggers,
    List<String>? strengths,
    List<String>? interests,
    int? conversationDepth,
    bool? enablePersonalization,
    bool? shareEmotionalState,
    List<String>? topicsToAvoid,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (mentalHealthGoals != null) {
        updates['mentalHealthGoals'] = mentalHealthGoals;
      }
      if (preferredCopingStrategies != null) {
        updates['preferredCopingStrategies'] = preferredCopingStrategies;
      }
      if (communicationStyle != null) {
        updates['communicationStyle'] = communicationStyle;
      }
      if (triggers != null) updates['triggers'] = triggers;
      if (strengths != null) updates['strengths'] = strengths;
      if (interests != null) updates['interests'] = interests;
      if (conversationDepth != null) {
        updates['conversationDepth'] = conversationDepth;
      }
      if (enablePersonalization != null) {
        updates['enablePersonalization'] = enablePersonalization;
      }
      if (shareEmotionalState != null) {
        updates['shareEmotionalState'] = shareEmotionalState;
      }
      if (topicsToAvoid != null) updates['topicsToAvoid'] = topicsToAvoid;

      await updateUserProfile(userId, updates);
      debugPrint('Personalization preferences updated for user: $userId');
    } catch (e) {
      debugPrint('Error updating personalization preferences: $e');
      throw 'Failed to update personalization preferences: $e';
    }
  }

  /// Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Ensure Firebase Auth user is up to date
    await user.reload();
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    // Load existing profile
    UserProfile? profile = await loadUserProfile(currentUser.uid);

    if (profile == null) {
      // Create new profile if none exists
      String userName = 'User';
      if (currentUser.displayName != null &&
          currentUser.displayName!.isNotEmpty) {
        userName = currentUser.displayName!;
        debugPrint(
            'Using Firebase Auth display name for new profile: $userName');
      } else {
        // Try to get name from Firestore user document as a fallback
        try {
          final userDoc =
              await _firestore.collection('users').doc(currentUser.uid).get();
          if (userDoc.exists &&
              userDoc.data() != null &&
              userDoc.data()!['name'] != null) {
            final firestoreName = userDoc.data()!['name'];
            if (firestoreName != null &&
                firestoreName != 'User' &&
                firestoreName.isNotEmpty) {
              userName = firestoreName;
              debugPrint(
                  'Using Firestore user name for new profile: $userName');
            }
          }
        } catch (e) {
          debugPrint('Error fetching user document: $e');
        }
      }

      profile = await initializeUserProfile(
        userId: currentUser.uid,
        name: userName,
        email: currentUser.email ?? '',
        photoUrl: currentUser.photoURL,
      );
    } else {
      // Update existing profile name if it's outdated
      bool needsUpdate = false;
      String updatedName = profile.name;

      // Check if Firebase Auth has a better name
      if (profile.name == 'User' &&
          currentUser.displayName != null &&
          currentUser.displayName!.isNotEmpty &&
          currentUser.displayName != 'User') {
        updatedName = currentUser.displayName!;
        needsUpdate = true;
        debugPrint(
            'Updating profile name from "User" to "${currentUser.displayName}"');
      }

      // Check if Firestore users collection has a better name
      if (profile.name == 'User' && updatedName == 'User') {
        try {
          final userDoc =
              await _firestore.collection('users').doc(currentUser.uid).get();
          if (userDoc.exists &&
              userDoc.data() != null &&
              userDoc.data()!['name'] != null) {
            final firestoreName = userDoc.data()!['name'];
            if (firestoreName != null &&
                firestoreName != 'User' &&
                firestoreName.isNotEmpty) {
              updatedName = firestoreName;
              needsUpdate = true;
              debugPrint('Updating profile name from Firestore: $updatedName');
            }
          }
        } catch (e) {
          debugPrint('Error fetching user document for name update: $e');
        }
      }

      if (needsUpdate) {
        final updatedProfile = profile.copyWith(name: updatedName);
        await saveUserProfile(updatedProfile);
        profile = updatedProfile;
      }
    }

    return profile;
  }

  /// Initialize personalization for current user
  Future<void> initializePersonalizationForCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Use the improved getCurrentUserProfile method which handles name synchronization
      final profile = await getCurrentUserProfile();

      if (profile != null) {
        debugPrint('Personalization initialized for user: ${profile.name}');
        // Profile is already saved and Gemini service is updated in getCurrentUserProfile
      } else {
        debugPrint(
            'Warning: Could not initialize personalization - profile is null');
      }
    } catch (e) {
      debugPrint('Error initializing personalization: $e');
    }
  }

  /// Clear user data from Gemini service (for logout)
  void clearUserDataFromGemini(String userId) {
    _geminiService.clearUserProfile(userId);
    _geminiService.clearUserMoodData(userId);
    debugPrint('User data cleared from Gemini service: $userId');
  }

  /// Update successful interventions based on user feedback
  Future<void> updateSuccessfulInterventions(
      String userId, List<String> interventions) async {
    try {
      await updateUserProfile(userId, {
        'successfulInterventions': interventions,
      });
      debugPrint('Successful interventions updated for user: $userId');
    } catch (e) {
      debugPrint('Error updating successful interventions: $e');
    }
  }

  /// Add crisis protocol information
  Future<void> updateCrisisProtocol(
      String userId, Map<String, dynamic> crisisInfo) async {
    try {
      await updateUserProfile(userId, {
        'crisisProtocol': crisisInfo,
      });
      debugPrint('Crisis protocol updated for user: $userId');
    } catch (e) {
      debugPrint('Error updating crisis protocol: $e');
    }
  }
}

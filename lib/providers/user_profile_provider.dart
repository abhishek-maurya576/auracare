import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../models/mood_entry.dart';

class UserProfileProvider extends ChangeNotifier {
  final UserProfileService _profileService = UserProfileService();
  
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _userProfile != null;
  bool get isPersonalizationEnabled => _userProfile?.enablePersonalization ?? false;

  /// Initialize user profile for the current user
  Future<void> initializeProfile({
    required String userId,
    required String name,
    required String email,
    int? age,
    String? photoUrl,
  }) async {
    _setLoading(true);
    
    try {
      _userProfile = await _profileService.initializeUserProfile(
        userId: userId,
        name: name,
        email: email,
        age: age,
        photoUrl: photoUrl,
      );
      _error = null;
      debugPrint('User profile initialized: ${_userProfile!.name}');
    } catch (e) {
      _error = 'Failed to initialize profile: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Load existing user profile
  Future<void> loadProfile(String userId) async {
    _setLoading(true);
    
    try {
      _userProfile = await _profileService.loadUserProfile(userId);
      _error = null;
      
      if (_userProfile != null) {
        debugPrint('User profile loaded: ${_userProfile!.name}');
      } else {
        debugPrint('No existing profile found for user: $userId');
      }
    } catch (e) {
      _error = 'Failed to load profile: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile with new data
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_userProfile == null) return;
    
    _setLoading(true);
    
    try {
      await _profileService.updateUserProfile(_userProfile!.id, updates);
      
      // Reload the profile to get updated data
      await loadProfile(_userProfile!.id);
      _error = null;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Setup personalization preferences
  Future<void> setupPersonalization({
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
    if (_userProfile == null) return;
    
    _setLoading(true);
    
    try {
      await _profileService.setupPersonalizationPreferences(
        _userProfile!.id,
        mentalHealthGoals: mentalHealthGoals,
        preferredCopingStrategies: preferredCopingStrategies,
        communicationStyle: communicationStyle,
        triggers: triggers,
        strengths: strengths,
        interests: interests,
        conversationDepth: conversationDepth,
        enablePersonalization: enablePersonalization,
        shareEmotionalState: shareEmotionalState,
        topicsToAvoid: topicsToAvoid,
      );
      
      // Reload profile to reflect changes
      await loadProfile(_userProfile!.id);
      _error = null;
      debugPrint('Personalization preferences updated');
    } catch (e) {
      _error = 'Failed to update personalization: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Update mood patterns in the user profile
  Future<void> updateMoodPatterns(List<MoodEntry> moodEntries) async {
    if (_userProfile == null) return;
    
    try {
      await _profileService.updateMoodPatterns(_userProfile!.id, moodEntries);
      
      // Reload profile to get updated mood patterns
      await loadProfile(_userProfile!.id);
      debugPrint('Mood patterns updated in user profile');
    } catch (e) {
      debugPrint('Failed to update mood patterns: $e');
    }
  }

  /// Update successful interventions based on user feedback
  Future<void> updateSuccessfulInterventions(List<String> interventions) async {
    if (_userProfile == null) return;
    
    try {
      await _profileService.updateSuccessfulInterventions(_userProfile!.id, interventions);
      await loadProfile(_userProfile!.id);
      debugPrint('Successful interventions updated');
    } catch (e) {
      debugPrint('Failed to update successful interventions: $e');
    }
  }

  /// Add or update crisis protocol
  Future<void> updateCrisisProtocol(Map<String, dynamic> crisisInfo) async {
    if (_userProfile == null) return;
    
    try {
      await _profileService.updateCrisisProtocol(_userProfile!.id, crisisInfo);
      await loadProfile(_userProfile!.id);
      debugPrint('Crisis protocol updated');
    } catch (e) {
      debugPrint('Failed to update crisis protocol: $e');
    }
  }

  /// Clear user profile data (for logout)
  void clearProfile() {
    if (_userProfile != null) {
      _profileService.clearUserDataFromGemini(_userProfile!.id);
    }
    _userProfile = null;
    _error = null;
    notifyListeners();
    debugPrint('User profile cleared');
  }

  /// Get personalization context for AI
  String getPersonalizationContext() {
    if (_userProfile == null || !_userProfile!.enablePersonalization) {
      return '';
    }
    return _userProfile!.generatePersonalizationContext();
  }

  /// Get mood context for AI
  String getMoodContext() {
    if (_userProfile == null || !_userProfile!.shareEmotionalState) {
      return '';
    }
    return _userProfile!.generateMoodContext();
  }

  /// Check if user is in potential crisis
  bool get isPotentialCrisis {
    return _userProfile?.isPotentialCrisis ?? false;
  }

  /// Get crisis protocol information
  Map<String, dynamic>? get crisisInfo {
    return _userProfile?.crisisInfo;
  }

  /// Get user's preferred communication style
  String get communicationStyle {
    return _userProfile?.communicationStyle ?? 'supportive';
  }

  /// Get user's conversation depth preference
  int get conversationDepth {
    return _userProfile?.conversationDepth ?? 3;
  }

  /// Get user's mental health goals
  List<String> get mentalHealthGoals {
    return _userProfile?.mentalHealthGoals ?? [];
  }

  /// Get user's preferred coping strategies
  List<String> get preferredCopingStrategies {
    return _userProfile?.preferredCopingStrategies ?? [];
  }

  /// Get user's known triggers
  List<String> get triggers {
    return _userProfile?.triggers ?? [];
  }

  /// Get user's strengths
  List<String> get strengths {
    return _userProfile?.strengths ?? [];
  }

  /// Get user's interests
  List<String> get interests {
    return _userProfile?.interests ?? [];
  }

  /// Check if specific personalization features are enabled
  bool get canShareEmotionalState => _userProfile?.shareEmotionalState ?? false;
  bool get canTrackMood => _userProfile?.allowMoodTracking ?? false;
  bool get enableProactiveSupport => _userProfile?.enableProactiveSupport ?? false;

  /// Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Quick setup for new users with common preferences
  Future<void> quickSetup({
    required List<String> selectedGoals,
    required List<String> selectedCopingStrategies,
    required String selectedCommunicationStyle,
    List<String>? selectedTriggers,
    List<String>? selectedStrengths,
    List<String>? selectedInterests,
  }) async {
    await setupPersonalization(
      mentalHealthGoals: selectedGoals,
      preferredCopingStrategies: selectedCopingStrategies,
      communicationStyle: selectedCommunicationStyle,
      triggers: selectedTriggers,
      strengths: selectedStrengths,
      interests: selectedInterests,
      enablePersonalization: true,
      shareEmotionalState: true,
      conversationDepth: 3,
    );
  }

  /// Get personalization completion percentage
  double get personalizationCompleteness {
    if (_userProfile == null) return 0.0;
    
    int completedFields = 0;
    int totalFields = 8;
    
    if (_userProfile!.mentalHealthGoals?.isNotEmpty == true) completedFields++;
    if (_userProfile!.preferredCopingStrategies?.isNotEmpty == true) completedFields++;
    if (_userProfile!.communicationStyle != null) completedFields++;
    if (_userProfile!.triggers?.isNotEmpty == true) completedFields++;
    if (_userProfile!.strengths?.isNotEmpty == true) completedFields++;
    if (_userProfile!.interests?.isNotEmpty == true) completedFields++;
    if (_userProfile!.conversationDepth > 0) completedFields++;
    if (_userProfile!.enablePersonalization) completedFields++;
    
    return completedFields / totalFields;
  }

  /// Get suggestions for improving personalization
  List<String> get personalizationSuggestions {
    if (_userProfile == null) return [];
    
    final suggestions = <String>[];
    
    if (_userProfile!.mentalHealthGoals?.isEmpty != false) {
      suggestions.add('Add your mental health goals');
    }
    if (_userProfile!.preferredCopingStrategies?.isEmpty != false) {
      suggestions.add('Select your preferred coping strategies');
    }
    if (_userProfile!.triggers?.isEmpty != false) {
      suggestions.add('Identify your stress triggers');
    }
    if (_userProfile!.strengths?.isEmpty != false) {
      suggestions.add('List your personal strengths');
    }
    if (_userProfile!.interests?.isEmpty != false) {
      suggestions.add('Share your interests and hobbies');
    }
    
    return suggestions;
  }
}
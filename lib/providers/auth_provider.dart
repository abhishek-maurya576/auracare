import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserProfileService _profileService = UserProfileService();
  
  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;
  StreamSubscription<User?>? _authStateSubscription;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated && _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    _setState(AuthState.loading);
    
    try {
      // Listen to Firebase auth state changes
      _authStateSubscription = _authService.authStateChanges.listen(_onAuthStateChanged);
      
      // Wait for the first authentication state change to determine initial status
      final currentUser = await _authService.authStateChanges.first;
      if (currentUser != null) {
        await _handleUserSignIn(currentUser);
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    }
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      await _handleUserSignIn(firebaseUser);
    } else {
      _handleUserSignOut();
    }
  }

  Future<void> _handleUserSignIn(User firebaseUser) async {
    try {
      final userModel = await _authService.firebaseUserToUserModel(firebaseUser);
      if (userModel != null) {
        _user = userModel;
        await _saveUserData(userModel);
        
        // Initialize or load user profile for personalization
        await _initializeUserProfile(userModel);
        
        _setState(AuthState.authenticated);
        
        // Notify other providers that user is authenticated
        debugPrint('User authenticated successfully with personalization: ${userModel.name}');
      }
    } catch (e) {
      _setError('Failed to process user sign-in: $e');
    }
  }

  void _handleUserSignOut() {
    // Clear user profile data from Gemini service
    if (_user != null) {
      _profileService.clearUserDataFromGemini(_user!.id);
    }
    
    _user = null;
    _clearUserData();
    _setState(AuthState.unauthenticated);
  }

  Future<bool> signInWithGoogle() async {
    _setState(AuthState.loading);
    
    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential == null) {
        _setState(AuthState.unauthenticated);
        return false;
      }

      // The auth state listener will handle the rest
      return true;
    } catch (e) {
      _setError('Google Sign-In failed: $e');
      return false;
    }
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    _setState(AuthState.loading);
    
    try {
      final userCredential = await _authService.signInWithEmailPassword(email, password);
      
      if (userCredential != null) {
        // The auth state listener will handle the rest
        return true;
      }
      
      _setState(AuthState.unauthenticated);
      return false;
    } catch (e) {
      _setError('Email sign-in failed: $e');
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    int? age,
  }) async {
    _setState(AuthState.loading);
    
    try {
      final userCredential = await _authService.createUserWithEmailPassword(email, password);
      
      if (userCredential != null && userCredential.user != null) {
        // Update the display name
        await _authService.updateUserProfile(displayName: name);
        
        // Create user document in Firestore
        final userModel = UserModel(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          age: age,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        
        await _authService.saveUserData(userModel);
        
        // The auth state listener will handle the rest
        return true;
      }
      
      _setState(AuthState.unauthenticated);
      return false;
    } catch (e) {
      _setError('Sign-up failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    _setState(AuthState.loading);
    
    try {
      await _authService.signOut();
      // The auth state listener will handle the rest
    } catch (e) {
      _setError('Sign-out failed: $e');
    }
  }

  Future<void> updateUserProfile({
    String? name,
    int? age,
    Map<String, dynamic>? preferences,
    List<String>? interests,
  }) async {
    if (_user == null) return;
    
    try {
      final updatedUser = _user!.copyWith(
        name: name,
        age: age,
        preferences: preferences,
        interests: interests,
      );
      
      // Update in Firestore
      await _authService.saveUserData(updatedUser);
      
      // Update Firebase Auth profile if name changed
      if (name != null) {
        await _authService.updateUserProfile(displayName: name);
      }
      
      _user = updatedUser;
      await _saveUserData(updatedUser);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update profile: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _setError('Failed to send password reset email: $e');
    }
  }

  Future<void> _saveUserData(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString('user_data', userJson);
    } catch (e) {
      debugPrint('Failed to save user data locally: $e');
    }
  }

  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
      debugPrint('Failed to clear user data: $e');
    }
  }

  void _setState(AuthState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _state = AuthState.error;
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Initialize user profile for personalized AI responses
  Future<void> _initializeUserProfile(UserModel userModel) async {
    try {
      // Try to load existing profile
      final existingProfile = await _profileService.loadUserProfile(userModel.id);
      
      if (existingProfile == null) {
        // Create new profile for first-time users
        await _profileService.initializeUserProfile(
          userId: userModel.id,
          name: userModel.name,
          email: userModel.email,
          age: userModel.age,
          photoUrl: userModel.photoUrl,
        );
        debugPrint('New user profile created for personalization: ${userModel.name}');
      } else {
        debugPrint('Existing user profile loaded for personalization: ${existingProfile.name}');
      }
    } catch (e) {
      debugPrint('Error initializing user profile: $e');
      // Don't throw error as this shouldn't prevent authentication
    }
  }

  /// Get current user ID for personalization
  String? get currentUserId => _user?.id;
}

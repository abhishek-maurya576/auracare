import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  static const String _loginStatusKey = 'isLoggedIn';
  static const String _loginMethodKey = 'loginMethod';
  static const String _lastLoginKey = 'lastLoginTime';

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in (persistent)
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_loginStatusKey) ?? false;
      final currentUser = _auth.currentUser;
      
      // Verify Firebase auth state matches stored preference
      if (isLoggedIn && currentUser == null) {
        await clearLoginStatus(); // Clean up inconsistent state
        return false;
      }
      
      return isLoggedIn && currentUser != null;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  // Get login method used
  Future<String?> getLoginMethod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_loginMethodKey);
    } catch (e) {
      debugPrint('Error getting login method: $e');
      return null;
    }
  }

  // Get last login time
  Future<DateTime?> getLastLoginTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastLoginKey);
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      debugPrint('Error getting last login time: $e');
      return null;
    }
  }

  // Set login status
  Future<void> setLoginStatus(String method) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loginStatusKey, true);
      await prefs.setString(_loginMethodKey, method);
      await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error setting login status: $e');
    }
  }

  // Clear login status
  Future<void> clearLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loginStatusKey);
      await prefs.remove(_loginMethodKey);
      await prefs.remove(_lastLoginKey);
    } catch (e) {
      debugPrint('Error clearing login status: $e');
    }
  }

  // Get login duration
  Future<String> getLoginDuration() async {
    try {
      final lastLogin = await getLastLoginTime();
      if (lastLogin == null) return 'Unknown';
      
      final now = DateTime.now();
      final difference = now.difference(lastLogin);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
      } else {
        return 'Just now';
      }
    } catch (e) {
      debugPrint('Error calculating login duration: $e');
      return 'Unknown';
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      debugPrint('Attempting to sign in with email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('Sign in successful for user: ${credential.user?.uid}');
      await setLoginStatus('email');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected error during sign in: $e');
      throw 'An unexpected error occurred: $e';
    }
  }

  // Create user with email and password
  Future<UserCredential?> createUserWithEmailPassword(String email, String password) async {
    try {
      debugPrint('Attempting to create user with email: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('User creation successful for user: ${credential.user?.uid}');
      await setLoginStatus('email');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during signup: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected error during signup: $e');
      throw 'An unexpected error occurred: $e';
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign-In process...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: [
          'email',
          'profile',
        ],
      );

      debugPrint('Google user obtained: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;



      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      debugPrint('Google credential created, signing in to Firebase...');

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      debugPrint('Google Sign-In successful for user: ${userCredential.user?.uid}');
      await setLoginStatus('google');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during Google Sign-In: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Unexpected error during Google Sign-In: $e');
      throw 'Google Sign-In failed: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      await clearLoginStatus();
    } catch (e) {
      throw 'Sign-out failed: $e';
    }
  }

  // Save user data to Firestore
  Future<void> saveUserData(UserModel userModel) async {
    try {
      await _firestore.collection('users').doc(userModel.id).set(userModel.toJson());
    } catch (e) {
      throw 'Failed to save user data: $e';
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Failed to get user data: $e';
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw 'Failed to update user data: $e';
    }
  }

  // Convert Firebase User to UserModel
  Future<UserModel?> firebaseUserToUserModel(User? firebaseUser) async {
    if (firebaseUser == null) return null;
    
    // Try to get existing user data from Firestore
    try {
      final userData = await getUserData(firebaseUser.uid);
      if (userData != null) {
        // If the user has a default name in Firestore but now has a real name in Firebase Auth,
        // update the Firestore record
        if (userData.name == 'User' && firebaseUser.displayName != null && firebaseUser.displayName != 'User') {
          final updatedUser = userData.copyWith(
            name: firebaseUser.displayName,
            lastLoginAt: DateTime.now()
          );
          await saveUserData(updatedUser);
          debugPrint('Updated user name from "User" to "${firebaseUser.displayName}"');
          return updatedUser;
        }
        return userData.copyWith(lastLoginAt: DateTime.now());
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    
    // Create new user model if no existing data
    // Ensure we're using the most accurate name available
    final name = firebaseUser.displayName;
    if (name == null || name.isEmpty) {
      debugPrint('Warning: User has no display name in Firebase Auth. Using default "User"');
    }
    
    final userModel = UserModel(
      id: firebaseUser.uid,
      name: (name != null && name.isNotEmpty) ? name : 'User',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    
    // Save this new user model to Firestore
    try {
      await saveUserData(userModel);
      debugPrint('Created and saved new user model for ${userModel.name}');
    } catch (e) {
      debugPrint('Error saving new user model: $e');
    }
    
    return userModel;
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    debugPrint('Handling Firebase Auth Exception: ${e.code} - ${e.message}');
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak (minimum 6 characters).';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'invalid-credential':
        return 'The credentials provided are invalid. Please check your email and password.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      default:
        return 'Authentication error: ${e.message ?? e.code}';
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email: $e';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) {
          debugPrint('Updating Firebase Auth displayName to: $displayName');
          await user.updateDisplayName(displayName);
        }
        
        if (photoURL != null) {
          // Only update Firebase Auth photoURL if it's a network URL
          // For asset paths, we'll just store them in Firestore
          if (photoURL.startsWith('http')) {
            debugPrint('Updating Firebase Auth photoURL to: $photoURL');
            await user.updatePhotoURL(photoURL);
          } else {
            debugPrint('Skipping Firebase Auth photoURL update for asset path: $photoURL');
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw 'Failed to update profile: $e';
    }
  }
}


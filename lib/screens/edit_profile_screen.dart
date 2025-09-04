import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../models/user_model.dart';
import '../utils/avatar_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  int _selectedAvatarIndex = 0; // Default to first avatar
  bool _isLoading = false;
  
  // Get avatar paths from utility class
  final List<String> _avatarPaths = AvatarUtils.getAvatarPaths();

  @override
  void initState() {
    super.initState();
    print('EditProfileScreen initState called');
    
    // Log all avatar paths for debugging
    for (int i = 0; i < _avatarPaths.length; i++) {
      print('Avatar path $i: ${_avatarPaths[i]}');
    }
    
    // Pre-cache all avatar images using utility
    AvatarUtils.precacheAvatars(context);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      print('User from AuthProvider: $user');
      if (user != null) {
        _nameController.text = user.name;
        print('User name: ${user.name}');
        print('User photoUrl: ${user.photoUrl}');
        
        // Find the index of the user's avatar using utility
        if (user.photoUrl != null) {
          // Get avatar index (1-based) and convert to 0-based for array indexing
          final avatarIndex = AvatarUtils.getAvatarIndexFromPath(user.photoUrl!) - 1;
          setState(() {
            _selectedAvatarIndex = avatarIndex;
          });
          print('Selected avatar index set to: $_selectedAvatarIndex (from path: ${user.photoUrl})');
        } else {
          // If user has no avatar, use the default (index 0)
          print('User has no avatar. Using default avatar.');
          setState(() {
            _selectedAvatarIndex = 0;
          });
        }
        
        // Show a welcome toast
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.edit, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Edit your profile and select an avatar'),
              ],
            ),
            backgroundColor: Colors.purple,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Edit Profile',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Stack(
        children: [
          const AuraBackground(),
          SafeArea(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.user;
                
                if (user == null) {
                  return const Center(
                    child: Text(
                      'User not found',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture Section
                      _buildProfilePictureSection(user),
                      
                      const SizedBox(height: 24),
                      
                      // Profile Information Section
                      _buildProfileInfoSection(user),
                      
                      const SizedBox(height: 24),
                      
                      // Save Button
                      _buildSaveButton(authProvider),
                      
                      const SizedBox(height: 100), // Bottom padding
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection(UserModel user) {
    return GlassWidget(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header with more prominent styling
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.face_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Choose Your Avatar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Current Profile Picture with animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.withValues(alpha: 0.3),
                  Colors.blue.withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.6),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: AvatarUtils.buildAvatarWidget(
                photoUrl: _avatarPaths[_selectedAvatarIndex],
                size: 140,
                placeholder: Container(
                  color: Colors.grey.withOpacity(0.2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 30, color: Colors.white70),
                      const SizedBox(height: 4),
                      Text(
                        'Error loading avatar',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Instruction card with animation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Tap any avatar below to select it',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your selected avatar will appear on your profile and in chats',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Selection indicator with animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Avatar ${_selectedAvatarIndex + 1} Selected',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Avatar Grid with enhanced visual cues and animations
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: List.generate(9, (index) {
              final isSelected = _selectedAvatarIndex == index;
              
              return GestureDetector(
                onTap: () {
                  print('Avatar selected at index: $index, path: ${_avatarPaths[index]}');
                  setState(() {
                    _selectedAvatarIndex = index;
                  });
                  // Show feedback to user
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Avatar ${index + 1} selected'),
                        ],
                      ),
                      duration: const Duration(seconds: 1),
                      backgroundColor: Colors.purple,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 3,
                      )
                    ] : [],
                  ),
                  child: Stack(
                    children: [
                      // Avatar image with border and ripple effect
                      Material(
                        color: Colors.transparent,
                        child: Ink(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.purple : Colors.white.withValues(alpha: 0.3),
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            splashColor: Colors.purple.withOpacity(0.3),
                            highlightColor: Colors.purple.withOpacity(0.1),
                            onTap: () {
                              setState(() {
                                _selectedAvatarIndex = index;
                              });
                              // Show feedback to user
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text('Avatar ${index + 1} selected'),
                                    ],
                                  ),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: Colors.purple,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            child: ClipOval(
                              child: AvatarUtils.buildAvatarWidget(
                                photoUrl: _avatarPaths[index],
                                size: 80,
                                placeholder: Container(
                                  color: Colors.grey.withOpacity(0.3),
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Selection indicator
                      if (isSelected)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoSection(UserModel user) {
    return GlassWidget(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Name Field
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.purple),
              ),
              prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Email (Read-only)
          TextField(
            readOnly: true,
            controller: TextEditingController(text: user.email),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            decoration: InputDecoration(
              labelText: 'Email (cannot be changed)',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withValues(alpha: 0.5)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AuthProvider authProvider) {
    return Column(
      children: [
        // Instruction card with animation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.save_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Save Your Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click the button below to update your profile with the selected avatar and name',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Save button with enhanced styling and animation
        SizedBox(
          width: double.infinity,
          height: 60, // Taller button for better touch target
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _isLoading 
                      ? Colors.purple.withOpacity(0.3) 
                      : Colors.purple.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _saveProfile(authProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0, // We're using custom shadow above
                disabledBackgroundColor: Colors.purple.withValues(alpha: 0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _isLoading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Saving...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.save_rounded, size: 28),
                            const SizedBox(width: 12),
                            const Text(
                              'Save Profile Changes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
        
        // Cancel button
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Cancel and Go Back'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _saveProfile(AuthProvider authProvider) async {
    // Validate name
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Please enter your name'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedAvatarPath = _avatarPaths[_selectedAvatarIndex];
      
      print('Saving profile with name: ${_nameController.text.trim()}');
      print('Selected avatar index: $_selectedAvatarIndex');
      print('Selected avatar path: $selectedAvatarPath');
      
      // Verify the avatar path is valid
      if (!AvatarUtils.isValidAvatarPath(selectedAvatarPath)) {
        print('Invalid avatar path detected: $selectedAvatarPath');
        throw 'Selected avatar is invalid. Please try another avatar.';
      }
      
      // Update user profile
      await authProvider.updateUserProfile(
        name: _nameController.text.trim(),
        photoUrl: selectedAvatarPath,
      );

      // Also update the user profile in UserProfileProvider if it's being used
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      if (userProfileProvider.hasProfile) {
        print('Updating UserProfileProvider with photoUrl: $selectedAvatarPath');
        await userProfileProvider.updateProfile({
          'name': _nameController.text.trim(),
          'photoUrl': selectedAvatarPath,
        });
      }

      if (mounted) {
        // Refresh the user data before popping
        await authProvider.refreshUserData();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Profile updated successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            action: SnackBarAction(
              label: 'VIEW PROFILE',
              textColor: Colors.white,
              onPressed: () {
                // Do nothing, we're already navigating back
              },
            ),
          ),
        );
        
        // Add a small delay to show the success message before navigating back
        await Future.delayed(const Duration(milliseconds: 500));
        
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to update profile: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _saveProfile(authProvider),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

extension ColorExtension on Color {
  Color withValues({double? red, double? green, double? blue, double? alpha}) {
    return Color.fromRGBO(
      (red != null) ? (red * 255).round() : this.red,
      (green != null) ? (green * 255).round() : this.green,
      (blue != null) ? (blue * 255).round() : this.blue,
      alpha ?? this.alpha.toDouble(),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/mood_provider.dart';
import '../models/user_model.dart';
import '../utils/avatar_utils.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load mood data for statistics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.Provider.of<MoodProvider>(context, listen: false).loadMoodHistory();
      
      // Debug user photo URL
      final user = provider.Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        debugPrint('ProfileScreen - User photoUrl: ${user.photoUrl}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Profile',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        trailing: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
          icon: const Icon(Icons.settings_rounded),
          tooltip: 'Settings',
        ),
      ),
      body: Stack(
        children: [
          const AuraBackground(),
          SafeArea(
            child: provider.Consumer2<AuthProvider, MoodProvider>(
              builder: (context, authProvider, moodProvider, child) {
                final user = authProvider.user;
                final moodStats = moodProvider.getMoodStatistics();
                final stressAnalysis = moodProvider.getStressAnalysis();
                
                if (user == null) {
                  return const Center(
                    child: Text(
                      'User not found',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Profile Header Card
                    _buildProfileHeader(user, moodStats),
                    
                    const SizedBox(height: 20),

                    // Quick Stats Row
                    _buildQuickStatsRow(moodStats, stressAnalysis),
                    
                    const SizedBox(height: 20),

                    // Insights & Analytics Card
                    GlassCard(
                      title: 'Insights & Analytics',
                      subtitle: 'View detailed mood patterns and trends',
                      leadingIcon: Icons.analytics_rounded,
                      trailingIcon: Icons.arrow_forward_ios_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InsightsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Wellness Journey Card
                    _buildWellnessJourneyCard(moodStats),

                    const SizedBox(height: 16),

                    // Achievement Badges
                    _buildAchievementSection(moodStats),

                    const SizedBox(height: 16),

                    // Account Management
                    _buildAccountSection(context, authProvider),

                    const SizedBox(height: 100), // Bottom padding
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, Map<String, dynamic> moodStats) {
    return GlassWidget(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile Picture with Edit Button
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Profile Picture Container
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: AvatarUtils.buildAvatarWidget(
                    photoUrl: user.photoUrl,
                    size: 100,
                    placeholder: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
              ),
              
              // Edit Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                  ).then((_) {
                    // Refresh user data when returning from edit profile
                    final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
                    authProvider.refreshUserData();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 51),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // User Name
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // User Email
          Text(
            user.email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Member Since
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'Member since ${_formatDate(user.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                ).then((_) {
                  // Refresh user data when returning from edit profile
                  final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
                  authProvider.refreshUserData();
                });
              },
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.withValues(alpha: 0.6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow(Map<String, dynamic> moodStats, Map<String, dynamic> stressAnalysis) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Mood Entries',
            '${moodStats['totalEntries']}',
            Icons.mood_rounded,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Current Streak',
            '${moodStats['streakDays']} days',
            Icons.local_fire_department_rounded,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Avg Mood',
            '${(moodStats['averageMoodScore'] as double).toStringAsFixed(1)}/5',
            Icons.trending_up_rounded,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassWidget(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWellnessJourneyCard(Map<String, dynamic> moodStats) {
    final longestStreak = moodStats['longestStreak'] as int;
    final currentStreak = moodStats['streakDays'] as int;
    final totalEntries = moodStats['totalEntries'] as int;
    
    return GlassWidget(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Wellness Journey',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress indicators
          _buildProgressItem(
            'Longest Streak',
            '$longestStreak days',
            longestStreak / 30, // Assuming 30 days as max for visualization
            Colors.orange,
          ),
          
          const SizedBox(height: 12),
          
          _buildProgressItem(
            'Total Check-ins',
            '$totalEntries entries',
            (totalEntries / 100).clamp(0.0, 1.0), // Assuming 100 as milestone
            Colors.blue,
          ),
          
          const SizedBox(height: 12),
          
          _buildProgressItem(
            'Consistency',
            '${((currentStreak / 7) * 100).clamp(0, 100).toInt()}%',
            (currentStreak / 7).clamp(0.0, 1.0),
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String title, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildAchievementSection(Map<String, dynamic> moodStats) {
    final achievements = _getAchievements(moodStats);
    
    return GlassWidget(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Achievement badges
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievements.map((achievement) => _buildAchievementBadge(
              achievement['title'],
              achievement['icon'],
              achievement['color'],
              achievement['earned'],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String title, IconData icon, Color color, bool earned) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: earned 
            ? color.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: earned 
              ? color.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: earned ? color : Colors.white.withValues(alpha: 0.3),
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: earned ? Colors.white : Colors.white.withValues(alpha: 0.5),
              fontWeight: earned ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, AuthProvider authProvider) {
    return GlassWidget(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Account options
          _buildAccountOption(
            'Export Data',
            'Download your wellness data',
            Icons.download_rounded,
            () => _exportData(context),
          ),
          
          const SizedBox(height: 12),
          
          _buildAccountOption(
            'Privacy Settings',
            'Manage your data and privacy',
            Icons.privacy_tip_rounded,
            () => _showPrivacySettings(context),
          ),
          
          const SizedBox(height: 12),
          
          _buildAccountOption(
            'Help & Support',
            'Get help and contact support',
            Icons.help_rounded,
            () => _showHelpSupport(context),
          ),
          
          const SizedBox(height: 16),
          
          // Sign out button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _signOut(context, authProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.2),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded),
                  SizedBox(width: 8),
                  Text('Sign Out'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getAchievements(Map<String, dynamic> moodStats) {
    final totalEntries = moodStats['totalEntries'] as int;
    final longestStreak = moodStats['longestStreak'] as int;
    
    return [
      {
        'title': 'First Step',
        'icon': Icons.star_rounded,
        'color': Colors.yellow,
        'earned': totalEntries >= 1,
      },
      {
        'title': 'Week Warrior',
        'icon': Icons.calendar_view_week_rounded,
        'color': Colors.blue,
        'earned': longestStreak >= 7,
      },
      {
        'title': 'Consistency King',
        'icon': Icons.local_fire_department_rounded,
        'color': Colors.orange,
        'earned': longestStreak >= 30,
      },
      {
        'title': 'Mood Master',
        'icon': Icons.psychology_rounded,
        'color': Colors.purple,
        'earned': totalEntries >= 50,
      },
      {
        'title': 'Wellness Warrior',
        'icon': Icons.fitness_center_rounded,
        'color': Colors.green,
        'earned': totalEntries >= 100,
      },
      {
        'title': 'Streak Legend',
        'icon': Icons.emoji_events_rounded,
        'color': Colors.amber,
        'earned': longestStreak >= 100,
      },
    ];
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _exportData(BuildContext context) {
    // TODO: Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showPrivacySettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacySettingsScreen(),
      ),
    );
  }

  void _showHelpSupport(BuildContext context) {
    // TODO: Implement help & support
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Help & support coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _signOut(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authProvider.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      }
    }
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:provider/provider.dart';
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/mood_check_card.dart';
import '../widgets/mood_graph_card.dart';
import '../widgets/crisis_dashboard_widget.dart';
import '../providers/auth_provider.dart';
import 'simple_ai_chat_screen.dart';
import 'meditation_screen.dart';
import 'journal_screen.dart';
import 'insights_screen.dart';
import 'chat_history_screen.dart';
import 'profile_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: GlassAppBar(
            title: 'AuraCare',
            showUserProfile: true,
            userName: user?.name,
            userPhotoUrl: user?.photoUrl,
            onProfileTap: () => _showProfileMenu(context),
            showNotificationBadge: true,
            notificationCount: 3, // TODO: Connect to real notification system
            trailing: DynamicMoodPill(
              onTap: () => _scrollToMoodSection(context),
            ),
          ),
          floatingActionButton: GlassFloatingActionButton(
        icon: Icons.self_improvement_rounded,
        tooltip: 'Calm Now',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MeditationScreen()),
          );
        },
      ),
      body: Stack(
        children: [
          // Animated background with liquid blobs
          const AuraBackground(),

          // Main content
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Crisis Dashboard (only shows when needed)
                const CrisisDashboardWidget(),
                
                // Hero card - Mood Check-In
                const MoodCheckCard(),
                
                const SizedBox(height: 16),

                // Talk to Aura
                // Talk to Aura
                GlassCard(
                  title: 'Talk to Aura',
                  subtitle: 'Human-like AI chat for emotional support',
                  leadingIcon: Icons.psychology_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SimpleAIChatScreen()),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Journaling
                GlassCard(
                  title: 'Journaling',
                  subtitle: 'Write your thoughts and reflect on your day',
                  leadingIcon: Icons.book_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JournalScreen()),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Chat History
                GlassCard(
                  title: 'Chat History',
                  subtitle: 'View and resume past conversations with Aura',
                  leadingIcon: Icons.history_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatHistoryScreen()),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Mood Graph
                const MoodGraphCard(),

                const SizedBox(height: 16),

                // Meditation & Breathing
                GlassCard(
                  title: 'Meditation & Breathing',
                  subtitle: 'Guided sessions for calm and focus',
                  leadingIcon: Icons.self_improvement_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MeditationScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Community Connect
                GlassCard(
                  title: 'Community Connect',
                  subtitle: 'Anonymous support groups & forums',
                  leadingIcon: Icons.groups_rounded,
                  onTap: () {
                    // TODO: Navigate to community
                  },
                ),

                const SizedBox(height: 16),

                // Nearby Help
                GlassCard(
                  title: 'Nearby Help',
                  subtitle: 'Counsellors • NGOs • Helplines',
                  leadingIcon: Icons.location_on_rounded,
                  onTap: () {
                    // TODO: Navigate to nearby help
                  },
                ),

                const SizedBox(height: 16),

                // Insights & Analytics
                GlassCard(
                  title: 'Insights & Analytics',
                  subtitle: 'Mood trends • Patterns • Progress',
                  leadingIcon: Icons.analytics_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InsightsScreen()),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Profile & Progress
                GlassCard(
                  title: 'Profile & Progress',
                  subtitle: 'Personal settings • Achievements • Streaks',
                  leadingIcon: Icons.person_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                ),

                const SizedBox(height: 100), // Bottom padding for FAB
              ],
            ),
          ),
        ],
      ),
    );
        },
    );
  }

  void _scrollToMoodSection(BuildContext context) {
    // TODO: Implement smooth scroll to mood check card
    // For now, show a quick mood check-in dialog
    _showQuickMoodEntry(context);
  }

  void _showQuickMoodEntry(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF0B2E3C),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Quick Mood Check-In',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'How are you feeling right now?',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Quick mood selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickMoodOption(context, '😊', 'Happy'),
                _buildQuickMoodOption(context, '😌', 'Calm'),
                _buildQuickMoodOption(context, '😐', 'Neutral'),
                _buildQuickMoodOption(context, '😰', 'Stressed'),
                _buildQuickMoodOption(context, '😢', 'Sad'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'Tap to log your mood',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMoodOption(BuildContext context, String emoji, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        // TODO: Save quick mood entry
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$emoji $label mood logged!'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((255 * 0.1).toInt()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withAlpha((255 * 0.2).toInt()),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final screenWidth = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 400 ? 16 : 24,
                vertical: 20,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF0B2E3C),
                    Color(0xFF1E293B),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: Colors.white.withAlpha((255 * 0.1).toInt()),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Enhanced profile info
                  if (user != null) _buildUserProfileSection(user, screenWidth),

                  const SizedBox(height: 24),

                  // Enhanced menu options
                  _buildMenuOptions(context, authProvider, screenWidth),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileSection(dynamic user, double screenWidth) {
    final isCompact = screenWidth < 400;
    
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((255 * 0.05).toInt()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withAlpha((255 * 0.1).toInt()),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Enhanced avatar with status indicator
          Stack(
            children: [
              CircleAvatar(
                radius: isCompact ? 28 : 35,
                backgroundColor: const Color(0xFF1E293B),
                backgroundImage: user.photoUrl != null 
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null 
                    ? Icon(
                        Icons.person_rounded, 
                        size: isCompact ? 28 : 35,
                        color: Colors.white70,
                      )
                    : null,
              ),
              // Online status indicator
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0F172A),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // User information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: isCompact ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 14,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.age != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E40AF).withAlpha((255 * 0.2).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Age ${user.age}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF93C5FD),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions(BuildContext context, dynamic authProvider, double screenWidth) {
    final isCompact = screenWidth < 400;
    
    final menuItems = [
      _MenuItemData(
        icon: Icons.person_rounded,
        title: 'Profile & Settings',
        subtitle: 'Manage your account & preferences',
        color: const Color(0xFF3B82F6),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.analytics_rounded,
        title: 'Progress & Analytics',
        subtitle: 'View your wellness journey insights',
        color: const Color(0xFF10B981),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InsightsScreen()),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.help_rounded,
        title: 'Help & Support',
        subtitle: 'Get assistance & contact support',
        color: const Color(0xFF8B5CF6),
        onTap: () {
          Navigator.pop(context);
          // TODO: Navigate to help screen
        },
      ),
      _MenuItemData(
        icon: Icons.logout_rounded,
        title: 'Sign Out',
        subtitle: 'Securely logout from your account',
        color: const Color(0xFFEF4444),
        isDestructive: true,
        onTap: () async {
          Navigator.pop(context);
          await authProvider.signOut();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/auth', 
              (route) => false
            );
          }
        },
      ),
    ];

    return Column(
      children: menuItems.map((item) => _buildMenuItem(item, isCompact)).toList(),
    );
  }

  Widget _buildMenuItem(_MenuItemData item, bool isCompact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        tileColor: Colors.white.withAlpha((255 * 0.03).toInt()),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item.color.withAlpha((255 * 0.15).toInt()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            item.icon,
            color: item.color,
            size: 20,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: item.isDestructive ? item.color : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: isCompact ? 15 : 16,
          ),
        ),
        subtitle: !isCompact ? Text(
          item.subtitle,
          style: TextStyle(
            color: item.isDestructive 
                ? item.color.withAlpha((255 * 0.7).toInt())
                : Colors.white60,
            fontSize: 13,
          ),
        ) : null,
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.white.withValues(alpha: 0.4),
          size: 20,
        ),
        onTap: item.onTap,
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDestructive;
  final VoidCallback onTap;

  _MenuItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isDestructive = false,
    required this.onTap,
  });
}

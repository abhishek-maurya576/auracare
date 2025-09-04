import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'AuraCare',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MoodPill(emoji: '😊', label: 'Calm'),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showProfileMenu(context),
              icon: const Icon(Icons.account_circle_rounded),
              tooltip: 'Profile',
            ),
          ],
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
  }

  void _showProfileMenu(BuildContext context) {
    final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF0B2E3C)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile info
            if (user != null) ...[
              CircleAvatar(
                radius: 30,
                backgroundImage: user.photoUrl != null 
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null 
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                user.email,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Menu options
            ListTile(
              leading: const Icon(Icons.person_rounded, color: Colors.white),
              title: const Text('Profile & Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to profile screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics_rounded, color: Colors.white),
              title: const Text('Progress & Analytics', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to analytics screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_rounded, color: Colors.white),
              title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to help screen
              },
            ),
            const Divider(color: Colors.white30),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
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
          ],
        ),
      ),
    );
  }
}

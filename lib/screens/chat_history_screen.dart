import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/chat_session_service.dart';
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../utils/app_colors.dart';
import 'simple_ai_chat_screen.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ChatSessionService _chatSessionService = ChatSessionService();
  late Future<List<Map<String, dynamic>>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _chatSessionService.getUserSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        ),
        title: const GlassWidget(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, color: AppColors.accentTeal, size: 20),
                SizedBox(width: 8),
                Text(
                  'Chat History',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AuraBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _sessionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading chat history',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      ),
                    );
                  }
                  
                  final sessions = snapshot.data ?? [];
                  
                  if (sessions.isEmpty) {
                    return Center(
                      child: Text(
                        'No chat history yet',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final lastUpdated = session['lastUpdated']?.toDate() ?? DateTime.now();
                      final messageCount = session['messageCount'] ?? 0;
                      final title = session['title'] ?? 'Chat Session';
                      final mood = session['mood'];
                      final topics = session['topics'] as List<dynamic>? ?? [];
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SimpleAIChatScreen(sessionId: session['sessionId']),
                                ),
                              );
                            },
                            onLongPress: () => _showSessionOptions(context, session),
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Session header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentTeal.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.chat_bubble_outline,
                                        color: AppColors.accentTeal,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatSessionDate(lastUpdated),
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (mood != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getMoodColor(mood).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _getMoodColor(mood).withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _getMoodEmoji(mood),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Session details
                                Row(
                                  children: [
                                    _buildSessionStat(Icons.message_outlined, '$messageCount messages'),
                                    const SizedBox(width: 16),
                                    _buildSessionStat(Icons.access_time_rounded, _getSessionDuration(session)),
                                  ],
                                ),
                                
                                // Topics
                                if (topics.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: topics.take(3).map((topic) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentTeal.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.accentTeal.withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        topic.toString(),
                                        style: TextStyle(
                                          color: AppColors.accentTeal,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to build session statistics
  Widget _buildSessionStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Format session date in a user-friendly way
  String _formatSessionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Format time in 12-hour format
  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Get session duration from start to end time
  String _getSessionDuration(Map<String, dynamic> session) {
    try {
      final startTime = DateTime.parse(session['startTime'] ?? '');
      final endTime = DateTime.parse(session['endTime'] ?? '');
      final duration = endTime.difference(startTime);
      
      if (duration.inMinutes < 1) {
        return '< 1 min';
      } else if (duration.inMinutes < 60) {
        return '${duration.inMinutes} min';
      } else {
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;
        return '${hours}h ${minutes}m';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get mood color based on mood string
  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'excited':
        return AppColors.moodHappy;
      case 'calm':
      case 'content':
      case 'good':
        return AppColors.moodCalm;
      case 'neutral':
      case 'okay':
        return AppColors.moodNeutral;
      case 'sad':
      case 'down':
        return AppColors.moodSad;
      case 'angry':
      case 'frustrated':
        return AppColors.moodAngry;
      case 'stressed':
      case 'overwhelmed':
        return AppColors.moodStressed;
      default:
        return AppColors.accentTeal;
    }
  }

  /// Get mood emoji based on mood string
  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'excited':
        return '😊';
      case 'calm':
      case 'content':
      case 'good':
        return '😌';
      case 'neutral':
      case 'okay':
        return '😐';
      case 'sad':
      case 'down':
        return '😢';
      case 'angry':
      case 'frustrated':
        return '😠';
      case 'stressed':
      case 'overwhelmed':
        return '😰';
      default:
        return '💭';
    }
  }

  /// Show session management options
  void _showSessionOptions(BuildContext context, Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: AppColors.accentTeal.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Session title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                session['title'] ?? 'Chat Session',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const Divider(color: AppColors.textSecondary, height: 1),
            
            // Options
            ListTile(
              leading: const Icon(Icons.chat_rounded, color: AppColors.accentTeal),
              title: const Text('Resume Chat', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SimpleAIChatScreen(sessionId: session['sessionId']),
                  ),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.share_rounded, color: AppColors.accentTeal),
              title: const Text('Share Session', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _shareSession(session);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.moodSad),
              title: const Text('Delete Session', style: TextStyle(color: AppColors.moodSad)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteSession(context, session);
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Share session summary
  void _shareSession(Map<String, dynamic> session) async {
    try {
      final title = session['title'] ?? 'Chat Session';
      final messageCount = session['messageCount'] ?? 0;
      final topics = (session['topics'] as List<dynamic>? ?? []).join(', ');
      
      final shareText = '''
🌟 AuraCare Chat Session Summary

📝 Session: $title
💬 Messages: $messageCount
🏷️ Topics: ${topics.isNotEmpty ? topics : 'General conversation'}
📅 Date: ${_formatSessionDate(session['lastUpdated']?.toDate() ?? DateTime.now())}

Shared from AuraCare - Your AI Mental Wellness Companion
      '''.trim();
      
      await Share.share(shareText);
    } catch (e) {
      debugPrint('Error sharing session: $e');
    }
  }

  /// Confirm session deletion
  void _confirmDeleteSession(BuildContext context, Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.glassWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Session?',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will permanently delete "${session['title'] ?? 'Chat Session'}" and all its messages. This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSession(session['sessionId']);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.moodSad)),
          ),
        ],
      ),
    );
  }

  /// Delete session from Firestore
  void _deleteSession(String sessionId) async {
    try {
      await _chatSessionService.clearSession(sessionId);
      
      // Refresh the sessions list
      setState(() {
        _sessionsFuture = _chatSessionService.getUserSessions();
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session deleted successfully'),
            backgroundColor: AppColors.accentTeal,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete session'),
            backgroundColor: AppColors.moodSad,
          ),
        );
      }
    }
  }
}

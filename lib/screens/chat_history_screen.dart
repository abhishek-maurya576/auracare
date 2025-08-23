import 'package:flutter/material.dart';
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
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: ListTile(
                          leading: const Icon(Icons.chat_bubble_outline, color: AppColors.accentTeal),
                          title: Text(
                            '${lastUpdated.day}/${lastUpdated.month}/${lastUpdated.year}',
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                          subtitle: Text(
                            '$messageCount messages',
                            style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.7)),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.accentTeal),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SimpleAIChatScreen(sessionId: session['sessionId']),
                              ),
                            );
                          },
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
}

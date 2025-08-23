import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../services/chat_session_service.dart';
import '../services/gemini_service.dart';
import '../services/user_profile_service.dart';
import '../providers/auth_provider.dart';
import '../providers/mood_provider.dart';
import '../utils/app_colors.dart';

class SimpleAIChatScreen extends StatefulWidget {
  final String? sessionId;
  const SimpleAIChatScreen({super.key, this.sessionId});

  @override
  State<SimpleAIChatScreen> createState() => _SimpleAIChatScreenState();
}

class _SimpleAIChatScreenState extends State<SimpleAIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  final ChatSessionService _chatSessionService = ChatSessionService();
  final UserProfileService _userProfileService = UserProfileService();
  String? _sessionId;
  String? _currentUserId;
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    // Get current user
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = authProvider.user?.uid;
    
    // Load user profile and mood data for personalization
    if (_currentUserId != null) {
      await _loadUserDataForPersonalization();
    }
    
    if (widget.sessionId != null) {
      _sessionId = widget.sessionId;
      _loadChatHistory();
    } else {
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _addWelcomeMessage();
    }
  }

  Future<void> _loadUserDataForPersonalization() async {
    if (_currentUserId == null) return;
    
    try {
      // Load user profile for personalization
      final profile = await _userProfileService.getUserProfile(_currentUserId!);
      if (profile != null) {
        _geminiService.setUserProfile(_currentUserId!, profile);
        debugPrint('✅ User profile loaded for AI personalization: ${profile.name}');
      }
      
      // Load recent mood data for context
      if (mounted) {
        final moodProvider = Provider.of<MoodProvider>(context, listen: false);
        await moodProvider.loadMoodHistory(days: 7); // Load last 7 days
        final moodEntries = moodProvider.moodEntries;
        
        if (moodEntries.isNotEmpty) {
          _geminiService.setUserMoodData(_currentUserId!, moodEntries);
          debugPrint('✅ Mood data loaded for AI context: ${moodEntries.length} entries');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load user data for personalization: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() async {
    // Get personalized welcome message
    String welcomeMessage = "Hello! I'm Aura, your AI companion for mental wellness. I'm here to listen and support you. How are you feeling today?";
    
    // Try to personalize if user profile is available
    if (_currentUserId != null) {
      try {
        final profile = await _userProfileService.getUserProfile(_currentUserId!);
        if (profile != null && profile.name.isNotEmpty) {
          welcomeMessage = "Hello ${profile.name}! I'm Aura, your AI companion for mental wellness. I remember our previous conversations and I'm here to support you on your wellness journey. How are you feeling today?";
        }
      } catch (e) {
        debugPrint('Could not load profile for welcome message: $e');
      }
    }
    
    setState(() {
      _messages.add(
        ChatMessage(
          text: "$welcomeMessage\n\n✨ Created by Junior Developer, Abhishek Maurya",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _loadChatHistory() async {
    if (_sessionId == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final history = await _chatSessionService.loadConversationHistory(_sessionId!); // Assuming _chatSessionService is available
      setState(() {
        _messages.clear();
        for (var msg in history) {
          _messages.add(ChatMessage(
            text: msg['content']!,
            isUser: msg['role'] == 'user',
            timestamp: DateTime.now(), // Firestore doesn't store timestamp per message in history
          ));
        }
      });
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                Icon(Icons.psychology_rounded, color: AppColors.accentTeal, size: 20),
                SizedBox(width: 8),
                Text(
                  'Talk to Aura',
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
            child: Column(
              children: [
                // Messages list
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
                
                // Loading indicator
                if (_isLoading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Row(
                      children: [
                        SizedBox(width: 50),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.accentTeal),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Aura is thinking...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                
                // Message input
                _buildMessageInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.auraGradient1,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: GlassWidget(
              backgroundColor: message.isUser 
                  ? AppColors.accentTeal.withValues(alpha: 0.2)
                  : AppColors.glassWhite,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentTeal,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GlassWidget(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Share your thoughts...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : _sendMessage,
                icon: Icon(
                  Icons.send_rounded,
                  color: _isLoading ? AppColors.textMuted : AppColors.accentTeal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    debugPrint('=== SENDING MESSAGE: "$userMessage" ===');

    // Add user message immediately
    setState(() {
      _messages.add(
        ChatMessage(
          text: userMessage,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      debugPrint('Calling Gemini API for chat response...');
      
      // Generate AI response with personalization
      final aiResponse = await _geminiService.generateChatResponse(
        userMessage,
        sessionId: _sessionId,
        userId: _currentUserId, // ✅ NOW PERSONALIZED!
      );
      
      debugPrint('Got response from Gemini: "${aiResponse.substring(0, aiResponse.length > 100 ? 100 : aiResponse.length)}..."');

      // Add AI response immediately
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: aiResponse,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });

        _scrollToBottom();
        debugPrint('Response added to UI successfully!');
      }
    } catch (e) {
      debugPrint('ERROR in _sendMessage: $e');
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: "I'm sorry, I'm having trouble responding right now. Please try again!",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}



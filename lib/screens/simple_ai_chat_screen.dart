import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context, message),
              child: GlassWidget(
                backgroundColor: message.isUser 
                    ? AppColors.accentTeal.withValues(alpha: 0.2)
                    : AppColors.glassWhite,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        message.text,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                          // Copy button with gentle hover effect
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _copyMessageText(message.text),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.accentTeal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.accentTeal.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 14,
                                      color: AppColors.accentTeal.withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Copy',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.accentTeal.withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
        
        // 🆕 AUTO-SAVE: Save conversation after each exchange
        await _saveCurrentSession();
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

  /// 🆕 AUTO-SAVE: Save current session to Firestore
  Future<void> _saveCurrentSession() async {
    if (_sessionId == null || _messages.isEmpty) return;
    
    try {
      // Convert messages to the format expected by ChatSessionService
      final history = _messages.map((msg) => {
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
        'timestamp': msg.timestamp.toIso8601String(),
      }).toList();
      
      // Save to Firestore with enhanced metadata
      await _chatSessionService.saveConversationHistory(_sessionId!, history);
      
      // Also save session metadata for better organization
      await _saveSessionMetadata();
      
      debugPrint('✅ Session auto-saved: ${_messages.length} messages');
    } catch (e) {
      debugPrint('⚠️ Failed to auto-save session: $e');
    }
  }

  /// 🆕 Save session metadata for better organization
  Future<void> _saveSessionMetadata() async {
    if (_sessionId == null || _currentUserId == null) return;
    
    try {
      // Extract session summary from first few messages
      String sessionTitle = 'Chat Session';
      if (_messages.length > 1) {
        final firstUserMessage = _messages.firstWhere((msg) => msg.isUser, orElse: () => _messages.first);
        sessionTitle = firstUserMessage.text.length > 50 
            ? '${firstUserMessage.text.substring(0, 50)}...'
            : firstUserMessage.text;
      }
      
      // Get current mood context if available
      String? currentMood;
      if (mounted) {
        final moodProvider = Provider.of<MoodProvider>(context, listen: false);
        final todayMoodEntries = moodProvider.getMoodEntriesForDate(DateTime.now());
        if (todayMoodEntries.isNotEmpty) {
          currentMood = todayMoodEntries.first.mood;
        }
      }
      
      final metadata = {
        'title': sessionTitle,
        'messageCount': _messages.length,
        'lastUpdated': FieldValue.serverTimestamp(),
        'startTime': _messages.isNotEmpty ? _messages.first.timestamp.toIso8601String() : DateTime.now().toIso8601String(),
        'endTime': _messages.isNotEmpty ? _messages.last.timestamp.toIso8601String() : DateTime.now().toIso8601String(),
        'mood': currentMood,
        'topics': _extractTopics(), // Extract key topics discussed
        'isActive': true,
      };
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId!)
          .collection('chat_sessions')
          .doc(_sessionId!)
          .set(metadata, SetOptions(merge: true));
          
    } catch (e) {
      debugPrint('⚠️ Failed to save session metadata: $e');
    }
  }

  /// 🆕 Extract key topics from conversation
  List<String> _extractTopics() {
    final topics = <String>[];
    final keywords = {
      'stress': ['stress', 'stressed', 'pressure', 'overwhelmed'],
      'anxiety': ['anxiety', 'anxious', 'worry', 'nervous'],
      'depression': ['sad', 'depressed', 'down', 'hopeless'],
      'school': ['school', 'college', 'study', 'exam', 'homework'],
      'relationships': ['friend', 'family', 'relationship', 'parents'],
      'sleep': ['sleep', 'tired', 'insomnia', 'rest'],
      'work': ['work', 'job', 'career', 'boss'],
    };
    
    final allText = _messages.map((msg) => msg.text.toLowerCase()).join(' ');
    
    for (final topic in keywords.keys) {
      if (keywords[topic]!.any((keyword) => allText.contains(keyword))) {
        topics.add(topic);
      }
    }
    
    return topics;
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

  /// Copy message text to clipboard with gentle, supportive feedback
  void _copyMessageText(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      
      if (mounted) {
        // Gentle haptic feedback first - like a caring touch
        HapticFeedback.lightImpact();
        
        // Show warm, glass-morphic success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.glassWhite.withValues(alpha: 0.95),
                    AppColors.accentTeal.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentTeal.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentTeal.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.accentTeal,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Message copied! 💙',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'You can now paste it anywhere you need',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to copy text: $e');
      
      if (mounted) {
        // Gentle error feedback - still supportive
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.glassWhite.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.moodSad.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.moodSad,
                    size: 18,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Copy not available right now',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Try selecting the text manually',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  /// Show premium message options with luxurious glass-morphic design
  void _showMessageOptions(BuildContext context, ChatMessage message) {
    // Gentle haptic feedback for the interaction
    HapticFeedback.selectionClick();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.only(top: 100),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.glassWhite.withValues(alpha: 0.92),
                AppColors.accentTeal.withValues(alpha: 0.12),
                AppColors.accentBlue.withValues(alpha: 0.15),
                AppColors.accentTeal.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            border: Border.all(
              color: AppColors.accentTeal.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 60,
                offset: const Offset(0, -15),
                spreadRadius: 8,
              ),
              BoxShadow(
                color: AppColors.accentTeal.withValues(alpha: 0.12),
                blurRadius: 40,
                offset: const Offset(0, -8),
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium handle bar with glow effect
              Container(
                margin: const EdgeInsets.only(top: 20),
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentTeal.withValues(alpha: 0.8),
                      AppColors.accentBlue.withValues(alpha: 0.6),
                      AppColors.accentTeal.withValues(alpha: 0.4),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentTeal.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Luxurious header with animated icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: message.isUser 
                            ? [
                                AppColors.accentTeal.withValues(alpha: 0.15),
                                AppColors.accentTeal.withValues(alpha: 0.05),
                              ]
                            : [
                                AppColors.accentBlue.withValues(alpha: 0.15),
                                AppColors.accentBlue.withValues(alpha: 0.05),
                              ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: message.isUser 
                            ? AppColors.accentTeal.withValues(alpha: 0.2)
                            : AppColors.accentBlue.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: message.isUser 
                              ? AppColors.accentTeal.withValues(alpha: 0.1)
                              : AppColors.accentBlue.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        message.isUser ? Icons.person_rounded : Icons.psychology_rounded,
                        color: message.isUser ? AppColors.accentTeal : AppColors.accentBlue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message.isUser ? 'Your Thoughts' : 'Aura\'s Wisdom',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Choose an action',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Premium action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Copy option with premium styling
                    _buildPremiumActionButton(
                      icon: Icons.copy_rounded,
                      title: 'Copy Message',
                      subtitle: 'Save to clipboard for later',
                      emoji: '💙',
                      gradient: [
                        AppColors.accentTeal.withValues(alpha: 0.15),
                        AppColors.accentTeal.withValues(alpha: 0.08),
                      ],
                      borderColor: AppColors.accentTeal.withValues(alpha: 0.3),
                      iconColor: AppColors.accentTeal,
                      onTap: () {
                        Navigator.pop(context);
                        _copyMessageText(message.text);
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Share option with premium styling
                    _buildPremiumActionButton(
                      icon: Icons.share_rounded,
                      title: 'Share Message',
                      subtitle: 'Spread hope and support',
                      emoji: '✨',
                      gradient: [
                        AppColors.accentBlue.withValues(alpha: 0.15),
                        AppColors.accentBlue.withValues(alpha: 0.08),
                      ],
                      borderColor: AppColors.accentBlue.withValues(alpha: 0.3),
                      iconColor: AppColors.accentBlue,
                      onTap: () {
                        Navigator.pop(context);
                        _shareMessage(message);
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Build premium action button with glass-morphic design
  Widget _buildPremiumActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required String emoji,
    required List<Color> gradient,
    required Color borderColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.85),
                ...gradient,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 25,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: iconColor.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container with glow
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withValues(alpha: 0.2),
                      iconColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow indicator with glow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: iconColor.withValues(alpha: 0.7),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Share message with beautiful, supportive formatting
  void _shareMessage(ChatMessage message) async {
    try {
      // Gentle haptic feedback
      HapticFeedback.lightImpact();
      
      // Create beautiful, supportive share text
      final String shareText = _formatMessageForSharing(message);
      
      // Share with native platform sharing
      await Share.share(
        shareText,
        subject: message.isUser 
          ? 'A thought I wanted to share 💭'
          : 'Wisdom from AuraCare 💙',
      );
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.glassWhite.withValues(alpha: 0.95),
                    AppColors.accentBlue.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentBlue.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: AppColors.accentBlue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Message shared! ✨',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Spreading hope and support 💙',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to share message: $e');
      
      if (mounted) {
        // Gentle error feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.glassWhite.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.moodSad.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.moodSad,
                    size: 18,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sharing not available right now',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Try copying the message instead',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  /// Format message for sharing with beautiful, supportive text
  String _formatMessageForSharing(ChatMessage message) {
    final String timestamp = _formatTime(message.timestamp);
    final String date = '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
    
    if (message.isUser) {
      return '''💭 A thought I wanted to share:

"${message.text}"

Shared from my AuraCare journey 💙
$date at $timestamp

---
AuraCare: Your companion for mental wellness
Download: [App Store/Play Store Link]''';
    } else {
      return '''✨ Wisdom from AuraCare:

"${message.text}"

This supportive message was generated by Aura, my AI wellness companion, during our conversation on $date at $timestamp.

💙 If you're going through a tough time, know that support is available. AuraCare is here to help with mental wellness, mood tracking, and connecting you with resources.

---
AuraCare: Compassionate AI for mental wellness
Download: [App Store/Play Store Link]''';
    }
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



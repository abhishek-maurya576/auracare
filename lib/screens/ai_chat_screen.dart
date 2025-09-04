import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/api_status_indicator.dart';
import '../services/gemini_service.dart';
import '../services/firebase_service.dart';
import '../services/chat_session_service.dart';
import '../services/crisis_intervention_service.dart';
import '../providers/auth_provider.dart';
import '../providers/api_status_provider.dart';
import '../providers/user_profile_provider.dart';
import '../utils/app_colors.dart';
import 'crisis_intervention_screen.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  final FirebaseService _firebaseService = FirebaseService();
  final ChatSessionService _chatSessionService = ChatSessionService();
  final CrisisInterventionService _crisisService = CrisisInterventionService();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _sessionId;
  List<String> _suggestedResponses = [];

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }
  
  Future<void> _initializeSession() async {
    try {
      // Get or create session with persistent memory
      _sessionId = await _chatSessionService.getOrCreateSession();
      
      // Load chat history from Firebase
      await _loadChatHistory();
      
      // Add welcome message if no messages exist
      _addWelcomeMessage();
    } catch (e) {
      debugPrint('Error initializing session: $e');
      // Fallback to basic session
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _addWelcomeMessage();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      final welcomeMessage = ChatMessage(
        text: "Hello! I'm Aura, your AI companion for mental wellness. I'm here to listen, support, and help you navigate your emotions. How are you feeling today?\n Created by Juniour dev, Abhishek Maurya",
        isUser: false,
        timestamp: DateTime.now(),
        sessionId: _sessionId!,
      );
      
      setState(() {
        _messages.add(welcomeMessage);
      });
      
      // Add welcome message to session history
      _geminiService.addToSessionHistory(_sessionId!, 'Aura', welcomeMessage.text);
      
      _saveMessage(welcomeMessage);
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final messages = await _firebaseService.getChatMessages();
      if (messages.isNotEmpty) {
        setState(() {
          _messages.addAll(messages);
        });
        
        // Initialize session history with loaded messages
        for (final message in messages) {
          final role = message.isUser ? 'User' : 'Aura';
          _geminiService.addToSessionHistory(_sessionId!, role, message.text);
        }
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  Future<void> _saveMessage(ChatMessage message) async {
    try {
      await _firebaseService.saveChatMessage(message);
    } catch (e) {
      debugPrint('Error saving message: $e');
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
        actions: [
          IconButton(
            onPressed: _showClearHistoryDialog,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'New Conversation',
          ),
        ],
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
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(width: 50),
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.accentTeal),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Aura is thinking...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                
                // API Status Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const ApiStatusIndicator(showDetails: true),
                    ],
                  ),
                ),
                
                // Message input
                _buildMessageInput(),
                
                // Suggested responses
                if (_suggestedResponses.isNotEmpty)
                  _buildSuggestedResponses(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
    
    // Check API status before sending
    final apiStatus = Provider.of<ApiStatusProvider>(context, listen: false);
    if (!apiStatus.isApiConfigured) {
      // Show error message and try to validate API again
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('AI service is not available. Trying to reconnect...'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => apiStatus.validateApiConfiguration(),
            textColor: Colors.white,
          ),
        ),
      );
      
      // Try to validate API configuration
      apiStatus.validateApiConfiguration();
      return;
    }

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    // Get current user ID for personalization
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    // Add user message
    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
      sessionId: _sessionId!,
    );
    
    setState(() {
      _messages.add(userChatMessage);
      _isLoading = true;
    });
    
    _saveMessage(userChatMessage);

    _scrollToBottom();

    try {
      debugPrint('Starting personalized chat response generation for: "$userMessage"');
      
      // Get user profile for personalized crisis detection
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      final userProfile = userProfileProvider.userProfile;
      
      // Comprehensive crisis analysis
      final crisisAnalysis = await _crisisService.analyzeCrisisLevel(
        userMessage,
        userId: userId,
        userProfile: userProfile,
        conversationHistory: _messages.map((m) => m.text).toList(),
      );
      
      debugPrint('🚨 Crisis analysis: Severity ${crisisAnalysis.severityLevel}/10, Type: ${crisisAnalysis.crisisType}');

      // Handle crisis situations
      if (crisisAnalysis.severityLevel >= 7) {
        debugPrint('🚨 CRISIS DETECTED - Triggering intervention protocol');
        
        // Show crisis intervention screen immediately
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CrisisInterventionScreen(
                analysisResult: crisisAnalysis,
                userId: userId,
              ),
            ),
          );
        }
        
        // Generate crisis-aware response
        final crisisResponse = await _crisisService.generateCrisisResponse(
          crisisAnalysis,
          userProfile,
        );
        
        // Use the immediate crisis message as AI response
        final aiResponse = crisisResponse.immediateMessage;
        
        // Add crisis indicator to the message
        final aiChatMessage = ChatMessage(
          text: '🚨 **Crisis Support Activated**\n\n$aiResponse\n\n*I\'ve opened immediate crisis resources for you. Please consider reaching out to a professional.*',
          isUser: false,
          timestamp: DateTime.now(),
          sessionId: _sessionId!,
        );
        
        if (mounted) {
          setState(() {
            _messages.add(aiChatMessage);
            _isLoading = false;
          });
        }
        
        _saveMessage(aiChatMessage);
        _scrollToBottom();
        return;
      }

      // Generate AI response using persistent session memory and personalization
      String aiResponse;
      if (crisisAnalysis.severityLevel >= 4) {
        debugPrint('Generating supportive response for elevated stress...');
        // Enhanced supportive response for moderate distress
        aiResponse = await _geminiService.generateChatResponse(
          userMessage,
          sessionId: _sessionId,
          userId: userId,
        );
        
        // Add supportive message if available
        if (crisisAnalysis.supportMessage.isNotEmpty) {
          aiResponse = '${crisisAnalysis.supportMessage}\n\n$aiResponse';
        }
      } else {
        debugPrint('Generating personalized chat response with persistent memory...');
        // Use Gemini service directly with personalization
        aiResponse = await _geminiService.generateChatResponse(
          userMessage,
          sessionId: _sessionId,
          userId: userId,
        );
      }

      debugPrint('AI response received: "${aiResponse.substring(0, aiResponse.length > 100 ? 100 : aiResponse.length)}..."');

      // Check if response is empty or null
      if (aiResponse.isEmpty) {
        throw 'Empty response from AI service';
      }

      // Add AI response
      final aiChatMessage = ChatMessage(
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
        sessionId: _sessionId!,
      );
      
      if (mounted) {
        setState(() {
          _messages.add(aiChatMessage);
          _isLoading = false;
        });

        _saveMessage(aiChatMessage);
        _scrollToBottom();
        _generateAndDisplaySuggestedResponses(aiChatMessage.text); // New line
        debugPrint('AI response added to chat successfully');
      }
    } catch (e) {
      debugPrint('Error in chat response: $e');
      final errorMessage = ChatMessage(
        text: "I apologize, but I'm having trouble responding right now. Please try again in a moment, or consider reaching out to a mental health professional if you need immediate support.",
        isUser: false,
        timestamp: DateTime.now(),
        sessionId: _sessionId!,
      );
      
      if (mounted) {
        setState(() {
          _messages.add(errorMessage);
          _isLoading = false;
        });
        _saveMessage(errorMessage);
        _scrollToBottom();
      }
    }
  }

  /*
  Future<String> _generateCrisisResponse(String message, {String? userId}) async {
    try {
      // Use personalized crisis response if user profile is available
      if (userId != null) {
        final response = await _geminiService.generateChatResponse(
          message,
          sessionId: _sessionId,
          userId: userId,
        );
        
        // Ensure crisis resources are included
        final crisisResources = '''

IMMEDIATE SUPPORT RESOURCES:
• National Suicide Prevention Lifeline: 988
• Crisis Text Line: Text HOME to 741741
• Emergency Services: Call 911

You deserve help and support. Please reach out to someone you trust.''';
        
        return response + crisisResources;
      }
    } catch (e) {
      debugPrint('Error generating personalized crisis response: $e');
    }
    
    // Fallback to standard crisis response
    return '''I'm really concerned about what you've shared. Your feelings are valid, and I want you to know that you're not alone. 

Please consider reaching out for immediate support:
• National Suicide Prevention Lifeline: 988
• Crisis Text Line: Text HOME to 741741
• Emergency Services: Call 911

You deserve help and support. Is there a trusted friend, family member, or mental health professional you could contact right now?''';
  }
  */

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _generateAndDisplaySuggestedResponses(String lastMessage) async {
    try {
      final responses = await _geminiService.generateSuggestedResponses(lastMessage);
      if (mounted && responses.isNotEmpty) {
        setState(() {
          _suggestedResponses = responses;
        });
      }
    } catch (e) {
      debugPrint('Error generating suggested responses: $e');
    }
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.glassWhite,
          title: const Text(
            'Start New Conversation',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'This will clear your current conversation history and start fresh. Your previous conversations are still saved.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearCurrentConversation();
              },
              child: const Text(
                'Start New',
                style: TextStyle(color: AppColors.accentTeal),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearCurrentConversation() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Clear current session
      if (_sessionId != null) {
        await _chatSessionService.clearSession(_sessionId!);
      }
      
      // Create new session
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Clear UI messages
      setState(() {
        _messages.clear();
        _suggestedResponses.clear();
      });
      
      // Add welcome message
      _addWelcomeMessage();
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Started new conversation'),
          backgroundColor: AppColors.accentTeal,
        ),
      );
    } catch (e) {
      debugPrint('Error clearing conversation: $e');
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Error starting new conversation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSuggestedResponses() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: _suggestedResponses.map((response) {
          return ActionChip(
            label: Text(response),
            labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
            backgroundColor: AppColors.glassWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide.none,
            ),
            onPressed: () {
              _messageController.text = response;
              _sendMessage();
              setState(() {
                _suggestedResponses = []; // Clear suggestions after selection
              });
            },
          );
        }).toList(),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String sessionId;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.sessionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'],
      isUser: map['isUser'],
      timestamp: DateTime.parse(map['timestamp']),
      sessionId: map['sessionId'],
    );
  }
}

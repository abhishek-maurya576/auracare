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
import '../models/user_profile.dart';
import '../models/chat_message.dart';
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
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      final userProfile = userProfileProvider.userProfile;
      
      String welcomeText;
      if (userProfile?.name != null) {
        final firstName = _getFirstName(userProfile!.name);
        welcomeText = "Hello $firstName! 💙 I'm Aura, your AI companion for mental wellness. I can see you're here and ready to connect - that's a wonderful first step!\n\nI'm here to listen, support, and help you navigate your emotions with care and understanding. Your wellbeing matters, and I'm honored to be part of your journey.\n\nHow are you feeling today? I'm ready to support you with personalized guidance.\n\n✨ Created with care by Junior dev, Abhishek Maurya";
      } else {
        welcomeText = "Hello there! 💙 I'm Aura, your AI companion for mental wellness. I'm here to listen, support, and help you navigate your emotions with care and understanding.\n\nHow are you feeling today? I'm ready to support you on your journey to wellbeing.\n\n✨ Created with care by Junior dev, Abhishek Maurya";
      }
      
      final welcomeMessage = ChatMessage(
        text: welcomeText,
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
        title: Consumer<UserProfileProvider>(
          builder: (context, userProfileProvider, child) {
            final userProfile = userProfileProvider.userProfile;
            return GlassWidget(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Aura's avatar
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.auraGradient1,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentTeal.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile?.name != null 
                              ? 'Talk to Aura'
                              : 'Talk to Aura',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          userProfile?.name != null 
                              ? 'Hi ${_getFirstName(userProfile!.name)}! 💙'
                              : 'Your AI companion',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // User's profile picture preview in app bar - Enhanced visibility
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentTeal.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentTeal.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.accentTeal.withValues(alpha: 0.1),
                        backgroundImage: userProfile?.photoUrl != null 
                            ? NetworkImage(userProfile!.photoUrl!)
                            : null,
                        child: userProfile?.photoUrl == null
                            ? Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.accentTeal.withValues(alpha: 0.8),
                                      AppColors.accentTeal.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                        onBackgroundImageError: (exception, stackTrace) {
                          debugPrint('App bar profile image failed to load: $exception');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _showClearHistoryDialog();
              } else if (value == 'profile') {
                // Navigate to profile settings
                // _navigateToProfile();
              }
            },
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 18, color: AppColors.textPrimary),
                    SizedBox(width: 12),
                    Text('New Conversation'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_rounded, size: 18, color: AppColors.textPrimary),
                    SizedBox(width: 12),
                    Text('Profile Settings'),
                  ],
                ),
              ),
            ],
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
          
          // Enhanced floating user profile indicator - Always visible when profile exists
          Consumer<UserProfileProvider>(
            builder: (context, userProfileProvider, child) {
              final userProfile = userProfileProvider.userProfile;
              // Show floating indicator if user has profile and there are messages
              if (userProfile != null && _messages.length > 1) {
                return Positioned(
                  top: 100, // Position below app bar
                  right: 16,
                  child: _buildEnhancedFloatingProfileIndicator(userProfile),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        final userProfile = userProfileProvider.userProfile;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                // Aura's Avatar with beautiful gradient and animation
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.auraGradient1,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentTeal.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              Flexible(
                child: Column(
                  crossAxisAlignment: message.isUser 
                      ? CrossAxisAlignment.end 
                      : CrossAxisAlignment.start,
                  children: [
                    // Name label for personalization
                    if (!message.isUser) 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 4),
                        child: Text(
                          'Aura',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentTeal,
                          ),
                        ),
                      ),
                    
                    if (message.isUser && userProfile?.name != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, right: 4),
                        child: Text(
                          _getFirstName(userProfile!.name),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    
                    // Message bubble
                    GlassWidget(
                      backgroundColor: message.isUser 
                          ? AppColors.accentTeal.withValues(alpha: 0.15)
                          : AppColors.glassWhite,
                      borderColor: message.isUser
                          ? AppColors.accentTeal.withValues(alpha: 0.3)
                          : AppColors.glassBorder,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                height: 1.4,
                                fontWeight: message.isUser ? FontWeight.w500 : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _formatTime(message.timestamp),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                                if (message.isUser) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.check,
                                    size: 12,
                                    color: AppColors.textMuted.withValues(alpha: 0.6),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (message.isUser) ...[
                const SizedBox(width: 12),
                // User's actual profile picture or elegant fallback
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.glassShadow.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.accentTeal.withValues(alpha: 0.1),
                    backgroundImage: userProfile?.photoUrl != null 
                        ? NetworkImage(userProfile!.photoUrl!)
                        : null,
                    child: userProfile?.photoUrl == null
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.accentTeal.withValues(alpha: 0.8),
                                  AppColors.accentTeal.withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          )
                        : null,
                    onBackgroundImageError: (exception, stackTrace) {
                      // Graceful fallback if profile image fails to load
                      debugPrint('Profile image failed to load: $exception');
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _getFirstName(String fullName) {
    return fullName.split(' ').first;
  }

  /// Floating profile indicator showing user's picture and connection status
  Widget _buildFloatingProfileIndicator(UserProfile userProfile) {
    return GestureDetector(
      onTap: () {
        // Optional: Show user profile quick actions
        _showProfileQuickActions(userProfile);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: GlassWidget(
          backgroundColor: AppColors.glassWhite.withValues(alpha: 0.9),
          borderColor: AppColors.accentTeal.withValues(alpha: 0.3),
          radius: 25,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // User's profile picture with online indicator
                Stack(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentTeal.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.accentTeal.withValues(alpha: 0.1),
                        backgroundImage: userProfile.photoUrl != null 
                            ? NetworkImage(userProfile.photoUrl!)
                            : null,
                        child: userProfile.photoUrl == null
                            ? Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.accentTeal.withValues(alpha: 0.8),
                                      AppColors.accentTeal.withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    // Online indicator
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981), // Green for active
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 8),
                
                // User name and status
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getFirstName(userProfile.name),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Connected 💙',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.accentTeal.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Enhanced floating profile indicator with better visibility and animations
  Widget _buildEnhancedFloatingProfileIndicator(UserProfile userProfile) {
    return GestureDetector(
      onTap: () {
        _showProfileQuickActions(userProfile);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: GlassWidget(
          backgroundColor: AppColors.glassWhite.withValues(alpha: 0.95),
          borderColor: AppColors.accentTeal.withValues(alpha: 0.4),
          radius: 28,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentTeal.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.glassShadow.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced user profile picture with pulse animation
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentTeal.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.accentTeal.withValues(alpha: 0.1),
                        backgroundImage: userProfile.photoUrl != null 
                            ? NetworkImage(userProfile.photoUrl!)
                            : null,
                        child: userProfile.photoUrl == null
                            ? Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.accentTeal.withValues(alpha: 0.9),
                                      AppColors.accentTeal.withValues(alpha: 0.7),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 22,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                        onBackgroundImageError: (exception, stackTrace) {
                          debugPrint('Enhanced floating profile image failed to load: $exception');
                        },
                      ),
                    ),
                    // Active status indicator with pulse animation
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 1000),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981), // Green for active
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 10),
                
                // User info with enhanced styling
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getFirstName(userProfile.name),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active now',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.accentTeal.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show quick profile actions when floating indicator is tapped
  void _showProfileQuickActions(UserProfile userProfile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassWidget(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: userProfile.photoUrl != null 
                        ? NetworkImage(userProfile.photoUrl!)
                        : null,
                    backgroundColor: AppColors.accentTeal.withValues(alpha: 0.1),
                    child: userProfile.photoUrl == null
                        ? const Icon(
                            Icons.person_rounded,
                            color: AppColors.accentTeal,
                            size: 28,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Connected to Aura 💙',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Quick actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickActionButton(
                    icon: Icons.refresh_rounded,
                    label: 'New Chat',
                    onTap: _showClearHistoryDialog,
                  ),
                  _buildQuickActionButton(
                    icon: Icons.psychology_rounded,
                    label: 'Mood Check',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to mood tracker if available
                    },
                  ),
                  _buildQuickActionButton(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to settings
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentTeal.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.accentTeal,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        final userProfile = userProfileProvider.userProfile;
        final hints = [
          'Share your thoughts...',
          'How are you feeling?',
          'What\'s on your mind?',
          'I\'m here to listen...',
          'Tell me about your day...',
        ];
        
        final firstName = userProfile?.name != null ? _getFirstName(userProfile!.name) : null;
        final personalizedHints = firstName != null ? [
          'Share your thoughts, $firstName...',
          'How are you feeling today?',
          'What\'s on your mind, $firstName?',
          'I\'m here to support you...',
          'Tell me about your day...',
        ] : hints;
        
        final currentHint = personalizedHints[DateTime.now().second % personalizedHints.length];
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Enhanced user's profile picture in input area - Always visible
              Container(
                margin: const EdgeInsets.only(bottom: 8, right: 12),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentTeal.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentTeal.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 16.5,
                  backgroundColor: AppColors.accentTeal.withValues(alpha: 0.1),
                  backgroundImage: userProfile?.photoUrl != null 
                      ? NetworkImage(userProfile!.photoUrl!)
                      : null,
                  child: userProfile?.photoUrl == null
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.accentTeal.withValues(alpha: 0.8),
                                AppColors.accentTeal.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        )
                      : null,
                  onBackgroundImageError: (exception, stackTrace) {
                    debugPrint('Input area profile image failed to load: $exception');
                  },
                ),
              ),
              
              // Enhanced message input
              Expanded(
                child: GlassWidget(
                  backgroundColor: AppColors.glassWhite,
                  borderColor: AppColors.glassBorder.withValues(alpha: 0.6),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxHeight: 120, // Allows for multiline input
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                height: 1.4,
                              ),
                              decoration: InputDecoration(
                                hintText: currentHint,
                                hintStyle: TextStyle(
                                  color: AppColors.textMuted.withValues(alpha: 0.8),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              maxLines: null,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _sendMessage(),
                              onChanged: (text) {
                                setState(() {
                                  // Update UI to reflect text input state
                                });
                              },
                            ),
                          ),
                          
                          // Enhanced send button
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: IconButton(
                                onPressed: _isLoading ? null : _sendMessage,
                                icon: _isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            AppColors.accentTeal.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.send_rounded,
                                        color: _messageController.text.trim().isNotEmpty
                                            ? AppColors.accentTeal
                                            : AppColors.textMuted,
                                      ),
                                tooltip: _isLoading ? 'Sending...' : 'Send message',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
    // Enhanced suggested responses that are more supportive and contextual
    final defaultSuggestions = [
      "I'm feeling anxious today 😰",
      "Can you help me relax? 🌸",
      "I need some motivation 💪",
      "Tell me about breathing exercises 🫁",
      "I'm struggling with sleep 😴",
      "Help me process my emotions 💭",
    ];
    
    final suggestions = _suggestedResponses.isNotEmpty ? _suggestedResponses : defaultSuggestions;
    
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (suggestions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Quick ways to start:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: suggestions.map((response) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            _messageController.text = response.replaceAll(RegExp(r'[😰🌸💪🫁😴💭]'), '').trim();
                            _sendMessage();
                            setState(() {
                              _suggestedResponses = []; // Clear suggestions after selection
                            });
                          },
                          child: GlassWidget(
                            backgroundColor: AppColors.accentTeal.withValues(alpha: 0.08),
                            borderColor: AppColors.accentTeal.withValues(alpha: 0.2),
                            radius: 20,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    response,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: AppColors.accentTeal.withValues(alpha: 0.6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}



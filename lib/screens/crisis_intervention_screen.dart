import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/crisis_intervention_service.dart';

import '../widgets/glass_widgets.dart';
import '../utils/app_colors.dart';

/// Crisis Intervention Screen - Immediate support interface for users in crisis
/// Provides immediate resources, safety planning, and professional connections
class CrisisInterventionScreen extends StatefulWidget {
  final CrisisAnalysisResult analysisResult;
  final String? userId;

  const CrisisInterventionScreen({
    super.key,
    required this.analysisResult,
    this.userId,
  });

  @override
  State<CrisisInterventionScreen> createState() => _CrisisInterventionScreenState();
}

class _CrisisInterventionScreenState extends State<CrisisInterventionScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  final CrisisInterventionService _crisisService = CrisisInterventionService();
  CrisisResponse? _crisisResponse;
  bool _isLoading = true;
  bool _safetyPlanExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateCrisisResponse();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  Future<void> _generateCrisisResponse() async {
    try {
      final response = await _crisisService.generateCrisisResponse(
        widget.analysisResult,
        null, // TODO: Get user profile from provider
      );
      
      setState(() {
        _crisisResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _crisisResponse = CrisisResponse(
          immediateMessage: 'I\'m here to support you through this difficult time. Please reach out to a crisis counselor who can provide immediate professional help.',
          resources: widget.analysisResult.suggestedResources,
          followUpActions: [
            'Call 988 (Suicide & Crisis Lifeline)',
            'Text HOME to 741741 (Crisis Text Line)',
            'Reach out to a trusted adult',
            'Go to emergency room if in immediate danger',
          ],
          safetyPlan: [
            'Stay with trusted friends or family',
            'Remove harmful items from your environment',
            'Call crisis hotline when feeling unsafe',
            'Practice grounding techniques',
          ],
          urgencyLevel: 'HIGH',
        );
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor.withValues(alpha: 26),
              AppColors.secondaryColor.withValues(alpha: 26),
              Colors.red.withValues(alpha: 13),
            ],
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: _isLoading ? _buildLoadingState() : _buildCrisisInterface(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Icon(
                      Icons.favorite,
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Connecting you with support...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrisisInterface() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildImmediateMessage(),
          const SizedBox(height: 24),
          _buildEmergencyResources(),
          const SizedBox(height: 24),
          _buildSafetyPlan(),
          const SizedBox(height: 24),
          _buildFollowUpActions(),
          const SizedBox(height: 32),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 51),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emergency,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crisis Support',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Immediate help is available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 204),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImmediateMessage() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.message,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Immediate Support',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _crisisResponse?.immediateMessage ?? 'Loading support message...',
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyResources() {
    final resources = _crisisResponse?.resources ?? [];
    
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone_in_talk,
                  color: Colors.green.shade300,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Get Help Now',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (resources.isEmpty)
              _buildDefaultEmergencyResources()
            else
              ...resources.map((resource) => _buildResourceCard(resource)),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultEmergencyResources() {
    return Column(
      children: [
        _buildResourceCard(EmergencyResource(
          name: '988 Suicide & Crisis Lifeline',
          phone: '988',
          description: '24/7 free and confidential support',
          priority: 10,
        )),
        const SizedBox(height: 12),
        _buildResourceCard(EmergencyResource(
          name: 'Crisis Text Line',
          text: 'Text HOME to 741741',
          description: 'Free 24/7 crisis support via text',
          priority: 9,
        )),
      ],
    );
  }

  Widget _buildResourceCard(EmergencyResource resource) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 51),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resource.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resource.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 204),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (resource.phone != null) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(resource.phone!),
                    icon: const Icon(Icons.phone, size: 18),
                    label: Text('Call ${resource.phone}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (resource.text != null) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendText(resource.text!),
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('Text'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (resource.chat != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openChat(resource.chat!),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyPlan() {
    final safetyPlan = _crisisResponse?.safetyPlan ?? [];
    
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _safetyPlanExpanded = !_safetyPlanExpanded;
                });
              },
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: Colors.orange.shade300,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Safety Plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    _safetyPlanExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            if (_safetyPlanExpanded) ...[
              const SizedBox(height: 16),
              const Text(
                'Immediate steps to help keep you safe:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              ...safetyPlan.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 77),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 230),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpActions() {
    final actions = _crisisResponse?.followUpActions ?? [];
    
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.checklist,
                  color: Colors.blue.shade300,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Next Steps',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...actions.map((action) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.white.withValues(alpha: 179),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      action,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 230),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _makePhoneCall('988'),
            icon: const Icon(Icons.phone, size: 20),
            label: const Text(
              'Call 988 Crisis Lifeline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 20),
            label: const Text(
              'Return to Chat',
              style: TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final uri = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorDialog('Unable to make phone call. Please dial $phoneNumber manually.');
      }
    } catch (e) {
      _showErrorDialog('Error making phone call: $e');
    }
  }

  Future<void> _sendText(String textInfo) async {
    try {
      // Extract phone number from text info (e.g., "Text HOME to 741741")
      final phoneMatch = RegExp(r'\d{5,}').firstMatch(textInfo);
      if (phoneMatch != null) {
        final phoneNumber = phoneMatch.group(0)!;
        final uri = Uri.parse('sms:$phoneNumber');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _copyToClipboard(textInfo);
        }
      } else {
        _copyToClipboard(textInfo);
      }
    } catch (e) {
      _copyToClipboard(textInfo);
    }
  }

  Future<void> _openChat(String chatUrl) async {
    try {
      final uri = Uri.parse(chatUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog('Unable to open chat. Please visit: $chatUrl');
      }
    } catch (e) {
      _showErrorDialog('Error opening chat: $e');
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard: $text'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
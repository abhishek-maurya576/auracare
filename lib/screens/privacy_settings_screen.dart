import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../services/privacy_security_service.dart';
import '../providers/user_profile_provider.dart';
import '../utils/app_colors.dart';

/// Privacy Settings Screen for managing user privacy preferences and COPPA compliance
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  PrivacySettings? _privacySettings;
  DataRetentionSettings? _dataRetentionSettings;
  ParentalConsent? _parentalConsent;
  bool _anonymousMode = false;
  bool _isLoading = true;
  bool _requiresParentalConsent = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final privacySettings = await PrivacySecurityService.loadPrivacySettings();
      final dataRetentionSettings = await PrivacySecurityService.loadDataRetentionSettings();
      final parentalConsent = await PrivacySecurityService.loadParentalConsent();
      final anonymousMode = await PrivacySecurityService.isAnonymousModeEnabled();
      
      // Check if user requires parental consent
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      final userProfile = userProfileProvider.userProfile;
      final requiresConsent = PrivacySecurityService.requiresParentalConsent(userProfile?.birthDate);

      setState(() {
        _privacySettings = privacySettings;
        _dataRetentionSettings = dataRetentionSettings;
        _parentalConsent = parentalConsent;
        _anonymousMode = anonymousMode;
        _requiresParentalConsent = requiresConsent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading privacy settings: $e');
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
        title: const Text(
          'Privacy & Security',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AuraBackground(),
          SafeArea(
            child: _isLoading ? _buildLoadingState() : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_requiresParentalConsent) ...[
            _buildParentalConsentSection(),
            const SizedBox(height: 24),
          ],
          _buildPrivacyControlsSection(),
          const SizedBox(height: 24),
          _buildDataRetentionSection(),
          const SizedBox(height: 24),
          _buildAnonymousModeSection(),
          const SizedBox(height: 24),
          _buildDataManagementSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildParentalConsentSection() {
    final hasConsent = _parentalConsent != null && _parentalConsent!.consentGiven;
    
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasConsent ? Icons.verified_user : Icons.warning,
                  color: hasConsent ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Parental Consent',
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
              hasConsent 
                  ? 'Parental consent has been provided and verified.'
                  : 'As a user under 18, parental consent is required for full app functionality.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 204),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (!hasConsent)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showParentalConsentForm,
                  icon: const Icon(Icons.family_restroom),
                  label: const Text('Get Parental Consent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 77),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Consent provided by ${_parentalConsent!.parentName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
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

  Widget _buildPrivacyControlsSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.privacy_tip,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Privacy Controls',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPrivacyToggle(
              'Allow Analytics',
              'Help improve the app by sharing anonymous usage data',
              _privacySettings?.allowAnalytics ?? true,
              (value) => _updatePrivacySetting('allowAnalytics', value),
            ),
            _buildPrivacyToggle(
              'Enable Personalization',
              'Allow AI to remember your preferences and conversation history',
              _privacySettings?.allowPersonalization ?? true,
              (value) => _updatePrivacySetting('allowPersonalization', value),
            ),
            _buildPrivacyToggle(
              'Share Data for Research',
              'Contribute anonymized data to mental health research',
              _privacySettings?.shareDataForResearch ?? false,
              (value) => _updatePrivacySetting('shareDataForResearch', value),
            ),
            _buildPrivacyToggle(
              'Show in Community',
              'Allow your profile to be visible in community features',
              _privacySettings?.showInCommunity ?? false,
              (value) => _updatePrivacySetting('showInCommunity', value),
            ),
            _buildPrivacyToggle(
              'Allow Notifications',
              'Receive helpful reminders and wellness check-ins',
              _privacySettings?.allowNotifications ?? true,
              (value) => _updatePrivacySetting('allowNotifications', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRetentionSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: Colors.blue.shade300,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Data Retention',
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
              'Control how long your data is stored in the app.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 204),
              ),
            ),
            const SizedBox(height: 16),
            _buildRetentionSetting(
              'Chat Messages',
              _dataRetentionSettings?.chatRetentionDays ?? 90,
              'chatRetentionDays',
            ),
            _buildRetentionSetting(
              'Mood Entries',
              _dataRetentionSettings?.moodRetentionDays ?? 365,
              'moodRetentionDays',
            ),
            _buildRetentionSetting(
              'Journal Entries',
              _dataRetentionSettings?.journalRetentionDays ?? 365,
              'journalRetentionDays',
            ),
            _buildRetentionSetting(
              'Crisis Alerts',
              _dataRetentionSettings?.crisisRetentionDays ?? 30,
              'crisisRetentionDays',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnonymousModeSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.visibility_off,
                  color: Colors.purple.shade300,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Anonymous Mode',
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
              'When enabled, your conversations and data are not linked to your profile.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 204),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _anonymousMode ? 'Anonymous Mode: ON' : 'Anonymous Mode: OFF',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _anonymousMode ? Colors.green : Colors.white,
                    ),
                  ),
                ),
                Switch(
                  value: _anonymousMode,
                  onChanged: _toggleAnonymousMode,
                  activeColor: AppColors.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: Colors.orange.shade300,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Data Management',
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
              'Manage your personal data and account information.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 204),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _exportUserData,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Export Data'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showDeleteDataDialog,
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text('Delete Data'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyToggle(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 179),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionSetting(String title, int days, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 26),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              days == 0 ? 'Never delete' : '$days days',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updatePrivacySetting(String setting, bool value) async {
    if (_privacySettings == null) return;

    PrivacySettings updatedSettings;
    switch (setting) {
      case 'allowAnalytics':
        updatedSettings = PrivacySettings(
          shareDataForResearch: _privacySettings!.shareDataForResearch,
          allowAnalytics: value,
          shareWithThirdParties: _privacySettings!.shareWithThirdParties,
          enableCrashReporting: _privacySettings!.enableCrashReporting,
          allowPersonalization: _privacySettings!.allowPersonalization,
          showInCommunity: _privacySettings!.showInCommunity,
          allowNotifications: _privacySettings!.allowNotifications,
        );
        break;
      case 'allowPersonalization':
        updatedSettings = PrivacySettings(
          shareDataForResearch: _privacySettings!.shareDataForResearch,
          allowAnalytics: _privacySettings!.allowAnalytics,
          shareWithThirdParties: _privacySettings!.shareWithThirdParties,
          enableCrashReporting: _privacySettings!.enableCrashReporting,
          allowPersonalization: value,
          showInCommunity: _privacySettings!.showInCommunity,
          allowNotifications: _privacySettings!.allowNotifications,
        );
        break;
      case 'shareDataForResearch':
        updatedSettings = PrivacySettings(
          shareDataForResearch: value,
          allowAnalytics: _privacySettings!.allowAnalytics,
          shareWithThirdParties: _privacySettings!.shareWithThirdParties,
          enableCrashReporting: _privacySettings!.enableCrashReporting,
          allowPersonalization: _privacySettings!.allowPersonalization,
          showInCommunity: _privacySettings!.showInCommunity,
          allowNotifications: _privacySettings!.allowNotifications,
        );
        break;
      case 'showInCommunity':
        updatedSettings = PrivacySettings(
          shareDataForResearch: _privacySettings!.shareDataForResearch,
          allowAnalytics: _privacySettings!.allowAnalytics,
          shareWithThirdParties: _privacySettings!.shareWithThirdParties,
          enableCrashReporting: _privacySettings!.enableCrashReporting,
          allowPersonalization: _privacySettings!.allowPersonalization,
          showInCommunity: value,
          allowNotifications: _privacySettings!.allowNotifications,
        );
        break;
      case 'allowNotifications':
        updatedSettings = PrivacySettings(
          shareDataForResearch: _privacySettings!.shareDataForResearch,
          allowAnalytics: _privacySettings!.allowAnalytics,
          shareWithThirdParties: _privacySettings!.shareWithThirdParties,
          enableCrashReporting: _privacySettings!.enableCrashReporting,
          allowPersonalization: _privacySettings!.allowPersonalization,
          showInCommunity: _privacySettings!.showInCommunity,
          allowNotifications: value,
        );
        break;
      default:
        return;
    }

    await PrivacySecurityService.savePrivacySettings(updatedSettings);
    setState(() {
      _privacySettings = updatedSettings;
    });
  }

  void _toggleAnonymousMode(bool value) async {
    await PrivacySecurityService.setAnonymousMode(value);
    setState(() {
      _anonymousMode = value;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value 
              ? 'Anonymous mode enabled. Your data is now private.'
              : 'Anonymous mode disabled. Personalization features restored.',
        ),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  void _showParentalConsentForm() {
    // TODO: Implement parental consent form
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Parental Consent Required',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'To comply with COPPA regulations, we need parental consent for users under 18. This feature will be implemented in the next update.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _exportUserData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          backgroundColor: Colors.transparent,
          content: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );

      // Simulate data export
      await Future.delayed(const Duration(seconds: 2));
      await PrivacySecurityService.exportUserData('current_user');
      
      Navigator.of(context).pop(); // Close loading dialog
      
      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Data Export Complete',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Your data has been prepared for export. In a full implementation, this would be sent to your email or downloaded as a file.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorSnackBar('Error exporting data: $e');
    }
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete All Data',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'This will permanently delete all your data including chat history, mood entries, and journal entries. This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteUserData();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteUserData() async {
    try {
      await PrivacySecurityService.deleteUserData('current_user');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All user data has been deleted.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error deleting data: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
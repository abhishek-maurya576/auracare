import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../providers/auth_provider.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings state
  bool _dataAnalytics = true;
  bool _crashReporting = true;
  String _theme = 'Auto';
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Settings',
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Stack(
        children: [
          const AuraBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Appearance Section
                _buildAppearanceSettings(),
                
                const SizedBox(height: 20),

                // Privacy & Data Section
                _buildPrivacySettings(),
                
                const SizedBox(height: 20),

                // Account Section
                _buildAccountSettings(),
                
                const SizedBox(height: 20),

                // About Section
                _buildAboutSettings(),
                
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildAppearanceSettings() {
    return GlassWidget(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Appearance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Theme selector
          _buildOptionTile(
            'Theme',
            _theme,
            Icons.brightness_6_rounded,
            () => _showThemeDialog(),
          ),
          
          const SizedBox(height: 12),
          
          // Language selector
          _buildOptionTile(
            'Language',
            _language,
            Icons.language_rounded,
            () => _showLanguageDialog(),
          ),
          
          const SizedBox(height: 16),
          
          // Preview card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.preview_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Theme Preview',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  width: 60,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF14B8A6)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return GlassWidget(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Privacy & Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Data analytics
          _buildSwitchTile(
            'Anonymous Analytics',
            'Help improve AuraCare by sharing anonymous usage data',
            _dataAnalytics,
            (value) => setState(() => _dataAnalytics = value),
          ),
          
          const SizedBox(height: 12),
          
          // Crash reporting
          _buildSwitchTile(
            'Crash Reporting',
            'Automatically send crash reports to help fix bugs',
            _crashReporting,
            (value) => setState(() => _crashReporting = value),
          ),
          
          const SizedBox(height: 16),
          
          // Privacy options
          _buildActionTile(
            'Privacy Policy',
            'Read our privacy policy and data handling practices',
            Icons.policy_rounded,
            () => _showPrivacyPolicy(),
          ),
          
          const SizedBox(height: 12),
          
          _buildActionTile(
            'Data Export',
            'Download all your data in a portable format',
            Icons.download_rounded,
            () => _exportUserData(),
          ),
          
          const SizedBox(height: 12),
          
          _buildActionTile(
            'Delete Account',
            'Permanently delete your account and all data',
            Icons.delete_forever_rounded,
            () => _showDeleteAccountDialog(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return provider.Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return GlassWidget(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_circle_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              if (user != null) ...[
                // Account info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signed in as',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
              
              // Account actions
              _buildActionTile(
                'Edit Profile',
                'Update your name, photo, and preferences',
                Icons.edit_rounded,
                () => _editProfile(),
              ),
              
              const SizedBox(height: 12),
              
              _buildActionTile(
                'Change Password',
                'Update your account password',
                Icons.lock_rounded,
                () => _changePassword(),
              ),
              
              const SizedBox(height: 12),
              
              _buildActionTile(
                'Linked Accounts',
                'Manage connected social accounts',
                Icons.link_rounded,
                () => _manageLinkedAccounts(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutSettings() {
    return GlassWidget(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // App info
          _buildInfoTile('Version', '1.0.0+1'),
          const SizedBox(height: 12),
          _buildInfoTile('Build', 'Release'),
          
          const SizedBox(height: 16),
          
          // About actions
          _buildActionTile(
            'Help & Support',
            'Get help, report issues, or contact support',
            Icons.help_rounded,
            () => _showHelpSupport(),
          ),
          
          const SizedBox(height: 12),
          
          _buildActionTile(
            'Terms of Service',
            'Read our terms and conditions',
            Icons.description_rounded,
            () => _showTermsOfService(),
          ),
          
          const SizedBox(height: 12),
          
          _buildActionTile(
            'Rate AuraCare',
            'Leave a review on the app store',
            Icons.star_rounded,
            () => _rateApp(),
          ),
          
          const SizedBox(height: 12),
          
          _buildActionTile(
            'Share AuraCare',
            'Tell your friends about AuraCare',
            Icons.share_rounded,
            () => _shareApp(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF8B5CF6),
          activeTrackColor: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
          inactiveThumbColor: Colors.white.withValues(alpha: 0.5),
          inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
        ),
      ],
    );
  }

  Widget _buildOptionTile(String title, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDestructive 
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive 
                ? Colors.red.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive 
                  ? Colors.red
                  : Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDestructive 
                          ? Colors.red.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDestructive 
                  ? Colors.red.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog and action methods

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Select Theme', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Auto', 'Light', 'Dark'
          ].map((theme) => ListTile(
            title: Text(theme, style: const TextStyle(color: Colors.white)),
            onTap: () {
              setState(() => _theme = theme);
              Navigator.pop(context);
            },
            trailing: _theme == theme 
                ? const Icon(Icons.check, color: Colors.green)
                : null,
          )).toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Select Language', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'English', 'Spanish', 'French', 'German', 'Chinese'
          ].map((language) => ListTile(
            title: Text(language, style: const TextStyle(color: Colors.white)),
            onTap: () {
              setState(() => _language = language);
              Navigator.pop(context);
            },
            trailing: _language == language 
                ? const Icon(Icons.check, color: Colors.green)
                : null,
          )).toList(),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Action implementations
  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy policy feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportUserData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _deleteAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account deletion feature coming soon!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password change feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _manageLinkedAccounts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Linked accounts management coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showHelpSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Help & support feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terms of service feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App rating feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App sharing feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crisis_alert_provider.dart';
import '../widgets/glass_widgets.dart';
import '../utils/app_colors.dart';
import '../screens/crisis_intervention_screen.dart';
import '../services/crisis_intervention_service.dart';

/// Crisis Dashboard Widget - Shows crisis status and quick access to resources
class CrisisDashboardWidget extends StatelessWidget {
  const CrisisDashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CrisisAlertProvider>(
      builder: (context, crisisProvider, child) {
        // Don't show widget if no crisis activity
        if (!crisisProvider.hasRecentCrisisActivity() && !crisisProvider.isInCrisis) {
          return const SizedBox.shrink();
        }

        return _buildCrisisCard(context, crisisProvider);
      },
    );
  }

  Widget _buildCrisisCard(BuildContext context, CrisisAlertProvider crisisProvider) {
    final isInCrisis = crisisProvider.isInCrisis;
    final activeAlert = crisisProvider.activeAlert;
    final recentAlerts = crisisProvider.getRecentAlerts();

    return GlassCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInCrisis ? Colors.red.withOpacity(0.5) : Colors.orange.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isInCrisis, activeAlert),
            const SizedBox(height: 12),
            if (isInCrisis && activeAlert != null) ...[
              _buildActiveAlert(context, activeAlert),
              const SizedBox(height: 16),
            ],
            _buildQuickActions(context, crisisProvider),
            if (recentAlerts.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildRecentActivity(recentAlerts),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isInCrisis, activeAlert) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isInCrisis ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isInCrisis ? Icons.emergency : Icons.warning,
            color: isInCrisis ? Colors.red : Colors.orange,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isInCrisis ? 'Crisis Support Active' : 'Wellness Check',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                isInCrisis 
                    ? 'Immediate support resources available'
                    : 'Recent activity detected',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        if (isInCrisis)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveAlert(BuildContext context, activeAlert) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.priority_high,
                color: Colors.red.shade300,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                activeAlert.crisisTypeDescription,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                'Severity: ${activeAlert.severityLevel}/10',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            activeAlert.message,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, CrisisAlertProvider crisisProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.phone,
            label: 'Call 988',
            color: Colors.green,
            onTap: () => _call988(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.message,
            label: 'Text Crisis Line',
            color: Colors.blue,
            onTap: () => _textCrisisLine(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.support_agent,
            label: 'Resources',
            color: AppColors.primaryColor,
            onTap: () => _showCrisisResources(context, crisisProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List recentAlerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity (${recentAlerts.length})',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentAlerts.length.clamp(0, 5),
            itemBuilder: (context, index) {
              final alert = recentAlerts[index];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSeverityColor(alert.severityLevel).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getSeverityColor(alert.severityLevel).withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${alert.severityLevel}/10',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      alert.timeSinceCreated.split(' ')[0],
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(int severity) {
    if (severity >= 8) return Colors.red;
    if (severity >= 6) return Colors.orange;
    if (severity >= 4) return Colors.yellow;
    return Colors.green;
  }

  void _call988() {
    // This would integrate with url_launcher to make the call
    debugPrint('📞 Calling 988 Crisis Lifeline');
    // TODO: Implement actual phone call
  }

  void _textCrisisLine() {
    // This would integrate with url_launcher to send SMS
    debugPrint('💬 Opening Crisis Text Line');
    // TODO: Implement SMS to 741741
  }

  void _showCrisisResources(BuildContext context, CrisisAlertProvider crisisProvider) {
    if (crisisProvider.isInCrisis && crisisProvider.activeAlert != null) {
      // Create a mock crisis analysis result for the screen
      final mockAnalysis = CrisisAnalysisResult(
        severityLevel: crisisProvider.activeAlert!.severityLevel,
        crisisType: crisisProvider.activeAlert!.crisisType,
        confidence: 0.8,
        immediateAction: true,
        suggestedResources: [],
        supportMessage: crisisProvider.activeAlert!.message,
        detectedKeywords: [],
        aiInsights: 'Crisis resources requested from dashboard',
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CrisisInterventionScreen(
            analysisResult: mockAnalysis,
            userId: crisisProvider.activeAlert!.userId,
          ),
        ),
      );
    } else {
      _showResourcesDialog(context);
    }
  }

  void _showResourcesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Crisis Resources',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResourceItem('988 Suicide & Crisis Lifeline', '24/7 support'),
            _buildResourceItem('Crisis Text Line', 'Text HOME to 741741'),
            _buildResourceItem('Teen Line', '1-800-852-8336'),
            _buildResourceItem('Trevor Project (LGBTQ+)', '1-866-488-7386'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceItem(String name, String info) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            info,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
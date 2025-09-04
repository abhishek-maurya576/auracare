import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/crisis_alert.dart';
import '../services/crisis_intervention_service.dart';

/// Provider for managing crisis alerts and intervention state
class CrisisAlertProvider with ChangeNotifier {
  final CrisisInterventionService _crisisService = CrisisInterventionService();
  
  // Crisis alerts
  final List<CrisisAlert> _alerts = [];
  List<CrisisAlert> get alerts => List.unmodifiable(_alerts);
  
  // Active crisis state
  bool _isInCrisis = false;
  bool get isInCrisis => _isInCrisis;
  
  CrisisAlert? _activeAlert;
  CrisisAlert? get activeAlert => _activeAlert;
  
  // Crisis monitoring
  StreamSubscription<CrisisAlert>? _crisisSubscription;
  
  // Statistics
  int get totalAlerts => _alerts.length;
  int get unresolvedAlerts => _alerts.where((alert) => !alert.resolved).length;
  int get criticalAlerts => _alerts.where((alert) => alert.severityLevel >= 8).length;
  
  CrisisAlertProvider() {
    _initializeCrisisMonitoring();
  }

  /// Initialize crisis monitoring stream
  void _initializeCrisisMonitoring() {
    _crisisSubscription = _crisisService.crisisAlertStream.listen(
      (alert) {
        _handleNewCrisisAlert(alert);
      },
      onError: (error) {
        debugPrint('Error in crisis monitoring: $error');
      },
    );
  }

  /// Handle new crisis alert
  void _handleNewCrisisAlert(CrisisAlert alert) {
    debugPrint('🚨 New crisis alert received: ${alert.id}');
    
    // Add to alerts list
    _alerts.insert(0, alert); // Add to beginning for chronological order
    
    // Set as active alert if severity is high
    if (alert.severityLevel >= 7) {
      _activeAlert = alert;
      _isInCrisis = true;
    }
    
    // Limit alerts history to last 50
    if (_alerts.length > 50) {
      _alerts.removeRange(50, _alerts.length);
    }
    
    notifyListeners();
  }

  /// Mark alert as resolved
  Future<void> resolveAlert(String alertId, String followUpNotes) async {
    try {
      final alertIndex = _alerts.indexWhere((alert) => alert.id == alertId);
      if (alertIndex != -1) {
        final resolvedAlert = _alerts[alertIndex].markResolved(followUpNotes);
        _alerts[alertIndex] = resolvedAlert;
        
        // Clear active alert if this was the active one
        if (_activeAlert?.id == alertId) {
          _activeAlert = null;
          _isInCrisis = false;
        }
        
        notifyListeners();
        debugPrint('✅ Crisis alert resolved: $alertId');
      }
    } catch (e) {
      debugPrint('Error resolving crisis alert: $e');
    }
  }

  /// Add intervention action to alert
  Future<void> addInterventionAction(String alertId, String action) async {
    try {
      final alertIndex = _alerts.indexWhere((alert) => alert.id == alertId);
      if (alertIndex != -1) {
        final updatedAlert = _alerts[alertIndex].addInterventionAction(action);
        _alerts[alertIndex] = updatedAlert;
        notifyListeners();
        debugPrint('📝 Intervention action added to alert $alertId: $action');
      }
    } catch (e) {
      debugPrint('Error adding intervention action: $e');
    }
  }

  /// Get alerts by severity level
  List<CrisisAlert> getAlertsBySeverity(int minSeverity) {
    return _alerts.where((alert) => alert.severityLevel >= minSeverity).toList();
  }

  /// Get recent alerts (last 24 hours)
  List<CrisisAlert> getRecentAlerts() {
    final now = DateTime.now();
    return _alerts.where((alert) {
      return now.difference(alert.timestamp).inHours <= 24;
    }).toList();
  }

  /// Get alerts by crisis type
  List<CrisisAlert> getAlertsByType(CrisisType type) {
    return _alerts.where((alert) => alert.crisisType == type).toList();
  }

  /// Check if user has had recent crisis alerts
  bool hasRecentCrisisActivity() {
    final recentAlerts = getRecentAlerts();
    return recentAlerts.any((alert) => alert.severityLevel >= 6);
  }

  /// Get crisis statistics for analytics
  Map<String, dynamic> getCrisisStatistics() {
    final now = DateTime.now();
    final last7Days = _alerts.where((alert) {
      return now.difference(alert.timestamp).inDays <= 7;
    }).toList();
    
    final last30Days = _alerts.where((alert) {
      return now.difference(alert.timestamp).inDays <= 30;
    }).toList();

    // Calculate average severity
    double avgSeverity = 0;
    if (_alerts.isNotEmpty) {
      avgSeverity = _alerts.fold<double>(0, (sum, alert) => sum + alert.severityLevel) / _alerts.length;
    }

    // Count by crisis type
    final typeCount = <String, int>{};
    for (final alert in _alerts) {
      final type = alert.crisisType.toString().split('.').last;
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }

    return {
      'totalAlerts': totalAlerts,
      'unresolvedAlerts': unresolvedAlerts,
      'criticalAlerts': criticalAlerts,
      'averageSeverity': avgSeverity.toStringAsFixed(1),
      'alertsLast7Days': last7Days.length,
      'alertsLast30Days': last30Days.length,
      'alertsByType': typeCount,
      'hasRecentActivity': hasRecentCrisisActivity(),
      'isCurrentlyInCrisis': _isInCrisis,
    };
  }

  /// Clear all resolved alerts (for privacy)
  void clearResolvedAlerts() {
    _alerts.removeWhere((alert) => alert.resolved);
    notifyListeners();
    debugPrint('🗑️ Cleared resolved crisis alerts');
  }

  /// Clear all alerts (for privacy/reset)
  void clearAllAlerts() {
    _alerts.clear();
    _activeAlert = null;
    _isInCrisis = false;
    notifyListeners();
    debugPrint('🗑️ Cleared all crisis alerts');
  }

  /// Simulate crisis alert for testing
  void simulateCrisisAlert({
    int severityLevel = 8,
    CrisisType crisisType = CrisisType.general,
    String? message,
  }) {
    if (kDebugMode) {
      final testAlert = CrisisAlert(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'test_user',
        severityLevel: severityLevel,
        crisisType: crisisType,
        timestamp: DateTime.now(),
        message: message ?? 'This is a test crisis alert for development purposes.',
        resources: [],
        resolved: false,
      );
      
      _handleNewCrisisAlert(testAlert);
      debugPrint('🧪 Simulated crisis alert for testing');
    }
  }

  /// Get crisis intervention recommendations
  List<String> getCrisisInterventionRecommendations() {
    if (!_isInCrisis || _activeAlert == null) {
      return [];
    }

    final recommendations = <String>[];
    final alert = _activeAlert!;

    switch (alert.crisisType) {
      case CrisisType.suicide:
        recommendations.addAll([
          'Call 988 Suicide & Crisis Lifeline immediately',
          'Stay with trusted friends or family',
          'Remove means of self-harm from environment',
          'Go to emergency room if thoughts become overwhelming',
        ]);
        break;
      
      case CrisisType.selfHarm:
        recommendations.addAll([
          'Use ice cubes or rubber band as alternatives',
          'Call Crisis Text Line: Text HOME to 741741',
          'Practice grounding techniques (5-4-3-2-1 method)',
          'Reach out to a trusted adult or counselor',
        ]);
        break;
      
      case CrisisType.youthCrisis:
        recommendations.addAll([
          'Talk to school counselor or trusted teacher',
          'Contact Teen Line: 1-800-852-8336',
          'Reach out to parent or guardian',
          'Use stress management techniques',
        ]);
        break;
      
      default:
        recommendations.addAll([
          'Call 988 for immediate crisis support',
          'Reach out to trusted friends or family',
          'Contact mental health professional',
          'Use crisis chat services if available',
        ]);
    }

    return recommendations;
  }

  @override
  void dispose() {
    _crisisSubscription?.cancel();
    super.dispose();
  }
}
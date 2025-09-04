import '../services/crisis_intervention_service.dart';

/// Crisis Alert model for tracking and managing mental health crisis events
class CrisisAlert {
  final String id;
  final String userId;
  final int severityLevel; // 0-10 scale
  final CrisisType crisisType;
  final DateTime timestamp;
  final String message;
  final List<EmergencyResource> resources;
  final bool resolved;
  final DateTime? resolvedAt;
  final String? followUpNotes;
  final List<String> interventionActions;

  CrisisAlert({
    required this.id,
    required this.userId,
    required this.severityLevel,
    required this.crisisType,
    required this.timestamp,
    required this.message,
    required this.resources,
    required this.resolved,
    this.resolvedAt,
    this.followUpNotes,
    this.interventionActions = const [],
  });

  /// Create CrisisAlert from JSON
  factory CrisisAlert.fromJson(Map<String, dynamic> json) {
    return CrisisAlert(
      id: json['id'] as String,
      userId: json['userId'] as String,
      severityLevel: json['severityLevel'] as int,
      crisisType: _parseCrisisType(json['crisisType'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      message: json['message'] as String,
      resources: (json['resources'] as List<dynamic>?)
          ?.map((r) => EmergencyResource(
                name: r['name'] as String,
                phone: r['phone'] as String?,
                text: r['text'] as String?,
                chat: r['chat'] as String?,
                description: r['description'] as String,
                priority: r['priority'] as int,
              ))
          .toList() ?? [],
      resolved: json['resolved'] as bool,
      resolvedAt: json['resolvedAt'] != null 
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      followUpNotes: json['followUpNotes'] as String?,
      interventionActions: (json['interventionActions'] as List<dynamic>?)
          ?.cast<String>() ?? [],
    );
  }

  /// Convert CrisisAlert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'severityLevel': severityLevel,
      'crisisType': crisisType.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'resources': resources.map((r) => {
        'name': r.name,
        'phone': r.phone,
        'text': r.text,
        'chat': r.chat,
        'description': r.description,
        'priority': r.priority,
      }).toList(),
      'resolved': resolved,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'followUpNotes': followUpNotes,
      'interventionActions': interventionActions,
    };
  }

  /// Create a copy with updated fields
  CrisisAlert copyWith({
    String? id,
    String? userId,
    int? severityLevel,
    CrisisType? crisisType,
    DateTime? timestamp,
    String? message,
    List<EmergencyResource>? resources,
    bool? resolved,
    DateTime? resolvedAt,
    String? followUpNotes,
    List<String>? interventionActions,
  }) {
    return CrisisAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      severityLevel: severityLevel ?? this.severityLevel,
      crisisType: crisisType ?? this.crisisType,
      timestamp: timestamp ?? this.timestamp,
      message: message ?? this.message,
      resources: resources ?? this.resources,
      resolved: resolved ?? this.resolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      followUpNotes: followUpNotes ?? this.followUpNotes,
      interventionActions: interventionActions ?? this.interventionActions,
    );
  }

  /// Mark alert as resolved
  CrisisAlert markResolved(String followUpNotes) {
    return copyWith(
      resolved: true,
      resolvedAt: DateTime.now(),
      followUpNotes: followUpNotes,
    );
  }

  /// Add intervention action
  CrisisAlert addInterventionAction(String action) {
    final updatedActions = List<String>.from(interventionActions)..add(action);
    return copyWith(interventionActions: updatedActions);
  }

  /// Get severity description
  String get severityDescription {
    switch (severityLevel) {
      case 10:
        return 'CRITICAL - Immediate danger';
      case 8:
      case 9:
        return 'HIGH - Urgent intervention needed';
      case 6:
      case 7:
        return 'MODERATE - Professional support recommended';
      case 4:
      case 5:
        return 'MILD - Monitor and support';
      case 1:
      case 2:
      case 3:
        return 'LOW - General support';
      default:
        return 'NONE - No immediate concern';
    }
  }

  /// Get crisis type description
  String get crisisTypeDescription {
    switch (crisisType) {
      case CrisisType.suicide:
        return 'Suicide Risk';
      case CrisisType.selfHarm:
        return 'Self-Harm Risk';
      case CrisisType.youthCrisis:
        return 'Youth-Specific Crisis';
      case CrisisType.eatingDisorder:
        return 'Eating Disorder';
      case CrisisType.abuse:
        return 'Abuse Situation';
      case CrisisType.general:
        return 'General Mental Health Crisis';
      case CrisisType.unknown:
        return 'Unknown Crisis Type';
      default:
        return 'No Crisis Detected';
    }
  }

  /// Check if alert requires immediate action
  bool get requiresImmediateAction => severityLevel >= 7;

  /// Check if alert is recent (within last 24 hours)
  bool get isRecent {
    final now = DateTime.now();
    return now.difference(timestamp).inHours <= 24;
  }

  /// Get time since alert was created
  String get timeSinceCreated {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  /// Parse crisis type from string
  static CrisisType _parseCrisisType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'suicide':
        return CrisisType.suicide;
      case 'selfharm':
        return CrisisType.selfHarm;
      case 'youthcrisis':
        return CrisisType.youthCrisis;
      case 'eatingdisorder':
        return CrisisType.eatingDisorder;
      case 'abuse':
        return CrisisType.abuse;
      case 'general':
        return CrisisType.general;
      case 'unknown':
        return CrisisType.unknown;
      default:
        return CrisisType.none;
    }
  }

  @override
  String toString() {
    return 'CrisisAlert(id: $id, userId: $userId, severity: $severityLevel, type: $crisisType, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CrisisAlert && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
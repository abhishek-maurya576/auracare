import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String sessionId;
  final String? id; // Firestore document ID

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.sessionId,
    this.id,
  });

  /// Convert to Map for Firestore storage
  /// Uses FieldValue.serverTimestamp() for accurate server-side timing
  Map<String, dynamic> toFirestoreMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': FieldValue.serverTimestamp(), // Use server timestamp for accuracy
      'sessionId': sessionId,
      'createdAt': DateTime.now().toIso8601String(), // Fallback client timestamp
    };
  }

  /// Convert to Map for local storage (preserves exact timestamp)
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'id': id,
    };
  }

  /// Create from Firestore document
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle timestamp conversion from Firestore
    DateTime messageTimestamp;
    if (data['timestamp'] != null) {
      if (data['timestamp'] is Timestamp) {
        // Firestore Timestamp
        messageTimestamp = (data['timestamp'] as Timestamp).toDate();
      } else if (data['timestamp'] is String) {
        // ISO8601 string fallback
        messageTimestamp = DateTime.parse(data['timestamp']);
      } else {
        // Fallback to createdAt or current time
        if (data['createdAt'] != null) {
          messageTimestamp = DateTime.parse(data['createdAt']);
        } else {
          messageTimestamp = DateTime.now();
        }
      }
    } else {
      // No timestamp found, use createdAt or current time
      if (data['createdAt'] != null) {
        messageTimestamp = DateTime.parse(data['createdAt']);
      } else {
        messageTimestamp = DateTime.now();
      }
    }

    return ChatMessage(
      text: data['text'] ?? '',
      isUser: data['isUser'] ?? false,
      timestamp: messageTimestamp,
      sessionId: data['sessionId'] ?? '',
      id: doc.id,
    );
  }

  /// Create from Map (for local storage)
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: map['timestamp'] is String 
          ? DateTime.parse(map['timestamp'])
          : map['timestamp'] ?? DateTime.now(),
      sessionId: map['sessionId'] ?? '',
      id: map['id'],
    );
  }

  /// Create a copy with updated fields
  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? sessionId,
    String? id,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      id: id ?? this.id,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(text: $text, isUser: $isUser, timestamp: $timestamp, sessionId: $sessionId, id: $id)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.text == text &&
        other.isUser == isUser &&
        other.timestamp == timestamp &&
        other.sessionId == sessionId &&
        other.id == id;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        isUser.hashCode ^
        timestamp.hashCode ^
        sessionId.hashCode ^
        id.hashCode;
  }
}
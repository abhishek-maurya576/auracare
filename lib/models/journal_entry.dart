import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String mood;
  final String emoji;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPrivate;
  final bool isEncrypted;
  final Map<String, dynamic>? metadata;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.mood,
    required this.emoji,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.isPrivate = true,
    this.isEncrypted = false,
    this.metadata,
  });

  // Create from Firestore document
  factory JournalEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return JournalEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      mood: data['mood'] ?? 'neutral',
      emoji: data['emoji'] ?? '😐',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPrivate: data['isPrivate'] ?? true,
      isEncrypted: data['isEncrypted'] ?? false,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'mood': mood,
      'emoji': emoji,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPrivate': isPrivate,
      'isEncrypted': isEncrypted,
      'metadata': metadata,
    };
  }

  // Create a copy with updated fields
  JournalEntry copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? mood,
    String? emoji,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPrivate,
    bool? isEncrypted,
    Map<String, dynamic>? metadata,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      emoji: emoji ?? this.emoji,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPrivate: isPrivate ?? this.isPrivate,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get word count
  int get wordCount {
    return content.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  // Get reading time estimate (average 200 words per minute)
  int get readingTimeMinutes {
    return (wordCount / 200).ceil();
  }

  // Check if entry is recent (within last 24 hours)
  bool get isRecent {
    return DateTime.now().difference(createdAt).inHours < 24;
  }

  // Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  @override
  String toString() {
    return 'JournalEntry(id: $id, title: $title, mood: $mood, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JournalEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
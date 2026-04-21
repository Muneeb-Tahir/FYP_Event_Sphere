// lib/models/comment.dart
// Comment model for event comments and discussions

class EventComment {
  final String id;
  final String eventId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? parentId; // For nested replies
  final bool isEdited;

  // Related data
  final String? userName;
  final String? userProfileImageUrl;
  final List<EventComment> replies;

  EventComment({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.parentId,
    this.isEdited = false,
    this.userName,
    this.userProfileImageUrl,
    this.replies = const [],
  });

  factory EventComment.fromMap(Map<String, dynamic> map) {
    return EventComment(
      id: map['id'] ?? '',
      eventId: map['event_id'] ?? '',
      userId: map['user_id'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      parentId: map['parent_id'],
      isEdited: map['is_edited'] ?? false,
      userName: map['users']?['name'] ?? map['user_name'],
      userProfileImageUrl: map['users']?['profile_image_url'],
      replies: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'parent_id': parentId,
      'is_edited': isEdited,
    };
  }

  EventComment copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentId,
    bool? isEdited,
    String? userName,
    String? userProfileImageUrl,
    List<EventComment>? replies,
  }) {
    return EventComment(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentId: parentId ?? this.parentId,
      isEdited: isEdited ?? this.isEdited,
      userName: userName ?? this.userName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      replies: replies ?? this.replies,
    );
  }

  // Check if this is a reply
  bool get isReply => parentId != null;

  // Time since posted
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

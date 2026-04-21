// lib/models/feedback.dart
// Feedback model for event ratings and reviews

class EventFeedback {
  final String id;
  final String eventId;
  final String userId;
  final int rating; // 1-5 stars
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Related data
  final String? userName;
  final String? userProfileImageUrl;
  final String? eventTitle;

  EventFeedback({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
    this.userName,
    this.userProfileImageUrl,
    this.eventTitle,
  });

  factory EventFeedback.fromMap(Map<String, dynamic> map) {
    return EventFeedback(
      id: map['id'] ?? '',
      eventId: map['event_id'] ?? '',
      userId: map['user_id'] ?? '',
      rating: map['rating'] ?? 0,
      comment: map['comment'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      userName: map['users']?['name'],
      userProfileImageUrl: map['users']?['profile_image_url'],
      eventTitle: map['events']?['title'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  EventFeedback copyWith({
    String? id,
    String? eventId,
    String? userId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventFeedback(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

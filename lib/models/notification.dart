// lib/models/notification.dart
// Notification model for in-app notifications

enum NotificationType {
  eventCreated,
  eventApproved,
  eventRejected,
  eventReminder,
  registrationConfirmed,
  registrationCancelled,
  announcement,
  societyUpdate,
  pollCreated,
  feedbackReceived,
  general,
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;

  // Deep link data
  final String? eventId;
  final String? societyId;
  final String? routeName;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.eventId,
    this.societyId,
    this.routeName,
    this.data,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: _parseType(map['type']),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      isRead: map['is_read'] ?? false,
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
      eventId: map['event_id'],
      societyId: map['society_id'],
      routeName: map['route_name'],
      data: map['data'],
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'event_created': return NotificationType.eventCreated;
      case 'event_approved': return NotificationType.eventApproved;
      case 'event_rejected': return NotificationType.eventRejected;
      case 'event_reminder': return NotificationType.eventReminder;
      case 'registration_confirmed': return NotificationType.registrationConfirmed;
      case 'registration_cancelled': return NotificationType.registrationCancelled;
      case 'announcement': return NotificationType.announcement;
      case 'society_update': return NotificationType.societyUpdate;
      case 'poll_created': return NotificationType.pollCreated;
      case 'feedback_received': return NotificationType.feedbackReceived;
      default: return NotificationType.general;
    }
  }

  /// Convert camelCase to snake_case safely
  static String _camelToSnake(String input) {
    final result = input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
    return result.startsWith('_') ? result.substring(1) : result;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': _camelToSnake(type.name),
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'event_id': eventId,
      'society_id': societyId,
      'route_name': routeName,
      'data': data,
    };
  }

  AppNotification markAsRead() {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      isRead: true,
      readAt: DateTime.now(),
      eventId: eventId,
      societyId: societyId,
      routeName: routeName,
      data: data,
    );
  }

  // Time since notification
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} year(s) ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} month(s) ago';
    if (diff.inDays > 0) return '${diff.inDays} day(s) ago';
    if (diff.inHours > 0) return '${diff.inHours} hour(s) ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minute(s) ago';
    return 'Just now';
  }

  // Icon based on type
  String get icon {
    switch (type) {
      case NotificationType.eventCreated: return '📅';
      case NotificationType.eventApproved: return '✅';
      case NotificationType.eventRejected: return '❌';
      case NotificationType.eventReminder: return '⏰';
      case NotificationType.registrationConfirmed: return '🎫';
      case NotificationType.registrationCancelled: return '🚫';
      case NotificationType.announcement: return '📢';
      case NotificationType.societyUpdate: return '🏛️';
      case NotificationType.pollCreated: return '📊';
      case NotificationType.feedbackReceived: return '⭐';
      case NotificationType.general: return '🔔';
    }
  }
}

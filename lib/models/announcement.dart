// lib/models/announcement.dart
// Announcement model for society/event announcements

/// Announcement priority levels — single source of truth
enum AnnouncementPriority {
  low,
  normal,
  high,
  urgent;

  /// Convert to database string format
  String toDbString() => name;

  /// Parse from database string
  static AnnouncementPriority fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return AnnouncementPriority.low;
      case 'high':
        return AnnouncementPriority.high;
      case 'urgent':
        return AnnouncementPriority.urgent;
      case 'normal':
      default:
        return AnnouncementPriority.normal;
    }
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case AnnouncementPriority.low:
        return 'Low';
      case AnnouncementPriority.normal:
        return 'Normal';
      case AnnouncementPriority.high:
        return 'High';
      case AnnouncementPriority.urgent:
        return 'Urgent';
    }
  }
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final String? societyId;
  final String? eventId;
  final String createdBy;
  final DateTime createdAt;
  final AnnouncementPriority priority;
  final bool isPinned;
  final DateTime? expiresAt;

  // Related data
  final String? societyName;
  final String? eventTitle;
  final String? creatorName;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.societyId,
    this.eventId,
    required this.createdBy,
    required this.createdAt,
    this.priority = AnnouncementPriority.normal,
    this.isPinned = false,
    this.expiresAt,
    this.societyName,
    this.eventTitle,
    this.creatorName,
  });

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      societyId: map['society_id'],
      eventId: map['event_id'],
      createdBy: map['created_by'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      priority: _parsePriority(map['priority']),
      isPinned: map['is_pinned'] ?? false,
      expiresAt: map['expires_at'] != null ? DateTime.parse(map['expires_at']) : null,
      societyName: map['societies']?['name'],
      eventTitle: map['events']?['title'],
      creatorName: map['users']?['name'],
    );
  }

  static AnnouncementPriority _parsePriority(String? priority) {
    switch (priority) {
      case 'low': return AnnouncementPriority.low;
      case 'high': return AnnouncementPriority.high;
      case 'urgent': return AnnouncementPriority.urgent;
      default: return AnnouncementPriority.normal;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'society_id': societyId,
      'event_id': eventId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'priority': priority.name,
      'is_pinned': isPinned,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isUrgent => priority == AnnouncementPriority.urgent;
}

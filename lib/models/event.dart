// lib/models/event.dart
// Event model with category, image, and capacity support

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String venue;
  final String societyId;
  final String createdBy;
  final String approvalStatus; // 'pending', 'approved', 'rejected'
  final String category; // 'Tech', 'Sports', 'Cultural', 'Academic', 'Music'
  final String? imageUrl; // Event poster/thumbnail URL
  final int? maxAttendees; // Maximum capacity (null = unlimited)
  final int currentAttendees; // Current registration count
  final DateTime? endDate; // Event end time (null = not specified)
  final DateTime? deletedAt; // Soft delete timestamp (null = active)

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.venue,
    required this.societyId,
    required this.createdBy,
    required this.approvalStatus,
    this.category = 'Tech',
    this.imageUrl,
    this.maxAttendees,
    this.currentAttendees = 0,
    this.endDate,
    this.deletedAt,
  });

  // Check if event is soft-deleted
  bool get isDeleted => deletedAt != null;

  // Check if event is at capacity
  bool get isFull => maxAttendees != null && currentAttendees >= maxAttendees!;

  // Get remaining spots
  int? get remainingSpots => maxAttendees != null ? maxAttendees! - currentAttendees : null;

  // Capacity display string
  String get capacityDisplay {
    if (maxAttendees == null) return 'Unlimited';
    if (isFull) return 'SOLD OUT';
    return '$currentAttendees / $maxAttendees';
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? venue,
    String? societyId,
    String? createdBy,
    String? approvalStatus,
    String? category,
    String? imageUrl,
    int? maxAttendees,
    int? currentAttendees,
    DateTime? endDate,
    DateTime? deletedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      venue: venue ?? this.venue,
      societyId: societyId ?? this.societyId,
      createdBy: createdBy ?? this.createdBy,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      currentAttendees: currentAttendees ?? this.currentAttendees,
      endDate: endDate ?? this.endDate,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Convert to Map for caching/serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'venue': venue,
      'society_id': societyId,
      'created_by': createdBy,
      'approval_status': approvalStatus,
      'category': category,
      'image_url': imageUrl,
      'max_attendees': maxAttendees,
      'current_attendees': currentAttendees,
      'end_date': endDate?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  /// Create Event from Map (for caching/database)
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      venue: map['venue'],
      societyId: map['society_id'] ?? '',
      createdBy: map['created_by'] ?? '',
      approvalStatus: map['approval_status'] ?? 'pending',
      category: map['category'] ?? 'Tech',
      imageUrl: map['image_url'],
      maxAttendees: map['max_attendees'],
      currentAttendees: map['current_attendees'] ?? 0,
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }
}

// lib/constants/enums.dart
// Centralized enums for type safety

/// Event approval status
enum ApprovalStatus {
  pending,
  approved,
  rejected;

  /// Convert to database string format
  String toDbString() => name;

  /// Parse from database string
  static ApprovalStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      case 'pending':
      default:
        return ApprovalStatus.pending;
    }
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case ApprovalStatus.pending:
        return 'Pending';
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Event categories
enum EventCategory {
  tech,
  sports,
  cultural,
  academic,
  music,
  other;

  /// Convert to database string format
  String toDbString() {
    switch (this) {
      case EventCategory.tech:
        return 'Tech';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.cultural:
        return 'Cultural';
      case EventCategory.academic:
        return 'Academic';
      case EventCategory.music:
        return 'Music';
      case EventCategory.other:
        return 'Other';
    }
  }

  /// Parse from database string
  static EventCategory fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'tech':
        return EventCategory.tech;
      case 'sports':
        return EventCategory.sports;
      case 'cultural':
        return EventCategory.cultural;
      case 'academic':
        return EventCategory.academic;
      case 'music':
        return EventCategory.music;
      case 'other':
      default:
        return EventCategory.other;
    }
  }

  /// Get display name for UI
  String get displayName => toDbString();
}

// NOTE: AnnouncementPriority is defined in models/announcement.dart.
// Do NOT duplicate it here. Import from there instead.

/// Registration status for events
enum RegistrationStatus {
  registered,
  waitlisted,
  cancelled,
  attended;

  /// Convert to database string format
  String toDbString() => name;

  /// Parse from database string
  static RegistrationStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'waitlisted':
        return RegistrationStatus.waitlisted;
      case 'cancelled':
        return RegistrationStatus.cancelled;
      case 'attended':
        return RegistrationStatus.attended;
      case 'registered':
      default:
        return RegistrationStatus.registered;
    }
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case RegistrationStatus.registered:
        return 'Registered';
      case RegistrationStatus.waitlisted:
        return 'Waitlisted';
      case RegistrationStatus.cancelled:
        return 'Cancelled';
      case RegistrationStatus.attended:
        return 'Attended';
    }
  }
}

/// Society membership role
enum SocietyRole {
  member,
  vicePresident,
  president,
  admin;

  /// Convert to database string format
  String toDbString() {
    switch (this) {
      case SocietyRole.member:
        return 'member';
      case SocietyRole.vicePresident:
        return 'vice_president';
      case SocietyRole.president:
        return 'president';
      case SocietyRole.admin:
        return 'admin';
    }
  }

  /// Parse from database string
  static SocietyRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'vice_president':
        return SocietyRole.vicePresident;
      case 'president':
        return SocietyRole.president;
      case 'admin':
        return SocietyRole.admin;
      default:
        return SocietyRole.member;
    }
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case SocietyRole.member:
        return 'Member';
      case SocietyRole.vicePresident:
        return 'Vice President';
      case SocietyRole.president:
        return 'President';
      case SocietyRole.admin:
        return 'Admin';
    }
  }

  /// Check if can manage events
  bool get canManageEvents =>
    this == SocietyRole.president ||
    this == SocietyRole.vicePresident ||
    this == SocietyRole.admin;
}

/// Committee member role
enum CommitteeRole {
  head,
  coordinator,
  volunteer;

  /// Convert to database string format
  String toDbString() => name;

  /// Parse from database string
  static CommitteeRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'head':
        return CommitteeRole.head;
      case 'coordinator':
        return CommitteeRole.coordinator;
      default:
        return CommitteeRole.volunteer;
    }
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case CommitteeRole.head:
        return '👑 Head';
      case CommitteeRole.coordinator:
        return '📋 Coordinator';
      case CommitteeRole.volunteer:
        return '🙋 Volunteer';
    }
  }
}

/// Resource file types
enum ResourceType {
  link,
  pdf,
  image,
  video,
  document;

  /// Convert to database string format
  String toDbString() => name;

  /// Parse from database string
  static ResourceType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'link':
        return ResourceType.link;
      case 'pdf':
        return ResourceType.pdf;
      case 'image':
      case 'jpg':
      case 'png':
      case 'jpeg':
        return ResourceType.image;
      case 'video':
        return ResourceType.video;
      default:
        return ResourceType.document;
    }
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case ResourceType.link:
        return 'Link';
      case ResourceType.pdf:
        return 'PDF';
      case ResourceType.image:
        return 'Image';
      case ResourceType.video:
        return 'Video';
      case ResourceType.document:
        return 'Document';
    }
  }
}

// NOTE: NotificationType is defined in models/notification.dart (11 values).
// Do NOT duplicate it here. Import from there instead.

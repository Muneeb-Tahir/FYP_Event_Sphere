// lib/models/registration.dart
// Registration model for event registrations

class Registration {
  final String id;
  final String eventId;
  final String userId;
  final DateTime registeredAt;
  final bool checkedIn;
  final DateTime? checkedInAt;
  final bool showInList; // Privacy consent

  // Related user info (populated via join)
  final String? userName;
  final String? userEmail;
  final String? userProfileImageUrl;

  Registration({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.registeredAt,
    this.checkedIn = false,
    this.checkedInAt,
    this.showInList = true,
    this.userName,
    this.userEmail,
    this.userProfileImageUrl,
  });

  factory Registration.fromMap(Map<String, dynamic> map) {
    // Handle nested user data
    final userData = map['users'] as Map<String, dynamic>?;

    return Registration(
      id: map['id'] ?? '',
      eventId: map['event_id'] ?? '',
      userId: map['user_id'] ?? '',
      registeredAt: DateTime.parse(map['registered_at'] ?? DateTime.now().toIso8601String()),
      checkedIn: map['checked_in'] ?? false,
      checkedInAt: map['checked_in_at'] != null ? DateTime.parse(map['checked_in_at']) : null,
      showInList: map['show_in_list'] ?? true,
      userName: userData?['name'],
      userEmail: userData?['email'],
      userProfileImageUrl: userData?['profile_image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'registered_at': registeredAt.toIso8601String(),
      'checked_in': checkedIn,
      'checked_in_at': checkedInAt?.toIso8601String(),
      'show_in_list': showInList,
    };
  }

  Registration copyWith({
    String? id,
    String? eventId,
    String? userId,
    DateTime? registeredAt,
    bool? checkedIn,
    DateTime? checkedInAt,
    bool? showInList,
    String? userName,
    String? userEmail,
    String? userProfileImageUrl,
  }) {
    return Registration(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      registeredAt: registeredAt ?? this.registeredAt,
      checkedIn: checkedIn ?? this.checkedIn,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      showInList: showInList ?? this.showInList,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
    );
  }
}

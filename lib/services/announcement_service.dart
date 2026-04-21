// lib/services/announcement_service.dart
// MOCK SERVICE - Replace with Firebase/Supabase in production

import 'dart:async';

class Announcement {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? eventId;
  final bool isUrgent;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.eventId,
    this.isUrgent = false,
  });
}

class AnnouncementService {
  static final List<Announcement> _announcements = [
    Announcement(
      id: 'ann1',
      title: 'Welcome to Event Sphere',
      message: 'Stay updated with the latest campus events!',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Announcement(
      id: 'ann2',
      title: 'Tech Workshop Reminder',
      message: 'Don\'t forget to register for tomorrow\'s Flutter workshop.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      eventId: 'event1',
      isUrgent: true,
    ),
  ];

  // ------------------------- STREAM ANNOUNCEMENTS -------------------------
  static Stream<List<Announcement>> getAnnouncementsStream() async* {
    yield List.from(_announcements);
    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      yield List.from(_announcements);
    }
  }

  // ------------------------- GET ALL ANNOUNCEMENTS -------------------------
  static Future<List<Announcement>> getAnnouncements() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_announcements);
  }

  // ------------------------- CREATE ANNOUNCEMENT -------------------------
  static Future<void> createAnnouncement({
    required String title,
    required String message,
    String? eventId,
    bool isUrgent = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _announcements.insert(0, Announcement(
      id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      createdAt: DateTime.now(),
      eventId: eventId,
      isUrgent: isUrgent,
    ));
  }

  // ------------------------- DELETE ANNOUNCEMENT -------------------------
  static Future<void> deleteAnnouncement(String announcementId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _announcements.removeWhere((a) => a.id == announcementId);
  }

  // ------------------------- MARK AS READ -------------------------
  // TODO: Implement user-specific read status tracking
  static Future<void> markAsRead(String userId, String announcementId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // In production: Update read status in database
  }
}

// lib/services/user_stats_service.dart
// Updated to use Supabase services

import 'dart:async';
import 'registration_service.dart';
import 'bookmark_service.dart';

class UserStats {
  final int eventsRegistered;
  final int eventsAttended;
  final int bookmarksCount;
  final int pollsVoted;
  final int announcementsRead;

  UserStats({
    required this.eventsRegistered,
    required this.eventsAttended,
    required this.bookmarksCount,
    required this.pollsVoted,
    required this.announcementsRead,
  });
}

class UserStatsService {
  // Get user stats from Supabase services
  static Future<UserStats> getUserStats(String userId) async {
    // Get registered events count from RegistrationService
    final registeredIds = await RegistrationService.getUserRegistrations(userId);

    // Get bookmarks count from BookmarkService
    final bookmarkIds = await BookmarkService.getBookmarks(userId);

    // Get attended events count
    final attendedIds = await RegistrationService.getAttendedEvents(userId);

    return UserStats(
      eventsRegistered: registeredIds.length,
      eventsAttended: attendedIds.length,
      bookmarksCount: bookmarkIds.length,
      pollsVoted: 0, // Will be implemented with PollService
      announcementsRead: 0, // Will be implemented with AnnouncementService
    );
  }

  // Get attended events list
  static Future<List<String>> getAttendedEventIds(String userId) async {
    return await RegistrationService.getAttendedEvents(userId);
  }

  // Mark event as attended (via QR scan check-in)
  static Future<void> markEventAttended(String userId, String eventId) async {
    await RegistrationService.checkInAttendee(userId, eventId);
  }

  // Increment stat (for analytics)
  static Future<void> incrementStat(String userId, String statType) async {
    // Will be implemented with analytics service
  }

  // Get quick summary for profile header - uses Supabase data
  static Future<Map<String, int>> getQuickStats(String userId) async {
    final stats = await getUserStats(userId);
    return {
      'events': stats.eventsRegistered,
      'bookmarks': stats.bookmarksCount,
      'attended': stats.eventsAttended,
    };
  }
}

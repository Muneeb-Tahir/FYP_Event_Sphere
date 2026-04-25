// lib/services/announcement_service.dart
// Announcement service using Supabase

import 'dart:async';
import '../models/announcement.dart';
import 'supabase_service.dart';
import 'logging_service.dart';
import 'cache_service.dart';

class AnnouncementService {
  // ------------------------- STREAM ANNOUNCEMENTS -------------------------
  static Stream<List<Announcement>> getAnnouncementsStream() {
    return SupabaseService.client
        .from('announcements')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => Announcement.fromMap(e)).toList());
  }

  // ------------------------- GET ALL ANNOUNCEMENTS -------------------------
  static Future<List<Announcement>> getAnnouncements() async {
    try {
      final data = await SupabaseService.client
          .from('announcements')
          .select('*, societies(name), events(title), users!announcements_created_by_fkey(name)')
          .order('created_at', ascending: false);

      return (data as List).map((e) => Announcement.fromMap(e)).toList();
    } catch (e) {
      LoggingService.error('Error fetching announcements', e);
      return [];
    }
  }

  // ------------------------- GET SOCIETY ANNOUNCEMENTS -------------------------
  static Future<List<Announcement>> getSocietyAnnouncements(String societyId) async {
    try {
      final data = await SupabaseService.client
          .from('announcements')
          .select('*, societies(name), events(title), users!announcements_created_by_fkey(name)')
          .eq('society_id', societyId)
          .order('created_at', ascending: false);

      return (data as List).map((e) => Announcement.fromMap(e)).toList();
    } catch (e) {
      LoggingService.error('Error fetching society announcements', e);
      return [];
    }
  }

  // ------------------------- CREATE ANNOUNCEMENT -------------------------
  static Future<void> createAnnouncement({
    required String title,
    required String content,
    String? societyId,
    String? eventId,
    AnnouncementPriority priority = AnnouncementPriority.normal,
    bool isPinned = false,
    DateTime? expiresAt,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await SupabaseService.client.from('announcements').insert({
      'title': title,
      'content': content,
      'society_id': societyId,
      'event_id': eventId,
      'created_by': userId,
      'priority': priority.toDbString(),
      'is_pinned': isPinned,
      'expires_at': expiresAt?.toIso8601String(),
    });

    LoggingService.info('Announcement created: $title');
  }

  // ------------------------- DELETE ANNOUNCEMENT -------------------------
  static Future<void> deleteAnnouncement(String announcementId) async {
    await SupabaseService.client
        .from('announcements')
        .delete()
        .eq('id', announcementId);

    LoggingService.info('Announcement deleted: $announcementId');
  }

  // ------------------------- MARK AS READ -------------------------
  /// Track read status locally per-device using Hive cache.
  /// Read IDs are persisted so they survive app restarts.
  static final Set<String> _readIds = {};
  static bool _readIdsLoaded = false;

  static void _ensureReadIdsLoaded() {
    if (_readIdsLoaded) return;
    final stored = CacheService.getSetting('announcement_read_ids');
    if (stored != null && stored.isNotEmpty) {
      _readIds.addAll(stored.split(','));
    }
    _readIdsLoaded = true;
  }

  static Future<void> _persistReadIds() async {
    await CacheService.saveSetting('announcement_read_ids', _readIds.join(','));
  }

  static Future<void> markAsRead(String userId, String announcementId) async {
    _ensureReadIdsLoaded();
    final key = '${userId}_$announcementId';
    _readIds.add(key);
    await _persistReadIds();
  }

  static bool isRead(String userId, String announcementId) {
    _ensureReadIdsLoaded();
    return _readIds.contains('${userId}_$announcementId');
  }
}

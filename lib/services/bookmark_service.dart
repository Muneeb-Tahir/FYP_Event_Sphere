// lib/services/bookmark_service.dart
// Supabase Bookmark Service

import 'supabase_service.dart';
import 'dart:async';

class BookmarkService {
  // ------------------------- GET BOOKMARKS STREAM -------------------------
  static Stream<List<String>> getBookmarksStream(String userId) {
    return SupabaseService.client
        .from('bookmarks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map((e) => e['event_id'] as String).toList());
  }

  // ------------------------- GET BOOKMARKS LIST -------------------------
  static Future<List<String>> getBookmarks(String userId) async {
    final data = await SupabaseService.bookmarks
        .select('event_id')
        .eq('user_id', userId);

    return (data as List).map((e) => e['event_id'] as String).toList();
  }

  // ------------------------- TOGGLE BOOKMARK -------------------------
  static Future<bool> toggleBookmark(String userId, String eventId) async {
    final exists = await isBookmarked(userId, eventId);

    if (exists) {
      await removeBookmark(userId, eventId);
      return false;
    } else {
      await addBookmark(userId, eventId);
      return true;
    }
  }

  // ------------------------- ADD BOOKMARK -------------------------
  static Future<void> addBookmark(String userId, String eventId) async {
    await SupabaseService.bookmarks.insert({
      'user_id': userId,
      'event_id': eventId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ------------------------- REMOVE BOOKMARK -------------------------
  static Future<void> removeBookmark(String userId, String eventId) async {
    await SupabaseService.bookmarks
        .delete()
        .eq('user_id', userId)
        .eq('event_id', eventId);
  }

  // ------------------------- CHECK IF BOOKMARKED -------------------------
  static Future<bool> isBookmarked(String userId, String eventId) async {
    try {
      final data = await SupabaseService.bookmarks
          .select()
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      return data != null;
    } catch (e) {
      return false;
    }
  }

  // ------------------------- GET BOOKMARK COUNT FOR EVENT -------------------------
  static Future<int> getBookmarkCount(String eventId) async {
    final data = await SupabaseService.bookmarks
        .select('id')
        .eq('event_id', eventId);

    return (data as List).length;
  }
}

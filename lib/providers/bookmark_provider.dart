// lib/providers/bookmark_provider.dart
// Riverpod providers for bookmark management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bookmark_service.dart';

/// Stream provider for user's bookmarked event IDs
final bookmarksStreamProvider = StreamProvider.family<List<String>, String>((ref, userId) {
  return BookmarkService.getBookmarksStream(userId);
});

/// Future provider for user's bookmarks (one-time fetch)
final bookmarksProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  return await BookmarkService.getBookmarks(userId);
});

/// Check if specific event is bookmarked
final isBookmarkedProvider = FutureProvider.family<bool, ({String userId, String eventId})>((ref, params) async {
  return await BookmarkService.isBookmarked(params.userId, params.eventId);
});

/// Get bookmark count for an event
final bookmarkCountProvider = FutureProvider.family<int, String>((ref, eventId) async {
  return await BookmarkService.getBookmarkCount(eventId);
});

/// State notifier for bookmark operations
class BookmarkNotifier extends StateNotifier<Set<String>> {
  final String userId;

  BookmarkNotifier(this.userId) : super({}) {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await BookmarkService.getBookmarks(userId);
    state = bookmarks.toSet();
  }

  bool isBookmarked(String eventId) => state.contains(eventId);

  Future<void> toggle(String eventId) async {
    final wasBookmarked = state.contains(eventId);

    // Optimistic update
    if (wasBookmarked) {
      state = {...state}..remove(eventId);
    } else {
      state = {...state, eventId};
    }

    try {
      await BookmarkService.toggleBookmark(userId, eventId);
    } catch (e) {
      // Revert on error
      if (wasBookmarked) {
        state = {...state, eventId};
      } else {
        state = {...state}..remove(eventId);
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadBookmarks();
  }
}

/// Bookmark notifier provider (requires userId)
final bookmarkNotifierProvider = StateNotifierProvider.family<BookmarkNotifier, Set<String>, String>((ref, userId) {
  return BookmarkNotifier(userId);
});

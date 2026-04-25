// lib/services/reaction_service.dart
// Service for managing event like/dislike reactions

import 'dart:async';
import 'supabase_service.dart';

/// Represents a user's reaction to an event
enum ReactionType { like, dislike }

class ReactionService {
  // ========================= GET USER REACTION =========================
  /// Returns the current user's reaction for an event, or null if none
  static Future<ReactionType?> getUserReaction(String userId, String eventId) async {
    try {
      final data = await SupabaseService.eventReactions
          .select('reaction_type')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      if (data == null) return null;
      return data['reaction_type'] == 'like' ? ReactionType.like : ReactionType.dislike;
    } catch (e) {
      return null;
    }
  }

  // ========================= GET BATCH REACTIONS =========================
  /// Returns a map of eventId → ReactionType for all events a user has reacted to
  static Future<Map<String, ReactionType>> getUserReactions(String userId) async {
    try {
      final data = await SupabaseService.eventReactions
          .select('event_id, reaction_type')
          .eq('user_id', userId);

      final map = <String, ReactionType>{};
      for (final row in data as List) {
        map[row['event_id'] as String] =
            row['reaction_type'] == 'like' ? ReactionType.like : ReactionType.dislike;
      }
      return map;
    } catch (e) {
      return {};
    }
  }

  // ========================= TOGGLE REACTION =========================
  /// Toggles a reaction:
  /// - If user has no reaction → sets the given type
  /// - If user has the SAME reaction → removes it (toggle off)
  /// - If user has a DIFFERENT reaction → switches to the new type
  ///
  /// Returns the new reaction state (null = removed)
  static Future<ReactionType?> toggleReaction(
    String userId,
    String eventId,
    ReactionType type,
  ) async {
    final currentReaction = await getUserReaction(userId, eventId);

    if (currentReaction == type) {
      // Same reaction → remove it (toggle off)
      await _removeReaction(userId, eventId);
      return null;
    } else if (currentReaction != null) {
      // Different reaction → switch
      await _updateReaction(userId, eventId, type);
      return type;
    } else {
      // No reaction → add new
      await _addReaction(userId, eventId, type);
      return type;
    }
  }

  // ========================= PRIVATE HELPERS =========================

  static Future<void> _addReaction(String userId, String eventId, ReactionType type) async {
    await SupabaseService.eventReactions.insert({
      'user_id': userId,
      'event_id': eventId,
      'reaction_type': type == ReactionType.like ? 'like' : 'dislike',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> _updateReaction(String userId, String eventId, ReactionType type) async {
    await SupabaseService.eventReactions
        .update({
          'reaction_type': type == ReactionType.like ? 'like' : 'dislike',
        })
        .eq('user_id', userId)
        .eq('event_id', eventId);
  }

  static Future<void> _removeReaction(String userId, String eventId) async {
    await SupabaseService.eventReactions
        .delete()
        .eq('user_id', userId)
        .eq('event_id', eventId);
  }

  // ========================= REACTION COUNTS =========================
  /// Get like and dislike counts for an event
  static Future<({int likes, int dislikes})> getReactionCounts(String eventId) async {
    try {
      final data = await SupabaseService.eventReactions
          .select('reaction_type')
          .eq('event_id', eventId);

      int likes = 0;
      int dislikes = 0;
      for (final row in data as List) {
        if (row['reaction_type'] == 'like') {
          likes++;
        } else {
          dislikes++;
        }
      }
      return (likes: likes, dislikes: dislikes);
    } catch (e) {
      return (likes: 0, dislikes: 0);
    }
  }

  // ========================= REAL-TIME STREAM =========================
  /// Stream of reaction changes for a specific event
  static Stream<List<Map<String, dynamic>>> getReactionsStream(String eventId) {
    return SupabaseService.client
        .from('event_reactions')
        .stream(primaryKey: ['id'])
        .eq('event_id', eventId);
  }
}

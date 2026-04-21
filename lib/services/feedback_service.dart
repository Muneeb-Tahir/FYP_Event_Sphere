// lib/services/feedback_service.dart
// Event Feedback & Rating Service

import 'supabase_service.dart';

class EventFeedback {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  EventFeedback({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory EventFeedback.fromMap(Map<String, dynamic> data) {
    return EventFeedback(
      id: data['id'] ?? '',
      eventId: data['event_id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['users']?['name'] ?? data['user_name'] ?? 'Anonymous',
      rating: data['rating'] ?? 0,
      comment: data['comment'],
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class FeedbackService {
  // Submit feedback for an event
  static Future<void> submitFeedback({
    required String eventId,
    required String userId,
    required int rating,
    String? comment,
  }) async {
    // Check if user already submitted feedback
    final existing = await SupabaseService.client
        .from('event_feedback')
        .select('id')
        .eq('event_id', eventId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      // Update existing feedback
      await SupabaseService.client
          .from('event_feedback')
          .update({
            'rating': rating,
            'comment': comment,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing['id']);
    } else {
      // Insert new feedback
      await SupabaseService.client.from('event_feedback').insert({
        'event_id': eventId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Get all feedback for an event
  static Future<List<EventFeedback>> getEventFeedback(String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('event_feedback')
          .select('*, users!inner(name)')
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      return (data as List).map((e) => EventFeedback.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get average rating for an event
  static Future<double> getAverageRating(String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('event_feedback')
          .select('rating')
          .eq('event_id', eventId);

      if ((data as List).isEmpty) return 0.0;

      final total = data.fold<int>(0, (sum, item) => sum + (item['rating'] as int));
      return total / data.length;
    } catch (e) {
      return 0.0;
    }
  }

  // Get feedback count for an event
  static Future<int> getFeedbackCount(String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('event_feedback')
          .select('id')
          .eq('event_id', eventId);

      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Check if user has given feedback
  static Future<EventFeedback?> getUserFeedback(String eventId, String userId) async {
    try {
      final data = await SupabaseService.client
          .from('event_feedback')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;
      return EventFeedback.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // Delete feedback
  static Future<void> deleteFeedback(String feedbackId) async {
    await SupabaseService.client
        .from('event_feedback')
        .delete()
        .eq('id', feedbackId);
  }
}

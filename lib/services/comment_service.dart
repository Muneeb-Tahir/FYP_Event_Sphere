// lib/services/comment_service.dart
// Event Comments/Discussion Service

import 'supabase_service.dart';

class EventComment {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final String? parentId;
  final DateTime createdAt;
  final List<EventComment> replies;

  EventComment({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.parentId,
    required this.createdAt,
    this.replies = const [],
  });

  factory EventComment.fromMap(Map<String, dynamic> data) {
    return EventComment(
      id: data['id'] ?? '',
      eventId: data['event_id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['users']?['name'] ?? 'Anonymous',
      userAvatar: data['users']?['profile_image_url'],
      content: data['content'] ?? '',
      parentId: data['parent_id'],
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  EventComment copyWith({List<EventComment>? replies}) {
    return EventComment(
      id: id,
      eventId: eventId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: content,
      parentId: parentId,
      createdAt: createdAt,
      replies: replies ?? this.replies,
    );
  }
}

class CommentService {
  // Add a comment
  static Future<void> addComment({
    required String eventId,
    required String userId,
    required String content,
    String? parentId,
  }) async {
    await SupabaseService.client.from('event_comments').insert({
      'event_id': eventId,
      'user_id': userId,
      'content': content,
      'parent_id': parentId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Get comments for an event (with replies organized)
  static Future<List<EventComment>> getEventComments(String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('event_comments')
          .select('*, users!inner(name, profile_image_url)')
          .eq('event_id', eventId)
          .order('created_at', ascending: true);

      final allComments = (data as List).map((e) => EventComment.fromMap(e)).toList();

      // Organize into parent-child structure
      final Map<String, EventComment> commentMap = {};
      final List<EventComment> topLevel = [];

      // First pass: create map
      for (final comment in allComments) {
        commentMap[comment.id] = comment;
      }

      // Second pass: organize replies
      for (final comment in allComments) {
        if (comment.parentId == null) {
          topLevel.add(comment);
        } else {
          final parent = commentMap[comment.parentId];
          if (parent != null) {
            commentMap[comment.parentId!] = parent.copyWith(
              replies: [...parent.replies, comment],
            );
          }
        }
      }

      // Return top-level comments with their replies
      return topLevel.map((c) => commentMap[c.id] ?? c).toList().reversed.toList();
    } catch (e) {
      return [];
    }
  }

  // Get comment count for an event
  static Future<int> getCommentCount(String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('event_comments')
          .select('id')
          .eq('event_id', eventId);

      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Delete a comment (only by author or admin)
  static Future<void> deleteComment(String commentId) async {
    // First delete all replies
    await SupabaseService.client
        .from('event_comments')
        .delete()
        .eq('parent_id', commentId);

    // Then delete the comment
    await SupabaseService.client
        .from('event_comments')
        .delete()
        .eq('id', commentId);
  }

  // Update a comment
  static Future<void> updateComment(String commentId, String newContent) async {
    await SupabaseService.client
        .from('event_comments')
        .update({
          'content': newContent,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', commentId);
  }
}

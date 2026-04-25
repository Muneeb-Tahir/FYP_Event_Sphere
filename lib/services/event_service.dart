// lib/services/event_service.dart
// Supabase Event Service - Full CRUD operations with Offline Support

import '../models/event.dart';
import 'supabase_service.dart';
import 'cache_service.dart';
import 'email_service.dart';
import '../utils/pagination.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class EventService {
  // Pagination constants
  static const int defaultPageSize = 20;

  // ------------------------- GET ALL EVENTS (with offline support) -------------------------
  static Future<List<Event>> getAllEvents() async {
    try {
      // If offline, return cached data (already filtered)
      if (!CacheService.isOnline) {
        final cached = CacheService.getCachedEvents();
        return cached.map((e) => _mapToEvent(e)).toList();
      }

      // Fetch only approved, non-deleted events from Supabase
      final data = await SupabaseService.events
          .select()
          .eq('approval_status', 'approved')
          .isFilter('deleted_at', null)
          .order('date', ascending: true);

      // Cache the data
      await CacheService.cacheEvents(List<Map<String, dynamic>>.from(data));

      return (data as List).map((e) => _mapToEvent(e)).toList();
    } catch (e) {
      // On error, try to return cached data
      final cached = CacheService.getCachedEvents();
      if (cached.isNotEmpty) {
        return cached.map((e) => _mapToEvent(e)).toList();
      }
      rethrow;
    }
  }

  // ------------------------- GET EVENTS PAGINATED -------------------------
  static Future<PaginatedResult<Event>> getEventsPaginated({
    int page = 0,
    int pageSize = defaultPageSize,
    String? category,
    bool approvedOnly = true,
  }) async {
    try {
      final start = page * pageSize;
      final end = start + pageSize - 1;

      var query = SupabaseService.events.select();

      if (approvedOnly) {
        query = query.eq('approval_status', 'approved');
      }

      // Always exclude soft-deleted events
      query = query.isFilter('deleted_at', null);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final response = await query
          .order('date', ascending: true)
          .range(start, end);

      final events = (response as List).map((e) => _mapToEvent(e)).toList();

      // Note: count requires a separate query or PostgrestResponse handling
      final hasMore = events.length == pageSize;

      return PaginatedResult(
        items: events,
        page: page,
        pageSize: pageSize,
        hasMore: hasMore,
      );
    } catch (e) {
      rethrow;
    }
  }



  // ------------------------- STREAM EVENTS (REALTIME) -------------------------
  static Stream<List<Event>> getEventsStream() {
    return SupabaseService.client
        .from('events')
        .stream(primaryKey: ['id'])
        .order('date', ascending: true)
        .map((data) {
          // Filter out soft-deleted events client-side
          final filtered = data.where((e) => e['deleted_at'] == null).toList();
          return filtered.map((e) => _mapToEvent(e)).toList();
        });
  }

  // ------------------------- GET APPROVED EVENTS -------------------------
  // NOTE: Supabase .stream() doesn't support .eq() filters on non-primary-key
  // columns, so we must filter client-side. This downloads all events.
  static Stream<List<Event>> getApprovedEventsStream() {
    return SupabaseService.client
        .from('events')
        .stream(primaryKey: ['id'])
        .order('date', ascending: true)
        .map((data) {
          // Filter approved AND non-deleted events client-side
          final filtered = data.where((e) =>
            e['approval_status'] == 'approved' &&
            e['deleted_at'] == null
          ).toList();
          return filtered.map((e) => _mapToEvent(e)).toList();
        });
  }


  // ------------------------- GET PENDING EVENTS -------------------------
  static Stream<List<Event>> getPendingEventsStream() {
    return SupabaseService.client
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('approval_status', 'pending')
        .order('date', ascending: true)
        .map((data) {
          // Filter out soft-deleted events client-side
          final filtered = data.where((e) => e['deleted_at'] == null).toList();
          return filtered.map((e) => _mapToEvent(e)).toList();
        });
  }

  // ------------------------- GET EVENTS BY CATEGORY -------------------------
  static Future<List<Event>> getEventsByCategory(String category) async {
    final data = await SupabaseService.events
        .select()
        .eq('category', category)
        .eq('approval_status', 'approved')
        .isFilter('deleted_at', null)
        .order('date', ascending: true);

    return (data as List).map((e) => _mapToEvent(e)).toList();
  }

  // ------------------------- CREATE EVENT -------------------------
  static Future<void> createEvent(Event event) async {
    final data = <String, dynamic>{
      'id': event.id,
      'title': event.title,
      'description': event.description,
      'date': event.date.toIso8601String(),
      'venue': event.venue,
      'society_id': event.societyId,
      'created_by': event.createdBy,
      'approval_status': event.approvalStatus,
      'category': event.category,
      'image_url': event.imageUrl,
      'max_attendees': event.maxAttendees,
      'current_attendees': 0,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Only include optional columns if they have non-default values
    // (prevents errors if columns haven't been added to DB yet)
    if (event.endDate != null) data['end_date'] = event.endDate!.toIso8601String();
    if (event.isFeatured) data['is_featured'] = true;

    await SupabaseService.events.insert(data);
  }

  // ------------------------- UPDATE EVENT -------------------------
  static Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    final updateData = <String, dynamic>{};

    if (data['title'] != null) updateData['title'] = data['title'];
    if (data['description'] != null) updateData['description'] = data['description'];
    if (data['date'] != null) updateData['date'] = (data['date'] as DateTime).toIso8601String();
    if (data['venue'] != null) updateData['venue'] = data['venue'];
    if (data['category'] != null) updateData['category'] = data['category'];
    if (data['approvalStatus'] != null) updateData['approval_status'] = data['approvalStatus'];
    if (data.containsKey('image_url')) updateData['image_url'] = data['image_url'];
    if (data['end_date'] != null) updateData['end_date'] = (data['end_date'] as DateTime).toIso8601String();
    if (data.containsKey('is_featured')) updateData['is_featured'] = data['is_featured'];

    updateData['updated_at'] = DateTime.now().toIso8601String();

    await SupabaseService.events
        .update(updateData)
        .eq('id', eventId);
  }

  // ------------------------- APPROVE EVENT -------------------------
  static Future<void> approveEvent(String eventId) async {
    // Update event status
    await SupabaseService.events
        .update({
          'approval_status': 'approved',
          'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', eventId);

    // Get event details for notification
    final event = await getEvent(eventId);
    if (event != null) {
      // Notify all users about the new event (fire and forget)
      EmailService.notifyAllUsersAboutNewEvent(
        eventTitle: event.title,
        eventDate: DateFormat('EEEE, MMMM d, y').format(event.date),
        venue: event.venue,
        category: event.category,
        description: event.description.length > 200
            ? '${event.description.substring(0, 200)}...'
            : event.description,
      );
    }
  }

  // ------------------------- REJECT EVENT -------------------------
  static Future<void> rejectEvent(String eventId) async {
    await SupabaseService.events
        .update({
          'approval_status': 'rejected',
          'rejected_at': DateTime.now().toIso8601String(),
        })
        .eq('id', eventId);
  }

  // ------------------------- DELETE EVENT (SOFT DELETE) -------------------------
  /// Soft deletes an event by setting deleted_at timestamp
  /// The event is preserved in the database for historical reference
  static Future<void> deleteEvent(String eventId) async {
    // Soft delete: set deleted_at timestamp instead of removing
    await SupabaseService.events
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', eventId);
  }

  /// Permanently delete an event (use with caution)
  static Future<void> permanentlyDeleteEvent(String eventId) async {
    // Delete related registrations first
    await SupabaseService.registrations.delete().eq('event_id', eventId);
    await SupabaseService.bookmarks.delete().eq('event_id', eventId);
    // Then delete the event
    await SupabaseService.events.delete().eq('id', eventId);
  }

  /// Restore a soft-deleted event
  static Future<void> restoreEvent(String eventId) async {
    await SupabaseService.events
        .update({'deleted_at': null})
        .eq('id', eventId);
  }

  // ------------------------- GET SINGLE EVENT -------------------------
  static Future<Event?> getEvent(String eventId) async {
    try {
      final data = await SupabaseService.events
          .select()
          .eq('id', eventId)
          .single();

      return _mapToEvent(data);
    } catch (e) {
      return null;
    }
  }

  // ------------------------- GET EVENTS BY SOCIETY -------------------------
  static Future<List<Event>> getEventsBySociety(String societyId) async {
    final data = await SupabaseService.events
        .select()
        .eq('society_id', societyId)
        .order('date', ascending: true);

    return (data as List).map((e) => _mapToEvent(e)).toList();
  }

  // ------------------------- GET EVENTS BY CREATOR -------------------------
  static Future<List<Event>> getEventsByCreator(String userId) async {
    final data = await SupabaseService.events
        .select()
        .eq('created_by', userId)
        .order('date', ascending: true);

    return (data as List).map((e) => _mapToEvent(e)).toList();
  }

  // ------------------------- SEARCH EVENTS -------------------------
  static Future<List<Event>> searchEvents(String query) async {
    final data = await SupabaseService.events
        .select()
        .or('title.ilike.%$query%,description.ilike.%$query%,venue.ilike.%$query%')
        .eq('approval_status', 'approved')
        .isFilter('deleted_at', null)
        .order('date', ascending: true);

    return (data as List).map((e) => _mapToEvent(e)).toList();
  }

  // ------------------------- MAP DATABASE TO MODEL -------------------------
  static Event _mapToEvent(Map<String, dynamic> data) {
    return Event(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
      venue: data['venue'] ?? '',
      societyId: data['society_id'] ?? '',
      createdBy: data['created_by'] ?? '',
      approvalStatus: data['approval_status'] ?? 'pending',
      category: data['category'] ?? 'General',
      imageUrl: data['image_url'],
      maxAttendees: data['max_attendees'],
      currentAttendees: data['current_attendees'] ?? 0,
      endDate: data['end_date'] != null ? DateTime.tryParse(data['end_date']) : null,
      deletedAt: data['deleted_at'] != null ? DateTime.tryParse(data['deleted_at']) : null,
      isFeatured: data['is_featured'] ?? false,
      likeCount: data['like_count'] ?? 0,
      dislikeCount: data['dislike_count'] ?? 0,
    );
  }
}

// Extension remains for backward compatibility
extension StartWithExtension<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}

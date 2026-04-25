// lib/repositories/event_repository.dart
// Event repository implementation

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';
import '../core/result.dart';
import '../services/supabase_service.dart';
import '../services/cache_service.dart';
import '../services/logging_service.dart';
import 'base_repository.dart';

/// Repository for Event data access
class EventRepository implements BaseRepository<Event> {
  final SupabaseClient _client;

  EventRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Get table reference
  SupabaseQueryBuilder get _events => _client.from('events');

  @override
  Future<Result<List<Event>>> getAll() async {
    try {
      // Check if offline
      if (!CacheService.isOnline) {
        final cached = CacheService.getCachedEvents();
        final events = cached.map((e) => Event.fromMap(e)).toList();
        LoggingService.cache('read', key: 'events', hit: cached.isNotEmpty);
        return Success(events);
      }

      final data = await _events
          .select()
          .eq('approval_status', 'approved')
          .isFilter('deleted_at', null)
          .order('date', ascending: true);

      final events = (data as List).map((e) => Event.fromMap(e)).toList();

      // Cache for offline use
      await CacheService.cacheEvents(List<Map<String, dynamic>>.from(data));
      LoggingService.database('select_all', 'events', count: events.length);

      return Success(events);
    } catch (e, stackTrace) {
      LoggingService.error('EventRepository.getAll failed', e, stackTrace);

      // Try to return cached data on error
      final cached = CacheService.getCachedEvents();
      if (cached.isNotEmpty) {
        LoggingService.cache('fallback', key: 'events');
        return Success(cached.map((e) => Event.fromMap(e)).toList());
      }

      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<Event?>> getById(String id) async {
    try {
      final data = await _events
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) {
        return const Success(null);
      }

      LoggingService.database('select', 'events');
      return Success(Event.fromMap(data));
    } catch (e, stackTrace) {
      LoggingService.error('EventRepository.getById failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<Event>> create(Event event) async {
    try {
      await _events.insert(event.toMap());
      LoggingService.database('insert', 'events');
      return Success(event);
    } catch (e, stackTrace) {
      LoggingService.error('EventRepository.create failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<Event>> update(String id, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      await _events.update(data).eq('id', id);

      // Fetch updated event
      final result = await getById(id);
      return result.when(
        success: (event) {
          if (event != null) {
            LoggingService.database('update', 'events');
            return Success(event);
          }
          return const Failure('Event not found after update');
        },
        failure: (message, error) => Failure(message, error: error),
      );
    } catch (e, stackTrace) {
      LoggingService.error('EventRepository.update failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      // Soft delete
      await _events.update({
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      LoggingService.database('soft_delete', 'events');
      return const Success(null);
    } catch (e, stackTrace) {
      LoggingService.error('EventRepository.delete failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  /// Get events by category
  Future<Result<List<Event>>> getByCategory(String category) async {
    try {
      final data = await _events
          .select()
          .eq('category', category)
          .eq('approval_status', 'approved')
          .isFilter('deleted_at', null)
          .order('date', ascending: true);

      final events = (data as List).map((e) => Event.fromMap(e)).toList();
      LoggingService.database('select', 'events', count: events.length);
      return Success(events);
    } catch (e, stackTrace) {
      LoggingService.error('EventRepository.getByCategory failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  /// Get events by society
  Future<Result<List<Event>>> getBySociety(String societyId) async {
    try {
      final data = await _events
          .select()
          .eq('society_id', societyId)
          .isFilter('deleted_at', null)
          .order('date', ascending: true);

      final events = (data as List).map((e) => Event.fromMap(e)).toList();
      LoggingService.database('select', 'events', count: events.length);
      return Success(events);
    } catch (e, stackTrace) {
      LoggingService.error('EventRepository.getBySociety failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  /// Get events by creator
  Future<Result<List<Event>>> getByCreator(String userId) async {
    try {
      final data = await _events
          .select()
          .eq('created_by', userId)
          .isFilter('deleted_at', null)
          .order('date', ascending: true);

      final events = (data as List).map((e) => Event.fromMap(e)).toList();
      LoggingService.database('select', 'events', count: events.length);
      return Success(events);
    } catch (e, stackTrace) {
      LoggingService.error('EventRepository.getByCreator failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  /// Search events by query
  Future<Result<List<Event>>> search(String query) async {
    try {
      final data = await _events
          .select()
          .or('title.ilike.%$query%,description.ilike.%$query%,venue.ilike.%$query%')
          .eq('approval_status', 'approved')
          .isFilter('deleted_at', null)
          .order('date', ascending: true);

      final events = (data as List).map((e) => Event.fromMap(e)).toList();
      LoggingService.database('search', 'events', count: events.length);
      return Success(events);
    } catch (e, stackTrace) {
      LoggingService.error('EventRepository.search failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  /// Get pending events (for admin approval)
  Future<Result<List<Event>>> getPending() async {
    try {
      final data = await _events
          .select()
          .eq('approval_status', 'pending')
          .isFilter('deleted_at', null)
          .order('date', ascending: true);

      final events = (data as List).map((e) => Event.fromMap(e)).toList();
      LoggingService.database('select_pending', 'events', count: events.length);
      return Success(events);
    } catch (e, stackTrace) {
      LoggingService.error('EventRepository.getPending failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  /// Approve an event
  Future<Result<void>> approve(String id) async {
    try {
      await _events.update({
        'approval_status': 'approved',
        'approved_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      LoggingService.database('approve', 'events');
      return const Success(null);
    } catch (e, stackTrace) {
      LoggingService.error('EventRepository.approve failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  /// Reject an event
  Future<Result<void>> reject(String id) async {
    try {
      await _events.update({
        'approval_status': 'rejected',
        'rejected_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      LoggingService.database('reject', 'events');
      return const Success(null);
    } catch (e, stackTrace) {
      LoggingService.error('EventRepository.reject failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  /// Get real-time event stream
  Stream<List<Event>> getStream() {
    return _client
        .from('events')
        .stream(primaryKey: ['id'])
        .order('date', ascending: true)
        .map((data) => data.map((e) => Event.fromMap(e)).toList());
  }

  /// Get approved events stream
  Stream<List<Event>> getApprovedStream() {
    return _client
        .from('events')
        .stream(primaryKey: ['id'])
        .order('date', ascending: true)
        .map((data) {
          final approved = data
              .where((e) => e['approval_status'] == 'approved' && e['deleted_at'] == null)
              .toList();
          return approved.map((e) => Event.fromMap(e)).toList();
        });
  }
}

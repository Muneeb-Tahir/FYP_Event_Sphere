// lib/services/chatbot/database_handler.dart
// Database queries for Event Sphere Chatbot

import 'package:intl/intl.dart';
import '../supabase_service.dart';
import '../auth_service.dart';
import '../event_service.dart';
import '../registration_service.dart';
import '../logging_service.dart';
import '../../models/event.dart';

/// Handles all database queries for the chatbot
class ChatDatabaseHandler {

  // ============================================================================
  // EVENT QUERIES
  // ============================================================================

  /// Get all upcoming/current events (excludes deleted events)
  static Future<List<Event>> getCurrentEvents({int limit = 10}) async {
    try {
      final now = DateTime.now().toIso8601String();
      final data = await SupabaseService.client
          .from('events')
          .select()
          .gte('date', now)
          .eq('approval_status', 'approved')
          .filter('deleted_at', 'is', null) // Exclude soft-deleted events
          .order('date', ascending: true)
          .limit(limit);

      return (data as List).map((e) => Event.fromMap(e)).toList();
    } catch (e) {
      LoggingService.error('ChatDatabaseHandler.getCurrentEvents error', e);
      return [];
    }
  }

  /// Get past events (includes soft-deleted events for historical reference)
  static Future<List<Event>> getPastEvents({int limit = 10}) async {
    try {
      final now = DateTime.now().toIso8601String();
      // Get past events OR deleted events (soft-deleted are considered archived/past)
      final data = await SupabaseService.client
          .from('events')
          .select()
          .eq('approval_status', 'approved')
          .or('date.lt.$now,deleted_at.not.is.null')
          .order('date', ascending: false)
          .limit(limit);

      return (data as List).map((e) => Event.fromMap(e)).toList();
    } catch (e) {
      LoggingService.error('ChatDatabaseHandler.getPastEvents error', e);
      return [];
    }
  }

  /// Get all events
  static Future<List<Event>> getAllEvents({int limit = 20}) async {
    try {
      final data = await SupabaseService.client
          .from('events')
          .select()
          .eq('approval_status', 'approved')
          .order('date', ascending: false)
          .limit(limit);

      return (data as List).map((e) => Event.fromMap(e)).toList();
    } catch (e) {
      LoggingService.error('ChatDatabaseHandler.getAllEvents error', e);
      return [];
    }
  }

  /// Search events by query
  static Future<List<Event>> searchEvents(String query, {Map<String, dynamic> filters = const {}}) async {
    try {
      var builder = SupabaseService.client
          .from('events')
          .select()
          .eq('approval_status', 'approved');

      // Apply text search
      if (query.isNotEmpty) {
        builder = builder.or('title.ilike.%$query%,description.ilike.%$query%,venue.ilike.%$query%');
      }

      // Apply date filter
      if (filters.containsKey('dateFilter')) {
        final now = DateTime.now();
        switch (filters['dateFilter']) {
          case 'today':
            final start = DateTime(now.year, now.month, now.day);
            final end = start.add(const Duration(days: 1));
            builder = builder.gte('date', start.toIso8601String()).lt('date', end.toIso8601String());
            break;
          case 'tomorrow':
            final start = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
            final end = start.add(const Duration(days: 1));
            builder = builder.gte('date', start.toIso8601String()).lt('date', end.toIso8601String());
            break;
          case 'this_week':
            final start = now;
            final end = now.add(const Duration(days: 7));
            builder = builder.gte('date', start.toIso8601String()).lt('date', end.toIso8601String());
            break;
          case 'this_month':
            final start = now;
            final end = DateTime(now.year, now.month + 1, 1);
            builder = builder.gte('date', start.toIso8601String()).lt('date', end.toIso8601String());
            break;
        }
      }

      // Apply category filter
      if (filters.containsKey('category')) {
        builder = builder.ilike('category', '%${filters['category']}%');
      }

      // Apply location filter
      if (filters.containsKey('location')) {
        builder = builder.ilike('venue', '%${filters['location']}%');
      }

      final data = await builder.order('date', ascending: true).limit(10);
      return (data as List).map((e) => Event.fromMap(e)).toList();
    } catch (e) {
      LoggingService.error('ChatDatabaseHandler.searchEvents error', e);
      return [];
    }
  }

  /// Get event by name (exact match first, then fuzzy)
  static Future<Event?> getEventByName(String name) async {
    try {
      // First try exact match (case-insensitive)
      var data = await SupabaseService.client
          .from('events')
          .select()
          .ilike('title', name) // Exact match (case-insensitive)
          .maybeSingle();

      if (data != null) {
        return Event.fromMap(data);
      }

      // Fall back to fuzzy match if no exact match
      data = await SupabaseService.client
          .from('events')
          .select()
          .ilike('title', '%$name%')
          .order('title', ascending: true) // Shorter names first
          .limit(1)
          .maybeSingle();

      if (data != null) {
        return Event.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get event by ID
  static Future<Event?> getEventById(String id) async {
    try {
      return await EventService.getEvent(id);
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // USER REGISTRATION QUERIES
  // ============================================================================

  /// Get user's registered events
  static Future<List<Event>> getUserRegistrations() async {
    try {
      final user = AuthService.getCurrentUser();
      if (user == null) return [];

      // Get event IDs from registrations
      final eventIds = await RegistrationService.getUserRegistrations(user.id);
      if (eventIds.isEmpty) return [];

      // Fetch full event details for each ID
      final events = <Event>[];
      for (final eventId in eventIds) {
        final event = await getEventById(eventId);
        if (event != null) events.add(event);
      }
      return events;
    } catch (e) {
      return [];
    }
  }

  /// Get user's attended events
  static Future<List<Event>> getUserAttendedEvents() async {
    try {
      final user = AuthService.getCurrentUser();
      if (user == null) return [];

      final data = await SupabaseService.client
          .from('registrations')
          .select('events(*)')
          .eq('user_id', user.id)
          .eq('attendance_marked', true);

      return (data as List)
          .where((r) => r['events'] != null)
          .map((r) => Event.fromMap(r['events']))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if user is registered for an event
  static Future<bool> isUserRegistered(String eventId) async {
    try {
      final user = AuthService.getCurrentUser();
      if (user == null) return false;

      return await RegistrationService.checkRegistration(user.id, eventId);
    } catch (e) {
      return false;
    }
  }

  /// Register user for event
  static Future<Map<String, dynamic>> registerForEvent(String eventId) async {
    try {
      final user = AuthService.getCurrentUser();
      if (user == null) {
        return {'success': false, 'message': 'Please login first'};
      }

      // Check if already registered
      if (await isUserRegistered(eventId)) {
        return {'success': false, 'message': 'You are already registered for this event'};
      }

      // Get event details
      final event = await getEventById(eventId);
      if (event == null) {
        return {'success': false, 'message': 'Event not found'};
      }

      // Check capacity
      if (event.isFull) {
        return {'success': false, 'message': 'Event is full. You can join the waitlist.'};
      }

      await RegistrationService.registerForEvent(user.id, eventId);
      return {'success': true, 'message': 'Successfully registered for ${event.title}!'};
    } catch (e) {
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  /// Get user's QR code for an event
  static Future<String?> getQrCode(String eventId) async {
    try {
      final user = AuthService.getCurrentUser();
      if (user == null) return null;

      final data = await SupabaseService.client
          .from('registrations')
          .select('qr_code')
          .eq('event_id', eventId)
          .eq('user_id', user.id)
          .maybeSingle();

      return data?['qr_code'] as String?;
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // ANALYTICS & SUMMARIES
  // ============================================================================

  /// Get event statistics
  static Future<Map<String, dynamic>> getEventStats() async {
    try {
      final allEvents = await getAllEvents(limit: 100);
      final now = DateTime.now();

      final upcomingCount = allEvents.where((e) => e.date.isAfter(now)).length;
      final pastCount = allEvents.where((e) => e.date.isBefore(now)).length;

      // Category breakdown
      final categories = <String, int>{};
      for (final event in allEvents) {
        categories[event.category] = (categories[event.category] ?? 0) + 1;
      }

      return {
        'total': allEvents.length,
        'upcoming': upcomingCount,
        'past': pastCount,
        'categories': categories,
      };
    } catch (e) {
      return {};
    }
  }

  /// Get weekly digest (events this week)
  static Future<Map<String, dynamic>> getWeeklyDigest() async {
    try {
      final now = DateTime.now();
      final weekEnd = now.add(const Duration(days: 7));

      final data = await SupabaseService.client
          .from('events')
          .select()
          .gte('date', now.toIso8601String())
          .lt('date', weekEnd.toIso8601String())
          .eq('approval_status', 'approved')
          .order('date');

      final events = (data as List).map((e) => Event.fromMap(e)).toList();

      return {
        'weekStart': DateFormat('MMM d').format(now),
        'weekEnd': DateFormat('MMM d').format(weekEnd),
        'events': events,
        'count': events.length,
      };
    } catch (e) {
      return {'events': [], 'count': 0};
    }
  }

  // ============================================================================
  // RECOMMENDATIONS
  // ============================================================================

  /// Get event recommendations for user
  static Future<List<Event>> getRecommendations() async {
    try {
      final user = AuthService.getCurrentUser();

      // Get upcoming events
      final events = await getCurrentEvents(limit: 20);

      if (events.isEmpty) return [];

      // If user is logged in, personalize
      if (user != null) {
        // Get user's past registrations to find preferences
        final pastEvents = await getUserRegistrations();
        final preferredCategories = <String>{};

        for (final event in pastEvents) {
          preferredCategories.add(event.category);
        }

        // Sort by preference (preferred categories first)
        events.sort((a, b) {
          final aPreferred = preferredCategories.contains(a.category) ? 0 : 1;
          final bPreferred = preferredCategories.contains(b.category) ? 0 : 1;
          return aPreferred.compareTo(bPreferred);
        });
      }

      return events.take(5).toList();
    } catch (e) {
      return [];
    }
  }
}

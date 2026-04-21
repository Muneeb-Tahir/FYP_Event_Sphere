// lib/services/waitlist_service.dart
// Event Waitlist Service - Queue users when events are full

import 'supabase_service.dart';
import 'registration_service.dart';
import 'logging_service.dart';

class WaitlistEntry {
  final String id;
  final String eventId;
  final String userId;
  final int position;
  final DateTime joinedAt;
  final DateTime? promotedAt;
  final String? userName;

  WaitlistEntry({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.position,
    required this.joinedAt,
    this.promotedAt,
    this.userName,
  });

  factory WaitlistEntry.fromMap(Map<String, dynamic> data) {
    // Parse as UTC and convert to local time
    DateTime joinedAt = DateTime.now();
    if (data['joined_at'] != null) {
      final parsed = DateTime.tryParse(data['joined_at'].toString());
      if (parsed != null) {
        // Force treat as UTC even if not marked, then convert to local
        final utcTime = DateTime.utc(
          parsed.year, parsed.month, parsed.day,
          parsed.hour, parsed.minute, parsed.second, parsed.millisecond
        );
        joinedAt = utcTime.toLocal();
      }
    }

    return WaitlistEntry(
      id: data['id'] ?? '',
      eventId: data['event_id'] ?? '',
      userId: data['user_id'] ?? '',
      position: data['position'] ?? 0,
      joinedAt: joinedAt,
      promotedAt: data['promoted_at'] != null
          ? DateTime.tryParse(data['promoted_at'].toString())?.toLocal()
          : null,
      userName: data['users']?['name'],
    );
  }
}

class WaitlistService {
  /// Join the waitlist for an event
  static Future<int?> joinWaitlist(String eventId) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return null;

      // Check if already on waitlist
      final existing = await SupabaseService.client
          .from('event_waitlist')
          .select('position')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        return existing['position'] as int;
      }

      // Get current max position
      final maxPos = await SupabaseService.client
          .from('event_waitlist')
          .select('position')
          .eq('event_id', eventId)
          .order('position', ascending: false)
          .limit(1)
          .maybeSingle();

      final newPosition = (maxPos?['position'] ?? 0) + 1;

      await SupabaseService.client.from('event_waitlist').insert({
        'event_id': eventId,
        'user_id': userId,
        'position': newPosition,
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      });

      return newPosition;
    } catch (e) {
      LoggingService.error('Error joining waitlist', e);
      return null;
    }
  }

  /// Leave the waitlist
  static Future<bool> leaveWaitlist(String eventId) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return false;

      // Get user's position first
      final userEntry = await SupabaseService.client
          .from('event_waitlist')
          .select('position')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      if (userEntry == null) return true; // Not on waitlist

      final position = userEntry['position'] as int;

      // Delete the entry
      await SupabaseService.client
          .from('event_waitlist')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);

      // Update positions of users behind (decrement by 1)
      final behindUsers = await SupabaseService.client
          .from('event_waitlist')
          .select('id, position')
          .eq('event_id', eventId)
          .gt('position', position)
          .order('position', ascending: true);

      for (final entry in (behindUsers as List)) {
        await SupabaseService.client
            .from('event_waitlist')
            .update({'position': (entry['position'] as int) - 1})
            .eq('id', entry['id']);
      }

      return true;
    } catch (e) {
      LoggingService.error('Error leaving waitlist', e);
      return false;
    }
  }

  /// Get user's position on waitlist
  static Future<int?> getPosition(String eventId) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return null;

      final data = await SupabaseService.client
          .from('event_waitlist')
          .select('position')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      return data?['position'] as int?;
    } catch (e) {
      return null;
    }
  }

  /// Check if user is on waitlist
  static Future<bool> isOnWaitlist(String eventId) async {
    final position = await getPosition(eventId);
    return position != null;
  }

  /// Get waitlist count for an event
  static Future<int> getWaitlistCount(String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('event_waitlist')
          .select('id')
          .eq('event_id', eventId);

      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get full waitlist for an event (for organizers)
  static Future<List<WaitlistEntry>> getEventWaitlist(String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('event_waitlist')
          .select('*, users(name)')
          .eq('event_id', eventId)
          .order('position', ascending: true);

      return (data as List).map((e) => WaitlistEntry.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Promote next person from waitlist (when someone cancels registration)
  static Future<bool> promoteNextInQueue(String eventId) async {
    try {
      // Get first person in waitlist
      final next = await SupabaseService.client
          .from('event_waitlist')
          .select('*')
          .eq('event_id', eventId)
          .order('position', ascending: true)
          .limit(1)
          .maybeSingle();

      if (next == null) return false;

      final userId = next['user_id'] as String;

      // Register them for the event
      try {
        await RegistrationService.registerForEvent(userId, eventId);
      } catch (e) {
        // Registration failed
        return false;
      }

      // Remove from waitlist
      await SupabaseService.client
          .from('event_waitlist')
          .delete()
          .eq('id', next['id']);

      return true;
    } catch (e) {
      LoggingService.error('Error promoting from waitlist', e);
      return false;
    }
  }
}

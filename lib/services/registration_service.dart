// lib/services/registration_service.dart
// Supabase Event Registration Service

import 'supabase_service.dart';
import 'waitlist_service.dart';
import 'logging_service.dart';
import 'dart:async';

class RegistrationService {
  // ------------------------- CHECK IF REGISTERED -------------------------
  /// Synchronous stub — always returns false. Use [checkRegistration] instead.
  @Deprecated('Use checkRegistration() for accurate results')
  static bool isRegistered(String userId, String eventId) {
    return false;
  }

  // ------------------------- CHECK REGISTRATION ASYNC -------------------------
  static Future<bool> checkRegistration(String userId, String eventId) async {
    try {
      final data = await SupabaseService.registrations
          .select()
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      return data != null;
    } catch (e) {
      return false;
    }
  }

  // ------------------------- REGISTER FOR EVENT -------------------------
  static Future<void> registerForEvent(String userId, String eventId, {bool showInList = true}) async {
    // Check if already registered
    final exists = await checkRegistration(userId, eventId);
    if (exists) {
      throw Exception('Already registered for this event');
    }

    // Prevent registration for past events
    try {
      final eventData = await SupabaseService.client
          .from('events')
          .select('date')
          .eq('id', eventId)
          .maybeSingle();
      if (eventData != null) {
        final eventDate = DateTime.tryParse(eventData['date'] ?? '');
        if (eventDate != null && eventDate.isBefore(DateTime.now())) {
          throw Exception('Cannot register for a past event');
        }
      }
    } catch (e) {
      if (e.toString().contains('past event')) rethrow;
      // If date check fails, allow registration to proceed (fail-open)
    }

    await SupabaseService.registrations.insert({
      'user_id': userId,
      'event_id': eventId,
      'registered_at': DateTime.now().toIso8601String(),
      'status': 'registered',
      'checked_in': false,
      'show_in_list': showInList,
    });

    // Update current_attendees count in events table
    await _updateAttendeeCount(eventId);
  }

  // ------------------------- UNREGISTER FROM EVENT -------------------------
  static Future<void> unregisterFromEvent(String userId, String eventId) async {
    await SupabaseService.registrations
        .delete()
        .eq('user_id', userId)
        .eq('event_id', eventId);

    // Update current_attendees count in events table
    await _updateAttendeeCount(eventId);

    // Auto-promote next person from waitlist if there is one
    // Import at top: import 'waitlist_service.dart';
    try {
      await WaitlistService.promoteNextInQueue(eventId);
    } catch (e) {
      LoggingService.error('Error promoting from waitlist', e);
    }
  }

  // ------------------------- UPDATE ATTENDEE COUNT -------------------------
  static Future<void> _updateAttendeeCount(String eventId) async {
    try {
      final count = await getAttendeeCount(eventId);
      await SupabaseService.client
          .from('events')
          .update({'current_attendees': count})
          .eq('id', eventId);
    } catch (e) {
      LoggingService.error('Error updating attendee count', e);
    }
  }


  // ------------------------- GET USER REGISTRATIONS -------------------------
  static Future<List<String>> getUserRegistrations(String userId) async {
    final data = await SupabaseService.registrations
        .select('event_id')
        .eq('user_id', userId);

    return (data as List).map((e) => e['event_id'] as String).toList();
  }

  // ------------------------- STREAM USER REGISTRATIONS -------------------------
  static Stream<List<String>> getRegistrationsStream(String userId) {
    return SupabaseService.client
        .from('registrations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map((e) => e['event_id'] as String).toList());
  }

  // ------------------------- GET EVENT ATTENDEES -------------------------
  static Future<List<String>> getEventAttendees(String eventId) async {
    final data = await SupabaseService.registrations
        .select('user_id')
        .eq('event_id', eventId);

    return (data as List).map((e) => e['user_id'] as String).toList();
  }

  // ------------------------- GET ATTENDEE COUNT -------------------------
  static Future<int> getAttendeeCount(String eventId) async {
    final data = await SupabaseService.registrations
        .select('id')
        .eq('event_id', eventId);

    return (data as List).length;
  }

  // ------------------------- CHECK IN ATTENDEE -------------------------
  static Future<void> checkInAttendee(String userId, String eventId) async {
    await SupabaseService.registrations
        .update({
          'checked_in': true,
          'checked_in_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('event_id', eventId);
  }

  // ------------------------- GET CHECKED IN ATTENDEES -------------------------
  static Future<List<String>> getCheckedInAttendees(String eventId) async {
    final data = await SupabaseService.registrations
        .select('user_id')
        .eq('event_id', eventId)
        .eq('checked_in', true);

    return (data as List).map((e) => e['user_id'] as String).toList();
  }

  // ------------------------- GET USER ATTENDED EVENTS -------------------------
  static Future<List<String>> getAttendedEvents(String userId) async {
    final data = await SupabaseService.registrations
        .select('event_id')
        .eq('user_id', userId)
        .eq('checked_in', true);

    return (data as List).map((e) => e['event_id'] as String).toList();
  }
}

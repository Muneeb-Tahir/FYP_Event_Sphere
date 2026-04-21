// lib/providers/registration_provider.dart
// Riverpod providers for event registration management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/registration_service.dart';

/// Stream provider for user's registered event IDs
final registrationsStreamProvider = StreamProvider.family<List<String>, String>((ref, userId) {
  return RegistrationService.getRegistrationsStream(userId);
});

/// Future provider for user's registrations (one-time fetch)
final userRegistrationsProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  return await RegistrationService.getUserRegistrations(userId);
});

/// Check if user is registered for specific event
final isRegisteredProvider = FutureProvider.family<bool, ({String userId, String eventId})>((ref, params) async {
  return await RegistrationService.checkRegistration(params.userId, params.eventId);
});

/// Get attendee count for an event
final attendeeCountProvider = FutureProvider.family<int, String>((ref, eventId) async {
  return await RegistrationService.getAttendeeCount(eventId);
});

/// Get event attendees list
final eventAttendeesProvider = FutureProvider.family<List<String>, String>((ref, eventId) async {
  return await RegistrationService.getEventAttendees(eventId);
});

/// Get checked-in attendees for event
final checkedInAttendeesProvider = FutureProvider.family<List<String>, String>((ref, eventId) async {
  return await RegistrationService.getCheckedInAttendees(eventId);
});

/// Get user's attended (checked-in) events
final attendedEventsProvider = FutureProvider.family<List<String>, String>((ref, userId) async {
  return await RegistrationService.getAttendedEvents(userId);
});

/// State notifier for registration operations
class RegistrationNotifier extends StateNotifier<Set<String>> {
  final String userId;

  RegistrationNotifier(this.userId) : super({}) {
    _loadRegistrations();
  }

  Future<void> _loadRegistrations() async {
    final registrations = await RegistrationService.getUserRegistrations(userId);
    state = registrations.toSet();
  }

  bool isRegistered(String eventId) => state.contains(eventId);

  Future<void> register(String eventId, {bool showInList = true}) async {
    // Optimistic update
    state = {...state, eventId};

    try {
      await RegistrationService.registerForEvent(userId, eventId, showInList: showInList);
    } catch (e) {
      // Revert on error
      state = {...state}..remove(eventId);
      rethrow;
    }
  }

  Future<void> unregister(String eventId) async {
    // Optimistic update
    state = {...state}..remove(eventId);

    try {
      await RegistrationService.unregisterFromEvent(userId, eventId);
    } catch (e) {
      // Revert on error
      state = {...state, eventId};
      rethrow;
    }
  }

  Future<void> toggle(String eventId, {bool showInList = true}) async {
    if (isRegistered(eventId)) {
      await unregister(eventId);
    } else {
      await register(eventId, showInList: showInList);
    }
  }

  Future<void> refresh() async {
    await _loadRegistrations();
  }
}

/// Registration notifier provider (requires userId)
final registrationNotifierProvider = StateNotifierProvider.family<RegistrationNotifier, Set<String>, String>((ref, userId) {
  return RegistrationNotifier(userId);
});

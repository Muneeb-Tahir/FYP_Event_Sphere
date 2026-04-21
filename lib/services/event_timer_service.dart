// lib/services/event_timer_service.dart
// Event Timer Service - Adjustable manual timer for events

import 'supabase_service.dart';
import 'logging_service.dart';

class EventTimerState {
  final String eventId;
  final bool isRunning;
  final int totalDurationSeconds;
  final int elapsedSeconds;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final DateTime? eventDate;
  final String? postponeReason;

  EventTimerState({
    required this.eventId,
    required this.isRunning,
    this.totalDurationSeconds = 0,
    this.elapsedSeconds = 0,
    this.startedAt,
    this.pausedAt,
    this.eventDate,
    this.postponeReason,
  });

  factory EventTimerState.fromMap(Map<String, dynamic> data) {
    // Parse timestamps as UTC (database stores in UTC)
    DateTime? parseUtc(String? str) {
      if (str == null) return null;
      final dt = DateTime.tryParse(str);
      if (dt == null) return null;
      // If already has timezone info, use as-is. Otherwise, treat as UTC.
      return dt.isUtc ? dt : DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.millisecond);
    }

    return EventTimerState(
      eventId: data['event_id'] ?? '',
      isRunning: data['is_running'] ?? false,
      totalDurationSeconds: data['total_duration_seconds'] ?? 0,
      elapsedSeconds: data['elapsed_seconds'] ?? 0,
      startedAt: parseUtc(data['started_at']),
      pausedAt: parseUtc(data['paused_at']),
      eventDate: parseUtc(data['event_date']),
      postponeReason: data['postpone_reason'],
    );
  }

  // Get remaining seconds - FIXED timezone handling
  int get remainingSeconds {
    if (totalDurationSeconds == 0) return 0;

    int currentElapsed = elapsedSeconds;

    // If running, add time since started using UTC to avoid timezone issues
    if (isRunning && startedAt != null) {
      final nowUtc = DateTime.now().toUtc();
      final startUtc = startedAt!.toUtc();
      currentElapsed += nowUtc.difference(startUtc).inSeconds;
    }

    final remaining = totalDurationSeconds - currentElapsed;
    return remaining > 0 ? remaining : 0;
  }

  bool get isComplete => remainingSeconds == 0 && totalDurationSeconds > 0;
  bool get isNotSet => totalDurationSeconds == 0;
}

class EventTimerService {
  static Future<EventTimerState?> getTimerState(String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('event_timers')
          .select()
          .eq('event_id', eventId)
          .maybeSingle();

      if (data == null) return null;
      return EventTimerState.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  static Future<void> initializeTimer(String eventId, DateTime eventDate) async {
    try {
      final existing = await getTimerState(eventId);
      if (existing != null) return;

      // Calculate seconds until event starts
      final now = DateTime.now();
      final secondsUntilEvent = eventDate.difference(now).inSeconds;

      // Only set timer if event is in the future
      if (secondsUntilEvent > 0) {
        await SupabaseService.client.from('event_timers').insert({
          'event_id': eventId,
          'is_running': true, // Auto-start the countdown
          'total_duration_seconds': secondsUntilEvent,
          'elapsed_seconds': 0,
          'started_at': now.toUtc().toIso8601String(),
          'event_date': eventDate.toUtc().toIso8601String(),
        });
      } else {
        // Event has passed, create completed timer
        await SupabaseService.client.from('event_timers').insert({
          'event_id': eventId,
          'is_running': false,
          'total_duration_seconds': 0,
          'elapsed_seconds': 0,
          'event_date': eventDate.toUtc().toIso8601String(),
        });
      }
    } catch (e) {
      LoggingService.error('Error initializing timer', e);
    }
  }

  static Future<void> setTimerDuration(String eventId, int durationSeconds) async {
    try {
      final existing = await getTimerState(eventId);
      if (existing == null) {
        await SupabaseService.client.from('event_timers').insert({
          'event_id': eventId,
          'is_running': false,
          'total_duration_seconds': durationSeconds,
          'elapsed_seconds': 0,
        });
      } else {
        await SupabaseService.client
            .from('event_timers')
            .update({
              'total_duration_seconds': durationSeconds,
              'elapsed_seconds': 0,
              'is_running': false,
              'started_at': null,
              'paused_at': null,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('event_id', eventId);
      }
    } catch (e) {
      LoggingService.error('Error setting timer duration', e);
    }
  }

  static Future<void> startTimer(String eventId) async {
    try {
      await SupabaseService.client
          .from('event_timers')
          .update({
            'is_running': true,
            'started_at': DateTime.now().toUtc().toIso8601String(),
            'paused_at': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('event_id', eventId);
    } catch (e) {
      LoggingService.error('Error starting timer', e);
    }
  }

  static Future<void> pauseTimer(String eventId) async {
    try {
      final state = await getTimerState(eventId);
      if (state == null || !state.isRunning) return;

      // Calculate elapsed using UTC
      int additionalElapsed = 0;
      if (state.startedAt != null) {
        final nowUtc = DateTime.now().toUtc();
        final startUtc = state.startedAt!.toUtc();
        additionalElapsed = nowUtc.difference(startUtc).inSeconds;
      }

      await SupabaseService.client
          .from('event_timers')
          .update({
            'is_running': false,
            'elapsed_seconds': state.elapsedSeconds + additionalElapsed,
            'paused_at': DateTime.now().toUtc().toIso8601String(),
            'started_at': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('event_id', eventId);
    } catch (e) {
      LoggingService.error('Error pausing timer', e);
    }
  }

  static Future<void> resetTimer(String eventId) async {
    try {
      await SupabaseService.client
          .from('event_timers')
          .update({
            'is_running': false,
            'total_duration_seconds': 0,  // Reset to 00:00:00
            'elapsed_seconds': 0,
            'started_at': null,
            'paused_at': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('event_id', eventId);
    } catch (e) {
      LoggingService.error('Error resetting timer', e);
    }
  }

  static Future<void> addTime(String eventId, int additionalSeconds) async {
    try {
      final state = await getTimerState(eventId);
      if (state == null) return;

      await SupabaseService.client
          .from('event_timers')
          .update({
            'total_duration_seconds': state.totalDurationSeconds + additionalSeconds,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('event_id', eventId);
    } catch (e) {
      LoggingService.error('Error adding time', e);
    }
  }

  static Stream<EventTimerState?> streamTimerState(String eventId) {
    return SupabaseService.client
        .from('event_timers')
        .stream(primaryKey: ['id'])
        .eq('event_id', eventId)
        .map((data) {
          if (data.isEmpty) return null;
          return EventTimerState.fromMap(data.first);
        });
  }
}

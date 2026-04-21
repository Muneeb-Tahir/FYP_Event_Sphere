// lib/services/reminder_service.dart
// Event Reminder Service - Schedule notifications before events

import 'supabase_service.dart';
import 'notification_service.dart';
import 'logging_service.dart';

class Reminder {
  final String id;
  final String userId;
  final String eventId;
  final DateTime remindAt;
  final bool isSent;
  final String reminderType; // 'hour', 'day', 'week'
  final String? eventTitle;

  Reminder({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.remindAt,
    required this.isSent,
    required this.reminderType,
    this.eventTitle,
  });

  factory Reminder.fromMap(Map<String, dynamic> data) {
    return Reminder(
      id: data['id'] ?? '',
      userId: data['user_id'] ?? '',
      eventId: data['event_id'] ?? '',
      remindAt: DateTime.tryParse(data['remind_at'] ?? '') ?? DateTime.now(),
      isSent: data['is_sent'] ?? false,
      reminderType: data['reminder_type'] ?? 'day',
      eventTitle: data['events']?['title'],
    );
  }

  String get displayLabel {
    switch (reminderType) {
      case '30min': return '30 minutes before';
      case 'hour': return '1 hour before';
      case 'day': return '1 day before';
      default: return reminderType;
    }
  }
}

class ReminderService {
  /// Set a reminder for an event
  static Future<bool> setReminder({
    required String eventId,
    required String reminderType,
    required DateTime eventDate,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return false;

      // Calculate reminder time
      DateTime remindAt;
      switch (reminderType) {
        case '30min':
          remindAt = eventDate.subtract(const Duration(minutes: 30));
          break;
        case 'hour':
          remindAt = eventDate.subtract(const Duration(hours: 1));
          break;
        case 'day':
          remindAt = eventDate.subtract(const Duration(days: 1));
          break;
        default:
          remindAt = eventDate.subtract(const Duration(minutes: 30));
      }

      // Don't set reminder if it's in the past
      if (remindAt.isBefore(DateTime.now())) {
        return false;
      }

      await SupabaseService.client.from('event_reminders').upsert({
        'user_id': userId,
        'event_id': eventId,
        'remind_at': remindAt.toIso8601String(),
        'is_sent': false,
        'reminder_type': reminderType,
      }, onConflict: 'user_id,event_id,reminder_type');

      return true;
    } catch (e) {
      LoggingService.error('Error setting reminder', e);
      return false;
    }
  }

  /// Cancel a specific reminder
  static Future<bool> cancelReminder({
    required String eventId,
    required String reminderType,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return false;

      await SupabaseService.client
          .from('event_reminders')
          .delete()
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .eq('reminder_type', reminderType);

      return true;
    } catch (e) {
      LoggingService.error('Error canceling reminder', e);
      return false;
    }
  }

  /// Cancel all reminders for an event
  static Future<bool> cancelAllReminders(String eventId) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return false;

      await SupabaseService.client
          .from('event_reminders')
          .delete()
          .eq('user_id', userId)
          .eq('event_id', eventId);

      return true;
    } catch (e) {
      LoggingService.error('Error canceling reminders', e);
      return false;
    }
  }

  /// Get all reminders for an event
  static Future<List<String>> getEventReminders(String eventId) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return [];

      final data = await SupabaseService.client
          .from('event_reminders')
          .select('reminder_type')
          .eq('user_id', userId)
          .eq('event_id', eventId);

      return (data as List).map((e) => e['reminder_type'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all user reminders
  static Future<List<Reminder>> getUserReminders() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return [];

      final data = await SupabaseService.client
          .from('event_reminders')
          .select('*, events(title)')
          .eq('user_id', userId)
          .eq('is_sent', false)
          .order('remind_at', ascending: true);

      return (data as List).map((e) => Reminder.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if a specific reminder is set
  static Future<bool> hasReminder(String eventId, String reminderType) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return false;

      final data = await SupabaseService.client
          .from('event_reminders')
          .select('id')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .eq('reminder_type', reminderType)
          .maybeSingle();

      return data != null;
    } catch (e) {
      return false;
    }
  }

  /// Process due reminders (called by background service or Edge Function)
  static Future<void> processDueReminders() async {
    try {
      final now = DateTime.now();

      final data = await SupabaseService.client
          .from('event_reminders')
          .select('*, events(title)')
          .eq('is_sent', false)
          .lte('remind_at', now.toIso8601String());

      for (final reminder in data as List) {
        final eventTitle = reminder['events']?['title'] ?? 'Event';
        final reminderType = reminder['reminder_type'];

        String timeLabel;
        switch (reminderType) {
          case '30min': timeLabel = 'in 30 minutes'; break;
          case 'hour': timeLabel = 'in 1 hour'; break;
          case 'day': timeLabel = 'tomorrow'; break;
          default: timeLabel = 'soon';
        }

        // Send notification
        await NotificationService.showLocalNotification(
          title: '⏰ Event Reminder',
          body: '$eventTitle starts $timeLabel!',
          payload: 'event:${reminder['event_id']}',
        );

        // Mark as sent
        await SupabaseService.client
            .from('event_reminders')
            .update({'is_sent': true})
            .eq('id', reminder['id']);
      }
    } catch (e) {
      LoggingService.error('Error processing reminders', e);
    }
  }
}

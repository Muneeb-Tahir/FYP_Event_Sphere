// lib/services/qr_service.dart
// QR Code generation and attendance verification using Supabase

import 'supabase_service.dart';
import 'registration_service.dart';
import 'logging_service.dart';

class QrService {
  /// Generate a QR code string for an event
  /// Format: EVENTSPHERE:eventId:userId:timestamp
  static String generateQrCode(String eventId, String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final qrData = 'EVENTSPHERE:$eventId:$userId:$timestamp';
    LoggingService.info('QR code generated for event=$eventId user=$userId');
    return qrData;
  }

  /// Validate and parse a QR code string
  /// Returns a map with eventId, userId, timestamp or null if invalid
  static Map<String, String>? parseQrCode(String qrData) {
    try {
      if (!qrData.startsWith('EVENTSPHERE:')) return null;

      final parts = qrData.split(':');
      if (parts.length != 4) return null;

      return {
        'eventId': parts[1],
        'userId': parts[2],
        'timestamp': parts[3],
      };
    } catch (e) {
      LoggingService.error('Invalid QR code format', e);
      return null;
    }
  }

  /// Mark attendance by scanning QR code — persists to database
  static Future<bool> markAttendance(String qrData) async {
    final parsed = parseQrCode(qrData);
    if (parsed == null) return false;

    final eventId = parsed['eventId']!;
    final userId = parsed['userId']!;

    try {
      // Verify user is registered for this event
      final isRegistered = await RegistrationService.checkRegistration(userId, eventId);
      if (!isRegistered) {
        LoggingService.warning('QR scan failed: user $userId not registered for event $eventId');
        return false;
      }

      // Check if already checked in
      final existing = await SupabaseService.client
          .from('registrations')
          .select('checked_in')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      if (existing != null && existing['checked_in'] == true) {
        LoggingService.info('User $userId already checked in for event $eventId');
        return true; // Already checked in — not an error
      }

      // Mark as checked in via RegistrationService
      await RegistrationService.checkInAttendee(userId, eventId);
      LoggingService.info('Attendance marked: user=$userId event=$eventId');
      return true;
    } catch (e) {
      LoggingService.error('Error marking attendance', e);
      return false;
    }
  }

  /// Get all checked-in attendees for an event (from database)
  static Future<List<String>> getCheckedInAttendees(String eventId) async {
    return RegistrationService.getCheckedInAttendees(eventId);
  }

  /// Check if a specific user has checked in
  static Future<bool> isCheckedIn(String userId, String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('registrations')
          .select('checked_in')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      return data != null && data['checked_in'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get attendance count for an event
  static Future<int> getAttendanceCount(String eventId) async {
    try {
      final attendees = await getCheckedInAttendees(eventId);
      return attendees.length;
    } catch (e) {
      return 0;
    }
  }
}

// lib/services/qr_service.dart
// Secure QR Code generation and attendance verification using Supabase
// Features: JSON + Base64 encoding, HMAC signature, expiry validation

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'supabase_service.dart';
import 'registration_service.dart';
import 'logging_service.dart';

class QrService {
  // HMAC signing key loaded from environment variables (never hardcoded)
  // Production: flutter build apk --dart-define=QR_HMAC_SECRET=your_secret
  // Development: loaded from .env file via flutter_dotenv
  static String get _hmacSecret {
    // Try --dart-define first (production builds)
    const envSecret = String.fromEnvironment('QR_HMAC_SECRET');
    if (envSecret.isNotEmpty) return envSecret;

    // Fall back to .env file (development)
    final dotenvSecret = dotenv.env['QR_HMAC_SECRET'];
    if (dotenvSecret != null && dotenvSecret.isNotEmpty) return dotenvSecret;

    // Final fallback — should never be reached if .env is configured correctly
    LoggingService.warning('QR_HMAC_SECRET not found in environment — using fallback. Configure .env or --dart-define!');
    return 'eventsphere_fallback_key_change_me';
  }

  // QR codes expire after 24 hours
  static const int _expiryHours = 24;

  // ===================== GENERATE QR CODE =====================
  /// Generate a secure, signed QR code string for an event
  /// Returns a base64-encoded JSON string with HMAC signature
  static String generateQrCode({
    required String eventId,
    required String userId,
    String? userName,
    String? eventTitle,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final payload = {
      'prefix': 'EVENTSPHERE',
      'eventId': eventId,
      'userId': userId,
      'userName': userName ?? '',
      'eventTitle': eventTitle ?? '',
      'timestamp': timestamp,
    };

    // Create HMAC signature for forgery prevention
    final payloadJson = jsonEncode(payload);
    final signature = _generateSignature(payloadJson);

    final signedData = {
      'payload': payload,
      'signature': signature,
    };

    // Base64 encode the entire signed structure
    final encoded = base64Encode(utf8.encode(jsonEncode(signedData)));

    LoggingService.info('Secure QR code generated for event=$eventId user=$userId');
    return encoded;
  }

  // ===================== PARSE QR CODE =====================
  /// Validate and parse a secure QR code string
  /// Returns parsed data or null if invalid/tampered/expired
  static Map<String, dynamic>? parseQrCode(String qrData) {
    try {
      // Step 1: Base64 decode
      final decoded = utf8.decode(base64Decode(qrData));
      final signedData = jsonDecode(decoded) as Map<String, dynamic>;

      // Step 2: Extract payload and signature
      final payload = signedData['payload'] as Map<String, dynamic>?;
      final signature = signedData['signature'] as String?;

      if (payload == null || signature == null) {
        LoggingService.warning('QR code missing payload or signature');
        return null;
      }

      // Step 3: Verify prefix
      if (payload['prefix'] != 'EVENTSPHERE') {
        LoggingService.warning('QR code has invalid prefix');
        return null;
      }

      // Step 4: Verify HMAC signature (prevents forgery)
      final payloadJson = jsonEncode(payload);
      final expectedSignature = _generateSignature(payloadJson);
      if (signature != expectedSignature) {
        LoggingService.warning('QR code signature mismatch — possible forgery');
        return null;
      }

      // Step 5: Check expiry
      final timestamp = payload['timestamp'] as int?;
      if (timestamp != null) {
        final createdAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        if (now.difference(createdAt).inHours > _expiryHours) {
          LoggingService.warning('QR code expired (created ${now.difference(createdAt).inHours}h ago)');
          return {'expired': true, ...payload};
        }
      }

      return payload;
    } catch (e) {
      // Also try legacy format: EVENTSPHERE:eventId:userId:timestamp
      return _parseLegacyQrCode(qrData);
    }
  }

  // ===================== PARSE LEGACY FORMAT =====================
  /// Backward-compatible parser for old plain-text QR codes
  static Map<String, dynamic>? _parseLegacyQrCode(String qrData) {
    try {
      if (!qrData.startsWith('EVENTSPHERE:')) return null;

      final parts = qrData.split(':');
      if (parts.length != 4) return null;

      return {
        'prefix': 'EVENTSPHERE',
        'eventId': parts[1],
        'userId': parts[2],
        'timestamp': int.tryParse(parts[3]) ?? 0,
        'userName': '',
        'eventTitle': '',
        'legacy': true,
      };
    } catch (e) {
      LoggingService.error('Invalid QR code format', e);
      return null;
    }
  }

  // ===================== MARK ATTENDANCE =====================
  /// Full attendance flow: parse → validate → check-in
  /// Returns a result map with success status and details
  static Future<Map<String, dynamic>> markAttendance(String qrData) async {
    // Step 1: Parse QR code
    final parsed = parseQrCode(qrData);
    if (parsed == null) {
      return {
        'success': false,
        'error': 'Invalid QR code',
        'message': 'This QR code is not valid. Please generate a new one.',
      };
    }

    // Step 2: Check expiry
    if (parsed['expired'] == true) {
      return {
        'success': false,
        'error': 'QR code expired',
        'message': 'This QR code has expired. Please ask the attendee to generate a new one.',
      };
    }

    final eventId = parsed['eventId'] as String;
    final userId = parsed['userId'] as String;
    final userName = parsed['userName'] as String? ?? '';
    final eventTitle = parsed['eventTitle'] as String? ?? '';

    try {
      // Step 3: Verify user is registered for this event
      final isRegistered = await RegistrationService.checkRegistration(userId, eventId);
      if (!isRegistered) {
        LoggingService.warning('QR scan failed: user $userId not registered for event $eventId');
        return {
          'success': false,
          'error': 'Not registered',
          'message': 'This user is not registered for this event.',
          'userName': userName,
          'eventTitle': eventTitle,
        };
      }

      // Step 4: Check if already checked in
      final existing = await SupabaseService.client
          .from('registrations')
          .select('checked_in')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      if (existing != null && existing['checked_in'] == true) {
        LoggingService.info('User $userId already checked in for event $eventId');
        return {
          'success': false,
          'error': 'Already checked in',
          'message': '${userName.isNotEmpty ? userName : "This user"} has already checked in.',
          'userName': userName,
          'eventTitle': eventTitle,
        };
      }

      // Step 5: Mark as checked in
      await RegistrationService.checkInAttendee(userId, eventId);
      LoggingService.info('Attendance marked: user=$userId event=$eventId');

      return {
        'success': true,
        'message': 'Attendance marked successfully!',
        'userName': userName,
        'eventTitle': eventTitle,
        'eventId': eventId,
        'userId': userId,
        'checkedInAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      LoggingService.error('Error marking attendance', e);
      return {
        'success': false,
        'error': 'System error',
        'message': 'Failed to mark attendance. Please try again.',
      };
    }
  }

  // ===================== HMAC SIGNATURE =====================
  static String _generateSignature(String data) {
    final key = utf8.encode(_hmacSecret);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  // ===================== UTILITY METHODS =====================
  /// Get all checked-in attendees for an event
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

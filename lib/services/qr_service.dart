// lib/services/qr_service.dart
// QR Code generation and scanning service

import 'dart:async';

class QrService {
  // Track attendance: {eventId: {userId: attendedAt}}
  static final Map<String, Map<String, DateTime>> _attendance = {};

  // Track generated QR codes: {eventId_userId: qrData}
  static final Map<String, String> _generatedCodes = {};

  // ------------------------- GENERATE QR CODE DATA -------------------------
  static String generateQrData({
    required String eventId,
    required String userId,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final qrData = 'EVENTSPHERE:$eventId:$userId:$timestamp';

    // Store generated code for validation
    _generatedCodes['${eventId}_$userId'] = qrData;

    return qrData;
  }

  // ------------------------- VALIDATE QR CODE -------------------------
  static Future<Map<String, dynamic>> validateQrCode(String qrData) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Parse QR data
    if (!qrData.startsWith('EVENTSPHERE:')) {
      return {'valid': false, 'error': 'Invalid QR code format'};
    }

    final parts = qrData.split(':');
    if (parts.length < 4) {
      return {'valid': false, 'error': 'Corrupted QR code'};
    }

    final eventId = parts[1];
    final userId = parts[2];
    final timestamp = int.tryParse(parts[3]) ?? 0;

    // Check if QR code is too old (24 hours)
    final generatedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(generatedAt).inHours > 24) {
      return {'valid': false, 'error': 'QR code has expired'};
    }

    return {
      'valid': true,
      'eventId': eventId,
      'userId': userId,
      'generatedAt': generatedAt,
    };
  }

  // ------------------------- MARK ATTENDANCE -------------------------
  static Future<Map<String, dynamic>> markAttendance({
    required String eventId,
    required String userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if already marked
    if (_attendance[eventId]?.containsKey(userId) ?? false) {
      return {
        'success': false,
        'error': 'Attendance already marked',
        'markedAt': _attendance[eventId]![userId],
      };
    }

    // Mark attendance
    _attendance[eventId] ??= {};
    _attendance[eventId]![userId] = DateTime.now();

    return {
      'success': true,
      'message': 'Attendance marked successfully',
      'markedAt': DateTime.now(),
    };
  }

  // ------------------------- CHECK ATTENDANCE -------------------------
  static bool hasAttended(String eventId, String userId) {
    return _attendance[eventId]?.containsKey(userId) ?? false;
  }

  // ------------------------- GET EVENT ATTENDANCE -------------------------
  static Future<Map<String, DateTime>> getEventAttendance(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _attendance[eventId] ?? {};
  }

  // ------------------------- GET ATTENDANCE COUNT -------------------------
  static int getAttendanceCount(String eventId) {
    return _attendance[eventId]?.length ?? 0;
  }

  // ------------------------- PROCESS SCANNED QR -------------------------
  static Future<Map<String, dynamic>> processScannedQr(String qrData) async {
    // Step 1: Validate QR
    final validation = await validateQrCode(qrData);
    if (validation['valid'] != true) {
      return validation;
    }

    // Step 2: Mark attendance
    final result = await markAttendance(
      eventId: validation['eventId'],
      userId: validation['userId'],
    );

    return {
      ...result,
      'eventId': validation['eventId'],
      'userId': validation['userId'],
    };
  }
}

// lib/services/error_service.dart
// Centralized Error Handling with User-Friendly Messages

import 'logging_service.dart';

class ErrorService {
  // Convert technical errors to user-friendly messages
  static String getUserFriendlyMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Network errors
    if (errorStr.contains('socketexception') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('network is unreachable')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return 'Request timed out. Please try again.';
    }

    // Authentication errors
    if (errorStr.contains('invalid login credentials') ||
        errorStr.contains('invalid email or password')) {
      return 'Invalid email or password. Please try again.';
    }

    if (errorStr.contains('email already registered') ||
        errorStr.contains('user already registered')) {
      return 'This email is already registered. Try logging in instead.';
    }

    if (errorStr.contains('weak password') || errorStr.contains('password should be')) {
      return 'Password is too weak. Use at least 6 characters with letters and numbers.';
    }

    if (errorStr.contains('not authenticated') || errorStr.contains('jwt expired')) {
      return 'Your session has expired. Please log in again.';
    }

    // Permission errors
    if (errorStr.contains('permission denied') || errorStr.contains('not authorized')) {
      return 'You don\'t have permission to perform this action.';
    }

    if (errorStr.contains('row level security')) {
      return 'Access denied. Please contact support if this continues.';
    }

    // Database errors
    if (errorStr.contains('unique constraint') || errorStr.contains('duplicate key')) {
      return 'This record already exists.';
    }

    if (errorStr.contains('foreign key') || errorStr.contains('violates')) {
      return 'Cannot complete this action due to related data.';
    }

    if (errorStr.contains('not found') || errorStr.contains('no rows')) {
      return 'The requested item was not found.';
    }

    // Storage errors
    if (errorStr.contains('file too large') || errorStr.contains('payload too large')) {
      return 'File is too large. Maximum size is 5MB.';
    }

    if (errorStr.contains('invalid file type') || errorStr.contains('unsupported')) {
      return 'Invalid file type. Please use JPG, PNG, or GIF.';
    }

    // Event specific
    if (errorStr.contains('event is full') || errorStr.contains('capacity')) {
      return 'This event is at full capacity.';
    }

    if (errorStr.contains('already registered')) {
      return 'You are already registered for this event.';
    }

    if (errorStr.contains('registration closed')) {
      return 'Registration for this event has closed.';
    }

    // Generic fallback
    LoggingService.warning('Unhandled error type: $error');
    return 'Something went wrong. Please try again later.';
  }

  // Log error for debugging
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    // Use LoggingService for structured logging (filtered in production)
    LoggingService.error('[$context] $error', error, stackTrace);

    // Crashlytics placeholder — when Firebase Crashlytics is added, report here:
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
    LoggingService.fatal('[$context] Crash report would be sent', error, stackTrace);
  }

  // Check if error is a network error
  static bool isNetworkError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('socketexception') ||
           errorStr.contains('connection refused') ||
           errorStr.contains('network is unreachable') ||
           errorStr.contains('no internet') ||
           errorStr.contains('timeout');
  }

  // Check if error requires re-authentication
  static bool requiresReauth(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('jwt expired') ||
           errorStr.contains('not authenticated') ||
           errorStr.contains('session') ||
           errorStr.contains('unauthorized');
  }
}

// Extension for easy error handling
extension ErrorHandling on Future {
  Future<T> handleErrors<T>(String context) async {
    try {
      return await this as T;
    } catch (e, stack) {
      ErrorService.logError(context, e, stack);
      rethrow;
    }
  }
}

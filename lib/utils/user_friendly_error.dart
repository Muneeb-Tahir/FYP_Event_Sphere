// lib/utils/user_friendly_error.dart
// Maps technical errors to user-friendly messages

import '../core/app_exception.dart';

/// Converts technical error messages to user-friendly ones
class UserFriendlyError {
  /// Convert any error to a user-friendly message
  static String getMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socketexception') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Request timed out. Please try again.';
    }

    // Authentication errors
    if (errorString.contains('unauthenticated') ||
        errorString.contains('unauthorized') ||
        errorString.contains('not logged in')) {
      return 'Please log in to continue.';
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('forbidden') ||
        errorString.contains('access denied')) {
      return 'You don\'t have permission for this action.';
    }

    // Not found errors
    if (errorString.contains('not found') ||
        errorString.contains('does not exist')) {
      return 'The requested item was not found.';
    }

    // Already exists errors
    if (errorString.contains('already exists') ||
        errorString.contains('duplicate') ||
        errorString.contains('unique')) {
      return 'This item already exists.';
    }

    // Validation errors
    if (errorString.contains('invalid') || errorString.contains('validation')) {
      return 'Please check your input and try again.';
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('server error') ||
        errorString.contains('internal')) {
      return 'Something went wrong on our end. Please try again later.';
    }

    // Registration errors
    if (errorString.contains('already registered')) {
      return 'You\'re already registered for this event.';
    }

    // Capacity errors
    if (errorString.contains('full') || errorString.contains('capacity')) {
      return 'This event is full. You can join the waitlist.';
    }

    // Default message
    return 'Something went wrong. Please try again.';
  }

  /// Get a title for error dialogs based on error type
  static String getTitle(dynamic error) {
    if (error is AppException) {
      if (error.isAuth) return 'Authentication Error';
      if (error.isNetwork) return 'Network Error';
      if (error.isPermission) return 'Permission Denied';
      if (error.isNotFound) return 'Not Found';
      if (error.isValidation) return 'Validation Error';
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('socket')) {
      return 'Connection Error';
    }
    if (errorString.contains('timeout')) {
      return 'Timeout';
    }
    if (errorString.contains('permission') || errorString.contains('forbidden')) {
      return 'Access Denied';
    }

    return 'Error';
  }
}

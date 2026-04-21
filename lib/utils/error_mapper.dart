// lib/utils/error_mapper.dart
// Maps Supabase/Auth errors to user-friendly messages

class ErrorMapper {
  // Map Supabase auth errors to friendly messages
  static String mapAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Supabase specific error messages
    if (errorString.contains('invalid login credentials') ||
        errorString.contains('invalid credentials')) {
      return 'Invalid email or password. Please try again.';
    }

    if (errorString.contains('email not confirmed')) {
      return 'Please verify your email before logging in.';
    }

    if (errorString.contains('user already registered') ||
        errorString.contains('user already exists')) {
      return 'An account with this email already exists.';
    }

    if (errorString.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    if (errorString.contains('weak password') ||
        errorString.contains('password should be')) {
      return 'Password is too weak. Use at least 6 characters.';
    }

    if (errorString.contains('email rate limit exceeded')) {
      return 'Too many attempts. Please try again later.';
    }

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket')) {
      return 'Network error. Please check your internet connection.';
    }

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (errorString.contains('unauthorized') ||
        errorString.contains('not authenticated')) {
      return 'Session expired. Please log in again.';
    }

    if (errorString.contains('forbidden') ||
        errorString.contains('not allowed')) {
      return 'You don\'t have permission to perform this action.';
    }

    if (errorString.contains('not found')) {
      return 'The requested resource was not found.';
    }

    if (errorString.contains('already registered')) {
      return 'You are already registered for this event.';
    }

    if (errorString.contains('event is full') ||
        errorString.contains('capacity')) {
      return 'This event is at full capacity.';
    }

    // Default error message
    return 'An error occurred. Please try again.';
  }

  // Map database errors to friendly messages
  static String mapDatabaseError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('duplicate key') ||
        errorString.contains('unique constraint')) {
      return 'This record already exists.';
    }

    if (errorString.contains('foreign key')) {
      return 'Cannot complete this action due to related data.';
    }

    if (errorString.contains('rls') ||
        errorString.contains('row-level security')) {
      return 'You don\'t have permission to access this data.';
    }

    if (errorString.contains('violates check constraint')) {
      return 'Invalid data provided.';
    }

    return mapAuthError(error); // Fallback to auth error mapper
  }

  // Map storage errors to friendly messages
  static String mapStorageError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('file too large') ||
        errorString.contains('payload too large')) {
      return 'File is too large. Maximum size is 5MB.';
    }

    if (errorString.contains('invalid file type') ||
        errorString.contains('mime type')) {
      return 'Invalid file type. Please upload an image.';
    }

    if (errorString.contains('bucket not found')) {
      return 'Storage not configured. Please contact support.';
    }

    if (errorString.contains('permission denied') ||
        errorString.contains('not authorized')) {
      return 'You don\'t have permission to upload files.';
    }

    return mapAuthError(error); // Fallback
  }

  // Get action-specific error messages
  static String getActionError(String action, dynamic error) {
    final baseError = mapDatabaseError(error);

    switch (action) {
      case 'login':
        return 'Failed to sign in: $baseError';
      case 'signup':
        return 'Failed to create account: $baseError';
      case 'register':
        return 'Failed to register: $baseError';
      case 'upload':
        return 'Failed to upload: ${mapStorageError(error)}';
      case 'delete':
        return 'Failed to delete: $baseError';
      case 'update':
        return 'Failed to update: $baseError';
      default:
        return baseError;
    }
  }
}

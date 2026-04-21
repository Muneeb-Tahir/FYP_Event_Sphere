// lib/core/app_exception.dart
// Typed exception handling for better error management

import 'package:supabase_flutter/supabase_flutter.dart';

/// Base exception class for the app
class AppException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code = 'unknown',
    this.originalError,
    this.stackTrace,
  });

  /// Factory for database errors
  factory AppException.database(String message, {dynamic error, StackTrace? stack}) {
    return AppException(
      message: message,
      code: 'database_error',
      originalError: error,
      stackTrace: stack,
    );
  }

  /// Factory for authentication errors
  factory AppException.auth(String message, {dynamic error, StackTrace? stack}) {
    return AppException(
      message: message,
      code: 'auth_error',
      originalError: error,
      stackTrace: stack,
    );
  }

  /// Factory for network errors
  factory AppException.network(String message, {dynamic error, StackTrace? stack}) {
    return AppException(
      message: message,
      code: 'network_error',
      originalError: error,
      stackTrace: stack,
    );
  }

  /// Factory for validation errors
  factory AppException.validation(String message, {dynamic error, StackTrace? stack}) {
    return AppException(
      message: message,
      code: 'validation_error',
      originalError: error,
      stackTrace: stack,
    );
  }

  /// Factory for permission errors
  factory AppException.permission(String message, {dynamic error, StackTrace? stack}) {
    return AppException(
      message: message,
      code: 'permission_error',
      originalError: error,
      stackTrace: stack,
    );
  }

  /// Factory for not found errors
  factory AppException.notFound(String resource) {
    return AppException(
      message: '$resource not found',
      code: 'not_found',
    );
  }

  /// Factory from Supabase PostgrestException
  factory AppException.fromPostgrest(PostgrestException e, {StackTrace? stack}) {
    String userMessage = 'Database operation failed';

    // Map common error codes to user-friendly messages
    switch (e.code) {
      case '23505': // unique_violation
        userMessage = 'This record already exists';
        break;
      case '23503': // foreign_key_violation
        userMessage = 'Cannot delete: record is in use';
        break;
      case '42501': // insufficient_privilege
        userMessage = 'You don\'t have permission for this action';
        break;
      case 'PGRST116': // not found in single()
        userMessage = 'Record not found';
        break;
      default:
        userMessage = e.message;
    }

    return AppException(
      message: userMessage,
      code: e.code ?? 'database_error',
      originalError: e,
      stackTrace: stack,
    );
  }

  /// Factory from Supabase AuthException
  factory AppException.fromAuth(AuthException e, {StackTrace? stack}) {
    String userMessage = 'Authentication failed';

    // Map common auth errors
    if (e.message.contains('Invalid login credentials')) {
      userMessage = 'Invalid email or password';
    } else if (e.message.contains('Email not confirmed')) {
      userMessage = 'Please verify your email first';
    } else if (e.message.contains('Token expired')) {
      userMessage = 'Session expired, please log in again';
    } else {
      userMessage = e.message;
    }

    return AppException(
      message: userMessage,
      code: e.statusCode ?? 'auth_error',
      originalError: e,
      stackTrace: stack,
    );
  }

  @override
  String toString() => 'AppException($code): $message';

  /// Check if this is a specific error type
  bool get isDatabase => code == 'database_error';
  bool get isAuth => code == 'auth_error';
  bool get isNetwork => code == 'network_error';
  bool get isValidation => code == 'validation_error';
  bool get isPermission => code == 'permission_error';
  bool get isNotFound => code == 'not_found';
}

// lib/services/logging_service.dart
// Centralized logging with log levels

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging service for the application.
/// Provides different log levels and formatted output.
class LoggingService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    filter: kReleaseMode ? ProductionFilter() : DevelopmentFilter(),
  );

  /// Log a verbose/trace message (most detailed)
  static void trace(String message, [dynamic data]) {
    _logger.t(data != null ? '$message: $data' : message);
  }

  /// Log a debug message (development info)
  static void debug(String message, [dynamic data]) {
    _logger.d(data != null ? '$message: $data' : message);
  }

  /// Log an info message (general information)
  static void info(String message, [dynamic data]) {
    _logger.i(data != null ? '$message: $data' : message);
  }

  /// Log a warning message (potential issues)
  static void warning(String message, [dynamic data]) {
    _logger.w(data != null ? '$message: $data' : message);
  }

  /// Log an error message with optional exception and stack trace
  /// Accepts error as either positional or named parameter for flexibility
  static void error(String message, [Object? errorPositional, StackTrace? stackTracePositional]) {
    _logger.e(message, error: errorPositional, stackTrace: stackTracePositional);
  }

  /// Log a fatal/critical error
  static void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // ===================== Context-specific logging =====================

  /// Log API calls
  static void api(String endpoint, {String method = 'GET', dynamic body, int? statusCode}) {
    final sb = StringBuffer('[$method] $endpoint');
    if (statusCode != null) sb.write(' -> $statusCode');
    if (body != null && kDebugMode) {
      _logger.d('${sb.toString()}\n$body');
    } else {
      _logger.d(sb.toString());
    }
  }

  /// Log navigation events
  static void navigation(String from, String to) {
    _logger.i('Navigation: $from -> $to');
  }

  /// Log user actions
  static void userAction(String action, [Map<String, dynamic>? details]) {
    if (details != null) {
      _logger.i('User Action: $action - $details');
    } else {
      _logger.i('User Action: $action');
    }
  }

  /// Log auth events
  static void auth(String event, {String? userId, bool success = true}) {
    final status = success ? '✓' : '✗';
    final user = userId != null ? ' [$userId]' : '';
    _logger.i('Auth$user $status: $event');
  }

  /// Log performance metrics
  static void performance(String operation, Duration duration) {
    final ms = duration.inMilliseconds;
    if (ms > 1000) {
      _logger.w('Performance: $operation took ${ms}ms (slow!)');
    } else {
      _logger.d('Performance: $operation took ${ms}ms');
    }
  }

  /// Log database operations
  static void database(String operation, String? table, {int? count}) {
    final tableStr = table != null ? ' on $table' : '';
    final countStr = count != null ? ' ($count rows)' : '';
    _logger.d('DB: $operation$tableStr$countStr');
  }

  /// Log cache operations
  static void cache(String operation, {String? key, bool hit = false}) {
    final hitStr = operation == 'read' ? (hit ? ' [HIT]' : ' [MISS]') : '';
    final keyStr = key != null ? ' key=$key' : '';
    _logger.t('Cache: $operation$keyStr$hitStr');
  }
}

/// Production filter that only logs warnings and errors
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return event.level.index >= Level.warning.index;
  }
}

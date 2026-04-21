// lib/utils/sanitizer.dart
// Input sanitization utilities for security
//
// NOTE ON DATABASE SANITIZATION:
// Supabase uses parameterized queries internally, so sanitizeForDb() is
// redundant for SQL injection prevention. It is kept for backward compatibility
// but marked as @Deprecated. The HTML sanitize() method is still useful
// for user content rendered in email templates or WebViews.

/// Sanitizes user input to prevent XSS and other injection attacks
class Sanitizer {
  // Characters that could be dangerous in HTML context
  static final RegExp _htmlPattern = RegExp(r'[<>&"''/]');

  // SQL injection patterns
  static final RegExp _sqlPattern = RegExp(
    r"('|--|;|/\*|\*/|xp_|sp_|exec|execute|insert|select|delete|update|drop|create|alter|truncate)",
    caseSensitive: false,
  );

  // Script patterns
  static final RegExp _scriptPattern = RegExp(
    r'(javascript:|data:|vbscript:|on\w+\s*=)',
    caseSensitive: false,
  );

  /// Sanitize text for general use (removes dangerous characters)
  static String sanitize(String? input) {
    if (input == null || input.isEmpty) return '';

    String result = input;

    // Escape HTML entities
    result = result
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');

    // Remove potential script injection
    result = result.replaceAll(_scriptPattern, '');

    return result.trim();
  }

  /// Sanitize for plain text (strips all HTML)
  static String sanitizePlainText(String? input) {
    if (input == null || input.isEmpty) return '';

    // Remove all HTML tags
    String result = input.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode HTML entities back to text
    result = result
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll('&nbsp;', ' ');

    return result.trim();
  }

  /// Sanitize email address
  static String? sanitizeEmail(String? email) {
    if (email == null || email.isEmpty) return null;

    // Remove whitespace and convert to lowercase
    String result = email.trim().toLowerCase();

    // Only allow valid email characters
    result = result.replaceAll(RegExp(r'[^a-z0-9@._+-]'), '');

    // Validate format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(result)) return null;

    return result;
  }

  /// Sanitize for database queries (prevent SQL injection)
  static String sanitizeForDb(String? input) {
    if (input == null || input.isEmpty) return '';

    String result = input;

    // Remove SQL injection patterns
    result = result.replaceAll(_sqlPattern, '');

    // Escape single quotes (critical for SQL)
    result = result.replaceAll("'", "''");

    return result.trim();
  }

  /// Sanitize URL
  static String? sanitizeUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    String result = url.trim();

    // Block dangerous protocols
    if (result.toLowerCase().startsWith('javascript:') ||
        result.toLowerCase().startsWith('data:') ||
        result.toLowerCase().startsWith('vbscript:')) {
      return null;
    }

    // Ensure it starts with http:// or https://
    if (!result.startsWith('http://') && !result.startsWith('https://')) {
      // Add https:// if no protocol
      if (!result.contains('://')) {
        result = 'https://$result';
      }
    }

    return result;
  }

  /// Sanitize phone number (digits and + only)
  static String? sanitizePhone(String? phone) {
    if (phone == null || phone.isEmpty) return null;

    // Keep only digits, +, spaces, and dashes
    String result = phone.replaceAll(RegExp(r'[^\d+\s-]'), '');
    result = result.trim();

    // Must have at least 10 digits
    final digits = result.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return null;

    return result;
  }

  /// Sanitize name (letters, spaces, hyphens, apostrophes only)
  static String sanitizeName(String? name) {
    if (name == null || name.isEmpty) return '';

    // Keep only letters, spaces, hyphens, apostrophes
    String result = name.replaceAll(RegExp(r"[^a-zA-Z\s'-]"), '');

    // Normalize whitespace
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    return result.trim();
  }

  /// Sanitize filename
  static String sanitizeFilename(String? filename) {
    if (filename == null || filename.isEmpty) return 'file';

    // Remove path separators and null bytes
    String result = filename
        .replaceAll(RegExp(r'[/\\:\*\?"<>\|]'), '_')
        .replaceAll('\x00', '');

    // Limit length
    if (result.length > 255) {
      final ext = result.contains('.')
          ? result.substring(result.lastIndexOf('.'))
          : '';
      result = result.substring(0, 255 - ext.length) + ext;
    }

    return result;
  }

  /// Check if input contains potentially dangerous content
  static bool containsDangerousContent(String? input) {
    if (input == null || input.isEmpty) return false;

    return _htmlPattern.hasMatch(input) ||
           _sqlPattern.hasMatch(input) ||
           _scriptPattern.hasMatch(input);
  }

  /// Sanitize a map of values (useful for form data)
  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is String) {
        return MapEntry(key, sanitize(value));
      }
      return MapEntry(key, value);
    });
  }
}

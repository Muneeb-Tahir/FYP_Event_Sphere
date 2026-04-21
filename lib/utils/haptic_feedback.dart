// lib/utils/haptic_feedback.dart
// Haptic feedback utility for better UX

import 'package:flutter/services.dart';

/// Provides consistent haptic feedback across the app
class HapticUtils {
  /// Light impact - for subtle interactions like toggles, selections
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact - for standard button presses, confirmations
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for important actions like delete, submit
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Selection click - for list item selections, tab switches
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate - for notifications, alerts
  static void vibrate() {
    HapticFeedback.vibrate();
  }

  /// Success feedback - light vibration for successful actions
  static void success() {
    HapticFeedback.lightImpact();
  }

  /// Error feedback - medium vibration for errors
  static void error() {
    HapticFeedback.mediumImpact();
  }

  /// Warning feedback - heavy vibration for warnings
  static void warning() {
    HapticFeedback.heavyImpact();
  }
}

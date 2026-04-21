// lib/utils/accessibility.dart
// Accessibility utilities for improved a11y

import 'package:flutter/material.dart';

/// Extension methods for adding accessibility features to widgets
extension AccessibilityExtension on Widget {
  /// Wrap widget with semantic label for screen readers
  Widget withSemanticLabel(String label) {
    return Semantics(
      label: label,
      child: this,
    );
  }

  /// Mark widget as a button for screen readers
  Widget asSemanticButton({
    required String label,
    String? hint,
    bool enabled = true,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: enabled,
      child: this,
    );
  }

  /// Mark widget as a header for screen readers
  Widget asSemanticHeader(String label) {
    return Semantics(
      label: label,
      header: true,
      child: this,
    );
  }

  /// Mark widget as an image for screen readers
  Widget asSemanticImage(String description) {
    return Semantics(
      label: description,
      image: true,
      child: this,
    );
  }

  /// Mark widget as a link for screen readers
  Widget asSemanticLink(String label) {
    return Semantics(
      label: label,
      link: true,
      child: this,
    );
  }

  /// Exclude widget from semantics tree
  Widget excludeFromSemantics() {
    return ExcludeSemantics(child: this);
  }
}

/// Accessible color utilities
class AccessibleColors {
  /// Check if text color has sufficient contrast with background
  static bool hasGoodContrast(Color foreground, Color background) {
    final ratio = _contrastRatio(foreground, background);
    return ratio >= 4.5; // WCAG AA standard for normal text
  }

  /// Check if large text has sufficient contrast
  static bool hasGoodContrastLargeText(Color foreground, Color background) {
    final ratio = _contrastRatio(foreground, background);
    return ratio >= 3.0; // WCAG AA standard for large text
  }

  /// Get contrast ratio between two colors
  static double _contrastRatio(Color foreground, Color background) {
    final fLuminance = foreground.computeLuminance();
    final bLuminance = background.computeLuminance();

    final lighter = fLuminance > bLuminance ? fLuminance : bLuminance;
    final darker = fLuminance > bLuminance ? bLuminance : fLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Get the best text color (black or white) for a given background
  static Color getTextColor(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  /// Adjust color for better contrast if needed
  static Color ensureContrast(Color foreground, Color background) {
    if (hasGoodContrast(foreground, background)) {
      return foreground;
    }
    return getTextColor(background);
  }
}

/// Accessible tap target sizes
class AccessibleSizes {
  /// Minimum touch target size according to WCAG 2.5.5
  static const double minTouchTarget = 44.0;

  /// Recommended touch target size
  static const double recommendedTouchTarget = 48.0;

  /// Ensure minimum tap target size
  static Widget ensureMinTapTarget({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: minTouchTarget,
          minHeight: minTouchTarget,
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// Accessible text scaling
class AccessibleText {
  /// Get scaled font size respecting user preferences
  static double getScaledFontSize(BuildContext context, double baseSize) {
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);
    return baseSize * textScaleFactor;
  }

  /// Create text widget that respects accessibility settings
  static Widget accessibleText(
    String text, {
    TextStyle? style,
    String? semanticLabel,
    int? maxLines,
  }) {
    return Semantics(
      label: semanticLabel ?? text,
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      ),
    );
  }
}

/// Focus utilities for keyboard navigation
class FocusUtils {
  /// Request focus for keyboard navigation
  static void requestFocus(BuildContext context, FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }

  /// Move focus to next widget
  static void nextFocus(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Move focus to previous widget
  static void previousFocus(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Unfocus all widgets
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}

/// Accessible icon button with minimum touch target
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final double size;
  final Color? color;
  final String? tooltip;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.size = 24,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: Tooltip(
        message: tooltip ?? semanticLabel,
        child: IconButton(
          icon: Icon(icon, size: size, color: color),
          onPressed: onPressed,
          constraints: const BoxConstraints(
            minWidth: AccessibleSizes.minTouchTarget,
            minHeight: AccessibleSizes.minTouchTarget,
          ),
        ),
      ),
    );
  }
}

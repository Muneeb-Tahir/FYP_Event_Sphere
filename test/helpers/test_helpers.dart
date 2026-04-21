// test/helpers/test_helpers.dart
// Common test utilities and setup helpers

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Creates a testable widget wrapped with necessary providers
Widget testableWidget(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      home: child,
    ),
  );
}

/// Creates a testable widget with custom theme
Widget testableWidgetWithTheme(Widget child, {
  ThemeData? theme,
  List<Override>? overrides,
}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      theme: theme ?? ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: child,
    ),
  );
}

/// Creates a scaffold wrapped testable widget
Widget testableScaffold(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

/// Extension for common widget test operations
extension WidgetTesterExtension on WidgetTester {
  /// Pump and settle with extended timeout
  Future<void> pumpAndSettleExtended({Duration? duration}) async {
    await pumpAndSettle(
      duration ?? const Duration(seconds: 5),
    );
  }

  /// Tap and settle
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Enter text and settle
  Future<void> enterTextAndSettle(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettle();
  }

  /// Scroll until visible
  Future<void> scrollUntilVisible(
    Finder finder, {
    Finder? scrollable,
    double delta = 100,
  }) async {
    while (!any(finder)) {
      await drag(
        scrollable ?? find.byType(Scrollable).first,
        Offset(0, -delta),
      );
      await pump();
    }
  }
}

/// Common test finders
class TestFinders {
  static Finder byTooltip(String tooltip) => find.byTooltip(tooltip);
  static Finder byKey(String key) => find.byKey(Key(key));
  static Finder byIcon(IconData icon) => find.byIcon(icon);
  static Finder byText(String text) => find.text(text);
  static Finder textContaining(String text) => find.textContaining(text);
  static Finder byType<T extends Widget>() => find.byType(T);
  static Finder button(String text) => find.widgetWithText(ElevatedButton, text);
  static Finder textButton(String text) => find.widgetWithText(TextButton, text);
}

/// Mock navigator observer for testing navigation
class MockNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];
  final List<Route<dynamic>> poppedRoutes = [];
  final List<Route<dynamic>> replacedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    poppedRoutes.add(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) replacedRoutes.add(newRoute);
  }

  void clear() {
    pushedRoutes.clear();
    poppedRoutes.clear();
    replacedRoutes.clear();
  }
}

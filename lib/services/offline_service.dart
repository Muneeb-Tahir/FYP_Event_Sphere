// lib/services/offline_service.dart
// Offline support with connectivity detection and sync

import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/event.dart';
import 'logging_service.dart';
import 'registration_service.dart';
import 'bookmark_service.dart';

/// Represents a pending offline action to sync when online
class OfflineAction {
  final String id;
  final String type; // 'register', 'unregister', 'bookmark', 'unbookmark'
  final Map<String, dynamic> data;
  final DateTime createdAt;

  OfflineAction({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
  };

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
    id: json['id'],
    type: json['type'],
    data: Map<String, dynamic>.from(json['data']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class OfflineService {
  static const String _eventsBoxName = 'cached_events';
  static const String _actionsBoxName = 'offline_actions';

  static Box? _eventsBox;
  static Box? _actionsBox;

  static bool _isOnline = true;
  static final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  static StreamSubscription? _connectivitySubscription;

  /// Initialize the offline service
  /// NOTE: Hive.initFlutter() is NOT called here — CacheService.initialize()
  /// is called first in main.dart and handles Hive initialization.
  static Future<void> initialize() async {
    _eventsBox = await Hive.openBox(_eventsBoxName);
    _actionsBox = await Hive.openBox(_actionsBoxName);

    // Start monitoring connectivity
    _startConnectivityMonitoring();

    // Check initial connectivity
    await _checkConnectivity();
  }

  /// Start monitoring connectivity changes
  static void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final wasOnline = _isOnline;
        _isOnline = results.isNotEmpty &&
            !results.contains(ConnectivityResult.none);

        _connectivityController.add(_isOnline);

        // Sync pending actions when coming back online
        if (!wasOnline && _isOnline) {
          await syncPendingActions();
        }
      },
    );
  }

  /// Check current connectivity status
  static Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);
    _connectivityController.add(_isOnline);
  }

  /// Stream of connectivity changes
  static Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current online status
  static bool get isOnline => _isOnline;

  // ============================================================================
  // EVENT CACHING
  // ============================================================================

  /// Cache events for offline viewing
  static Future<void> cacheEvents(List<Event> events) async {
    if (_eventsBox == null) return;

    final eventsData = events.map((e) => e.toMap()).toList();
    await _eventsBox!.put('events', jsonEncode(eventsData));
    await _eventsBox!.put('lastCached', DateTime.now().toIso8601String());
  }

  /// Get cached events
  static List<Event>? getCachedEvents() {
    if (_eventsBox == null) return null;

    final data = _eventsBox!.get('events');
    if (data == null) return null;

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Event.fromMap(e)).toList();
    } catch (e) {
      LoggingService.error('Error loading cached events', e);
      return null;
    }
  }

  /// Get last cache timestamp
  static DateTime? getLastCacheTime() {
    if (_eventsBox == null) return null;

    final timeStr = _eventsBox!.get('lastCached');
    if (timeStr == null) return null;

    return DateTime.tryParse(timeStr);
  }

  /// Check if cache is stale (>5 minutes old)
  static bool isCacheStale() {
    final lastCached = getLastCacheTime();
    if (lastCached == null) return true;

    return DateTime.now().difference(lastCached).inMinutes > 5;
  }

  // ============================================================================
  // OFFLINE ACTION QUEUE
  // ============================================================================

  /// Queue an action to be performed when online
  static Future<void> queueAction(OfflineAction action) async {
    if (_actionsBox == null) return;

    final actions = _getPendingActions();

    // Check for duplicate action
    final existingIndex = actions.indexWhere(
      (a) => a.type == action.type &&
             jsonEncode(a.data) == jsonEncode(action.data)
    );

    if (existingIndex >= 0) {
      // Replace existing action with newer one
      actions[existingIndex] = action;
    } else {
      actions.add(action);
    }

    await _saveActions(actions);
  }

  /// Remove a queued action (for cancellation/opposite action)
  static Future<void> removeQueuedAction(String type, Map<String, dynamic> data) async {
    if (_actionsBox == null) return;

    final actions = _getPendingActions();
    actions.removeWhere(
      (a) => a.type == type && jsonEncode(a.data) == jsonEncode(data)
    );

    await _saveActions(actions);
  }

  /// Get all pending actions
  static List<OfflineAction> _getPendingActions() {
    if (_actionsBox == null) return [];

    final data = _actionsBox!.get('pending');
    if (data == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => OfflineAction.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get pending action count
  static int get pendingActionCount => _getPendingActions().length;

  /// Save actions to storage
  static Future<void> _saveActions(List<OfflineAction> actions) async {
    await _actionsBox!.put(
      'pending',
      jsonEncode(actions.map((a) => a.toJson()).toList())
    );
  }

  /// Sync all pending actions when online
  static Future<SyncResult> syncPendingActions() async {
    if (!_isOnline) {
      return SyncResult(success: false, message: 'Still offline');
    }

    final actions = _getPendingActions();
    if (actions.isEmpty) {
      return SyncResult(success: true, message: 'No pending actions');
    }

    int synced = 0;
    int failed = 0;
    final List<OfflineAction> failedActions = [];

    for (final action in actions) {
      try {
        await _executeAction(action);
        synced++;
      } catch (e) {
        LoggingService.error('Failed to sync action ${action.type}', e);
        failedActions.add(action);
        failed++;
      }
    }

    // Save failed actions back to queue
    await _saveActions(failedActions);

    return SyncResult(
      success: failed == 0,
      synced: synced,
      failed: failed,
      message: 'Synced $synced actions, $failed failed',
    );
  }

  /// Execute a single offline action by calling the appropriate service
  static Future<void> _executeAction(OfflineAction action) async {
    final userId = action.data['user_id'] as String?;
    final eventId = action.data['event_id'] as String?;

    if (userId == null || eventId == null) {
      LoggingService.warning('Skipping offline action ${action.type}: missing user_id or event_id');
      return;
    }

    switch (action.type) {
      case 'register':
        await RegistrationService.registerForEvent(userId, eventId);
        LoggingService.info('Synced offline registration: user=$userId event=$eventId');
        break;
      case 'unregister':
        await RegistrationService.unregisterFromEvent(userId, eventId);
        LoggingService.info('Synced offline unregistration: user=$userId event=$eventId');
        break;
      case 'bookmark':
        await BookmarkService.addBookmark(userId, eventId);
        LoggingService.info('Synced offline bookmark: user=$userId event=$eventId');
        break;
      case 'unbookmark':
        await BookmarkService.removeBookmark(userId, eventId);
        LoggingService.info('Synced offline unbookmark: user=$userId event=$eventId');
        break;
      default:
        throw Exception('Unknown action type: ${action.type}');
    }
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Clear all cached data
  static Future<void> clearCache() async {
    await _eventsBox?.clear();
    await _actionsBox?.clear();
  }

  /// Dispose resources
  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int synced;
  final int failed;
  final String message;

  SyncResult({
    required this.success,
    this.synced = 0,
    this.failed = 0,
    required this.message,
  });
}

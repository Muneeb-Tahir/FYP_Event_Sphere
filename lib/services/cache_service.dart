// lib/services/cache_service.dart
// Hive Local Cache for Offline Support

import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'logging_service.dart';

class CacheService {
  static late Box<Map> _eventsBox;
  static late Box<Map> _bookmarksBox;
  static late Box<Map> _userBox;
  static late Box<String> _settingsBox;

  static bool _isOnline = true;
  static StreamSubscription? _connectivitySubscription;
  static final _onlineController = StreamController<bool>.broadcast();

  static bool get isOnline => _isOnline;
  static Stream<bool> get onlineStream => _onlineController.stream;

  // ===================== INITIALIZE =====================
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();

      // Open boxes
      _eventsBox = await Hive.openBox<Map>('events_cache');
      _bookmarksBox = await Hive.openBox<Map>('bookmarks_cache');
      _userBox = await Hive.openBox<Map>('user_cache');
      _settingsBox = await Hive.openBox<String>('settings_cache');

      // Initialize connectivity listener
      await _initConnectivity();

      LoggingService.info('CacheService initialized successfully');
    } catch (e) {
      LoggingService.error('CacheService init error', e);
    }
  }

  // ===================== CONNECTIVITY =====================
  static Future<void> _initConnectivity() async {
    // Check initial connectivity
    final results = await Connectivity().checkConnectivity();
    _updateConnectivity(results);

    // Listen for changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectivity);
  }

  static void _updateConnectivity(List<ConnectivityResult> results) {
    _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    _onlineController.add(_isOnline);
    LoggingService.debug('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
  }

  // ===================== CACHE EVENTS =====================
  static Future<void> cacheEvents(List<Map<String, dynamic>> events) async {
    try {
      for (var event in events) {
        final id = event['id'] as String;
        event['cached_at'] = DateTime.now().toIso8601String();
        await _eventsBox.put(id, event);
      }
      LoggingService.debug('Cached ${events.length} events');
    } catch (e) {
      LoggingService.error('Failed to cache events', e);
    }
  }

  static Future<void> cacheEvent(Map<String, dynamic> event) async {
    try {
      final id = event['id'] as String;
      event['cached_at'] = DateTime.now().toIso8601String();
      await _eventsBox.put(id, event);
    } catch (e) {
      LoggingService.error('Failed to cache event', e);
    }
  }

  static List<Map<String, dynamic>> getCachedEvents() {
    try {
      return _eventsBox.values
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      LoggingService.error('Failed to get cached events', e);
      return [];
    }
  }

  static Map<String, dynamic>? getCachedEvent(String id) {
    try {
      final event = _eventsBox.get(id);
      return event != null ? Map<String, dynamic>.from(event) : null;
    } catch (e) {
      LoggingService.error('Failed to get cached event', e);
      return null;
    }
  }

  // ===================== CACHE BOOKMARKS =====================
  static Future<void> cacheBookmarks(List<Map<String, dynamic>> bookmarks) async {
    try {
      await _bookmarksBox.clear();
      for (var bookmark in bookmarks) {
        final id = bookmark['event_id'] ?? bookmark['id'];
        await _bookmarksBox.put(id, bookmark);
      }
      LoggingService.debug('Cached ${bookmarks.length} bookmarks');
    } catch (e) {
      LoggingService.error('Failed to cache bookmarks', e);
    }
  }

  static List<Map<String, dynamic>> getCachedBookmarks() {
    try {
      return _bookmarksBox.values
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      LoggingService.error('Failed to get cached bookmarks', e);
      return [];
    }
  }

  static Future<void> addBookmark(Map<String, dynamic> bookmark) async {
    try {
      final id = bookmark['event_id'] ?? bookmark['id'];
      await _bookmarksBox.put(id, bookmark);
    } catch (e) {
      LoggingService.error('Failed to add bookmark', e);
    }
  }

  static Future<void> removeBookmark(String eventId) async {
    try {
      await _bookmarksBox.delete(eventId);
    } catch (e) {
      LoggingService.error('Failed to remove bookmark', e);
    }
  }

  static bool isBookmarked(String eventId) {
    return _bookmarksBox.containsKey(eventId);
  }

  // ===================== CACHE USER DATA =====================
  static Future<void> cacheUser(Map<String, dynamic> user) async {
    try {
      await _userBox.put('current_user', user);
    } catch (e) {
      LoggingService.error('Failed to cache user', e);
    }
  }

  static Map<String, dynamic>? getCachedUser() {
    try {
      final user = _userBox.get('current_user');
      return user != null ? Map<String, dynamic>.from(user) : null;
    } catch (e) {
      LoggingService.error('Failed to get cached user', e);
      return null;
    }
  }

  static Future<void> clearUserCache() async {
    await _userBox.clear();
  }

  // ===================== SETTINGS CACHE =====================
  static Future<void> saveSetting(String key, String value) async {
    await _settingsBox.put(key, value);
  }

  static String? getSetting(String key) {
    return _settingsBox.get(key);
  }

  // ===================== CLEAR ALL CACHE =====================
  static Future<void> clearAll() async {
    await _eventsBox.clear();
    await _bookmarksBox.clear();
    await _userBox.clear();
    await _settingsBox.clear();
    LoggingService.info('All cache cleared');
  }

  // ===================== CACHE SIZE =====================
  static int get eventsCacheSize => _eventsBox.length;
  static int get bookmarksCacheSize => _bookmarksBox.length;

  // ===================== DISPOSE =====================
  static void dispose() {
    _connectivitySubscription?.cancel();
    _onlineController.close();
  }
}

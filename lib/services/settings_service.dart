// lib/services/settings_service.dart
// App settings with Hive persistence

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'logging_service.dart';

class NotificationSettings {
  final bool eventReminders;
  final bool newAnnouncements;
  final bool pollNotifications;
  final bool chatMessages;
  final bool emailNotifications;
  final bool newEvents;

  NotificationSettings({
    this.eventReminders = true,
    this.newAnnouncements = true,
    this.pollNotifications = true,
    this.chatMessages = true,
    this.emailNotifications = false,
    this.newEvents = true,
  });

  NotificationSettings copyWith({
    bool? eventReminders,
    bool? newAnnouncements,
    bool? pollNotifications,
    bool? chatMessages,
    bool? emailNotifications,
    bool? newEvents,
  }) {
    return NotificationSettings(
      eventReminders: eventReminders ?? this.eventReminders,
      newAnnouncements: newAnnouncements ?? this.newAnnouncements,
      pollNotifications: pollNotifications ?? this.pollNotifications,
      chatMessages: chatMessages ?? this.chatMessages,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      newEvents: newEvents ?? this.newEvents,
    );
  }

  Map<String, dynamic> toMap() => {
    'eventReminders': eventReminders,
    'newAnnouncements': newAnnouncements,
    'pollNotifications': pollNotifications,
    'chatMessages': chatMessages,
    'emailNotifications': emailNotifications,
    'newEvents': newEvents,
  };

  factory NotificationSettings.fromMap(Map<dynamic, dynamic> map) {
    return NotificationSettings(
      eventReminders: map['eventReminders'] ?? true,
      newAnnouncements: map['newAnnouncements'] ?? true,
      pollNotifications: map['pollNotifications'] ?? true,
      chatMessages: map['chatMessages'] ?? true,
      emailNotifications: map['emailNotifications'] ?? false,
      newEvents: map['newEvents'] ?? true,
    );
  }
}

class PrivacySettings {
  final bool profileVisible;
  final bool showEmail;
  final bool showPhone;
  final bool showSocieties;
  final bool allowDirectMessages;

  PrivacySettings({
    this.profileVisible = true,
    this.showEmail = false,
    this.showPhone = false,
    this.showSocieties = true,
    this.allowDirectMessages = true,
  });

  PrivacySettings copyWith({
    bool? profileVisible,
    bool? showEmail,
    bool? showPhone,
    bool? showSocieties,
    bool? allowDirectMessages,
  }) {
    return PrivacySettings(
      profileVisible: profileVisible ?? this.profileVisible,
      showEmail: showEmail ?? this.showEmail,
      showPhone: showPhone ?? this.showPhone,
      showSocieties: showSocieties ?? this.showSocieties,
      allowDirectMessages: allowDirectMessages ?? this.allowDirectMessages,
    );
  }

  Map<String, dynamic> toMap() => {
    'profileVisible': profileVisible,
    'showEmail': showEmail,
    'showPhone': showPhone,
    'showSocieties': showSocieties,
    'allowDirectMessages': allowDirectMessages,
  };

  factory PrivacySettings.fromMap(Map<dynamic, dynamic> map) {
    return PrivacySettings(
      profileVisible: map['profileVisible'] ?? true,
      showEmail: map['showEmail'] ?? false,
      showPhone: map['showPhone'] ?? false,
      showSocieties: map['showSocieties'] ?? true,
      allowDirectMessages: map['allowDirectMessages'] ?? true,
    );
  }
}

class AppSettings {
  final ThemeMode themeMode;
  final NotificationSettings notifications;
  final PrivacySettings privacy;
  final String language;

  AppSettings({
    this.themeMode = ThemeMode.light,
    NotificationSettings? notifications,
    PrivacySettings? privacy,
    this.language = 'en',
  }) : notifications = notifications ?? NotificationSettings(),
       privacy = privacy ?? PrivacySettings();
}

class SettingsService {
  static const String _boxName = 'app_settings';
  static AppSettings _settings = AppSettings();
  static final List<VoidCallback> _listeners = [];
  static Box? _box;

  // Get current settings
  static AppSettings get settings => _settings;

  // Get theme mode
  static ThemeMode get themeMode => _settings.themeMode;

  // Check if dark mode
  static bool get isDarkMode => _settings.themeMode == ThemeMode.dark;

  // Add listener for settings changes
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  // Remove listener
  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  // Notify all listeners
  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // Toggle theme
  static Future<void> toggleTheme() async {
    _settings = AppSettings(
      themeMode: _settings.themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light,
      notifications: _settings.notifications,
      privacy: _settings.privacy,
      language: _settings.language,
    );
    await saveSettings();
    _notifyListeners();
  }

  // Set theme mode
  static Future<void> setThemeMode(ThemeMode mode) async {
    _settings = AppSettings(
      themeMode: mode,
      notifications: _settings.notifications,
      privacy: _settings.privacy,
      language: _settings.language,
    );
    await saveSettings();
    _notifyListeners();
  }

  // Update notification settings
  static Future<void> updateNotificationSettings(NotificationSettings newSettings) async {
    _settings = AppSettings(
      themeMode: _settings.themeMode,
      notifications: newSettings,
      privacy: _settings.privacy,
      language: _settings.language,
    );
    await saveSettings();
    _notifyListeners();
  }

  // Update privacy settings
  static Future<void> updatePrivacySettings(PrivacySettings newSettings) async {
    _settings = AppSettings(
      themeMode: _settings.themeMode,
      notifications: _settings.notifications,
      privacy: newSettings,
      language: _settings.language,
    );
    await saveSettings();
    _notifyListeners();
  }

  // Get notification settings
  static NotificationSettings get notificationSettings => _settings.notifications;

  // Get privacy settings
  static PrivacySettings get privacySettings => _settings.privacy;

  // Save all settings to Hive
  static Future<void> saveSettings() async {
    try {
      _box ??= await Hive.openBox(_boxName);
      await _box!.put('themeMode', _settings.themeMode.index);
      await _box!.put('language', _settings.language);
      await _box!.put('notifications', _settings.notifications.toMap());
      await _box!.put('privacy', _settings.privacy.toMap());
    } catch (e) {
      LoggingService.error('Failed to save settings', e);
    }
  }

  // Load settings from Hive
  static Future<void> loadSettings() async {
    try {
      _box ??= await Hive.openBox(_boxName);

      final themeModeIndex = _box!.get('themeMode', defaultValue: ThemeMode.light.index) as int;
      final language = _box!.get('language', defaultValue: 'en') as String;
      final notifMap = _box!.get('notifications');
      final privMap = _box!.get('privacy');

      _settings = AppSettings(
        themeMode: ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)],
        language: language,
        notifications: notifMap != null
            ? NotificationSettings.fromMap(notifMap as Map<dynamic, dynamic>)
            : NotificationSettings(),
        privacy: privMap != null
            ? PrivacySettings.fromMap(privMap as Map<dynamic, dynamic>)
            : PrivacySettings(),
      );
    } catch (e) {
      LoggingService.error('Failed to load settings', e);
      _settings = AppSettings();
    }
  }
}

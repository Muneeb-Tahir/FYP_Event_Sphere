// lib/services/settings_service.dart
// Mock service for app settings - replace with SharedPreferences/Firebase later

import 'package:flutter/material.dart';

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
  static AppSettings _settings = AppSettings();
  static final List<VoidCallback> _listeners = [];

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
    await Future.delayed(const Duration(milliseconds: 100));
    _settings = AppSettings(
      themeMode: _settings.themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light,
      notifications: _settings.notifications,
      privacy: _settings.privacy,
      language: _settings.language,
    );
    _notifyListeners();
  }

  // Set theme mode
  static Future<void> setThemeMode(ThemeMode mode) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _settings = AppSettings(
      themeMode: mode,
      notifications: _settings.notifications,
      privacy: _settings.privacy,
      language: _settings.language,
    );
    _notifyListeners();
  }

  // Update notification settings
  static Future<void> updateNotificationSettings(NotificationSettings newSettings) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _settings = AppSettings(
      themeMode: _settings.themeMode,
      notifications: newSettings,
      privacy: _settings.privacy,
      language: _settings.language,
    );
    _notifyListeners();
  }

  // Update privacy settings
  static Future<void> updatePrivacySettings(PrivacySettings newSettings) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _settings = AppSettings(
      themeMode: _settings.themeMode,
      notifications: _settings.notifications,
      privacy: newSettings,
      language: _settings.language,
    );
    _notifyListeners();
  }

  // Get notification settings
  static NotificationSettings get notificationSettings => _settings.notifications;

  // Get privacy settings
  static PrivacySettings get privacySettings => _settings.privacy;

  // Save all settings (mock - in production save to SharedPreferences/Firebase)
  static Future<void> saveSettings() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO: Save to SharedPreferences or Firebase
  }

  // Load settings (mock - in production load from SharedPreferences/Firebase)
  static Future<void> loadSettings() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO: Load from SharedPreferences or Firebase
  }
}

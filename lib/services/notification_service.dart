// lib/services/notification_service.dart
// Firebase Cloud Messaging Push Notifications

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';
import 'settings_service.dart';
import 'logging_service.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.notification?.title}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Global navigator key for deep linking from notifications
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static String? _fcmToken;
  static String? get fcmToken => _fcmToken;

  // ===================== INITIALIZE =====================
  static Future<void> initialize() async {
    // Firebase push notifications only work on Android/iOS, skip on Web
    if (identical(0, 0.0)) {
      // This branch never runs — just a compile trick; use kIsWeb below
    }

    // Use Flutter's kIsWeb to detect web platform
    try {
      const bool isWeb = bool.fromEnvironment('dart.library.html');
      // Check if we're on a non-mobile platform
      bool onMobile = false;
      try {
        onMobile = Platform.isAndroid || Platform.isIOS;
      } catch (_) {
        // Platform.isAndroid throws on web
        onMobile = false;
      }

      if (!onMobile) {
        LoggingService.info('NotificationService: Skipping Firebase init on Web/Desktop');
        return;
      }

      // Initialize Firebase
      await Firebase.initializeApp();

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      await _requestPermission();

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      LoggingService.debug('FCM Token: $_fcmToken');

      // Save token to database
      await _saveTokenToDatabase();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        _saveTokenToDatabase();
      });

      // Initialize local notifications
      await _initLocalNotifications();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap (app in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Subscribe to topics
      await subscribeToTopic('all_users');

      LoggingService.info('NotificationService initialized successfully');
    } catch (e) {
      LoggingService.error('NotificationService init error', e);
    }
  }

  // ===================== REQUEST PERMISSION =====================
  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    LoggingService.debug('Notification permission: ${settings.authorizationStatus}');
  }

  // ===================== INIT LOCAL NOTIFICATIONS =====================
  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        LoggingService.debug('Local notification tapped: ${response.payload}');
      },
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'event_sphere_channel',
        'Event Sphere Notifications',
        description: 'Notifications for Event Sphere app',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // ===================== HANDLE FOREGROUND MESSAGE =====================
  static void _handleForegroundMessage(RemoteMessage message) {
    LoggingService.debug('Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification != null) {
      showLocalNotification(
        title: notification.title ?? 'Event Sphere',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  // ===================== HANDLE NOTIFICATION TAP =====================
  static void _handleNotificationTap(RemoteMessage message) {
    LoggingService.info('Notification tapped: ${message.data}');
    final data = message.data;
    final type = data['type'] as String?;
    final id = data['id'] as String?;

    // Navigate based on notification type
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    switch (type) {
      case 'event':
        if (id != null) {
          navigator.pushNamed('/event-detail', arguments: {'eventId': id});
        }
        break;
      case 'announcement':
        navigator.pushNamed('/announcements');
        break;
      case 'poll':
        navigator.pushNamed('/poll');
        break;
      case 'registration':
        navigator.pushNamed('/registered-events');
        break;
      default:
        navigator.pushNamed('/home');
        break;
    }
  }

  // ===================== SHOW LOCAL NOTIFICATION =====================
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'event_sphere_channel',
      'Event Sphere Notifications',
      channelDescription: 'Notifications for Event Sphere app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // ===================== SAVE TOKEN TO DATABASE =====================
  static Future<void> _saveTokenToDatabase() async {
    if (_fcmToken == null) return;

    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId != null) {
        await SupabaseService.client
            .from('users')
            .update({'fcm_token': _fcmToken})
            .eq('id', userId);
        LoggingService.debug('FCM token saved to database');
      }
    } catch (e) {
      LoggingService.error('Failed to save FCM token', e);
    }
  }

  // ===================== SUBSCRIBE TO TOPIC =====================
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      LoggingService.debug('Subscribed to topic: $topic');
    } catch (e) {
      LoggingService.error('Failed to subscribe to topic', e);
    }
  }

  // ===================== UNSUBSCRIBE FROM TOPIC =====================
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      LoggingService.debug('Unsubscribed from topic: $topic');
    } catch (e) {
      LoggingService.error('Failed to unsubscribe from topic', e);
    }
  }

  // ===================== SEND NOTIFICATION (via Supabase Edge Function) =====================
  static Future<bool> sendNotification({
    required String title,
    required String body,
    String? topic,
    String? userId,
    String? token,
    Map<String, String>? data,
  }) async {
    try {
      LoggingService.debug('Sending notification: title=$title, topic=$topic, userId=$userId');

      final response = await SupabaseService.client.functions.invoke(
        'send-notification',
        body: {
          'title': title,
          'body': body,
          if (topic != null) 'topic': topic,
          if (userId != null) 'userId': userId,
          if (token != null) 'token': token,
          if (data != null) 'data': data,
        },
      );

      LoggingService.debug('Notification response: status=${response.status}, data=${response.data}');

      if (response.status == 200) {
        LoggingService.info('Notification sent successfully');
        return true;
      } else {
        LoggingService.warning('Failed to send notification: ${response.data}');
        return false;
      }
    } catch (e, stack) {
      LoggingService.error('Error sending notification', e, stack);
      return false;
    }
  }

  // ===================== NOTIFY ALL USERS OF NEW EVENT =====================
  static Future<void> notifyNewEvent({
    required String eventName,
    required String societyName,
    String? eventId,
  }) async {
    // Check if new event notifications are enabled in settings
    if (!SettingsService.notificationSettings.newEvents) {
      LoggingService.debug('New event notifications disabled in settings');
      return;
    }

    await sendNotification(
      title: '🎉 New Event: $eventName',
      body: '$societyName just posted a new event. Check it out!',
      topic: 'all_users',
      data: eventId != null ? {'eventId': eventId, 'type': 'new_event'} : null,
    );
  }

  // ===================== NOTIFY ADMINS OF PENDING EVENT APPROVAL =====================
  static Future<void> notifyAdminsNewEventApproval({
    required String eventName,
    required String societyName,
    required String creatorName,
    String? eventId,
  }) async {
    try {
      // Get all admin users FCM tokens
      final response = await SupabaseService.client
          .from('users')
          .select('fcm_token')
          .or('role.eq.admin,role.eq.super_admin');

      final admins = response as List;
      LoggingService.info('Notifying ${admins.length} admins of pending event approval');

      // Send to each admin directly
      for (final admin in admins) {
        final token = admin['fcm_token'] as String?;
        if (token != null && token.isNotEmpty) {
          await sendNotification(
            title: '📋 Event Approval Required',
            body: '$creatorName from $societyName submitted "$eventName" for approval.',
            token: token,
            data: eventId != null ? {'eventId': eventId, 'type': 'approval_request'} : null,
          );
        }
      }
    } catch (e) {
      LoggingService.error('Error notifying admins', e);
    }
  }

  // ===================== NOTIFY SOCIETY MEMBERS =====================
  static Future<void> notifySocietyMembers({
    required String societyId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    // Send to society-specific topic
    await sendNotification(
      title: title,
      body: body,
      topic: 'society_$societyId',
      data: data,
    );
  }

  // ===================== NOTIFY SPECIFIC USER =====================
  static Future<void> notifyUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    await sendNotification(
      title: title,
      body: body,
      userId: userId,
      data: data,
    );
  }

  // ===================== NOTIFY EVENT REGISTRATION =====================
  static Future<void> notifyEventRegistration({
    required String organizerUserId,
    required String eventName,
    required String registrantName,
  }) async {
    await notifyUser(
      userId: organizerUserId,
      title: '📋 New Registration',
      body: '$registrantName just registered for $eventName',
      data: {'type': 'registration'},
    );
  }

  // ===================== NOTIFY EVENT REMINDER =====================
  static Future<void> notifyEventReminder({
    required String userId,
    required String eventName,
    required String timeUntil,
  }) async {
    await notifyUser(
      userId: userId,
      title: '⏰ Event Reminder',
      body: '$eventName starts in $timeUntil',
      data: {'type': 'reminder'},
    );
  }

  // ===================== SUBSCRIBE TO SOCIETY =====================
  static Future<void> subscribeToSociety(String societyId) async {
    await subscribeToTopic('society_$societyId');
  }

  // ===================== UNSUBSCRIBE FROM SOCIETY =====================
  static Future<void> unsubscribeFromSociety(String societyId) async {
    await unsubscribeFromTopic('society_$societyId');
  }
}

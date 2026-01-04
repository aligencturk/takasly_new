import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'navigation_service.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('📬 Background message received', name: 'FCM');
  developer.log('Message ID: ${message.messageId}', name: 'FCM');
  developer.log('Title: ${message.notification?.title}', name: 'FCM');
  developer.log('Body: ${message.notification?.body}', name: 'FCM');
  developer.log('Data: ${message.data}', name: 'FCM');
}

/// Firebase Cloud Messaging service for handling push notifications
class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  /// Initialize Firebase Messaging
  /// Request permissions and set up message handlers
  static Future<void> initialize() async {
    try {
      developer.log('🚀 Initializing Firebase Messaging', name: 'FCM');
      developer.log('📱 Platform: ${Platform.operatingSystem}', name: 'FCM');

      // Request notification permissions (iOS ve Android 13+)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      developer.log(
        '📱 Notification permission status: ${settings.authorizationStatus}',
        name: 'FCM',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log('✅ User granted permission', name: 'FCM');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        developer.log('⚠️ User granted provisional permission', name: 'FCM');
      } else {
        developer.log(
          '❌ User declined or has not accepted permission',
          name: 'FCM',
        );
        return;
      }

      // iOS: Set foreground notification presentation options
      if (Platform.isIOS) {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        developer.log('✅ iOS Foreground notification options set', name: 'FCM');

        // Get APNS token (iOS only)
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        developer.log('🍎 APNS Token: $apnsToken', name: 'FCM');
      }

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        developer.log('🔑 FCM Token: $token', name: 'FCM');
        // TODO: Send this token to your backend server
      } else {
        developer.log('⚠️ FCM Token is null!', name: 'FCM');
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        developer.log('🔄 FCM Token refreshed: $newToken', name: 'FCM');
        // TODO: Send updated token to your backend server
      });

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log('📨 Foreground message received', name: 'FCM');
        developer.log('Message ID: ${message.messageId}', name: 'FCM');

        if (message.notification != null) {
          developer.log(
            '📋 Notification Title: ${message.notification!.title}',
            name: 'FCM',
          );
          developer.log(
            '📋 Notification Body: ${message.notification!.body}',
            name: 'FCM',
          );
        }

        if (message.data.isNotEmpty) {
          developer.log('📦 Data: ${message.data}', name: 'FCM');
        }
      });

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log('🔔 Notification opened from background', name: 'FCM');
        developer.log('Message ID: ${message.messageId}', name: 'FCM');
        developer.log('Data: ${message.data}', name: 'FCM');

        _handleMessageNavigation(message);
      });

      // Check if app was opened from a terminated state via notification
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        developer.log(
          '🔔 App opened from terminated state via notification',
          name: 'FCM',
        );
        developer.log('Message ID: ${initialMessage.messageId}', name: 'FCM');
        developer.log('Data: ${initialMessage.data}', name: 'FCM');

        // Slight delay to ensure app handles initialization
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handleMessageNavigation(initialMessage);
        });
      }

      developer.log(
        '✅ Firebase Messaging initialized successfully',
        name: 'FCM',
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error initializing Firebase Messaging',
        name: 'FCM',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Subscribe to a topic using userId
  ///
  /// [userId] - The user ID to subscribe to
  static Future<void> subscribeToUserTopic(String userId) async {
    try {
      // Topic ismi - backend'in gönderdiği formatla aynı olmalı
      // Eğer backend "seller_123" gönderiyorsa burada da "seller_$userId" kullan
      // Eğer backend sadece "123" gönderiyorsa burada da sadece userId kullan
      final topicName = userId; // Backend'in gönderdiği formatla eşleşmeli!
      developer.log('📌 Subscribing to topic: $topicName', name: 'FCM');

      // APNS Token kontrol et
      final apnsToken = await _firebaseMessaging.getAPNSToken();
      developer.log('🍎 APNS Token for subscription: $apnsToken', name: 'FCM');

      // FCM Token kontrol et
      final token = await _firebaseMessaging.getToken();
      developer.log(
        '🔑 Current FCM Token for subscription: $token',
        name: 'FCM',
      );

      if (token == null) {
        developer.log('❌ Cannot subscribe - FCM Token is null!', name: 'FCM');
        return;
      }

      await _firebaseMessaging.subscribeToTopic(topicName);
      developer.log(
        '✅ Successfully subscribed to topic: $topicName',
        name: 'FCM',
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error subscribing to topic: $userId',
        name: 'FCM',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Unsubscribe from a topic using userId
  ///
  /// [userId] - The user ID to unsubscribe from
  static Future<void> unsubscribeFromUserTopic(String userId) async {
    try {
      final topicName = userId; // Backend'in gönderdiği formatla eşleşmeli!
      developer.log('📌 Unsubscribing from topic: $topicName', name: 'FCM');
      await _firebaseMessaging.unsubscribeFromTopic(topicName);
      developer.log(
        '✅ Successfully unsubscribed from topic: $topicName',
        name: 'FCM',
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error unsubscribing from topic: $userId',
        name: 'FCM',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      developer.log('🔑 Current FCM Token: $token', name: 'FCM');
      return token;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error getting FCM token',
        name: 'FCM',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Handle navigation based on message data
  static void _handleMessageNavigation(RemoteMessage message) {
    // API sends data in different formats sometimes, need to be careful
    // Assuming data structure matches NotificationModel or similar
    final data = message.data;
    if (data.isEmpty) return;

    // Parse fields safely
    final type = data['type'] as String? ?? '';
    final typeId = int.tryParse(data['type_id']?.toString() ?? '0') ?? 0;
    final url = data['url'] as String?;
    final title = message.notification?.title ?? data['title'] as String?;

    if (type.isNotEmpty) {
      developer.log('🚀 Navigating to: $type (ID: $typeId)', name: 'FCM');
      NavigationService().handleDeepLink(
        type: type,
        typeId: typeId,
        url: url,
        title: title,
      );
    }
  }

  /// Delete FCM token
  static Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      developer.log('🗑️ FCM Token deleted', name: 'FCM');
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error deleting FCM token',
        name: 'FCM',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

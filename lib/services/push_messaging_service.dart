import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_config.dart';

// Top-level background message handler (required by firebase_messaging)
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[FCM][BG] ${message.messageId} ${message.notification?.title}');
}

class PushMessagingService {
  PushMessagingService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> initialize() async {
    // Set background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permissions (iOS/macOS/Web). On Android 13+, also required.
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Get and persist FCM token for the signed-in user
    await _refreshAndSaveToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      _saveToken(token);
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM][FG] ${message.messageId} ${message.notification?.title}');
    });

    // App opened from terminated/background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM][OPEN] ${message.messageId}');
      // TODO: Deep link to screens based on message.data
    });
  }

  static Future<void> _refreshAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  // Get current FCM token
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Failed to subscribe to topic $topic: $e');
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Failed to unsubscribe from topic $topic: $e');
    }
  }

  // Handle notification tap
  static void handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    // TODO: Navigate to specific screen based on message data
    final data = message.data;
    if (data.containsKey('deviceId')) {
      // Navigate to device detail screen
      debugPrint('Navigate to device: ${data['deviceId']}');
    }
  }

  static Future<void> _saveToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      );
      
      await db.ref('Users/${user.uid}/notificationTokens/$token').set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }
}



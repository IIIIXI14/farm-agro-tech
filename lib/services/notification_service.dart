import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sensor_reading.dart';
import 'local_notification_service.dart';
import 'push_messaging_service.dart';

enum NotificationType {
  sensorAlert,
  deviceOffline,
  automationTriggered,
  systemAlert,
  weatherAlert,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Notification settings
  bool _notificationsEnabled = true;
  bool _sensorAlertsEnabled = true;
  bool _deviceOfflineAlertsEnabled = true;
  bool _automationAlertsEnabled = true;
  bool _weatherAlertsEnabled = true;

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get sensorAlertsEnabled => _sensorAlertsEnabled;
  bool get deviceOfflineAlertsEnabled => _deviceOfflineAlertsEnabled;
  bool get automationAlertsEnabled => _automationAlertsEnabled;
  bool get weatherAlertsEnabled => _weatherAlertsEnabled;

  // Initialize notification settings
  Future<void> initialize() async {
    // Initialize local notifications
    await LocalNotificationService.initialize();
    
    // Initialize push messaging
    await PushMessagingService.initialize();
    
    final user = _auth.currentUser;
    if (user != null) {
      await _loadNotificationSettings(user.uid);
    }
  }

  // Load notification settings from Firestore
  Future<void> _loadNotificationSettings(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _notificationsEnabled = data['enabled'] ?? true;
        _sensorAlertsEnabled = data['sensorAlerts'] ?? true;
        _deviceOfflineAlertsEnabled = data['deviceOfflineAlerts'] ?? true;
        _automationAlertsEnabled = data['automationAlerts'] ?? true;
        _weatherAlertsEnabled = data['weatherAlerts'] ?? true;
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  // Save notification settings to Firestore
  Future<void> saveNotificationSettings(String uid) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('notifications')
          .set({
        'enabled': _notificationsEnabled,
        'sensorAlerts': _sensorAlertsEnabled,
        'deviceOfflineAlerts': _deviceOfflineAlertsEnabled,
        'automationAlerts': _automationAlertsEnabled,
        'weatherAlerts': _weatherAlertsEnabled,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  // Update notification settings
  void updateNotificationSettings({
    bool? notificationsEnabled,
    bool? sensorAlertsEnabled,
    bool? deviceOfflineAlertsEnabled,
    bool? automationAlertsEnabled,
    bool? weatherAlertsEnabled,
  }) {
    if (notificationsEnabled != null) _notificationsEnabled = notificationsEnabled;
    if (sensorAlertsEnabled != null) _sensorAlertsEnabled = sensorAlertsEnabled;
    if (deviceOfflineAlertsEnabled != null) _deviceOfflineAlertsEnabled = deviceOfflineAlertsEnabled;
    if (automationAlertsEnabled != null) _automationAlertsEnabled = automationAlertsEnabled;
    if (weatherAlertsEnabled != null) _weatherAlertsEnabled = weatherAlertsEnabled;

    final user = _auth.currentUser;
    if (user != null) {
      saveNotificationSettings(user.uid);
    }
  }

  // Check sensor readings and send alerts if needed
  Future<void> checkSensorAlerts(SensorReading reading, String deviceId) async {
    if (!_notificationsEnabled || !_sensorAlertsEnabled) return;

    final alerts = <String>[];

    // Check temperature
    if (reading.temperature < 10 || reading.temperature > 40) {
      alerts.add('Temperature is ${reading.temperature.toStringAsFixed(1)}°C (outside normal range)');
    }

    // Check humidity
    if (reading.humidity < 30 || reading.humidity > 80) {
      alerts.add('Humidity is ${reading.humidity.toStringAsFixed(1)}% (outside normal range)');
    }

    // Check soil moisture
    if (reading.soilMoisture != null && (reading.soilMoisture! < 20 || reading.soilMoisture! > 80)) {
      alerts.add('Soil moisture is ${reading.soilMoisture!.toStringAsFixed(1)}% (outside normal range)');
    }

    // Check pH level
    if (reading.phLevel != null && (reading.phLevel! < 5.5 || reading.phLevel! > 7.5)) {
      alerts.add('pH level is ${reading.phLevel!.toStringAsFixed(1)} (outside normal range)');
    }

    // Check CO2 level
    if (reading.co2Level != null && reading.co2Level! > 1000) {
      alerts.add('CO2 level is ${reading.co2Level!.toStringAsFixed(1)} ppm (high)');
    }

    // Send alerts if any issues found
    for (final alert in alerts) {
      await _sendNotification(
        title: 'Sensor Alert',
        body: '$alert on device $deviceId',
        type: NotificationType.sensorAlert,
        data: {
          'deviceId': deviceId,
          'sensorReading': reading.toFirestore(),
        },
      );
    }
  }

  // Send device offline alert
  Future<void> sendDeviceOfflineAlert(String deviceId, String deviceName) async {
    if (!_notificationsEnabled || !_deviceOfflineAlertsEnabled) return;

    await _sendNotification(
      title: 'Device Offline',
      body: '$deviceName is offline',
      type: NotificationType.deviceOffline,
      data: {
        'deviceId': deviceId,
        'deviceName': deviceName,
      },
    );
  }

  // Send automation triggered alert
  Future<void> sendAutomationAlert(String deviceId, String actuator, String condition) async {
    if (!_notificationsEnabled || !_automationAlertsEnabled) return;

    await _sendNotification(
      title: 'Automation Triggered',
      body: '$actuator activated on device $deviceId due to $condition',
      type: NotificationType.automationTriggered,
      data: {
        'deviceId': deviceId,
        'actuator': actuator,
        'condition': condition,
      },
    );
  }

  // Send weather alert
  Future<void> sendWeatherAlert(String alert, String deviceId) async {
    if (!_notificationsEnabled || !_weatherAlertsEnabled) return;

    await _sendNotification(
      title: 'Weather Alert',
      body: alert,
      type: NotificationType.weatherAlert,
      data: {
        'deviceId': deviceId,
        'alert': alert,
      },
    );
  }

  // Send system alert
  Future<void> sendSystemAlert(String title, String body, {Map<String, dynamic>? data}) async {
    if (!_notificationsEnabled) return;

    await _sendNotification(
      title: title,
      body: body,
      type: NotificationType.systemAlert,
      data: data,
    );
  }

  // Internal method to send notification
  Future<void> _sendNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Store notification in Firestore
      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type.toString(),
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Show local notification
      await LocalNotificationService.showNotification(
        id: docRef.id.hashCode,
        title: title,
        body: body,
        payload: docRef.id,
        type: type,
      );

      // Send push notification (if enabled)
      if (_notificationsEnabled) {
        await _sendPushNotification(
          title: title,
          body: body,
          data: data,
        );
      }

      debugPrint('Notification sent: $title - $body');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // Send push notification
  Future<void> _sendPushNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // This would typically send to FCM or use a server endpoint
      // For now, we'll just log it
      debugPrint('Push notification would be sent: $title - $body');
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }

  // Get user notifications
  Stream<QuerySnapshot> getUserNotifications(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String uid, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String uid) async {
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    for (final doc in notifications.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  // Delete notification
  Future<void> deleteNotification(String uid, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Clear all notifications
  Future<void> clearAllNotifications(String uid) async {
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .get();

    for (final doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Get notification icon based on type
  static IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.sensorAlert:
        return Icons.warning;
      case NotificationType.deviceOffline:
        return Icons.wifi_off;
      case NotificationType.automationTriggered:
        return Icons.auto_awesome;
      case NotificationType.systemAlert:
        return Icons.info;
      case NotificationType.weatherAlert:
        return Icons.cloud;
    }
  }

  // Get notification color based on type
  static Color getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.sensorAlert:
        return Colors.red;
      case NotificationType.deviceOffline:
        return Colors.orange;
      case NotificationType.automationTriggered:
        return Colors.blue;
      case NotificationType.systemAlert:
        return Colors.grey;
      case NotificationType.weatherAlert:
        return Colors.purple;
    }
  }
} 
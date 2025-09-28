import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'app_config.dart';

enum LogType {
  info,
  success,
  warning,
  error,
}

class LogService {
  static Future<void> log(
    String message, {
    LogType type = LogType.info,
    String? userId,
    String? deviceId,
  }) async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      );
      
      final logId = 'log_${DateTime.now().millisecondsSinceEpoch}';
      
      // Try to write to user-specific logs first, fall back to system logs
      if (userId != null) {
        await db.ref('Users/$userId/Logs/$logId').set({
          'message': message,
          'type': type.name,
          'userId': userId,
          'deviceId': deviceId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        // For system logs, try to write to a user-accessible location
        await db.ref('system_logs/$logId').set({
          'message': message,
          'type': type.name,
          'userId': userId,
          'deviceId': deviceId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      // Silently fail for logging to avoid breaking the app
      // Only print in debug mode to avoid spam
      if (kDebugMode) {
        print('LogService error: $e');
      }
    }
  }

  static Future<void> logUserAction(
    String userId,
    String action, {
    LogType type = LogType.info,
  }) async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      );
      
      // Get user info from Realtime Database
      final userSnap = await db.ref('Users/$userId/Meta').get();
      String userName = 'Unknown User';
      String userEmail = 'No Email';
      
      if (userSnap.exists && userSnap.value is Map) {
        final userData = Map<String, dynamic>.from(userSnap.value as Map);
        userName = userData['name']?.toString() ?? 'Unknown User';
        userEmail = userData['email']?.toString() ?? 'No Email';
      }

      await log(
        'User Action: $action\nUser: $userName ($userEmail)',
        type: type,
        userId: userId,
      );
    } catch (e) {
      // Silently fail for logging to avoid breaking the app
      print('LogService error: $e');
    }
  }

  static Future<void> logDeviceAction(
    String userId,
    String deviceId,
    String action, {
    LogType type = LogType.info,
  }) async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      );
      
      // Get device info from Realtime Database
      final deviceSnap = await db.ref('Users/$userId/devices/$deviceId/Meta').get();
      String deviceName = 'Unknown Device';
      
      if (deviceSnap.exists && deviceSnap.value is Map) {
        final deviceData = Map<String, dynamic>.from(deviceSnap.value as Map);
        deviceName = deviceData['name']?.toString() ?? 'Unknown Device';
      }

      await log(
        'Device Action: $action\nDevice: $deviceName ($deviceId)',
        type: type,
        userId: userId,
        deviceId: deviceId,
      );
    } catch (e) {
      // Silently fail for logging to avoid breaking the app
      print('LogService error: $e');
    }
  }

  static Future<void> logSystemEvent(
    String event, {
    LogType type = LogType.info,
  }) async {
    await log('System Event: $event', type: type);
  }

  static Future<void> exportLogs() async {
    // TODO: Implement log export functionality
    // This could export logs to a CSV file or send them to a cloud storage
  }
}
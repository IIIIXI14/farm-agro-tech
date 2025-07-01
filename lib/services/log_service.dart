import 'package:cloud_firestore/cloud_firestore.dart';

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
    await FirebaseFirestore.instance.collection('system_logs').add({
      'message': message,
      'type': type.name,
      'userId': userId,
      'deviceId': deviceId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> logUserAction(
    String userId,
    String action, {
    LogType type = LogType.info,
  }) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    final userName = userDoc.data()?['name'] as String? ?? 'Unknown User';
    final userEmail = userDoc.data()?['email'] as String? ?? 'No Email';

    await log(
      'User Action: $action\nUser: $userName ($userEmail)',
      type: type,
      userId: userId,
    );
  }

  static Future<void> logDeviceAction(
    String userId,
    String deviceId,
    String action, {
    LogType type = LogType.info,
  }) async {
    final deviceDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(deviceId)
        .get();
    
    final deviceName = deviceDoc.data()?['name'] as String? ?? 'Unknown Device';

    await log(
      'Device Action: $action\nDevice: $deviceName ($deviceId)',
      type: type,
      userId: userId,
      deviceId: deviceId,
    );
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
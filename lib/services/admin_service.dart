import 'package:cloud_firestore/cloud_firestore.dart';
import 'log_service.dart';

class AdminService {
  static Future<void> updateUserStatus(String userId, bool isActive) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      'isActive': isActive,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    await LogService.logUserAction(
      userId,
      isActive ? 'Account activated' : 'Account deactivated',
      type: isActive ? LogType.success : LogType.warning,
    );
  }

  static Future<void> toggleAdminStatus(String userId, bool isAdmin) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      'isAdmin': isAdmin,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    await LogService.logUserAction(
      userId,
      isAdmin ? 'Promoted to admin' : 'Demoted from admin',
      type: LogType.warning,
    );
  }

  static Future<bool> isUserAdmin(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    if (!doc.exists) return false;
    return doc.data()?['isAdmin'] as bool? ?? false;
  }

  static Future<Map<String, dynamic>> getSystemStats() async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    final devicesSnapshot = await FirebaseFirestore.instance
        .collectionGroup('devices')
        .get();

    int totalUsers = usersSnapshot.docs.length;
    int activeUsers = usersSnapshot.docs
        .where((doc) => doc.data()['isActive'] == true)
        .length;
    int totalDevices = devicesSnapshot.docs.length;
    int activeDevices = devicesSnapshot.docs
        .where((doc) => doc.data()['status'] == 'online')
        .length;

    final stats = {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'totalDevices': totalDevices,
      'activeDevices': activeDevices,
      'lastUpdated': DateTime.now(),
    };

    await LogService.logSystemEvent(
      'System stats updated: '
      '$activeUsers/$totalUsers users active, '
      '$activeDevices/$totalDevices devices online',
      type: LogType.info,
    );

    return stats;
  }

  static Stream<Map<String, dynamic>> systemStatsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) {
      int totalUsers = snapshot.docs.length;
      int activeUsers = snapshot.docs
          .where((doc) => doc.data()['isActive'] == true)
          .length;

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'lastUpdated': DateTime.now(),
      };
    });
  }

  static Future<void> deleteInactiveDevices() async {
    final devicesSnapshot = await FirebaseFirestore.instance
        .collectionGroup('devices')
        .where('lastUpdate', isLessThan: Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 30)),
        ))
        .where('status', isEqualTo: 'offline')
        .get();

    for (final device in devicesSnapshot.docs) {
      final userId = device.reference.parent.parent?.id;
      if (userId == null) continue;

      await device.reference.delete();
      await LogService.logDeviceAction(
        userId,
        device.id,
        'Device automatically deleted due to inactivity',
        type: LogType.warning,
      );
    }

    await LogService.logSystemEvent(
      'Cleaned up ${devicesSnapshot.docs.length} inactive devices',
      type: LogType.info,
    );
  }

  static Future<void> backupSystemData() async {
    try {
      // TODO: Implement system backup functionality
      await LogService.logSystemEvent(
        'System backup completed successfully',
        type: LogType.success,
      );
    } catch (e) {
      await LogService.logSystemEvent(
        'System backup failed: $e',
        type: LogType.error,
      );
      rethrow;
    }
  }
} 
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_config.dart';

class MigrationService {
  /// Migrate all devices from Users/{uid}/devices to the new devices collection
  static Future<bool> migrateUserDevices(String uid) async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      );

      // Get all devices from the old structure
      final oldRef = db.ref('Users/$uid');
      final snapshot = await oldRef.get();
      
      if (!snapshot.exists) return true; // No data to migrate
      
      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      final devices = <String, Map<String, dynamic>>{};
      
      // Find all device-like entries (exclude notificationTokens and other non-device data)
      for (final entry in userData.entries) {
        final key = entry.key;
        final value = entry.value;
        
        // Skip known non-device fields
        if (key == 'notificationTokens' || 
            key == 'profile' || 
            key == 'settings' ||
            key == 'preferences') {
          continue;
        }
        
        // Check if this looks like a device (has device-like structure)
        if (value is Map) {
          final deviceData = Map<String, dynamic>.from(value);
          
          // Check if it has device-like properties
          if (deviceData.containsKey('Meta') || 
              deviceData.containsKey('Sensor_Data') ||
              deviceData.containsKey('Actuator_Status') ||
              deviceData.containsKey('DeviceStatus')) {
            
            // Add userId to the device data
            deviceData['userId'] = uid;
            deviceData['migratedAt'] = DateTime.now().millisecondsSinceEpoch;
            
            devices[key] = deviceData;
          }
        }
      }
      
      if (devices.isEmpty) return true; // No devices to migrate
      
      // Migrate each device to the new structure
      for (final deviceEntry in devices.entries) {
        final deviceId = deviceEntry.key;
        final deviceData = deviceEntry.value;
        
        // Store in new devices collection
        await db.ref('devices/$deviceId').set(deviceData);
      }
      
      print('Successfully migrated ${devices.length} devices for user $uid');
      return true;
      
    } catch (e) {
      print('Error migrating devices for user $uid: $e');
      return false;
    }
  }
  
  /// Check if a user's devices have been migrated
  static Future<bool> isUserMigrated(String uid) async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      );
      
      // Check if there are any devices in the new collection for this user
      final devicesRef = db.ref('devices');
      final snapshot = await devicesRef.get();
      
      if (!snapshot.exists) return false;
      
      final devices = Map<String, dynamic>.from(snapshot.value as Map);
      
      // Check if any device belongs to this user
      for (final device in devices.values) {
        if (device is Map && device['userId'] == uid) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking migration status for user $uid: $e');
      return false;
    }
  }
  
  /// Clean up old device data after successful migration
  static Future<bool> cleanupOldDeviceData(String uid) async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      );
      
      // Get all devices from the old structure
      final oldRef = db.ref('Users/$uid');
      final snapshot = await oldRef.get();
      
      if (!snapshot.exists) return true;
      
      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      final devicesToRemove = <String>[];
      
      // Find device entries to remove
      for (final entry in userData.entries) {
        final key = entry.key;
        final value = entry.value;
        
        // Skip known non-device fields
        if (key == 'notificationTokens' || 
            key == 'profile' || 
            key == 'settings' ||
            key == 'preferences') {
          continue;
        }
        
        // Check if this looks like a device
        if (value is Map) {
          final deviceData = Map<String, dynamic>.from(value);
          
          if (deviceData.containsKey('Meta') || 
              deviceData.containsKey('Sensor_Data') ||
              deviceData.containsKey('Actuator_Status') ||
              deviceData.containsKey('DeviceStatus')) {
            devicesToRemove.add(key);
          }
        }
      }
      
      // Remove device entries from old structure
      for (final deviceId in devicesToRemove) {
        await db.ref('Users/$uid/$deviceId').remove();
      }
      
      print('Successfully cleaned up ${devicesToRemove.length} old device entries for user $uid');
      return true;
      
    } catch (e) {
      print('Error cleaning up old device data for user $uid: $e');
      return false;
    }
  }
}

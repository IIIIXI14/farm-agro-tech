import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_config.dart';
import 'log_service.dart';
import '../models/actuator_status.dart';

class ActuatorService {
  final String uid;

  ActuatorService(this.uid);

  // Update actuator status in Firebase Realtime Database
  Future<void> updateActuatorStatus(
    String deviceId,
    String relayName,
    String status,
  ) async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      );
      
      final deviceRef = db.ref('Users/$uid/devices/$deviceId');
      
      // Update the specific relay status
      await deviceRef.child('Actuator_Status').child(relayName).set(status == 'Remote ON');
      
      // Update timestamp
      await deviceRef.child('Meta').update({
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      });

      // Log the action
      await LogService.logDeviceAction(
        uid,
        deviceId,
        'Actuator $relayName set to $status',
        type: LogType.info,
      );
    } catch (e) {
      throw Exception('Failed to update actuator status: $e');
    }
  }

  // Toggle a specific relay
  Future<void> toggleRelay(String deviceId, String relayName) async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      );
      
      final deviceRef = db.ref('Users/$uid/devices/$deviceId');
      
      // Get current status
      final currentStatus = await deviceRef.child('Actuator_Status').child(relayName).get();
      final isCurrentlyOn = currentStatus.exists && currentStatus.value == true;
      
      // Toggle the status
      final newStatus = !isCurrentlyOn;
      await deviceRef.child('Actuator_Status').child(relayName).set(newStatus);
      
      // Update timestamp
      await deviceRef.child('Meta').update({
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      });

      // Log the action
      await LogService.logDeviceAction(
        uid,
        deviceId,
        'Actuator $relayName toggled to ${newStatus ? 'ON' : 'OFF'}',
        type: LogType.info,
      );
    } catch (e) {
      throw Exception('Failed to toggle relay: $e');
    }
  }

  // Turn all relays on
  Future<void> turnAllRelaysOn(String deviceId) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    
    final deviceRef = db.ref('Users/$uid/devices/$deviceId');
    
    // Set all relays to ON
    await deviceRef.child('Actuator_Status').update({
      'relay1': true,
      'relay2': true,
      'relay3': true,
      'relay4': true,
      'relay5': true,
    });
    
    // Update timestamp
    await deviceRef.child('Meta').update({
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    });

    // Log the action
    await LogService.logDeviceAction(
      uid,
      deviceId,
      'All actuators turned ON',
      type: LogType.info,
    );
  }

  // Turn all relays off
  Future<void> turnAllRelaysOff(String deviceId) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    
    final deviceRef = db.ref('Users/$uid/devices/$deviceId');
    
    // Set all relays to OFF
    await deviceRef.child('Actuator_Status').update({
      'relay1': false,
      'relay2': false,
      'relay3': false,
      'relay4': false,
      'relay5': false,
    });
    
    // Update timestamp
    await deviceRef.child('Meta').update({
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    });

    // Log the action
    await LogService.logDeviceAction(
      uid,
      deviceId,
      'All actuators turned OFF',
      type: LogType.warning,
    );
  }

  // Get current actuator status
  Future<ActuatorStatus?> getActuatorStatus(String deviceId) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    
    final deviceRef = db.ref('Users/$uid/devices/$deviceId');
    final actuatorSnap = await deviceRef.child('Actuator_Status').get();
    
    if (!actuatorSnap.exists) {
      return null;
    }
    
    final actuatorData = actuatorSnap.value as Map<dynamic, dynamic>?;
    if (actuatorData == null) {
      return null;
    }
    
    final relayStatus = <String, String>{};
    actuatorData.forEach((key, value) {
      if (value is bool) {
        relayStatus[key.toString()] = value ? 'Remote ON' : 'Remote OFF';
      }
    });
    
    return ActuatorStatus(
      deviceId: deviceId,
      relayStatus: relayStatus,
      lastUpdated: DateTime.now(),
      userId: uid,
    );
  }

  // Stream actuator status changes
  Stream<ActuatorStatus?> getActuatorStatusStream(String deviceId) {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    
    return db.ref('Users/$uid/devices/$deviceId/Actuator_Status').onValue.map((event) {
      if (!event.snapshot.exists) {
        return null;
      }
      
      final actuatorData = event.snapshot.value as Map<dynamic, dynamic>?;
      if (actuatorData == null) {
        return null;
      }
      
      final relayStatus = <String, String>{};
      actuatorData.forEach((key, value) {
        if (value is bool) {
          relayStatus[key.toString()] = value ? 'Remote ON' : 'Remote OFF';
        }
      });
      
      return ActuatorStatus(
        deviceId: deviceId,
        relayStatus: relayStatus,
        lastUpdated: DateTime.now(),
        userId: uid,
      );
    });
  }

  // Emergency stop - turn off all relays immediately
  Future<void> emergencyStop(String deviceId) async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      );
      
      final deviceRef = db.ref('Users/$uid/devices/$deviceId');
      
      // Set all relays to OFF
      await deviceRef.child('Actuator_Status').update({
        'relay1': false,
        'relay2': false,
        'relay3': false,
        'relay4': false,
        'relay5': false,
      });
      
      // Update timestamp
      await deviceRef.child('Meta').update({
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      });

      // Log the emergency action
      await LogService.logDeviceAction(
        uid,
        deviceId,
        'EMERGENCY STOP - All actuators turned OFF',
        type: LogType.error,
      );
    } catch (e) {
      throw Exception('Failed to execute emergency stop: $e');
    }
  }

  // Get custom actuator names
  Future<Map<String, String>> getActuatorNames(String deviceId) async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      );
      
      final namesRef = db.ref('Users/$uid/devices/$deviceId/Actuator_Names');
      final snapshot = await namesRef.get();
      
      if (snapshot.exists && snapshot.value is Map) {
        final names = Map<String, dynamic>.from(snapshot.value as Map);
        return names.map((key, value) => MapEntry(key, value.toString()));
      }
      
      // Return default names if none are set
      return {
        'relay1': 'Motor Control',
        'relay2': 'Water Pump',
        'relay3': 'Lighting',
        'relay4': 'Siren',
        'relay5': 'Fan System',
      };
    } catch (e) {
      // Return default names on error
      return {
        'relay1': 'Motor Control',
        'relay2': 'Water Pump',
        'relay3': 'Lighting',
        'relay4': 'Siren',
        'relay5': 'Fan System',
      };
    }
  }

  // Update custom actuator names
  Future<void> updateActuatorNames(String deviceId, Map<String, String> names) async {
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConfig.realtimeDbUrl,
      );
      
      final deviceRef = db.ref('Users/$uid/devices/$deviceId');
      await deviceRef.child('Actuator_Names').set(names);
      
      // Update timestamp
      await deviceRef.child('Meta').update({
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      });

      // Log the action
      await LogService.logDeviceAction(
        uid,
        deviceId,
        'Actuator names updated',
        type: LogType.info,
      );
    } catch (e) {
      throw Exception('Failed to update actuator names: $e');
    }
  }

  // Stream actuator names changes
  Stream<Map<String, String>> getActuatorNamesStream(String deviceId) {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    
    return db.ref('Users/$uid/devices/$deviceId/Actuator_Names').onValue.map((event) {
      if (!event.snapshot.exists) {
        // Return default names if none are set
        return {
          'relay1': 'Motor Control',
          'relay2': 'Water Pump',
          'relay3': 'Lighting',
          'relay4': 'Siren',
          'relay5': 'Fan System',
        };
      }
      
      final names = event.snapshot.value as Map<dynamic, dynamic>?;
      if (names == null) {
        return {
          'relay1': 'Motor Control',
          'relay2': 'Water Pump',
          'relay3': 'Lighting',
          'relay4': 'Siren',
          'relay5': 'Fan System',
        };
      }
      
      return names.map((key, value) => MapEntry(key.toString(), value.toString()));
    });
  }
}

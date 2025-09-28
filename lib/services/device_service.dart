import 'package:cloud_firestore/cloud_firestore.dart';
import 'log_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_config.dart';
import 'notification_service.dart';
import '../models/sensor_reading.dart';

class AutomationRule {
  final String when;
  final String operator;
  final double value;

  AutomationRule({
    required this.when,
    required this.operator,
    required this.value,
  });

  factory AutomationRule.fromMap(Map<String, dynamic> map) {
    return AutomationRule(
      when: map['when'] as String,
      operator: map['operator'] as String,
      value: map['value'] as double,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'when': when,
      'operator': operator,
      'value': value,
    };
  }
}

class DeviceService {
  final String uid;

  DeviceService(this.uid);

  // Firestore list removed in favor of RTDB usage across UI
  Stream<QuerySnapshot> getDevicesStream() {
    return const Stream.empty();
  }

  Future<void> updateDeviceName(String deviceId, String name) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    
    // Update in user-scoped structure
    await db.ref('Users/$uid/Devices/$deviceId/Meta').update({
      'name': name,
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    });

    await LogService.logDeviceAction(
      uid,
      deviceId,
      'Device name updated to: $name',
      type: LogType.info,
    );
  }

  Future<void> updateActuator(String deviceId, String actuator, bool value) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    
    // Update in user-scoped structure (Actuators for control and reflect status)
    await db.ref('Users/$uid/Devices/$deviceId/Actuators/$actuator').set(value ? 'ON' : 'OFF');
    await db.ref('Users/$uid/Devices/$deviceId/Actuator_Status/$actuator/status').set(value ? 'ON' : 'OFF');
  }

  Future<void> deleteDevice(String deviceId) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    
    // Get device name from new structure first, fallback to old
    String deviceName = 'Unknown Device';
    final newMetaSnap = await db.ref('devices/$deviceId/Meta').get();
    if (newMetaSnap.exists && newMetaSnap.value is Map) {
      deviceName = Map<String, dynamic>.from(newMetaSnap.value as Map)['name']?.toString() ?? 'Unknown Device';
    } else {
      final oldMetaSnap = await db.ref('Users/$uid/devices/$deviceId/Meta').get();
      if (oldMetaSnap.exists && oldMetaSnap.value is Map) {
        deviceName = Map<String, dynamic>.from(oldMetaSnap.value as Map)['name']?.toString() ?? 'Unknown Device';
      }
    }
    
    // Delete from new devices collection
    await db.ref('devices/$deviceId').remove();
    
    // Also delete from old structure for backward compatibility
    await db.ref('Users/$uid/devices/$deviceId').remove();
    
    await LogService.logDeviceAction(uid, deviceId, 'Device deleted: $deviceName', type: LogType.warning);
  }

  Future<DocumentReference> addDevice(String name) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .add({
          'name': name,
          'deviceStatus': 'offline',
          'Sensor_Data': {
            'temperature': 0,
            'humidity': 0,
          },
          'Actuator_Status': {
            'motor': false,
            'light': false,
            'water': false,
            'siren': false,
          },
          'automationRules': {
            'motor': {
              'when': 'temperature',
              'operator': '>',
              'value': 35,
            },
            'water': {
              'when': 'humidity',
              'operator': '<',
              'value': 40,
            },
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> updateAutomationRule(
    String deviceId,
    String actuator,
    AutomationRule rule,
  ) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    await db.ref('Users/$uid/devices/$deviceId/AutomationRules/$actuator').set(rule.toMap());

    await LogService.logDeviceAction(
      uid,
      deviceId,
      'Automation rule updated for $actuator: ${rule.when} ${rule.operator} ${rule.value}',
      type: LogType.info,
    );
  }

  Future<void> deleteAutomationRule(String deviceId, String actuator) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    await db.ref('Users/$uid/devices/$deviceId/AutomationRules/$actuator').remove();

    await LogService.logDeviceAction(
      uid,
      deviceId,
      'Automation rule deleted for $actuator',
      type: LogType.info,
    );
  }

  Future<DocumentReference> addTestDevice() async {
    final testNames = [
      'Main Farm Motor',
      'Greenhouse Light',
      'Water Pump Station',
      'Security System',
      'Storage Room',
      'Field Sprinklers',
    ];
    final name = testNames[DateTime.now().microsecond % testNames.length];
    return addDevice(name);
  }

  Future<void> updateDeviceStatus(String deviceId, bool online) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .update({
          'deviceStatus': online ? 'online' : 'offline',
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Future<void> updateSensorData(
    String deviceId,
    double temperature,
    double humidity,
  ) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    final deviceRef = db.ref('Users/$uid/Devices/$deviceId');
    // Read current values
    final snap = await deviceRef.child('Sensor_Data').get();
    final currentMap = snap.exists && snap.value is Map
        ? Map<String, dynamic>.from(snap.value as Map)
        : <String, dynamic>{};
    final currentTemp = (currentMap['temperature'] as num?)?.toDouble();
    final currentHum = (currentMap['humidity'] as num?)?.toDouble();
    await deviceRef.update({
      'Sensor_Data': {
        'temperature': temperature,
        'humidity': humidity,
      },
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
      'deviceStatus': 'online',
    });

    // Create sensor reading for notification check
    final reading = SensorReading(
      deviceId: deviceId,
      temperature: temperature,
      humidity: humidity,
      timestamp: DateTime.now(),
    );

    // Check for sensor alerts
    await NotificationService().checkSensorAlerts(reading, deviceId);

    // Check for significant changes (more than 5 units)
    if (currentTemp != null &&
        currentHum != null &&
        ((temperature - currentTemp).abs() > 5 ||
        (humidity - currentHum).abs() > 5)) {
      await LogService.logDeviceAction(
        uid,
        deviceId,
        'Significant sensor change detected:\n'
        'Temperature: ${currentTemp.toStringAsFixed(1)}°C → ${temperature.toStringAsFixed(1)}°C\n'
        'Humidity: ${currentHum.toStringAsFixed(1)}% → ${humidity.toStringAsFixed(1)}%',
        type: LogType.warning,
      );
    }
  }

  Future<void> toggleActuator(String deviceId, String actuator, bool value) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    final ref = db.ref('Users/$uid/devices/$deviceId/Actuator_Status/$actuator');
    await ref.set(value ? 'ON' : 'OFF');
  }

  // Get actuator names for a device
  Future<Map<String, String>> getActuatorNames(String deviceId) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    final snapshot = await db.ref('Users/$uid/devices/$deviceId/Actuator_Names').get();
    
    if (snapshot.exists && snapshot.value is Map) {
      final Map<String, dynamic> names = Map<String, dynamic>.from(snapshot.value as Map);
      return names.map((key, value) => MapEntry(key, value.toString()));
    }
    
    // Return default names if none exist
    return {
      'relay1': 'Motor Control',
      'relay2': 'Water Pump',
      'relay3': 'Lighting',
      'relay4': 'Siren',
      'relay5': 'Fan System',
    };
  }

  // Toggle a specific relay
  Future<void> toggleRelay(String deviceId, String relay, bool value) async {
    await updateActuator(deviceId, relay, value);
  }

  // Turn all relays on
  Future<void> turnAllRelaysOn(String deviceId) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    
    final updates = <String, String>{};
    for (int i = 1; i <= 5; i++) {
      updates['relay$i/status'] = 'ON';
    }
    
    await db.ref('Users/$uid/devices/$deviceId/Actuator_Status').update(updates);
    
    await LogService.logDeviceAction(
      uid,
      deviceId,
      'All relays turned ON',
      type: LogType.info,
    );
  }

  // Turn all relays off
  Future<void> turnAllRelaysOff(String deviceId) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    
    final updates = <String, String>{};
    for (int i = 1; i <= 5; i++) {
      updates['relay$i/status'] = 'OFF';
    }
    
    await db.ref('Users/$uid/devices/$deviceId/Actuator_Status').update(updates);
    
    await LogService.logDeviceAction(
      uid,
      deviceId,
      'All relays turned OFF',
      type: LogType.info,
    );
  }

  // Emergency stop - turn off all actuators
  Future<void> emergencyStop(String deviceId) async {
    await turnAllRelaysOff(deviceId);
    
    await LogService.logDeviceAction(
      uid,
      deviceId,
      'EMERGENCY STOP activated',
      type: LogType.warning,
    );
  }

  // Update actuator names
  Future<void> updateActuatorNames(String deviceId, Map<String, String> names) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    
    await db.ref('Users/$uid/devices/$deviceId/Actuator_Names').set(names);
    
    await LogService.logDeviceAction(
      uid,
      deviceId,
      'Actuator names updated',
      type: LogType.info,
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'log_service.dart';

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

  Stream<QuerySnapshot> getDevicesStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .snapshots();
  }

  Future<void> updateDeviceName(String deviceId, String name) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .update({
      'name': name,
      'lastUpdate': FieldValue.serverTimestamp(),
    });

    await LogService.logDeviceAction(
      uid,
      deviceId,
      'Device name updated to: $name',
      type: LogType.info,
    );
  }

  Future<void> updateActuator(String deviceId, String actuator, bool value) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .update({'actuators.$actuator': value});
  }

  Future<void> deleteDevice(String deviceId) async {
    final deviceDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .get();

    final deviceName = deviceDoc.data()?['name'] as String? ?? 'Unknown Device';

    await deviceDoc.reference.delete();

    await LogService.logDeviceAction(
      uid,
      deviceId,
      'Device deleted: $deviceName',
      type: LogType.warning,
    );
  }

  Future<DocumentReference> addDevice(String name) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .add({
          'name': name,
          'status': 'offline',
          'sensorData': {
            'temperature': 0,
            'humidity': 0,
          },
          'actuators': {
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
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .update({
      'automationRules.$actuator': rule.toMap(),
      'lastUpdate': FieldValue.serverTimestamp(),
    });

    await LogService.logDeviceAction(
      uid,
      deviceId,
      'Automation rule updated for $actuator: ${rule.when} ${rule.operator} ${rule.value}',
      type: LogType.info,
    );
  }

  Future<void> deleteAutomationRule(String deviceId, String actuator) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .update({
      'automationRules.$actuator': FieldValue.delete(),
      'lastUpdate': FieldValue.serverTimestamp(),
    });

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
          'status': online ? 'online' : 'offline',
          'lastUpdate': FieldValue.serverTimestamp(),
        });
  }

  Future<void> updateSensorData(
    String deviceId,
    double temperature,
    double humidity,
  ) async {
    final deviceRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId);

    // Get current sensor data for comparison
    final deviceDoc = await deviceRef.get();
    final currentData = Map<String, dynamic>.from(
      deviceDoc.data()?['sensorData'] ?? {},
    );
    final currentTemp = (currentData['temperature'] as num?)?.toDouble();
    final currentHum = (currentData['humidity'] as num?)?.toDouble();

    // Update sensor data
    await deviceRef.update({
      'sensorData': {
        'temperature': temperature,
        'humidity': humidity,
      },
      'lastUpdate': FieldValue.serverTimestamp(),
    });

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
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .update({
      'actuators.$actuator': value,
      'lastUpdate': FieldValue.serverTimestamp(),
    });

    await LogService.logDeviceAction(
      uid,
      deviceId,
      'Actuator $actuator turned ${value ? 'ON' : 'OFF'}',
      type: value ? LogType.success : LogType.info,
    );
  }
} 
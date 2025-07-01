import 'package:hive_flutter/hive_flutter.dart';
import '../models/sensor_reading.dart';
import '../models/device_state.dart';
import '../models/automation_rule.dart';

class LocalStorageService {
  static const String _deviceBoxName = 'deviceBox';
  static const String _sensorBoxName = 'sensorBox';
  static const String _ruleBoxName = 'ruleBox';
  static const String _userBoxName = 'userBox';

  // Singleton pattern
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  // Box references
  late Box<DeviceState> _deviceBox;
  late Box<SensorReading> _sensorBox;
  late Box<AutomationRule> _ruleBox;
  late Box _userBox;

  // Initialize the service
  Future<void> initialize() async {
    _deviceBox = Hive.box<DeviceState>(_deviceBoxName);
    _sensorBox = Hive.box<SensorReading>(_sensorBoxName);
    _ruleBox = Hive.box<AutomationRule>(_ruleBoxName);
    _userBox = Hive.box(_userBoxName);
  }

  // ==================== DEVICE STATE OPERATIONS ====================

  // Save device state locally
  Future<void> saveDeviceState(DeviceState deviceState) async {
    await _deviceBox.put(deviceState.deviceId, deviceState);
  }

  // Get device state by ID
  DeviceState? getDeviceState(String deviceId) {
    return _deviceBox.get(deviceId);
  }

  // Get all device states for a user
  List<DeviceState> getDeviceStatesForUser(String userId) {
    return _deviceBox.values
        .where((device) => device.userId == userId)
        .toList();
  }

  // Update device actuators
  Future<void> updateDeviceActuators(String deviceId, Map<String, bool> actuators) async {
    final existing = _deviceBox.get(deviceId);
    if (existing != null) {
      final updated = existing.copyWith(
        actuators: actuators,
        lastUpdated: DateTime.now(),
      );
      await _deviceBox.put(deviceId, updated);
    }
  }

  // Delete device state
  Future<void> deleteDeviceState(String deviceId) async {
    await _deviceBox.delete(deviceId);
  }

  // ==================== SENSOR READINGS OPERATIONS ====================

  // Save sensor reading locally
  Future<void> saveSensorReading(SensorReading reading) async {
    await _sensorBox.add(reading);
  }

  // Get latest sensor reading for a device
  SensorReading? getLatestSensorReading(String deviceId) {
    final readings = _sensorBox.values
        .where((reading) => reading.deviceId == deviceId)
        .toList();
    
    if (readings.isEmpty) return null;
    
    readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return readings.first;
  }

  // Get sensor readings for a device within time range
  List<SensorReading> getSensorReadingsInRange(
    String deviceId,
    DateTime start,
    DateTime end,
  ) {
    return _sensorBox.values
        .where((reading) =>
            reading.deviceId == deviceId &&
            reading.timestamp.isAfter(start) &&
            reading.timestamp.isBefore(end))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // Get all sensor readings for a user
  List<SensorReading> getSensorReadingsForUser(String userId) {
    return _sensorBox.values
        .where((reading) => reading.userId == userId)
        .toList();
  }

  // Clean old sensor readings (keep last 1000 readings per device)
  Future<void> cleanOldSensorReadings() async {
    final deviceIds = _sensorBox.values.map((r) => r.deviceId).toSet();
    
    for (final deviceId in deviceIds) {
      final readings = _sensorBox.values
          .where((r) => r.deviceId == deviceId)
          .toList();
      
      if (readings.length > 1000) {
        readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final toDelete = readings.skip(1000);
        
        for (final reading in toDelete) {
          await reading.delete();
        }
      }
    }
  }

  // ==================== AUTOMATION RULES OPERATIONS ====================

  // Save automation rule locally
  Future<void> saveAutomationRule(AutomationRule rule) async {
    final key = '${rule.deviceId}_${rule.actuator}';
    await _ruleBox.put(key, rule);
  }

  // Get automation rule for a device and actuator
  AutomationRule? getAutomationRule(String deviceId, String actuator) {
    final key = '${deviceId}_$actuator';
    return _ruleBox.get(key);
  }

  // Get all automation rules for a device
  List<AutomationRule> getAutomationRulesForDevice(String deviceId) {
    return _ruleBox.values
        .where((rule) => rule.deviceId == deviceId)
        .toList();
  }

  // Get all automation rules for a user
  List<AutomationRule> getAutomationRulesForUser(String userId) {
    return _ruleBox.values
        .where((rule) => rule.userId == userId)
        .toList();
  }

  // Delete automation rule
  Future<void> deleteAutomationRule(String deviceId, String actuator) async {
    final key = '${deviceId}_$actuator';
    await _ruleBox.delete(key);
  }

  // ==================== USER DATA OPERATIONS ====================

  // Save user data locally
  Future<void> saveUserData(String userId, Map<String, dynamic> data) async {
    await _userBox.put(userId, data);
  }

  // Get user data
  Map<String, dynamic>? getUserData(String userId) {
    final data = _userBox.get(userId);
    return data is Map<String, dynamic> ? data : null;
  }

  // Save user's last sync timestamp
  Future<void> saveLastSyncTime(String userId) async {
    await _userBox.put('${userId}_lastSync', DateTime.now().millisecondsSinceEpoch);
  }

  // Get user's last sync timestamp
  DateTime? getLastSyncTime(String userId) {
    final timestamp = _userBox.get('${userId}_lastSync');
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // ==================== UTILITY OPERATIONS ====================

  // Clear all data for a user
  Future<void> clearUserData(String userId) async {
    // Clear device states
    final deviceStates = getDeviceStatesForUser(userId);
    for (final device in deviceStates) {
      await _deviceBox.delete(device.deviceId);
    }

    // Clear sensor readings
    final sensorReadings = getSensorReadingsForUser(userId);
    for (final reading in sensorReadings) {
      await reading.delete();
    }

    // Clear automation rules
    final automationRules = getAutomationRulesForUser(userId);
    for (final rule in automationRules) {
      await deleteAutomationRule(rule.deviceId, rule.actuator);
    }

    // Clear user data
    await _userBox.delete(userId);
    await _userBox.delete('${userId}_lastSync');
  }

  // Get storage statistics
  Map<String, int> getStorageStats() {
    return {
      'deviceStates': _deviceBox.length,
      'sensorReadings': _sensorBox.length,
      'automationRules': _ruleBox.length,
      'userData': _userBox.length,
    };
  }

  // Close all boxes
  Future<void> close() async {
    await _deviceBox.close();
    await _sensorBox.close();
    await _ruleBox.close();
    await _userBox.close();
  }
} 
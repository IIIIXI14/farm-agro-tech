import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

import 'package:farm_agro_tech/models/sensor_reading.dart';
import 'package:farm_agro_tech/models/device_state.dart';
import 'package:farm_agro_tech/models/automation_rule.dart';
import 'package:farm_agro_tech/services/local_storage_service.dart';

void main() {
  group('Local Storage Tests', () {
    late LocalStorageService storageService;

    setUpAll(() async {
      // Setup Hive for testing
      final tempDir = await Directory.systemTemp.createTemp('hive_test');
      Hive.init(tempDir.path);
      
      // Register adapters
      Hive.registerAdapter(SensorReadingAdapter());
      Hive.registerAdapter(DeviceStateAdapter());
      Hive.registerAdapter(AutomationRuleAdapter());
      
      // Open boxes
      await Hive.openBox<DeviceState>('deviceBox');
      await Hive.openBox<SensorReading>('sensorBox');
      await Hive.openBox<AutomationRule>('ruleBox');
      await Hive.openBox('userBox');
      
      storageService = LocalStorageService();
      await storageService.initialize();
    });

    tearDownAll(() async {
      await Hive.close();
    });

    test('should save and retrieve sensor reading', () async {
      // Arrange
      final reading = SensorReading(
        deviceId: 'test_device',
        temperature: 25.5,
        humidity: 60.2,
        timestamp: DateTime.now(),
        userId: 'test_user',
      );

      // Act
      await storageService.saveSensorReading(reading);
      final retrieved = storageService.getLatestSensorReading('test_device');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.deviceId, equals('test_device'));
      expect(retrieved.temperature, equals(25.5));
      expect(retrieved.humidity, equals(60.2));
    });

    test('should save and retrieve device state', () async {
      // Arrange
      final deviceState = DeviceState(
        deviceId: 'test_device',
        actuators: {
          'motor': true,
          'light': false,
          'water': true,
          'siren': false,
        },
        lastUpdated: DateTime.now(),
        userId: 'test_user',
        status: 'online',
        deviceName: 'Test Device',
      );

      // Act
      await storageService.saveDeviceState(deviceState);
      final retrieved = storageService.getDeviceState('test_device');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.deviceId, equals('test_device'));
      expect(retrieved.actuators['motor'], isTrue);
      expect(retrieved.actuators['light'], isFalse);
      expect(retrieved.status, equals('online'));
    });

    test('should save and retrieve automation rule', () async {
      // Arrange
      final rule = AutomationRule(
        deviceId: 'test_device',
        actuator: 'motor',
        condition: 'temperature',
        operator: '>',
        value: 35.0,
        duration: 300,
        userId: 'test_user',
      );

      // Act
      await storageService.saveAutomationRule(rule);
      final retrieved = storageService.getAutomationRule('test_device', 'motor');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.deviceId, equals('test_device'));
      expect(retrieved.actuator, equals('motor'));
      expect(retrieved.condition, equals('temperature'));
      expect(retrieved.operator, equals('>'));
      expect(retrieved.value, equals(35.0));
    });

    test('should update device actuators', () async {
      // Arrange
      final deviceState = DeviceState(
        deviceId: 'test_device_2',
        actuators: {
          'motor': false,
          'light': false,
        },
        lastUpdated: DateTime.now(),
        userId: 'test_user',
      );
      await storageService.saveDeviceState(deviceState);

      // Act
      await storageService.updateDeviceActuators('test_device_2', {
        'motor': true,
        'light': true,
      });
      final updated = storageService.getDeviceState('test_device_2');

      // Assert
      expect(updated, isNotNull);
      expect(updated!.actuators['motor'], isTrue);
      expect(updated.actuators['light'], isTrue);
    });

    test('should get storage statistics', () {
      // Act
      final stats = storageService.getStorageStats();

      // Assert
      expect(stats, isA<Map<String, int>>());
      expect(stats.containsKey('deviceStates'), isTrue);
      expect(stats.containsKey('sensorReadings'), isTrue);
      expect(stats.containsKey('automationRules'), isTrue);
      expect(stats.containsKey('userData'), isTrue);
    });

    test('automation rule should trigger correctly', () {
      // Arrange
      final rule = AutomationRule(
        deviceId: 'test_device',
        actuator: 'motor',
        condition: 'temperature',
        operator: '>',
        value: 30.0,
        userId: 'test_user',
      );

      // Act & Assert
      expect(rule.shouldTrigger(35.0, 50.0), isTrue); // Should trigger
      expect(rule.shouldTrigger(25.0, 50.0), isFalse); // Should not trigger
    });
  });
} 
# 📱 Offline Storage Implementation - Day 1

## Overview

This implementation adds **Hive-based local storage** to the FarmAgroTech app, enabling offline functionality and data caching.

## 🏗️ Architecture

### Data Models
- **SensorReading**: Stores temperature and humidity data
- **DeviceState**: Stores device actuator states and status
- **AutomationRule**: Stores automation rules for devices

### Storage Service
- **LocalStorageService**: Singleton service managing all local storage operations

## 📦 Dependencies Added

```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
```

## 🚀 Usage Examples

### 1. Saving Sensor Data Locally

```dart
final storage = LocalStorageService();

// Save a new sensor reading
final reading = SensorReading(
  deviceId: 'device_001',
  temperature: 25.5,
  humidity: 60.2,
  timestamp: DateTime.now(),
  userId: 'user_123',
);
await storage.saveSensorReading(reading);
```

### 2. Retrieving Latest Sensor Data

```dart
// Get latest reading for a device
final latestReading = storage.getLatestSensorReading('device_001');

// Get readings within a time range
final readings = storage.getSensorReadingsInRange(
  'device_001',
  DateTime.now().subtract(Duration(hours: 24)),
  DateTime.now(),
);
```

### 3. Managing Device States

```dart
// Save device state
final deviceState = DeviceState(
  deviceId: 'device_001',
  actuators: {
    'motor': true,
    'light': false,
    'water': true,
    'siren': false,
  },
  lastUpdated: DateTime.now(),
  userId: 'user_123',
  status: 'online',
  deviceName: 'Main Farm Device',
);
await storage.saveDeviceState(deviceState);

// Update actuators
await storage.updateDeviceActuators('device_001', {
  'motor': false,
  'light': true,
});
```

### 4. Automation Rules

```dart
// Save automation rule
final rule = AutomationRule(
  deviceId: 'device_001',
  actuator: 'motor',
  condition: 'temperature',
  operator: '>',
  value: 35.0,
  duration: 300, // 5 minutes
  userId: 'user_123',
);
await storage.saveAutomationRule(rule);

// Check if rule should trigger
if (rule.shouldTrigger(36.5, 45.0)) {
  print('Rule should trigger!');
}
```

### 5. User Data Management

```dart
// Save user data
await storage.saveUserData('user_123', {
  'preferences': {'theme': 'dark'},
  'lastSync': DateTime.now().toIso8601String(),
});

// Get user data
final userData = storage.getUserData('user_123');

// Track sync times
await storage.saveLastSyncTime('user_123');
final lastSync = storage.getLastSyncTime('user_123');
```

## 🔧 Storage Statistics

```dart
// Get storage statistics
final stats = storage.getStorageStats();
print('Device States: ${stats['deviceStates']}');
print('Sensor Readings: ${stats['sensorReadings']}');
print('Automation Rules: ${stats['automationRules']}');
print('User Data: ${stats['userData']}');
```

## 🧹 Data Cleanup

```dart
// Clean old sensor readings (keeps last 1000 per device)
await storage.cleanOldSensorReadings();

// Clear all data for a user
await storage.clearUserData('user_123');
```

## 🔄 Integration with Firebase

The models include conversion methods for seamless integration:

```dart
// Convert from Firestore data
final reading = SensorReading.fromFirestore(
  firestoreData,
  'device_001',
  'user_123',
);

// Convert to Firestore format
final firestoreData = reading.toFirestore();
```

## 📱 UI Integration

The `OfflineStatusWidget` demonstrates local storage functionality:

- Shows storage statistics
- Allows adding test data
- Provides data cleanup options
- Displays real-time storage status

## 🔮 Next Steps (Day 2+)

1. **Sync Service**: Implement bidirectional sync between local and Firebase
2. **Conflict Resolution**: Handle data conflicts during sync
3. **Offline Indicators**: Show offline status in UI
4. **Background Sync**: Sync data when app comes online
5. **Data Compression**: Optimize storage usage

## 🐛 Troubleshooting

### Build Issues
If you get build errors, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Storage Issues
- Check if Hive is properly initialized in `main.dart`
- Ensure adapters are registered before opening boxes
- Verify data types match Hive field types

### Performance Issues
- Use `cleanOldSensorReadings()` regularly
- Consider pagination for large datasets
- Monitor storage statistics

## 📊 Benefits

✅ **Offline Functionality**: App works without internet
✅ **Faster Loading**: Local data loads instantly
✅ **Reduced Bandwidth**: Less Firebase calls
✅ **Better UX**: No loading spinners for cached data
✅ **Data Persistence**: Data survives app restarts
✅ **Battery Efficient**: Fewer network requests 
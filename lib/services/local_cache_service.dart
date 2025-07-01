import 'package:hive/hive.dart';
import '../models/sensor_reading.dart';

class LocalCacheService {
  static Future<void> saveSensorReadings(List<SensorReading> readings) async {
    final box = Hive.box('sensorBox');
    for (var reading in readings) {
      box.put('${reading.deviceId}_${reading.timestamp.toIso8601String()}', reading);
    }
  }

  static Future<List<SensorReading>> getSensorReadings(String deviceId) async {
    final box = Hive.box('sensorBox');
    return box.values
      .cast<SensorReading>()
      .where((r) => r.deviceId == deviceId)
      .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
} 
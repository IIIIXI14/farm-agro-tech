import '../models/sensor_reading.dart';
import 'firebase_service.dart';
import 'local_cache_service.dart';
import 'connectivity_service.dart';

class DataRepository {
  static Future<List<SensorReading>> getSensorReadings(String deviceId) async {
    final online = await ConnectivityService.isOnline();

    if (online) {
      final firebaseData = await FirebaseService.getSensorReadings(deviceId);
      await LocalCacheService.saveSensorReadings(firebaseData);
      return firebaseData;
    } else {
      return await LocalCacheService.getSensorReadings(deviceId);
    }
  }
} 
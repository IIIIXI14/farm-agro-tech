import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_reading.dart';

class FirebaseService {
  static Future<List<SensorReading>> getSensorReadings(String deviceId) async {
    final snapshot = await FirebaseFirestore.instance
      .collection('sensor_data')
      .where('deviceId', isEqualTo: deviceId)
      .orderBy('timestamp', descending: true)
      .limit(50)
      .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return SensorReading(
        deviceId: data['deviceId'],
        temperature: (data['temperature'] as num).toDouble(),
        humidity: (data['humidity'] as num).toDouble(),
        timestamp: (data['timestamp'] as Timestamp).toDate(),
      );
    }).toList();
  }
} 
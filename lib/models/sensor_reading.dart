import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'sensor_reading.g.dart';

@HiveType(typeId: 0)
class SensorReading extends HiveObject {
  @HiveField(0)
  final String deviceId;

  @HiveField(1)
  final double temperature;

  @HiveField(2)
  final double humidity;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String? userId;

  SensorReading({
    required this.deviceId,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
    this.userId,
  });

  // Convert from Firestore data
  factory SensorReading.fromFirestore(Map<String, dynamic> data, String deviceId, String userId) {
    return SensorReading(
      deviceId: deviceId,
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (data['humidity'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: userId,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() {
    return 'SensorReading(deviceId: $deviceId, temperature: $temperature, humidity: $humidity, timestamp: $timestamp)';
  }
} 
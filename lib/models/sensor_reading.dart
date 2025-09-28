import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Added for IconData and Color

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

  // New sensor fields
  @HiveField(5)
  final double? soilMoisture;

  @HiveField(6)
  final double? lightIntensity;

  @HiveField(7)
  final double? phLevel;

  @HiveField(8)
  final double? co2Level;

  @HiveField(9)
  final double? airQuality;

  @HiveField(10)
  final double? rainfall;

  @HiveField(11)
  final double? windSpeed;

  @HiveField(12)
  final String? weatherCondition;

  @HiveField(13)
  final Map<String, dynamic>? additionalData;

  SensorReading({
    required this.deviceId,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
    this.userId,
    this.soilMoisture,
    this.lightIntensity,
    this.phLevel,
    this.co2Level,
    this.airQuality,
    this.rainfall,
    this.windSpeed,
    this.weatherCondition,
    this.additionalData,
  });

  // Convert from Firestore data
  factory SensorReading.fromFirestore(Map<String, dynamic> data, String deviceId, String userId) {
    return SensorReading(
      deviceId: deviceId,
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (data['humidity'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: userId,
      soilMoisture: (data['soilMoisture'] as num?)?.toDouble(),
      lightIntensity: (data['lightIntensity'] as num?)?.toDouble(),
      phLevel: (data['phLevel'] as num?)?.toDouble(),
      co2Level: (data['co2Level'] as num?)?.toDouble(),
      airQuality: (data['airQuality'] as num?)?.toDouble(),
      rainfall: (data['rainfall'] as num?)?.toDouble(),
      windSpeed: (data['windSpeed'] as num?)?.toDouble(),
      weatherCondition: data['weatherCondition'] as String?,
      additionalData: data['additionalData'] as Map<String, dynamic>?,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': timestamp,
    };

    // Add optional fields if they exist
    if (soilMoisture != null) map['soilMoisture'] = soilMoisture;
    if (lightIntensity != null) map['lightIntensity'] = lightIntensity;
    if (phLevel != null) map['phLevel'] = phLevel;
    if (co2Level != null) map['co2Level'] = co2Level;
    if (airQuality != null) map['airQuality'] = airQuality;
    if (rainfall != null) map['rainfall'] = rainfall;
    if (windSpeed != null) map['windSpeed'] = windSpeed;
    if (weatherCondition != null) map['weatherCondition'] = weatherCondition;
    if (additionalData != null) map['additionalData'] = additionalData;

    return map;
  }

  // Get sensor value by type
  double? getSensorValue(String sensorType) {
    switch (sensorType.toLowerCase()) {
      case 'temperature':
        return temperature;
      case 'humidity':
        return humidity;
      case 'soilmoisture':
        return soilMoisture;
      case 'lightintensity':
        return lightIntensity;
      case 'phlevel':
        return phLevel;
      case 'co2level':
        return co2Level;
      case 'airquality':
        return airQuality;
      case 'rainfall':
        return rainfall;
      case 'windspeed':
        return windSpeed;
      default:
        return null;
    }
  }

  // Get sensor unit by type
  static String getSensorUnit(String sensorType) {
    switch (sensorType.toLowerCase()) {
      case 'temperature':
        return '°C';
      case 'humidity':
        return '%';
      case 'soilmoisture':
        return '%';
      case 'lightintensity':
        return 'lux';
      case 'phlevel':
        return 'pH';
      case 'co2level':
        return 'ppm';
      case 'airquality':
        return 'AQI';
      case 'rainfall':
        return 'mm';
      case 'windspeed':
        return 'm/s';
      default:
        return '';
    }
  }

  // Get sensor icon by type
  static IconData getSensorIcon(String sensorType) {
    switch (sensorType.toLowerCase()) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'soilmoisture':
        return Icons.grass;
      case 'lightintensity':
        return Icons.wb_sunny;
      case 'phlevel':
        return Icons.science;
      case 'co2level':
        return Icons.cloud;
      case 'airquality':
        return Icons.air;
      case 'rainfall':
        return Icons.umbrella;
      case 'windspeed':
        return Icons.air;
      default:
        return Icons.sensors;
    }
  }

  // Check if sensor reading is within normal range
  bool isWithinNormalRange(String sensorType) {
    final value = getSensorValue(sensorType);
    if (value == null) return true;

    switch (sensorType.toLowerCase()) {
      case 'temperature':
        return value >= 10 && value <= 40;
      case 'humidity':
        return value >= 30 && value <= 80;
      case 'soilmoisture':
        return value >= 20 && value <= 80;
      case 'phlevel':
        return value >= 5.5 && value <= 7.5;
      case 'co2level':
        return value <= 1000;
      case 'airquality':
        return value <= 100;
      default:
        return true;
    }
  }

  // Get sensor status color
  Color getSensorStatusColor(String sensorType) {
    if (isWithinNormalRange(sensorType)) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  @override
  String toString() {
    return 'SensorReading(deviceId: $deviceId, temperature: $temperature, humidity: $humidity, timestamp: $timestamp)';
  }
} 
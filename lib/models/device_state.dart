import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'device_state.g.dart';

@HiveType(typeId: 1)
class DeviceState extends HiveObject {
  @HiveField(0)
  final String deviceId;

  @HiveField(1)
  final Map<String, bool> actuators; // e.g. {'motor': true, 'light': false}

  @HiveField(2)
  final DateTime lastUpdated;

  @HiveField(3)
  final String? userId;

  @HiveField(4)
  final String status; // 'online' or 'offline'

  @HiveField(5)
  final String? deviceName;

  DeviceState({
    required this.deviceId,
    required this.actuators,
    required this.lastUpdated,
    this.userId,
    this.status = 'offline',
    this.deviceName,
  });

  // Convert from Firestore data
  factory DeviceState.fromFirestore(Map<String, dynamic> data, String deviceId, String userId) {
    final actuatorsData = data['actuators'] as Map<String, dynamic>? ?? {};
    final actuators = <String, bool>{};
    
    actuatorsData.forEach((key, value) {
      actuators[key] = value as bool? ?? false;
    });

    return DeviceState(
      deviceId: deviceId,
      actuators: actuators,
      lastUpdated: (data['timestamp'] as Timestamp?)?.toDate() ?? (data['lastUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: userId,
      status: data['status'] as String? ?? 'offline',
      deviceName: data['name'] as String?,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'actuators': actuators,
      'timestamp': lastUpdated,
      'status': status,
      if (deviceName != null) 'name': deviceName,
    };
  }

  // Create a copy with updated actuators
  DeviceState copyWith({
    String? deviceId,
    Map<String, bool>? actuators,
    DateTime? lastUpdated,
    String? userId,
    String? status,
    String? deviceName,
  }) {
    return DeviceState(
      deviceId: deviceId ?? this.deviceId,
      actuators: actuators ?? this.actuators,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      deviceName: deviceName ?? this.deviceName,
    );
  }

  @override
  String toString() {
    return 'DeviceState(deviceId: $deviceId, actuators: $actuators, status: $status, lastUpdated: $lastUpdated)';
  }
} 
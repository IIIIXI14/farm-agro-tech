import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'actuator_status.g.dart';

@HiveType(typeId: 2)
class ActuatorStatus extends HiveObject {
  @HiveField(0)
  final String deviceId;

  @HiveField(1)
  final Map<String, String> relayStatus;

  @HiveField(2)
  final DateTime lastUpdated;

  @HiveField(3)
  final String? userId;

  ActuatorStatus({
    required this.deviceId,
    required this.relayStatus,
    required this.lastUpdated,
    this.userId,
  });

  // Convert from Firestore data
  factory ActuatorStatus.fromFirestore(Map<String, dynamic> data, String deviceId, String userId) {
    final actuatorData = data['Actuator_Status'] as Map<String, dynamic>? ?? {};
    final relayStatus = <String, String>{};
    
    // Convert boolean values to status strings
    actuatorData.forEach((key, value) {
      if (value is bool) {
        relayStatus[key] = value ? 'Remote ON' : 'Remote OFF';
      } else if (value is String) {
        relayStatus[key] = value;
      }
    });

    return ActuatorStatus(
      deviceId: deviceId,
      relayStatus: relayStatus,
      lastUpdated: (data['timestamp'] as Timestamp?)?.toDate() ?? 
                   (data['lastUpdate'] as Timestamp?)?.toDate() ?? 
                   DateTime.now(),
      userId: userId,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    final actuatorStatus = <String, dynamic>{};
    relayStatus.forEach((key, value) {
      // Convert status strings back to boolean for Firestore
      actuatorStatus[key] = value == 'Remote ON';
    });

    return {
      'Actuator_Status': actuatorStatus,
      'timestamp': lastUpdated,
    };
  }

  // Create a copy with updated fields
  ActuatorStatus copyWith({
    String? deviceId,
    Map<String, String>? relayStatus,
    DateTime? lastUpdated,
    String? userId,
  }) {
    return ActuatorStatus(
      deviceId: deviceId ?? this.deviceId,
      relayStatus: relayStatus ?? this.relayStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      userId: userId ?? this.userId,
    );
  }

  // Get status of a specific relay
  String getRelayStatus(String relayName) {
    return relayStatus[relayName] ?? 'Remote OFF';
  }

  // Check if a relay is on
  bool isRelayOn(String relayName) {
    return getRelayStatus(relayName) == 'Remote ON';
  }

  // Update a specific relay status
  ActuatorStatus updateRelayStatus(String relayName, String status) {
    final updatedStatus = Map<String, String>.from(relayStatus);
    updatedStatus[relayName] = status;
    
    return copyWith(
      relayStatus: updatedStatus,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'ActuatorStatus(deviceId: $deviceId, relayStatus: $relayStatus, lastUpdated: $lastUpdated)';
  }
}

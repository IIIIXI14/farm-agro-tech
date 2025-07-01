import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'automation_rule.g.dart';

@HiveType(typeId: 2)
class AutomationRule extends HiveObject {
  @HiveField(0)
  final String deviceId;

  @HiveField(1)
  final String actuator; // 'motor', 'light', 'water', 'siren'

  @HiveField(2)
  final String condition; // 'temperature' or 'humidity'

  @HiveField(3)
  final String operator; // '>', '<', '>=', '<=', '=='

  @HiveField(4)
  final double value; // threshold value

  @HiveField(5)
  final int? duration; // optional duration in seconds

  @HiveField(6)
  final String? userId;

  @HiveField(7)
  final bool isActive;

  @HiveField(8)
  final DateTime createdAt;

  AutomationRule({
    required this.deviceId,
    required this.actuator,
    required this.condition,
    required this.operator,
    required this.value,
    this.duration,
    this.userId,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert from Firestore data
  factory AutomationRule.fromFirestore(Map<String, dynamic> data, String deviceId, String actuator, String userId) {
    return AutomationRule(
      deviceId: deviceId,
      actuator: actuator,
      condition: data['when'] as String? ?? 'temperature',
      operator: data['operator'] as String? ?? '>',
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
      duration: data['duration'] as int?,
      userId: userId,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'when': condition,
      'operator': operator,
      'value': value,
      if (duration != null) 'duration': duration,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  // Check if the rule should trigger based on sensor values
  bool shouldTrigger(double temperature, double humidity) {
    if (!isActive) return false;

    double currentValue;
    switch (condition) {
      case 'temperature':
        currentValue = temperature;
        break;
      case 'humidity':
        currentValue = humidity;
        break;
      default:
        return false;
    }

    switch (operator) {
      case '>':
        return currentValue > value;
      case '<':
        return currentValue < value;
      case '>=':
        return currentValue >= value;
      case '<=':
        return currentValue <= value;
      case '==':
        return (currentValue - value).abs() < 0.1; // tolerance for floating point
      default:
        return false;
    }
  }

  // Create a copy with updated values
  AutomationRule copyWith({
    String? deviceId,
    String? actuator,
    String? condition,
    String? operator,
    double? value,
    int? duration,
    String? userId,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AutomationRule(
      deviceId: deviceId ?? this.deviceId,
      actuator: actuator ?? this.actuator,
      condition: condition ?? this.condition,
      operator: operator ?? this.operator,
      value: value ?? this.value,
      duration: duration ?? this.duration,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AutomationRule(deviceId: $deviceId, actuator: $actuator, condition: $condition $operator $value, isActive: $isActive)';
  }
} 
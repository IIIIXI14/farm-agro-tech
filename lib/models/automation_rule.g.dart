// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'automation_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AutomationRuleAdapter extends TypeAdapter<AutomationRule> {
  @override
  final int typeId = 2;

  @override
  AutomationRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AutomationRule(
      deviceId: fields[0] as String,
      actuator: fields[1] as String,
      condition: fields[2] as String,
      operator: fields[3] as String,
      value: fields[4] as double,
      duration: fields[5] as int?,
      userId: fields[6] as String?,
      isActive: fields[7] as bool,
      createdAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AutomationRule obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.deviceId)
      ..writeByte(1)
      ..write(obj.actuator)
      ..writeByte(2)
      ..write(obj.condition)
      ..writeByte(3)
      ..write(obj.operator)
      ..writeByte(4)
      ..write(obj.value)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.userId)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutomationRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

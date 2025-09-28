// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actuator_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActuatorStatusAdapter extends TypeAdapter<ActuatorStatus> {
  @override
  final int typeId = 2;

  @override
  ActuatorStatus read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActuatorStatus(
      deviceId: fields[0] as String,
      relayStatus: (fields[1] as Map).cast<String, String>(),
      lastUpdated: fields[2] as DateTime,
      userId: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ActuatorStatus obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.deviceId)
      ..writeByte(1)
      ..write(obj.relayStatus)
      ..writeByte(2)
      ..write(obj.lastUpdated)
      ..writeByte(3)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActuatorStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

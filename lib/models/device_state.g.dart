// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeviceStateAdapter extends TypeAdapter<DeviceState> {
  @override
  final int typeId = 1;

  @override
  DeviceState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeviceState(
      deviceId: fields[0] as String,
      actuators: (fields[1] as Map).cast<String, bool>(),
      lastUpdated: fields[2] as DateTime,
      userId: fields[3] as String?,
      status: fields[4] as String,
      deviceName: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DeviceState obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.deviceId)
      ..writeByte(1)
      ..write(obj.actuators)
      ..writeByte(2)
      ..write(obj.lastUpdated)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.deviceName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

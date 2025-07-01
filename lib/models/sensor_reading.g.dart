// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_reading.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SensorReadingAdapter extends TypeAdapter<SensorReading> {
  @override
  final int typeId = 0;

  @override
  SensorReading read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SensorReading(
      deviceId: fields[0] as String,
      temperature: fields[1] as double,
      humidity: fields[2] as double,
      timestamp: fields[3] as DateTime,
      userId: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SensorReading obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.deviceId)
      ..writeByte(1)
      ..write(obj.temperature)
      ..writeByte(2)
      ..write(obj.humidity)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorReadingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

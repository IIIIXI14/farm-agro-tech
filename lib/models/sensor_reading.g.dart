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
      soilMoisture: fields[5] as double?,
      lightIntensity: fields[6] as double?,
      phLevel: fields[7] as double?,
      co2Level: fields[8] as double?,
      airQuality: fields[9] as double?,
      rainfall: fields[10] as double?,
      windSpeed: fields[11] as double?,
      weatherCondition: fields[12] as String?,
      additionalData: (fields[13] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, SensorReading obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.deviceId)
      ..writeByte(1)
      ..write(obj.temperature)
      ..writeByte(2)
      ..write(obj.humidity)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.userId)
      ..writeByte(5)
      ..write(obj.soilMoisture)
      ..writeByte(6)
      ..write(obj.lightIntensity)
      ..writeByte(7)
      ..write(obj.phLevel)
      ..writeByte(8)
      ..write(obj.co2Level)
      ..writeByte(9)
      ..write(obj.airQuality)
      ..writeByte(10)
      ..write(obj.rainfall)
      ..writeByte(11)
      ..write(obj.windSpeed)
      ..writeByte(12)
      ..write(obj.weatherCondition)
      ..writeByte(13)
      ..write(obj.additionalData);
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

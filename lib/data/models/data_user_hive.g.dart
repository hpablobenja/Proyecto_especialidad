// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_user_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DataUserHiveAdapter extends TypeAdapter<DataUserHive> {
  @override
  final int typeId = 7;

  @override
  DataUserHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DataUserHive(
      userId: fields[0] as String,
      currentSessionMinutes: fields[1] as int,
      totalSessionMinutes: fields[2] as int,
      sessionStartTime: fields[3] as DateTime?,
      lastSessionEnd: fields[4] as DateTime,
      categoryProgress: (fields[5] as Map).cast<String, double>(),
      overallProgress: fields[6] as double,
      unlockedAchievements: (fields[7] as List).cast<String>(),
      updatedAt: fields[8] as DateTime,
      totalCourses: fields[9] as int,
      completedCourses: fields[10] as int,
      inProgressCourses: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DataUserHive obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.currentSessionMinutes)
      ..writeByte(2)
      ..write(obj.totalSessionMinutes)
      ..writeByte(3)
      ..write(obj.sessionStartTime)
      ..writeByte(4)
      ..write(obj.lastSessionEnd)
      ..writeByte(5)
      ..write(obj.categoryProgress)
      ..writeByte(6)
      ..write(obj.overallProgress)
      ..writeByte(7)
      ..write(obj.unlockedAchievements)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.totalCourses)
      ..writeByte(10)
      ..write(obj.completedCourses)
      ..writeByte(11)
      ..write(obj.inProgressCourses);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataUserHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

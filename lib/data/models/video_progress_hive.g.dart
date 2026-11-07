// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_progress_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoProgressHiveAdapter extends TypeAdapter<VideoProgressHive> {
  @override
  final int typeId = 1;

  @override
  VideoProgressHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoProgressHive(
      userId: fields[0] as String,
      courseId: fields[1] as String,
      moduleId: fields[2] as String,
      lessonId: fields[3] as String,
      currentPositionMs: fields[4] as int,
      lastValidPositionMs: fields[5] as int,
      maxReachedPositionMs: fields[6] as int,
      viewedSeconds: fields[7] as int,
      completionPercentage: fields[8] as double,
      totalDurationMs: fields[9] as int,
      checkpointsPassed: (fields[10] as List).cast<String>(),
      checkpointsFailed: (fields[11] as List).cast<String>(),
      isCompleted: fields[12] as bool,
      lastUpdated: fields[13] as DateTime,
      needsSync: fields[14] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, VideoProgressHive obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.courseId)
      ..writeByte(2)
      ..write(obj.moduleId)
      ..writeByte(3)
      ..write(obj.lessonId)
      ..writeByte(4)
      ..write(obj.currentPositionMs)
      ..writeByte(5)
      ..write(obj.lastValidPositionMs)
      ..writeByte(6)
      ..write(obj.maxReachedPositionMs)
      ..writeByte(7)
      ..write(obj.viewedSeconds)
      ..writeByte(8)
      ..write(obj.completionPercentage)
      ..writeByte(9)
      ..write(obj.totalDurationMs)
      ..writeByte(10)
      ..write(obj.checkpointsPassed)
      ..writeByte(11)
      ..write(obj.checkpointsFailed)
      ..writeByte(12)
      ..write(obj.isCompleted)
      ..writeByte(13)
      ..write(obj.lastUpdated)
      ..writeByte(14)
      ..write(obj.needsSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoProgressHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

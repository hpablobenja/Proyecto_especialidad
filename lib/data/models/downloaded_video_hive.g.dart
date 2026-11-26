// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloaded_video_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadedVideoHiveAdapter extends TypeAdapter<DownloadedVideoHive> {
  @override
  final int typeId = 6;

  @override
  DownloadedVideoHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadedVideoHive(
      userId: fields[0] as String,
      videoId: fields[1] as String,
      courseId: fields[2] as String,
      localPath: fields[3] as String,
      downloadStatus: fields[4] as String,
      downloadedAt: fields[5] as DateTime,
      fileSize: fields[6] as int,
      watchedSeconds: fields[7] as int,
      totalSeconds: fields[8] as int,
      pendingSync: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadedVideoHive obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.videoId)
      ..writeByte(2)
      ..write(obj.courseId)
      ..writeByte(3)
      ..write(obj.localPath)
      ..writeByte(4)
      ..write(obj.downloadStatus)
      ..writeByte(5)
      ..write(obj.downloadedAt)
      ..writeByte(6)
      ..write(obj.fileSize)
      ..writeByte(7)
      ..write(obj.watchedSeconds)
      ..writeByte(8)
      ..write(obj.totalSeconds)
      ..writeByte(9)
      ..write(obj.pendingSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadedVideoHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

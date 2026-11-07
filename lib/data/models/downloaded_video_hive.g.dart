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
      videoId: fields[0] as String,
      courseId: fields[1] as String,
      localPath: fields[2] as String,
      downloadStatus: fields[3] as String,
      downloadedAt: fields[4] as DateTime,
      fileSize: fields[5] as int,
      watchedSeconds: fields[6] as int,
      totalSeconds: fields[7] as int,
      pendingSync: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadedVideoHive obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.videoId)
      ..writeByte(1)
      ..write(obj.courseId)
      ..writeByte(2)
      ..write(obj.localPath)
      ..writeByte(3)
      ..write(obj.downloadStatus)
      ..writeByte(4)
      ..write(obj.downloadedAt)
      ..writeByte(5)
      ..write(obj.fileSize)
      ..writeByte(6)
      ..write(obj.watchedSeconds)
      ..writeByte(7)
      ..write(obj.totalSeconds)
      ..writeByte(8)
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

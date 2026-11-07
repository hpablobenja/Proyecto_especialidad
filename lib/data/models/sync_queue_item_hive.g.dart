// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue_item_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncQueueItemHiveAdapter extends TypeAdapter<SyncQueueItemHive> {
  @override
  final int typeId = 3;

  @override
  SyncQueueItemHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncQueueItemHive(
      syncId: fields[0] as String,
      operation: fields[1] as String,
      targetId: fields[2] as String,
      payloadJson: fields[3] as String,
      createdAt: fields[4] as DateTime,
      retryCount: fields[5] as int,
      isProcessing: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueueItemHive obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.syncId)
      ..writeByte(1)
      ..write(obj.operation)
      ..writeByte(2)
      ..write(obj.targetId)
      ..writeByte(3)
      ..write(obj.payloadJson)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.retryCount)
      ..writeByte(6)
      ..write(obj.isProcessing);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncQueueItemHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

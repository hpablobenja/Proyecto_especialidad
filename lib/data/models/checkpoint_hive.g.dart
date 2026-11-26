// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkpoint_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CheckpointHiveAdapter extends TypeAdapter<CheckpointHive> {
  @override
  final int typeId = 2;

  @override
  CheckpointHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckpointHive(
      userId: fields[0] as String,
      checkpointId: fields[1] as String,
      lessonId: fields[2] as String,
      triggerPositionSeconds: fields[3] as int,
      question: fields[4] as String,
      options: (fields[5] as List).cast<String>(),
      correctOptionIndex: fields[6] as int,
      isPassed: fields[7] as bool,
      passedAt: fields[8] as DateTime?,
      attempts: fields[9] as int,
      firstAttemptAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CheckpointHive obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.checkpointId)
      ..writeByte(2)
      ..write(obj.lessonId)
      ..writeByte(3)
      ..write(obj.triggerPositionSeconds)
      ..writeByte(4)
      ..write(obj.question)
      ..writeByte(5)
      ..write(obj.options)
      ..writeByte(6)
      ..write(obj.correctOptionIndex)
      ..writeByte(7)
      ..write(obj.isPassed)
      ..writeByte(8)
      ..write(obj.passedAt)
      ..writeByte(9)
      ..write(obj.attempts)
      ..writeByte(10)
      ..write(obj.firstAttemptAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckpointHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

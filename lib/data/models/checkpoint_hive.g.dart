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
      checkpointId: fields[0] as String,
      lessonId: fields[1] as String,
      triggerPositionSeconds: fields[2] as int,
      question: fields[3] as String,
      options: (fields[4] as List).cast<String>(),
      correctOptionIndex: fields[5] as int,
      isPassed: fields[6] as bool,
      passedAt: fields[7] as DateTime?,
      attempts: fields[8] as int,
      firstAttemptAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CheckpointHive obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.checkpointId)
      ..writeByte(1)
      ..write(obj.lessonId)
      ..writeByte(2)
      ..write(obj.triggerPositionSeconds)
      ..writeByte(3)
      ..write(obj.question)
      ..writeByte(4)
      ..write(obj.options)
      ..writeByte(5)
      ..write(obj.correctOptionIndex)
      ..writeByte(6)
      ..write(obj.isPassed)
      ..writeByte(7)
      ..write(obj.passedAt)
      ..writeByte(8)
      ..write(obj.attempts)
      ..writeByte(9)
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

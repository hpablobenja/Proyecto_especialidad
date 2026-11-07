// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_progress_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuizProgressHiveAdapter extends TypeAdapter<QuizProgressHive> {
  @override
  final int typeId = 4;

  @override
  QuizProgressHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuizProgressHive(
      userId: fields[0] as String,
      quizId: fields[1] as String,
      lessonId: fields[2] as String,
      courseId: fields[3] as String,
      moduleId: fields[4] as String,
      selectedAnswers: (fields[5] as Map).cast<int, int>(),
      score: fields[6] as int?,
      maxScore: fields[7] as int,
      isCompleted: fields[8] as bool,
      submittedAt: fields[9] as DateTime,
      needsSync: fields[10] as bool,
      answerDetails: (fields[11] as List).cast<QuizAnswerDetail>(),
    );
  }

  @override
  void write(BinaryWriter writer, QuizProgressHive obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.quizId)
      ..writeByte(2)
      ..write(obj.lessonId)
      ..writeByte(3)
      ..write(obj.courseId)
      ..writeByte(4)
      ..write(obj.moduleId)
      ..writeByte(5)
      ..write(obj.selectedAnswers)
      ..writeByte(6)
      ..write(obj.score)
      ..writeByte(7)
      ..write(obj.maxScore)
      ..writeByte(8)
      ..write(obj.isCompleted)
      ..writeByte(9)
      ..write(obj.submittedAt)
      ..writeByte(10)
      ..write(obj.needsSync)
      ..writeByte(11)
      ..write(obj.answerDetails);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizProgressHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuizAnswerDetailAdapter extends TypeAdapter<QuizAnswerDetail> {
  @override
  final int typeId = 5;

  @override
  QuizAnswerDetail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuizAnswerDetail(
      questionText: fields[0] as String,
      selectedAnswerIndex: fields[1] as int?,
      selectedAnswerText: fields[2] as String?,
      correctAnswerIndex: fields[3] as int,
      correctAnswerText: fields[4] as String,
      isCorrect: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, QuizAnswerDetail obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.questionText)
      ..writeByte(1)
      ..write(obj.selectedAnswerIndex)
      ..writeByte(2)
      ..write(obj.selectedAnswerText)
      ..writeByte(3)
      ..write(obj.correctAnswerIndex)
      ..writeByte(4)
      ..write(obj.correctAnswerText)
      ..writeByte(5)
      ..write(obj.isCorrect);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizAnswerDetailAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

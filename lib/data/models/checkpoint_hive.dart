// lib/data/models/checkpoint_hive.dart

import 'package:hive/hive.dart';

part 'checkpoint_hive.g.dart';

/// Modelo Hive para persistencia local de checkpoints
@HiveType(typeId: 2)
class CheckpointHive {
  @HiveField(0)
  String checkpointId;

  @HiveField(1)
  String lessonId;

  @HiveField(2)
  int triggerPositionSeconds;

  @HiveField(3)
  String question;

  @HiveField(4)
  List<String> options;

  @HiveField(5)
  int correctOptionIndex;

  @HiveField(6)
  bool isPassed;

  @HiveField(7)
  DateTime? passedAt;

  @HiveField(8)
  int attempts;

  @HiveField(9)
  DateTime? firstAttemptAt;

  CheckpointHive({
    required this.checkpointId,
    required this.lessonId,
    required this.triggerPositionSeconds,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    this.isPassed = false,
    this.passedAt,
    this.attempts = 0,
    this.firstAttemptAt,
  });

  /// Convierte desde Map (CheckpointEntity.toMap())
  factory CheckpointHive.fromMap(Map<String, dynamic> map) {
    return CheckpointHive(
      checkpointId: map['id'] as String,
      lessonId: map['lessonId'] as String,
      triggerPositionSeconds: map['triggerPositionSeconds'] as int,
      question: map['question'] as String,
      options: List<String>.from(map['options'] as List),
      correctOptionIndex: map['correctOptionIndex'] as int,
      isPassed: map['isPassed'] as bool? ?? false,
      passedAt:
          map['passedAt'] != null
              ? map['passedAt'] is DateTime
                  ? map['passedAt'] as DateTime
                  : DateTime.parse(map['passedAt'] as String)
              : null,
      attempts: map['attempts'] as int? ?? 0,
      firstAttemptAt:
          map['firstAttemptAt'] != null
              ? map['firstAttemptAt'] is DateTime
                  ? map['firstAttemptAt'] as DateTime
                  : DateTime.parse(map['firstAttemptAt'] as String)
              : null,
    );
  }

  /// Convierte a Map
  Map<String, dynamic> toMap() {
    return {
      'id': checkpointId,
      'lessonId': lessonId,
      'triggerPositionSeconds': triggerPositionSeconds,
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'isPassed': isPassed,
      'passedAt': passedAt?.toIso8601String(),
      'attempts': attempts,
      'firstAttemptAt': firstAttemptAt?.toIso8601String(),
    };
  }

  /// Genera una clave única para este checkpoint
  String get key => checkpointId;
}

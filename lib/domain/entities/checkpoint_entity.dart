// lib/domain/entities/checkpoint_entity.dart

import 'package:equatable/equatable.dart';

class CheckpointEntity extends Equatable {
  final String id;
  final String lessonId;
  final int triggerPositionSeconds;
  final String question;
  final List<String> options;
  final int correctOptionIndex;

  // Tracking de intentos
  final int attempts;
  final DateTime? firstAttemptAt;
  final DateTime? passedAt;
  final bool isPassed;

  const CheckpointEntity({
    required this.id,
    required this.lessonId,
    required this.triggerPositionSeconds,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    this.attempts = 0,
    this.firstAttemptAt,
    this.passedAt,
    this.isPassed = false,
  });

  @override
  List<Object?> get props => [
    id,
    lessonId,
    triggerPositionSeconds,
    question,
    options,
    correctOptionIndex,
    attempts,
    firstAttemptAt,
    passedAt,
    isPassed,
  ];

  CheckpointEntity copyWith({
    String? id,
    String? lessonId,
    int? triggerPositionSeconds,
    String? question,
    List<String>? options,
    int? correctOptionIndex,
    int? attempts,
    DateTime? firstAttemptAt,
    DateTime? passedAt,
    bool? isPassed,
  }) {
    return CheckpointEntity(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      triggerPositionSeconds:
          triggerPositionSeconds ?? this.triggerPositionSeconds,
      question: question ?? this.question,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      attempts: attempts ?? this.attempts,
      firstAttemptAt: firstAttemptAt ?? this.firstAttemptAt,
      passedAt: passedAt ?? this.passedAt,
      isPassed: isPassed ?? this.isPassed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lessonId': lessonId,
      'triggerPositionSeconds': triggerPositionSeconds,
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'attempts': attempts,
      'firstAttemptAt': firstAttemptAt?.toIso8601String(),
      'passedAt': passedAt?.toIso8601String(),
      'isPassed': isPassed,
    };
  }

  factory CheckpointEntity.fromMap(Map<String, dynamic> map) {
    return CheckpointEntity(
      id: map['id'] as String,
      lessonId: map['lessonId'] as String,
      triggerPositionSeconds: map['triggerPositionSeconds'] as int,
      question: map['question'] as String,
      options: List<String>.from(map['options'] as List),
      correctOptionIndex: map['correctOptionIndex'] as int,
      attempts: map['attempts'] as int? ?? 0,
      firstAttemptAt:
          map['firstAttemptAt'] != null
              ? DateTime.parse(map['firstAttemptAt'] as String)
              : null,
      passedAt:
          map['passedAt'] != null
              ? DateTime.parse(map['passedAt'] as String)
              : null,
      isPassed: map['isPassed'] as bool? ?? false,
    );
  }
}

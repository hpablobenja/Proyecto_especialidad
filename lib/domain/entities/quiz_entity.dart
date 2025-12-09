// lib/domain/entities/quiz_entity.dart

import 'package:equatable/equatable.dart';
import 'question_entity.dart';

class QuizEntity extends Equatable {
  final String id;
  final String lessonId;
  final String courseId;
  final String moduleId;
  final List<QuestionEntity> questions; // Máximo 5 preguntas

  const QuizEntity({
    required this.id,
    required this.lessonId,
    required this.courseId,
    required this.moduleId,
    required this.questions,
  });

  @override
  List<Object?> get props => [id, lessonId, courseId, moduleId, questions];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lessonId': lessonId,
      'courseId': courseId,
      'moduleId': moduleId,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  factory QuizEntity.fromMap(Map<String, dynamic> map) {
    return QuizEntity(
      id: map['id'] as String,
      lessonId: map['lessonId'] as String,
      courseId: map['courseId'] as String,
      moduleId: map['moduleId'] as String,
      questions: (map['questions'] as List)
          .map((q) => QuestionEntity.fromMap(q as Map<String, dynamic>))
          .toList(),
    );
  }
}


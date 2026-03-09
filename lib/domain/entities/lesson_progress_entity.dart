// lib/domain/entities/lesson_progress_entity.dart

import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum LessonProgressStatus {
  notStarted,
  inProgress, // Cuando se ha seleccionado "Reproducir video" al menos una vez
  completed, // Cuando se ha completado el cuestionario
}

class LessonProgressEntity extends Equatable {
  final String userId;
  final String courseId;
  final String moduleId;
  final String lessonId;
  final LessonProgressStatus status;
  final DateTime? lastUpdated;
  final bool hasViewedVideo;
  final bool hasCompletedQuiz;
  final int? quizScore;
  final int? maxQuizScore;

  const LessonProgressEntity({
    required this.userId,
    required this.courseId,
    required this.moduleId,
    required this.lessonId,
    required this.status,
    this.lastUpdated,
    this.hasViewedVideo = false,
    this.hasCompletedQuiz = false,
    this.quizScore,
    this.maxQuizScore,
  });

  @override
  List<Object?> get props => [
        userId,
        courseId,
        moduleId,
        lessonId,
        status,
        lastUpdated,
        hasViewedVideo,
        hasCompletedQuiz,
        quizScore,
        maxQuizScore,
      ];

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseId': courseId,
      'moduleId': moduleId,
      'lessonId': lessonId,
      'status': status.name,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'hasViewedVideo': hasViewedVideo,
      'hasCompletedQuiz': hasCompletedQuiz,
      'quizScore': quizScore,
      'maxQuizScore': maxQuizScore,
    };
  }

  factory LessonProgressEntity.fromMap(Map<String, dynamic> map) {
    return LessonProgressEntity(
      userId: map['userId'] as String,
      courseId: map['courseId'] as String,
      moduleId: map['moduleId'] as String,
      lessonId: map['lessonId'] as String,
      status: LessonProgressStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => LessonProgressStatus.notStarted,
      ),
      lastUpdated: map['lastUpdated'] != null
          ? map['lastUpdated'] is DateTime 
              ? map['lastUpdated'] as DateTime
              : map['lastUpdated'] is String 
                  ? DateTime.parse(map['lastUpdated'] as String)
                  : (map['lastUpdated'] as Timestamp).toDate()
          : null,
      hasViewedVideo: map['hasViewedVideo'] as bool? ?? false,
      hasCompletedQuiz: map['hasCompletedQuiz'] as bool? ?? false,
      quizScore: map['quizScore'] as int?,
      maxQuizScore: map['maxQuizScore'] as int?,
    );
  }
}


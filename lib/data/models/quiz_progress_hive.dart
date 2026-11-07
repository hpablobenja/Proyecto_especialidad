// lib/data/models/quiz_progress_hive.dart

import 'package:hive/hive.dart';

part 'quiz_progress_hive.g.dart';

/// Modelo Hive para persistencia local de progreso de quiz
/// Permite responder cuestionarios en modo offline y sincronizar después
@HiveType(typeId: 4)
class QuizProgressHive {
  @HiveField(0)
  String userId;

  @HiveField(1)
  String quizId;

  @HiveField(2)
  String lessonId;

  @HiveField(3)
  String courseId;

  @HiveField(4)
  String moduleId;

  @HiveField(5)
  Map<int, int> selectedAnswers; // questionIndex -> selectedOptionIndex

  @HiveField(6)
  int? score;

  @HiveField(7)
  int maxScore;

  @HiveField(8)
  bool isCompleted;

  @HiveField(9)
  DateTime submittedAt;

  @HiveField(10)
  bool needsSync;

  @HiveField(11)
  List<QuizAnswerDetail> answerDetails;

  QuizProgressHive({
    required this.userId,
    required this.quizId,
    required this.lessonId,
    required this.courseId,
    required this.moduleId,
    required this.selectedAnswers,
    this.score,
    required this.maxScore,
    required this.isCompleted,
    required this.submittedAt,
    required this.needsSync,
    required this.answerDetails,
  });

  /// Genera una clave única para este progreso de quiz
  String get key => '${userId}_$quizId';
}

/// Detalle de cada respuesta del quiz
@HiveType(typeId: 5)
class QuizAnswerDetail {
  @HiveField(0)
  String questionText;

  @HiveField(1)
  int? selectedAnswerIndex;

  @HiveField(2)
  String? selectedAnswerText;

  @HiveField(3)
  int correctAnswerIndex;

  @HiveField(4)
  String correctAnswerText;

  @HiveField(5)
  bool isCorrect;

  QuizAnswerDetail({
    required this.questionText,
    this.selectedAnswerIndex,
    this.selectedAnswerText,
    required this.correctAnswerIndex,
    required this.correctAnswerText,
    required this.isCorrect,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'selectedAnswerIndex': selectedAnswerIndex,
      'selectedAnswerText': selectedAnswerText,
      'correctAnswerIndex': correctAnswerIndex,
      'correctAnswerText': correctAnswerText,
      'isCorrect': isCorrect,
    };
  }

  factory QuizAnswerDetail.fromMap(Map<String, dynamic> map) {
    return QuizAnswerDetail(
      questionText: map['questionText'] as String,
      selectedAnswerIndex: map['selectedAnswerIndex'] as int?,
      selectedAnswerText: map['selectedAnswerText'] as String?,
      correctAnswerIndex: map['correctAnswerIndex'] as int,
      correctAnswerText: map['correctAnswerText'] as String,
      isCorrect: map['isCorrect'] as bool,
    );
  }
}

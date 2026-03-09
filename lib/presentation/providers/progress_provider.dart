// lib/presentation/providers/progress_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/usecases/courses/get_course_progress_usecase.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/lesson_progress_entity.dart';

class ProgressProvider extends ChangeNotifier {
  final GetCourseProgressUsecase getCourseProgressUsecase;
  final FirebaseFirestore firestore;

  ProgressProvider({
    required this.getCourseProgressUsecase,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;
  List<CourseProgressDetail> _completedCourses = [];
  List<CourseProgressDetail> _inProgressCourses = [];
  bool _hasViewedAnyLesson = false; // session flag

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CourseProgressDetail> get completedCourses => _completedCourses;
  List<CourseProgressDetail> get inProgressCourses => _inProgressCourses;
  bool get hasViewedAnyLesson => _hasViewedAnyLesson;

  Future<void> loadUserProgress(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userProgress = await getCourseProgressUsecase.call(userId);
      _completedCourses = userProgress.completedCourses;
      _inProgressCourses = userProgress.inProgressCourses;
    } catch (e) {
      _errorMessage = 'No se pudo cargar el progreso del usuario. $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Marca que el usuario visualizó al menos una lección (fin de video)
  void markAnyLessonViewed() {
    if (!_hasViewedAnyLesson) {
      _hasViewedAnyLesson = true;
      notifyListeners();
    }
  }

  // Marca una lección como "en curso" cuando se selecciona "Reproducir video"
  Future<void> markLessonInProgress({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    try {
      final progressId = '$userId-$courseId-$moduleId-$lessonId';
      final progressRef = firestore.collection('userProgress').doc(progressId);

      final progressData = {
        'userId': userId,
        'courseId': courseId,
        'moduleId': moduleId,
        'lessonId': lessonId,
        'status': LessonProgressStatus.inProgress.name,
        'hasViewedVideo': true,
        'hasCompletedQuiz': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await progressRef.set(progressData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error al marcar lección en progreso: $e');
    }
  }

  // Marca una lección como "completada" cuando se completa el cuestionario
  Future<void> markLessonCompleted({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
    int? score,
    int? maxScore,
  }) async {
    try {
      final progressId = '$userId-$courseId-$moduleId-$lessonId';
      final progressRef = firestore.collection('userProgress').doc(progressId);

      final progressData = {
        'userId': userId,
        'courseId': courseId,
        'moduleId': moduleId,
        'lessonId': lessonId,
        'status': LessonProgressStatus.completed.name,
        'hasViewedVideo': true,
        'hasCompletedQuiz': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (score != null) {
        progressData['quizScore'] = score;
      }
      if (maxScore != null) {
        progressData['maxQuizScore'] = maxScore;
      }

      await progressRef.set(progressData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error al marcar lección completada: $e');
    }
  }

  Future<LessonProgressEntity?> getLessonProgress({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    try {
      final progressId = '$userId-$courseId-$moduleId-$lessonId';
      final progressDoc = await firestore.collection('userProgress').doc(progressId).get();
      if (progressDoc.exists) {
        return LessonProgressEntity.fromMap(progressDoc.data()!);
      }
    } catch (e) {
      debugPrint('Error al obtener progreso de la lección: $e');
    }
    return null;
  }
}

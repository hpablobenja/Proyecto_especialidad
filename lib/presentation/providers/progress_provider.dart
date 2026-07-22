// lib/presentation/providers/progress_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/usecases/courses/get_course_progress_usecase.dart';
import '../../domain/entities/lesson_progress_entity.dart';
import '../../data/repositories/data_user_repository.dart';

class ProgressProvider extends ChangeNotifier {
  final GetCourseProgressUsecase getCourseProgressUsecase;
  final FirebaseFirestore firestore;
  final DataUserRepository _dataUserRepository = DataUserRepository();

  ProgressProvider({
    required this.getCourseProgressUsecase,
    required this.firestore,
  });

  bool _isLoading = false;
  String? _errorMessage;
  List<CourseProgressDetail> _completedCourses = [];
  List<CourseProgressDetail> _inProgressCourses = [];
  bool _hasViewedAnyLesson = false; // session flag
  String? _lastLoadedUserId; // cache: evita recargar si ya está cargado

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CourseProgressDetail> get completedCourses => _completedCourses;
  List<CourseProgressDetail> get inProgressCourses => _inProgressCourses;
  bool get hasViewedAnyLesson => _hasViewedAnyLesson;

  Future<void> loadUserProgress(String userId, {bool forceReload = false}) async {
    // Si ya cargamos para este usuario y no es forzado, no repetir la carga
    if (!forceReload && _lastLoadedUserId == userId && !_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userProgress = await getCourseProgressUsecase.call(userId);
      _completedCourses = userProgress.completedCourses;
      _inProgressCourses = userProgress.inProgressCourses;
      _lastLoadedUserId = userId;
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
      // Verificar si el rol es 'maestro'
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role');
      
      if (userRole != 'maestro') {
        return;
      }

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
      _lastLoadedUserId = null; // invalidar caché para próxima visita a Progreso
      
      // Actualizar progreso en Firestore
      await _updateProgressInFirestore(userId, courseId);
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
      // Verificar si el rol es 'maestro'
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role');
      
      if (userRole != 'maestro') {
        return;
      }

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
      _lastLoadedUserId = null; // invalidar caché para próxima visita a Progreso
      
      // Actualizar progreso en Firestore
      await _updateProgressInFirestore(userId, courseId);
    } catch (e) {
      debugPrint('Error al marcar lección completada: $e');
    }
  }

  // Actualizar progreso en Firestore cuando hay interacción
  Future<void> _updateProgressInFirestore(String userId, String courseId) async {
    try {
      // Obtener información del curso para categoría
      final courseDoc = await firestore.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) return;
      
      final courseData = courseDoc.data();
      final category = courseData?['targetAudience'] as String?;
      
      if (category == null) return;
      
      // Obtener todos los cursos de esa categoría
      final categoryCourses = await firestore
          .collection('courses')
          .where('targetAudience', isEqualTo: category)
          .get();
      
      final totalCoursesInCategory = categoryCourses.docs.length;
      
      // Obtener progreso del usuario en esa categoría
      final userProgressSnapshot = await firestore
          .collection('userProgress')
          .where('userId', isEqualTo: userId)
          .get();
      
      final userCourseIds = userProgressSnapshot.docs
          .map((doc) => doc.data()['courseId'] as String)
          .toSet();
      
      // Obtener cursos de la categoría que el usuario ha iniciado
      final categoryCourseIds = categoryCourses.docs.map((doc) => doc.id).toSet();
      final startedInCategory = categoryCourseIds.intersection(userCourseIds);
      
      // Calcular progreso (cursos iniciados / total cursos en categoría)
      final progress = totalCoursesInCategory > 0 
          ? (startedInCategory.length / totalCoursesInCategory) * 100 
          : 0.0;
      
      // Actualizar en dataUser
      await _dataUserRepository.updateCategoryProgress(category, progress);
      
      // Recalcular progreso general
      await _dataUserRepository.recalculateOverallProgress();
      
      // Verificar logros
      await _dataUserRepository.checkAndUnlockAchievements();
    } catch (e) {
      debugPrint('Error al actualizar progreso en Firestore: $e');
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

// lib/presentation/providers/progress_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/usecases/courses/get_course_progress_usecase.dart';
import '../../domain/entities/lesson_progress_entity.dart';
import '../../data/repositories/data_user_repository.dart';
import '../../core/services/dashboard_sync_service.dart';

class ProgressProvider extends ChangeNotifier {
  final GetCourseProgressUsecase getCourseProgressUsecase;
  final FirebaseFirestore firestore;
  final DataUserRepository _dataUserRepository = DataUserRepository();
  final DashboardSyncService _dashboardSyncService = DashboardSyncService();

  ProgressProvider({
    required this.getCourseProgressUsecase,
    required this.firestore,
  });

  bool _isLoading = false;
  String? _errorMessage;
  List<CourseProgressDetail> _completedCourses = [];
  List<CourseProgressDetail> _inProgressCourses = [];
  bool _hasViewedAnyLesson = false; // session flag
  String? _lastLoadedUserId; // cache: evita recargar si ya estÃÂÃÂ¡ cargado

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

  // Marca que el usuario visualizÃÂÃÂ³ al menos una lecciÃÂÃÂ³n (fin de video)
  void markAnyLessonViewed() {
    if (!_hasViewedAnyLesson) {
      _hasViewedAnyLesson = true;
      notifyListeners();
    }
  }

  // Marca una lecciÃÂÃÂ³n como "en curso" cuando se selecciona "Reproducir video"
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

      final progressDoc = await progressRef.get();

      final progressData = <String, dynamic>{
        'userId': userId,
        'courseId': courseId,
        'moduleId': moduleId,
        'lessonId': lessonId,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (progressDoc.exists) {
        final data = progressDoc.data()!;
        final currentStatus = data['status'];
        if (currentStatus == null || currentStatus == LessonProgressStatus.notStarted.name) {
          progressData['status'] = LessonProgressStatus.inProgress.name;
        }
      } else {
        progressData['status'] = LessonProgressStatus.inProgress.name;
        progressData['hasViewedVideo'] = false;
        progressData['hasCompletedStrategies'] = false;
        progressData['hasCompletedQuiz'] = false;
      }

      await progressRef.set(progressData, SetOptions(merge: true));
      _lastLoadedUserId = null;
      // Actualizar progreso en Firestore
      await _updateProgressInFirestore(userId, courseId);
    } catch (e) {
      debugPrint('Error al marcar lecciÃÂÃÂ³n en progreso: $e');
    }
  }


  // Marca el video como visto sin alterar estrategias ni cuestionario
  Future<void> markVideoViewed({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role');

      if (userRole != 'maestro') {
        return;
      }

      final progressId = '$userId-$courseId-$moduleId-$lessonId';
      final progressRef = firestore.collection('userProgress').doc(progressId);

      final progressDoc = await progressRef.get();
      final progressData = <String, dynamic>{
        'userId': userId,
        'courseId': courseId,
        'moduleId': moduleId,
        'lessonId': lessonId,
        'hasViewedVideo': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (progressDoc.exists) {
        final data = progressDoc.data()!;
        progressData['hasCompletedQuiz'] = data['hasCompletedQuiz'] ?? false;
        progressData['hasCompletedStrategies'] =
            data['hasCompletedStrategies'] ?? false;
        if (data.containsKey('quizScore')) progressData['quizScore'] = data['quizScore'];
        if (data.containsKey('maxQuizScore')) {
          progressData['maxQuizScore'] = data['maxQuizScore'];
        }

        final currentStatus = data['status'];
        if (currentStatus == null ||
            currentStatus == LessonProgressStatus.notStarted.name) {
          progressData['status'] = LessonProgressStatus.inProgress.name;
        }
      } else {
        progressData['hasCompletedQuiz'] = false;
        progressData['hasCompletedStrategies'] = false;
        progressData['status'] = LessonProgressStatus.inProgress.name;
      }

      await progressRef.set(progressData, SetOptions(merge: true));
      _lastLoadedUserId = null;

      await _checkAndMarkLessonCompleted(
        userId: userId,
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
      );

      await _updateProgressInFirestore(userId, courseId);
    } catch (e) {
      debugPrint('Error al marcar video visto: ');
    }
  }

  // Marca las estrategias como revisadas sin alterar video ni cuestionario
  Future<void> markStrategiesCompleted({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role');

      if (userRole != 'maestro') {
        return;
      }

      final progressId = '$userId-$courseId-$moduleId-$lessonId';
      final progressRef = firestore.collection('userProgress').doc(progressId);

      final progressDoc = await progressRef.get();
      final progressData = <String, dynamic>{
        'userId': userId,
        'courseId': courseId,
        'moduleId': moduleId,
        'lessonId': lessonId,
        'hasCompletedStrategies': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (progressDoc.exists) {
        final data = progressDoc.data()!;
        progressData['hasViewedVideo'] = data['hasViewedVideo'] ?? false;
        progressData['hasCompletedQuiz'] = data['hasCompletedQuiz'] ?? false;
        if (data.containsKey('quizScore')) progressData['quizScore'] = data['quizScore'];
        if (data.containsKey('maxQuizScore')) {
          progressData['maxQuizScore'] = data['maxQuizScore'];
        }

        final currentStatus = data['status'];
        if (currentStatus == null ||
            currentStatus == LessonProgressStatus.notStarted.name) {
          progressData['status'] = LessonProgressStatus.inProgress.name;
        }
      } else {
        progressData['hasViewedVideo'] = false;
        progressData['hasCompletedQuiz'] = false;
        progressData['status'] = LessonProgressStatus.inProgress.name;
      }

      await progressRef.set(progressData, SetOptions(merge: true));
      _lastLoadedUserId = null;

      await _checkAndMarkLessonCompleted(
        userId: userId,
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
      );

      await _updateProgressInFirestore(userId, courseId);
    } catch (e) {
      debugPrint('Error al marcar estrategias completadas: ');
    }
  }

  // Marca el cuestionario como completado sin alterar video ni estrategias
  Future<void> markQuizCompleted({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
    int? score,
    int? maxScore,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role');

      if (userRole != 'maestro') {
        return;
      }

      final progressId = '$userId-$courseId-$moduleId-$lessonId';
      final progressRef = firestore.collection('userProgress').doc(progressId);

      final progressDoc = await progressRef.get();
      final progressData = <String, dynamic>{
        'userId': userId,
        'courseId': courseId,
        'moduleId': moduleId,
        'lessonId': lessonId,
        'hasCompletedQuiz': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (score != null) {
        progressData['quizScore'] = score;
      }
      if (maxScore != null) {
        progressData['maxQuizScore'] = maxScore;
      }

      if (progressDoc.exists) {
        final data = progressDoc.data()!;
        progressData['hasViewedVideo'] = data['hasViewedVideo'] ?? false;
        progressData['hasCompletedStrategies'] =
            data['hasCompletedStrategies'] ?? false;

        final currentStatus = data['status'];
        if (currentStatus == null ||
            currentStatus == LessonProgressStatus.notStarted.name) {
          progressData['status'] = LessonProgressStatus.inProgress.name;
        }
      } else {
        progressData['hasViewedVideo'] = false;
        progressData['hasCompletedStrategies'] = false;
        progressData['status'] = LessonProgressStatus.inProgress.name;
      }

      await progressRef.set(progressData, SetOptions(merge: true));
      _lastLoadedUserId = null;

      await _checkAndMarkLessonCompleted(
        userId: userId,
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
      );

      await _updateProgressInFirestore(userId, courseId);
    } catch (e) {
      debugPrint('Error al marcar quiz completado: $e');
    }
  }

  // Compatibilidad hacia atrÃÂ¡s
  Future<void> markLessonCompleted({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
    int? score,
    int? maxScore,
  }) => markQuizCompleted(
    userId: userId,
    courseId: courseId,
    moduleId: moduleId,
    lessonId: lessonId,
    score: score,
    maxScore: maxScore,
  );

  // Verifica si los 3 criterios estÃÂ¡n completos y marca la lecciÃÂ³n como completada
  Future<void> _checkAndMarkLessonCompleted({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    try {
      final progressId = '$userId-$courseId-$moduleId-$lessonId';
      final progressRef = firestore.collection('userProgress').doc(progressId);
      final progressDoc = await progressRef.get();

      if (!progressDoc.exists) return;

      final data = progressDoc.data();
      final hasViewedVideo = data?['hasViewedVideo'] ?? false;
      final hasCompletedStrategies = data?['hasCompletedStrategies'] ?? false;
      final hasCompletedQuiz = data?['hasCompletedQuiz'] ?? false;

      // Solo marcar status como completed si los 3 criterios estÃÂ¡n cumplidos
      if (hasViewedVideo && hasCompletedStrategies && hasCompletedQuiz) {
        await progressRef.update({
          'status': LessonProgressStatus.completed.name,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        debugPrint('LecciÃÂ³n  marcada como completada (3 criterios cumplidos)');
      }
    } catch (e) {
      debugPrint('Error al verificar y marcar lecciÃÂ³n completada: ');
    }
  }

  // Actualizar progreso en Firestore cuando hay interacciÃÂÃÂ³n
  Future<void> _updateProgressInFirestore(String userId, String courseId) async {
    try {
      // Obtener informaciÃÂÃÂ³n del curso para categorÃÂÃÂ­a
      final courseDoc = await firestore.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) return;
      
      final courseData = courseDoc.data();
      final category = courseData?['targetAudience'] as String?;
      
      if (category == null) return;
      
      // Obtener todos los cursos de esa categorÃÂÃÂ­a
      final categoryCourses = await firestore
          .collection('courses')
          .where('targetAudience', isEqualTo: category)
          .get();
      
      final totalCoursesInCategory = categoryCourses.docs.length;
      
      // Obtener progreso del usuario en esa categorÃÂÃÂ­a
      final userProgressSnapshot = await firestore
          .collection('userProgress')
          .where('userId', isEqualTo: userId)
          .get();
      
      final userCourseIds = userProgressSnapshot.docs
          .map((doc) => doc.data()['courseId'] as String)
          .toSet();
      
      // Obtener cursos de la categorÃÂÃÂ­a que el usuario ha iniciado
      final categoryCourseIds = categoryCourses.docs.map((doc) => doc.id).toSet();
      final startedInCategory = categoryCourseIds.intersection(userCourseIds);
      
      // Calcular progreso (cursos iniciados / total cursos en categorÃÂÃÂ­a)
      final progress = totalCoursesInCategory > 0 
          ? (startedInCategory.length / totalCoursesInCategory) * 100 
          : 0.0;
      
      // Actualizar en dataUser
      await _dataUserRepository.updateCategoryProgress(category, progress);
      
      // Recalcular progreso general
      await _dataUserRepository.recalculateOverallProgress();
      
      // Verificar logros
      await _dataUserRepository.checkAndUnlockAchievements();
      
      // Sincronizar dashboard en segundo plano al actualizar progreso
      _dashboardSyncService.syncFromFirestore(userId).catchError((e) {
        debugPrint('Error al sincronizar dashboard al actualizar progreso: $e');
      });
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
      debugPrint('Error al obtener progreso de la lecciÃÂÃÂ³n: $e');
    }
    return null;
  }
}

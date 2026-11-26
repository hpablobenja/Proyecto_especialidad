// lib/core/services/quiz_sync_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/quiz_offline_service.dart';
import '../../data/repositories/data_user_repository.dart';
import '../../core/services/dashboard_sync_service.dart';
import 'performance_service.dart';

/// Servicio global para sincronizar quizzes offline cuando se restaura la conexión
/// Se inicializa en main.dart y escucha cambios de conectividad a nivel de aplicación
class QuizSyncService {
  static final QuizSyncService _instance = QuizSyncService._internal();
  factory QuizSyncService() => _instance;
  QuizSyncService._internal();

  final QuizOfflineService _quizOfflineService = QuizOfflineService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  final DataUserRepository _dataUserRepository = DataUserRepository();
  final DashboardSyncService _dashboardSyncService = DashboardSyncService();

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isInitialized = false;
  bool _isOnline = true;
  String? _currentUserId;

  /// Callback para notificar cuando se sincronizan quizzes
  Function(String userId)? onQuizzesSynced;

  /// Inicializa el servicio
  Future<void> init() async {
    if (_isInitialized) return;

    await _quizOfflineService.init();

    // Verificar conectividad inicial
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    // Escuchar cambios de conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );

    _isInitialized = true;
    debugPrint('QuizSyncService initialized');
  }

  /// Establece el usuario actual para sincronización
  void setCurrentUser(String userId) {
    _currentUserId = userId;
    debugPrint('QuizSyncService: User set to $userId');

    // Si ya está online, intentar sincronizar inmediatamente
    if (_isOnline && _currentUserId != null) {
      _syncPendingQuizzes();
    }
  }

  /// Limpia el usuario actual (logout)
  void clearUser() {
    _currentUserId = null;
    debugPrint('QuizSyncService: User cleared');
  }

  /// Maneja cambios de conectividad
  void _handleConnectivityChange(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (!wasOnline && _isOnline) {
      debugPrint(
        'QuizSyncService: Connection restored, syncing pending quizzes...',
      );
      _syncPendingQuizzes();
    } else if (wasOnline && !_isOnline) {
      debugPrint('QuizSyncService: Connection lost');
    }
  }

  /// Sincroniza quizzes pendientes de sincronización
  Future<void> _syncPendingQuizzes() async {
    if (_currentUserId == null) {
      debugPrint('QuizSyncService: No user set, skipping sync');
      return;
    }

    final pendingQuizzes = _quizOfflineService.getPendingSyncQuizzes(
      _currentUserId!,
    );

    if (pendingQuizzes.isEmpty) {
      debugPrint('QuizSyncService: No pending quizzes to sync');
      return;
    }

    debugPrint(
      'QuizSyncService: Found ${pendingQuizzes.length} pending quizzes to sync',
    );
    int syncedCount = 0;

    await PerformanceService.instance.trackFirestoreSync(
      syncType: 'quiz_results',
      operation: (trace) async {
        trace.setMetric('pending_quizzes_count', pendingQuizzes.length);

        for (final quiz in pendingQuizzes) {
          try {
            // Obtener la clave obligatoriamente desde el servidor (Source.server)
            final answersDoc = await _firestore
                .collection('quizAnswersKeys')
                .doc(quiz.quizId)
                .get(const GetOptions(source: Source.server));

            Map<String, dynamic> correctAnswersMap = {};
            if (answersDoc.exists && answersDoc.data() != null) {
              final data = answersDoc.data()!;
              if (data['answers'] is Map) {
                correctAnswersMap = Map<String, dynamic>.from(
                  data['answers'] as Map,
                );
              }
            }

            // Obtener preguntas del quiz para relacionar y calificar efímeramente
            final quizDoc = await _firestore
                .collection('quizzes')
                .doc(quiz.quizId)
                .get(const GetOptions(source: Source.server));

            final questionsData = (quizDoc.data()?['questions'] as List? ?? []);

            // Crear un mapa de pregunta ID -> índice en el array de Firestore
            final Map<String, int> questionIdToIndex = {};
            for (int i = 0; i < questionsData.length; i++) {
              final qMap = questionsData[i] as Map<String, dynamic>;
              final qId = qMap['id'] as String? ?? '';
              if (qId.isNotEmpty) {
                questionIdToIndex[qId] = i;
              }
            }

            int calculatedScore = 0;
            final List<Map<String, dynamic>> evaluatedAnswers = [];

            // Verificar si tenemos questionIds (datos nuevos) o solo selectedAnswers (datos antiguos)
            if (quiz.questionIds != null && quiz.questionIds!.isNotEmpty) {
              // Datos nuevos: usar IDs de preguntas para correspondencia correcta
              for (int i = 0; i < quiz.questionIds!.length; i++) {
                final questionId = quiz.questionIds![i];
                final selected = quiz.selectedAnswers[i];

                // Encontrar la pregunta en Firestore usando su ID
                final firestoreIndex = questionIdToIndex[questionId];
                if (firestoreIndex == null) {
                  debugPrint(
                    'QuizSyncService: Pregunta con ID $questionId no encontrada en Firestore',
                  );
                  continue;
                }

                final qMap =
                    questionsData[firestoreIndex] as Map<String, dynamic>;
                final qText = qMap['text'] as String? ?? '';
                final options = List<String>.from(
                  qMap['options'] as List? ?? [],
                );
                final correctIndex = correctAnswersMap[questionId] as int?;

                final isCorrect =
                    correctIndex != null && selected == correctIndex;
                if (isCorrect) {
                  calculatedScore++;
                }

                evaluatedAnswers.add({
                  'questionText': qText,
                  'selectedAnswerIndex': selected,
                  'selectedAnswerText':
                      (selected != null &&
                              selected >= 0 &&
                              selected < options.length)
                          ? options[selected]
                          : null,
                  'correctAnswerIndex': correctIndex ?? -1,
                  'correctAnswerText':
                      (correctIndex != null &&
                              correctIndex >= 0 &&
                              correctIndex < options.length)
                          ? options[correctIndex]
                          : '',
                  'isCorrect': isCorrect,
                });
              }
            } else {
              // Datos antiguos: usar índices (puede ser incorrecto si el orden cambió)
              debugPrint(
                'QuizSyncService: Usando método de índices (datos antiguos sin questionIds)',
              );
              for (int i = 0; i < questionsData.length; i++) {
                final qMap = questionsData[i] as Map<String, dynamic>;
                final qId = qMap['id'] as String? ?? '';
                final qText = qMap['text'] as String? ?? '';
                final options = List<String>.from(
                  qMap['options'] as List? ?? [],
                );
                final selected = quiz.selectedAnswers[i];
                final correctIndex = correctAnswersMap[qId] as int?;

                final isCorrect =
                    correctIndex != null && selected == correctIndex;
                if (isCorrect) {
                  calculatedScore++;
                }

                evaluatedAnswers.add({
                  'questionText': qText,
                  'selectedAnswerIndex': selected,
                  'selectedAnswerText':
                      (selected != null &&
                              selected >= 0 &&
                              selected < options.length)
                          ? options[selected]
                          : null,
                  'correctAnswerIndex': correctIndex ?? -1,
                  'correctAnswerText':
                      (correctIndex != null &&
                              correctIndex >= 0 &&
                              correctIndex < options.length)
                          ? options[correctIndex]
                          : '',
                  'isCorrect': isCorrect,
                });
              }
            }

            final finalScore =
                (quiz.questionIds != null && quiz.questionIds!.isNotEmpty)
                    ? calculatedScore
                    : (quiz.score ?? 0);
            final finalMaxScore =
                (quiz.questionIds != null && quiz.questionIds!.isNotEmpty)
                    ? quiz.questionIds!.length
                    : quiz.maxScore;

            // Guardar respuestas en quizRespuestas
            final quizRespuestaRef = await _firestore
                .collection('quizRespuestas')
                .add({
                  'userId': quiz.userId,
                  'quizId': quiz.quizId,
                  'lessonId': quiz.lessonId,
                  'moduleId': quiz.moduleId,
                  'courseId': quiz.courseId,
                  'score': finalScore,
                  'maxScore': finalMaxScore,
                  'answers': evaluatedAnswers,
                  'submittedAt': FieldValue.serverTimestamp(),
                });
            debugPrint(
              'QuizSyncService: Respuestas guardadas en quizRespuestas. Document ID: ${quizRespuestaRef.id}, Quiz ID: ${quiz.quizId}',
            );

            // Actualizar progreso en userProgress
            final progressId =
                '${quiz.userId}-${quiz.courseId}-${quiz.moduleId}-${quiz.lessonId}';
            await _firestore.collection('userProgress').doc(progressId).set({
              'userId': quiz.userId,
              'courseId': quiz.courseId,
              'moduleId': quiz.moduleId,
              'lessonId': quiz.lessonId,
              'hasCompletedQuiz': true,
              'quizScore': finalScore,
              'maxQuizScore': finalMaxScore,
              'lastUpdated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            // Limpiar los datos temporales del almacenamiento local (Hive)
            await _quizOfflineService.deleteQuizProgress(
              quiz.userId,
              quiz.quizId,
            );

            // Actualizar progreso por categoría y progreso general del usuario
            await _updateUserProgressAfterQuizSync(quiz.userId, quiz.courseId);

            syncedCount++;
            debugPrint(
              'QuizSyncService: Quiz sincronizado, evaluado online y eliminado de Hive: ${quiz.quizId}',
            );
          } catch (e) {
            debugPrint(
              'QuizSyncService: Error syncing quiz ${quiz.quizId}: $e',
            );
          }
          trace.setMetric('synced_quizzes_count', syncedCount);
        }
      },
    );

    if (syncedCount > 0 && _currentUserId != null) {
      onQuizzesSynced?.call(_currentUserId!);
    }

    debugPrint('QuizSyncService: Sync completed');
  }

  /// Fuerza una sincronización manual
  Future<void> forceSync() async {
    if (_currentUserId == null) {
      debugPrint('QuizSyncService: No user set, cannot force sync');
      return;
    }

    if (!_isOnline) {
      debugPrint('QuizSyncService: Offline, cannot force sync');
      return;
    }

    await _syncPendingQuizzes();
  }

  /// Actualiza el progreso por categoría y el progreso general del usuario después de sincronizar un quiz
  Future<void> _updateUserProgressAfterQuizSync(
    String userId,
    String courseId,
  ) async {
    try {
      // Obtener información del curso para categoría
      final courseDoc =
          await _firestore.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) return;

      final courseData = courseDoc.data();
      final category = courseData?['targetAudience'] as String?;

      if (category == null) return;

      // Obtener todos los cursos de esa categoría
      final categoryCourses =
          await _firestore
              .collection('courses')
              .where('targetAudience', isEqualTo: category)
              .get();

      final totalCoursesInCategory = categoryCourses.docs.length;

      // Obtener progreso del usuario en esa categoría
      final userProgressSnapshot =
          await _firestore
              .collection('userProgress')
              .where('userId', isEqualTo: userId)
              .get();

      final userCourseIds =
          userProgressSnapshot.docs
              .map((doc) => doc.data()['courseId'] as String)
              .toSet();

      // Obtener cursos de la categoría que el usuario ha iniciado
      final categoryCourseIds =
          categoryCourses.docs.map((doc) => doc.id).toSet();
      final startedInCategory = categoryCourseIds.intersection(userCourseIds);

      // Calcular progreso (cursos iniciados / total cursos en categoría)
      final progress =
          totalCoursesInCategory > 0
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
        debugPrint(
          'QuizSyncService: Error al sincronizar dashboard al actualizar progreso: $e',
        );
      });

      debugPrint(
        'QuizSyncService: Progreso del usuario actualizado después de sincronizar quiz',
      );
    } catch (e) {
      debugPrint(
        'QuizSyncService: Error al actualizar progreso del usuario después de sincronizar quiz: $e',
      );
    }
  }

  /// Dispose del servicio
  void dispose() {
    _connectivitySubscription?.cancel();
    _isInitialized = false;
    debugPrint('QuizSyncService disposed');
  }
}

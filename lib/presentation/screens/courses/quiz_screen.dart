// lib/presentation/screens/courses/quiz_screen.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/lesson_entity.dart';
import '../../../domain/entities/quiz_entity.dart';
import '../../../domain/entities/question_entity.dart';
import '../../../domain/entities/system_config_entity.dart';
import '../../../core/di/riverpod_providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/quiz_offline_service.dart';
import '../../../data/models/quiz_progress_hive.dart';
import '../../widgets/offline_lesson_badge.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final LessonEntity lesson;

  const QuizScreen({super.key, required this.lesson});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  QuizEntity? _quiz;
  bool _loading = true;
  String? _error;
  final Map<int, int?> _selectedAnswers =
      {}; // questionIndex -> selectedOptionIndex
  bool _isSubmitting = false;
  bool _showResults = false;
  int _score = 0;
  int? _previousScore;
  bool _showingPreviousScore = false;
  bool _isOnline = true;
  bool _submittedOffline = false;
  late final QuizOfflineService _quizOfflineService;
  SystemConfigEntity? _systemConfig;

  @override
  void initState() {
    super.initState();
    _quizOfflineService = QuizOfflineService();
    _checkConnectivity();
    _loadSystemConfig();
  }

  Future<void> _loadSystemConfig() async {
    try {
      final config = await ref.read(systemConfigProvider.future);
      if (mounted) {
        setState(() {
          _systemConfig = config;
        });
      }
      await _initializeAndLoadQuiz();
    } catch (e) {
      debugPrint('Error loading system config: $e');
      // Use default config if loading fails
      await _initializeAndLoadQuiz();
    }
  }

  Future<void> _initializeAndLoadQuiz() async {
    try {
      await _quizOfflineService.init();
      await _loadQuiz();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al inicializar el servicio de quiz: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  Future<void> _checkConnectivity() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    if (!mounted) return;
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });

    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      result,
    ) async {
      if (!mounted) return;
      final online = result != ConnectivityResult.none;
      setState(() {
        _isOnline = online;
      });
      if (online) {
        await _syncPendingQuizzes();
        if (mounted) {
          setState(() {
            _submittedOffline = false;
          });
        }
      }
    });
  }

  Future<void> _syncPendingQuizzes() async {
    final auth = ref.read(authStateProvider);
    if (auth.currentUser == null) return;

    final pendingQuizzes = _quizOfflineService.getPendingSyncQuizzes(
      auth.currentUser!.uid,
    );
    final firestore = ref.read(firestoreProvider);
    final progress = ref.read(progressStateProvider);
    int syncedCount = 0;

    for (final quiz in pendingQuizzes) {
      try {
        // Obtener la clave obligatoriamente desde el servidor (Source.server)
        final answersDoc = await firestore
            .collection('quizAnswers')
            .doc(quiz.quizId)
            .get(const GetOptions(source: Source.server));

        Map<String, dynamic> correctAnswersMap = {};
        if (answersDoc.exists && answersDoc.data() != null) {
          final data = answersDoc.data()!;
          if (data['answers'] is Map) {
            correctAnswersMap = Map<String, dynamic>.from(data['answers'] as Map);
          }
        }

        // Obtener preguntas del quiz para evaluación efímera
        final quizDoc = await firestore
            .collection('quizzes')
            .doc(quiz.quizId)
            .get(const GetOptions(source: Source.server));

        final questionsData =
            (quizDoc.data()?['questions'] as List? ?? []);

        int calculatedScore = 0;
        final List<Map<String, dynamic>> evaluatedAnswers = [];

        for (int i = 0; i < questionsData.length; i++) {
          final qMap = questionsData[i] as Map<String, dynamic>;
          final qId = qMap['id'] as String? ?? '';
          final qText = qMap['text'] as String? ?? '';
          final options = List<String>.from(qMap['options'] as List? ?? []);
          final selected = quiz.selectedAnswers[i];
          final correctIndex = correctAnswersMap[qId] as int?;

          final isCorrect = correctIndex != null && selected == correctIndex;
          if (isCorrect) {
            calculatedScore++;
          }

          evaluatedAnswers.add({
            'questionText': qText,
            'selectedAnswerIndex': selected,
            'selectedAnswerText':
                (selected != null && selected >= 0 && selected < options.length)
                    ? options[selected]
                    : null,
            'correctAnswerIndex': correctIndex ?? -1,
            'correctAnswerText': (correctIndex != null &&
                    correctIndex >= 0 &&
                    correctIndex < options.length)
                ? options[correctIndex]
                : '',
            'isCorrect': isCorrect,
          });
        }

        final finalScore =
            questionsData.isNotEmpty ? calculatedScore : (quiz.score ?? 0);
        final finalMaxScore =
            questionsData.isNotEmpty ? questionsData.length : quiz.maxScore;

        await firestore.collection('quizRespuestas').add({
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

        // Actualizar progreso en userProgress
        final progressId =
            '${quiz.userId}-${quiz.courseId}-${quiz.moduleId}-${quiz.lessonId}';
        await firestore.collection('userProgress').doc(progressId).set({
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
        await _quizOfflineService.deleteQuizProgress(quiz.userId, quiz.quizId);
        syncedCount++;
        debugPrint('Quiz sincronizado, evaluado online y eliminado de almacenamiento local: ${quiz.quizId}');
      } catch (e) {
        debugPrint('Error al sincronizar quiz ${quiz.quizId}: $e');
      }
    }

    if (syncedCount > 0 && mounted) {
      progress.loadUserProgress(auth.currentUser!.uid, forceReload: true);
    }
  }

  List<QuestionEntity> _getRandomQuestions(
    List<QuestionEntity> allQuestions,
    int count,
  ) {
    final random = Random();
    final shuffled = List<QuestionEntity>.from(allQuestions);
    shuffled.shuffle(random);
    return shuffled.take(count).toList();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authStateProvider);

      // Verificar si hay progreso local previo cuando está offline
      if (!_isOnline && auth.currentUser != null) {
        final localProgress = _quizOfflineService.getQuizProgressByLesson(
          auth.currentUser!.uid,
          widget.lesson.id,
        ) ?? _quizOfflineService.getQuizProgress(
          auth.currentUser!.uid,
          widget.lesson.id,
        );

        if (localProgress != null && localProgress.isCompleted) {
          setState(() {
            _previousScore = localProgress.score;
            _showingPreviousScore = true;
            _loading = false;
          });
          return;
        }
      }

      if (!_isOnline) {
        // Cargar preguntas cacheadas para esta lección
        final cacheService = ref.read(offlineCacheServiceProvider);
        final cachedQuestions = await cacheService.getCachedQuizQuestions(
          widget.lesson.id,
        );
        final cachedQuizId = await cacheService.getCachedQuizId(widget.lesson.id);
        if (cachedQuestions.isNotEmpty) {
          setState(() {
            _quiz = QuizEntity(
              id: cachedQuizId ?? 'cached_${widget.lesson.id}',
              lessonId: widget.lesson.id,
              courseId: widget.lesson.courseId,
              moduleId: widget.lesson.moduleId,
              questions: cachedQuestions,
            );
            _loading = false;
          });
          return;
        } else {
          setState(() {
            _error =
                'No hay cuestionario guardado para esta lección. Accede con conexión primero.';
            _loading = false;
          });
          return;
        }
      }

      final firestore = ref.read(firestoreProvider);
      final quizDoc =
          await firestore
              .collection('quizzes')
              .where('lessonId', isEqualTo: widget.lesson.id)
              .limit(1)
              .get();

      if (quizDoc.docs.isEmpty) {
        setState(() {
          _error = 'No hay cuestionario disponible para esta lección.';
          _loading = false;
        });
        return;
      }

      final quizData = quizDoc.docs.first.data();
      final questionsData = quizData['questions'] as List? ?? [];

      final allQuestions =
          questionsData
              .map((q) => QuestionEntity.fromMap(q as Map<String, dynamic>))
              .toList();

      // Guardar automáticamente en local las preguntas del cuestionario
      await ref
          .read(offlineCacheServiceProvider)
          .cacheQuizQuestions(widget.lesson.id, allQuestions);

      // Guardar el quizId real para uso offline
      await ref
          .read(offlineCacheServiceProvider)
          .cacheQuizId(widget.lesson.id, quizDoc.docs.first.id);

      final isTeacher = auth.currentUser?.role == 'maestro';
      final maxQuestionsForTeacher = _systemConfig?.maxQuestionsForTeacher ?? 5;

      List<QuestionEntity> questionsToShow;
      if (isTeacher && allQuestions.length > maxQuestionsForTeacher) {
        questionsToShow = _getRandomQuestions(allQuestions, maxQuestionsForTeacher);
      } else {
        questionsToShow = allQuestions;
      }

      int? fetchedScore;
      bool hasPrevious = false;

      final progress = ref.read(progressStateProvider);

      if (auth.currentUser != null) {
        final lessonProgress = await progress.getLessonProgress(
          userId: auth.currentUser!.uid,
          courseId: widget.lesson.courseId,
          moduleId: widget.lesson.moduleId,
          lessonId: widget.lesson.id,
        );
        if (lessonProgress != null && lessonProgress.quizScore != null) {
          fetchedScore = lessonProgress.quizScore;
          hasPrevious = true;
        }
      }

      setState(() {
        _quiz = QuizEntity(
          id: quizDoc.docs.first.id,
          lessonId: widget.lesson.id,
          courseId: widget.lesson.courseId,
          moduleId: widget.lesson.moduleId,
          questions: questionsToShow,
        );
        if (hasPrevious) {
          _previousScore = fetchedScore;
          _showingPreviousScore = true;
        }
        _loading = false;
      });
    } catch (e) {
      // Si falla la red, intentar recuperar de cache local
      try {
        final cacheService = ref.read(offlineCacheServiceProvider);
        final cachedQuestions = await cacheService.getCachedQuizQuestions(
          widget.lesson.id,
        );
        if (cachedQuestions.isNotEmpty) {
          final cachedQuizId = await cacheService.getCachedQuizId(widget.lesson.id);
          setState(() {
            _quiz = QuizEntity(
              id: cachedQuizId ?? 'cached_${widget.lesson.id}',
              lessonId: widget.lesson.id,
              courseId: widget.lesson.courseId,
              moduleId: widget.lesson.moduleId,
              questions: cachedQuestions,
            );
            _loading = false;
            _error = null;
          });
          return;
        }
      } catch (_) {}

      setState(() {
        _error = 'Error al cargar el cuestionario: $e';
        _loading = false;
      });
    }
  }

  Future<void> _submitQuiz() async {
    if (_quiz == null) return;

    // Verificar que todas las preguntas estén respondidas
    for (int i = 0; i < _quiz!.questions.length; i++) {
      if (_selectedAnswers[i] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor responde todas las preguntas.'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    final auth = ref.read(authStateProvider);
    final progress = ref.read(progressStateProvider);
    final firestore = ref.read(firestoreProvider);

    if (_isOnline) {
      try {
        // 4. Evaluación Online en Flutter:
        // Obtener obligatoriamente la clave desde Firestore usando Source.server
        final answersDoc = await firestore
            .collection('quizAnswers')
            .doc(_quiz!.id)
            .get(const GetOptions(source: Source.server));

        Map<String, dynamic> correctAnswersMap = {};
        if (answersDoc.exists && answersDoc.data() != null) {
          final data = answersDoc.data()!;
          if (data['answers'] is Map) {
            correctAnswersMap =
                Map<String, dynamic>.from(data['answers'] as Map);
          }
        }

        // Evaluar efímeramente en memoria del dispositivo
        int calculatedScore = 0;
        final List<Map<String, dynamic>> answerDetails = [];
        final List<QuestionEntity> evaluatedQuestions = [];

        for (int i = 0; i < _quiz!.questions.length; i++) {
          final q = _quiz!.questions[i];
          final selected = _selectedAnswers[i];
          final correctIndex = correctAnswersMap[q.id] as int?;

          final isCorrect =
              correctIndex != null && selected == correctIndex;
          if (isCorrect) {
            calculatedScore++;
          }

          answerDetails.add({
            'questionText': q.text,
            'selectedAnswerIndex': selected,
            'selectedAnswerText':
                selected != null ? q.options[selected] : null,
            'correctAnswerIndex': correctIndex ?? -1,
            'correctAnswerText': (correctIndex != null &&
                    correctIndex >= 0 &&
                    correctIndex < q.options.length)
                ? q.options[correctIndex]
                : '',
            'isCorrect': isCorrect,
          });

          // Actualizar pregunta efímeramente en memoria para mostrar resultados
          evaluatedQuestions.add(
            q.copyWith(correctAnswerIndex: correctIndex),
          );
        }

        if (auth.currentUser != null) {
          // Guardar directamente en Firestore
          await progress.markQuizCompleted(
            userId: auth.currentUser!.uid,
            courseId: widget.lesson.courseId,
            moduleId: widget.lesson.moduleId,
            lessonId: widget.lesson.id,
            score: calculatedScore,
            maxScore: _quiz!.questions.length,
          );

          await firestore.collection('quizRespuestas').add({
            'userId': auth.currentUser!.uid,
            'quizId': _quiz!.id,
            'lessonId': widget.lesson.id,
            'moduleId': widget.lesson.moduleId,
            'courseId': widget.lesson.courseId,
            'score': calculatedScore,
            'maxScore': _quiz!.questions.length,
            'answers': answerDetails,
            'submittedAt': FieldValue.serverTimestamp(),
          });

          // Limpiar datos temporales locales de Hive si existían
          await _quizOfflineService.deleteQuizProgress(
            auth.currentUser!.uid,
            _quiz!.id,
          );
        }

        if (!mounted) return;
        setState(() {
          _score = calculatedScore;
          _quiz = QuizEntity(
            id: _quiz!.id,
            lessonId: _quiz!.lessonId,
            courseId: _quiz!.courseId,
            moduleId: _quiz!.moduleId,
            questions: evaluatedQuestions,
          );
          _showResults = true;
          _isSubmitting = false;
          _submittedOffline = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cuestionario completado. Puntaje: $calculatedScore/${_quiz!.questions.length}',
            ),
            backgroundColor: AppColors.successColor,
          ),
        );
      } catch (e) {
        debugPrint('Error en evaluación online: $e');
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al evaluar cuestionario en línea: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } else {
      // 5. Manejo Offline:
      // Sin conexión: guardar localmente en Hive únicamente las selecciones del usuario
      // y posponer la calificación hasta que se restablezca la red.
      try {
        if (auth.currentUser != null) {
          final quizProgress = QuizProgressHive(
            userId: auth.currentUser!.uid,
            quizId: _quiz!.id,
            lessonId: widget.lesson.id,
            courseId: widget.lesson.courseId,
            moduleId: widget.lesson.moduleId,
            selectedAnswers: _selectedAnswers.cast<int, int>(),
            score: null, // Pospuesto: no hay calificación offline
            maxScore: _quiz!.questions.length,
            isCompleted: true,
            submittedAt: DateTime.now(),
            needsSync: true,
            answerDetails: const [], // Sin respuestas correctas en Hive
          );

          await _quizOfflineService.saveQuizProgress(quizProgress);
        }

        if (!mounted) return;
        setState(() {
          _score = 0;
          _showResults = true;
          _isSubmitting = false;
          _submittedOffline = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Respuestas guardadas sin conexión. La calificación se realizará cuando se restablezca la red.',
            ),
            backgroundColor: AppColors.successColor,
          ),
        );
      } catch (e) {
        debugPrint('Error al guardar quiz offline: $e');
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar localmente: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.lesson.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: const Column(
          children: [
            OfflineLessonBadge(),
            Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.lesson.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Column(
          children: [
            const OfflineLessonBadge(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Volver'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_quiz == null || _quiz!.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.lesson.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Column(
          children: [
            const OfflineLessonBadge(),
            const Expanded(
              child: Center(child: Text('No hay preguntas disponibles.')),
            ),
          ],
        ),
      );
    }

    if (_showingPreviousScore) {
      final auth = ref.read(authStateProvider);
      final hasPendingSync = !_isOnline &&
          auth.currentUser != null &&
          _quizOfflineService
              .getPendingSyncQuizzes(auth.currentUser!.uid)
              .any((q) => q.lessonId == widget.lesson.id);

      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.lesson.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Column(
          children: [
            const OfflineLessonBadge(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Último intento: $_previousScore / ${_quiz!.questions.length}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      if (hasPendingSync) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sync_problem,
                                size: 20,
                                color: Colors.amber.shade900,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Respondido en modo offline. Pendiente de sincronizar.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade900,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (hasPendingSync)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.block,
                                size: 20,
                                color: Colors.red.shade900,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'El cuestionario está bloqueado hasta que se sincronice con el servidor.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade900,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showingPreviousScore = false;
                              _selectedAnswers.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'Volver a intentar el cuestionario',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lesson.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          const OfflineLessonBadge(),
          Expanded(
            child:
                _showResults
                    ? _buildResults()
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.quiz,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Responde las siguientes preguntas. Máximo ${_quiz!.questions.length} preguntas.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ...List.generate(_quiz!.questions.length, (index) {
                            final question = _quiz!.questions[index];
                            return _QuestionCard(
                              questionNumber: index + 1,
                              question: question,
                              selectedAnswer: _selectedAnswers[index],
                              onAnswerSelected: (answerIndex) {
                                setState(() {
                                  _selectedAnswers[index] = answerIndex;
                                });
                              },
                            );
                          }),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitQuiz,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child:
                                  _isSubmitting
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text(
                                        'Enviar Cuestionario',
                                        style: TextStyle(fontSize: 16),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color:
                _score == _quiz!.questions.length
                    ? AppColors.successColor.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    _score == _quiz!.questions.length
                        ? Icons.check_circle
                        : Icons.info,
                    size: 64,
                    color:
                        _score == _quiz!.questions.length
                            ? AppColors.successColor
                            : Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Resultado del Cuestionario',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_isOnline && _submittedOffline) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 22,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cuestionario guardado sin conexión',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tus selecciones fueron guardadas localmente. La evaluación se pospone hasta restablecer la red.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Puntaje: $_score/${_quiz!.questions.length}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            _score == _quiz!.questions.length
                                ? AppColors.successColor
                                : Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (!_submittedOffline) ...[
            Text(
              'Revisión de Respuestas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(_quiz!.questions.length, (index) {
              final question = _quiz!.questions[index];
              final selected = _selectedAnswers[index];
              final isCorrect = question.correctAnswerIndex != null &&
                  selected == question.correctAnswerIndex;
              return _ResultQuestionCard(
                questionNumber: index + 1,
                question: question,
                selectedAnswer: selected,
                isCorrect: isCorrect,
              );
            }),
          ] else ...[
            Text(
              'Tus Respuestas Seleccionadas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Las respuestas se calificarán en el servidor al conectarte a internet.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...List.generate(_quiz!.questions.length, (index) {
              final question = _quiz!.questions[index];
              final selected = _selectedAnswers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pregunta ${index + 1}: ${question.text}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu selección: ${selected != null && selected >= 0 && selected < question.options.length ? question.options[selected] : "Sin respuesta"}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Volver', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int questionNumber;
  final QuestionEntity question;
  final int? selectedAnswer;
  final Function(int) onAnswerSelected;

  const _QuestionCard({
    required this.questionNumber,
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pregunta $questionNumber',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(question.text, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            ...List.generate(question.options.length, (index) {
              final isSelected = selectedAnswer == index;
              return InkWell(
                onTap: () => onAnswerSelected(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.08)
                            : Colors.transparent,
                    border: Border.all(
                      color:
                          isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child:
                            isSelected
                                ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.options[index],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ResultQuestionCard extends StatelessWidget {
  final int questionNumber;
  final QuestionEntity question;
  final int? selectedAnswer;
  final bool isCorrect;

  const _ResultQuestionCard({
    required this.questionNumber,
    required this.question,
    required this.selectedAnswer,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color:
          isCorrect
              ? AppColors.successColor.withValues(alpha: 0.1)
              : AppColors.errorColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Pregunta $questionNumber',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color:
                      isCorrect ? AppColors.successColor : AppColors.errorColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(question.text, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            ...List.generate(question.options.length, (index) {
              final isCorrectAnswer = index == question.correctAnswerIndex;
              Color? backgroundColor;
              IconData? icon;
              Color? iconColor;

              if (isCorrectAnswer) {
                backgroundColor = AppColors.successColor.withValues(alpha: 0.2);
                icon = Icons.check_circle;
                iconColor = AppColors.successColor;
              } else if (selectedAnswer == index && !isCorrect) {
                backgroundColor = AppColors.errorColor.withValues(alpha: 0.2);
                icon = Icons.cancel;
                iconColor = AppColors.errorColor;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isCorrectAnswer
                            ? AppColors.successColor
                            : (selectedAnswer == index
                                ? AppColors.errorColor
                                : Colors.grey[300]!),
                    width: isCorrectAnswer || selectedAnswer == index ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        question.options[index],
                        style: TextStyle(
                          fontWeight:
                              isCorrectAnswer
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isCorrectAnswer)
                      Text(
                        'Correcta',
                        style: TextStyle(
                          color: AppColors.successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

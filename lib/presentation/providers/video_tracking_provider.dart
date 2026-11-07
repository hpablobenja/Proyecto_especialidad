// lib/presentation/providers/video_tracking_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/video_tracking_entity.dart';
import '../../domain/entities/checkpoint_entity.dart';
import '../../domain/entities/system_config_entity.dart';
import '../../domain/repositories/video_tracking_repository.dart';
import '../../domain/usecases/video/initialize_video_tracking_usecase.dart';
import '../../domain/usecases/video/update_video_progress_usecase.dart';
import '../../domain/usecases/video/get_resume_position_usecase.dart';
import '../../domain/usecases/video/mark_lesson_completed_usecase.dart';
import '../../domain/usecases/video/sync_pending_progress_usecase.dart';
import '../../domain/usecases/video/validate_checkpoint_usecase.dart';
import '../../core/services/video_tracking_service.dart';
import '../../core/services/checkpoint_service.dart';
import '../../core/services/offline_sync_service.dart';
import '../../core/services/quiz_offline_service.dart';
import '../../data/datasources/local/video_tracking_hive_datasource.dart';
import '../../data/datasources/local/checkpoint_hive_datasource.dart';
import '../../data/datasources/local/sync_queue_hive_datasource.dart';
import '../../data/datasources/remote/video_tracking_remote_datasource.dart';
import '../../data/repositories/video_tracking_hive_repository_impl.dart';
import '../providers/auth_provider.dart';
import '../../core/di/riverpod_providers.dart';

/// Provider para el repositorio de tracking usando Hive
final videoTrackingRepositoryProvider = Provider<VideoTrackingRepository>((
  ref,
) {
  final localDataSource = VideoTrackingHiveDataSource();
  final remoteDataSource = VideoTrackingRemoteDataSource(
    firestore: FirebaseFirestore.instance,
  );
  final checkpointLocalDataSource = CheckpointHiveDataSource();
  final syncQueueDataSource = SyncQueueHiveDataSource();

  return VideoTrackingHiveRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    checkpointLocalDataSource: checkpointLocalDataSource,
    syncQueueDataSource: syncQueueDataSource,
  );
});

/// Provider para el repositorio de checkpoints usando Hive
final checkpointRepositoryProvider = Provider<CheckpointRepository>((ref) {
  final localDataSource = CheckpointHiveDataSource();
  return CheckpointHiveRepositoryImpl(localDataSource: localDataSource);
});

final initializeVideoTrackingUsecaseProvider =
    Provider<InitializeVideoTrackingUsecase>((ref) {
      return InitializeVideoTrackingUsecase(
        ref.watch(videoTrackingRepositoryProvider),
      );
    });

final updateVideoProgressUsecaseProvider = Provider<UpdateVideoProgressUsecase>(
  (ref) {
    return UpdateVideoProgressUsecase(
      ref.watch(videoTrackingRepositoryProvider),
    );
  },
);

final getResumePositionUsecaseProvider = Provider<GetResumePositionUsecase>((
  ref,
) {
  return GetResumePositionUsecase(ref.watch(videoTrackingRepositoryProvider));
});

final markLessonCompletedUsecaseProvider = Provider<MarkLessonCompletedUsecase>(
  (ref) {
    return MarkLessonCompletedUsecase(
      ref.watch(videoTrackingRepositoryProvider),
    );
  },
);

final syncPendingProgressUsecaseProvider = Provider<SyncPendingProgressUsecase>(
  (ref) {
    return SyncPendingProgressUsecase(
      ref.watch(videoTrackingRepositoryProvider),
    );
  },
);

final validateCheckpointUsecaseProvider = Provider<ValidateCheckpointUsecase>((
  ref,
) {
  return ValidateCheckpointUsecase(
    checkpointRepository: ref.watch(checkpointRepositoryProvider),
    checkpointService: ref.watch(checkpointServiceProvider),
  );
});

/// Provider para el VideoTrackingService
final videoTrackingServiceProvider = Provider<VideoTrackingService>((ref) {
  // Cargar configuración del sistema
  SystemConfigEntity? config;
  try {
    final configAsync = ref.watch(systemConfigProvider);
    config = configAsync.value;
  } catch (e) {
    debugPrint('Error loading config for VideoTrackingService: $e');
    // Usar valores por defecto si falla la carga
  }

  final service = VideoTrackingService(
    checkpoints: <CheckpointEntity>[],
    config: config,
    onPositionChanged: (position) {
      // Notificar cambios de posición si es necesario
    },
    onCheckpointReached: (checkpoint) {
      // Manejar checkpoint alcanzado
    },
    onProgressUpdated: (tracking) {
      // Notificar actualización de progreso
    },
    onLessonCompleted: () {
      // Manejar lección completada
    },
    onSyncNeeded: (tracking) async {
      // Sincronizar con Firestore cuando se dispara el evento
      final repository = ref.read(videoTrackingRepositoryProvider);
      await repository.saveVideoProgress(tracking);
    },
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Provider para el CheckpointService (singleton para mantener estado)
final checkpointServiceProvider = Provider<CheckpointService>((ref) {
  final service = CheckpointService();
  ref.onDispose(() {
    service.clearCache();
  });
  return service;
}, dependencies: []);

/// Provider para el OfflineSyncService
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final service = OfflineSyncService(
    connectivity: Connectivity(),
    onConnectivityRestored: () async {
      // Sincronizar progreso de video
      await ref.read(videoTrackingRepositoryProvider).syncPendingProgress();

      // Sincronizar quizzes pendientes
      await _syncPendingQuizzes(ref);
    },
    onSyncItem: (item) async {
      // Implementar sincronización real
      final repository = ref.read(videoTrackingRepositoryProvider);

      switch (item.operation) {
        case 'update_progress':
          final tracking = VideoTrackingEntity.fromMap(item.payload);
          await repository.saveVideoProgress(tracking);
          break;
        case 'checkpoint_passed':
          // Los checkpoints se sincronizan como parte del tracking de video
          break;
        case 'lesson_completed':
          final tracking = VideoTrackingEntity.fromMap(item.payload);
          await repository.saveVideoProgress(tracking);
          break;
        case 'quiz_submitted':
          // Sincronizar quiz
          await _syncQuizItem(ref, item);
          break;
      }
    },
    onSyncError: (error) {
      debugPrint('Sync error: $error');
    },
    onQueueEmpty: () {
      debugPrint('Sync queue empty');
    },
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Función auxiliar para sincronizar quizzes pendientes
Future<void> _syncPendingQuizzes(ProviderRef<Object?> ref) async {
  final auth = ref.read(authStateProvider);
  if (auth.currentUser == null) return;

  final quizOfflineService = ref.read(quizOfflineServiceProvider);
  final pendingQuizzes = quizOfflineService.getPendingSyncQuizzes(
    auth.currentUser!.uid,
  );
  final firestore = ref.read(firestoreProvider);

  for (final quiz in pendingQuizzes) {
    try {
      await firestore.collection('quizRespuestas').add({
        'userId': quiz.userId,
        'quizId': quiz.quizId,
        'lessonId': quiz.lessonId,
        'moduleId': quiz.moduleId,
        'courseId': quiz.courseId,
        'score': quiz.score,
        'maxScore': quiz.maxScore,
        'answers': quiz.answerDetails.map((a) => a.toMap()).toList(),
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
        //'status': 'completed',
        //'hasViewedVideo': true,
        'hasCompletedQuiz': true,
        'quizScore': quiz.score,
        'maxQuizScore': quiz.maxScore,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await quizOfflineService.markAsSynced(quiz.userId, quiz.quizId);
      debugPrint('Quiz sincronizado: ${quiz.quizId}');
    } catch (e) {
      debugPrint('Error al sincronizar quiz ${quiz.quizId}: $e');
    }
  }
}

/// Función auxiliar para sincronizar un item de quiz individual
Future<void> _syncQuizItem(ProviderRef<Object?> ref, SyncQueueItem item) async {
  final firestore = ref.read(firestoreProvider);
  final quizOfflineService = ref.read(quizOfflineServiceProvider);

  try {
    await firestore.collection('quizRespuestas').add({
      'userId': item.payload['userId'],
      'quizId': item.payload['quizId'],
      'lessonId': item.payload['lessonId'],
      'moduleId': item.payload['moduleId'],
      'courseId': item.payload['courseId'],
      'score': item.payload['score'],
      'maxScore': item.payload['maxScore'],
      'answers': item.payload['answers'],
      'submittedAt': FieldValue.serverTimestamp(),
    });

    // Actualizar progreso en userProgress
    final progressId =
        '${item.payload['userId']}-${item.payload['courseId']}-${item.payload['moduleId']}-${item.payload['lessonId']}';
    await firestore.collection('userProgress').doc(progressId).set({
      'userId': item.payload['userId'],
      'courseId': item.payload['courseId'],
      'moduleId': item.payload['moduleId'],
      'lessonId': item.payload['lessonId'],
      //'status': 'completed',
      //'hasViewedVideo': true,
      'hasCompletedQuiz': true,
      'quizScore': item.payload['score'],
      'maxQuizScore': item.payload['maxScore'],
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await quizOfflineService.markAsSynced(
      item.payload['userId'],
      item.payload['quizId'],
    );
    debugPrint('Quiz sincronizado desde cola: ${item.payload['quizId']}');
  } catch (e) {
    debugPrint('Error al sincronizar quiz item ${item.targetId}: $e');
    rethrow;
  }
}

/// Provider para el estado de tracking de video actual
class VideoTrackingNotifier extends StateNotifier<VideoTrackingState> {
  final VideoTrackingService trackingService;
  final CheckpointService checkpointService;
  final InitializeVideoTrackingUsecase initializeUsecase;
  final UpdateVideoProgressUsecase updateProgressUsecase;
  final GetResumePositionUsecase getResumePositionUsecase;
  final MarkLessonCompletedUsecase markCompletedUsecase;
  final SyncPendingProgressUsecase syncPendingUsecase;
  final ValidateCheckpointUsecase validateCheckpointUsecase;

  VideoTrackingNotifier({
    required this.trackingService,
    required this.checkpointService,
    required this.initializeUsecase,
    required this.updateProgressUsecase,
    required this.getResumePositionUsecase,
    required this.markCompletedUsecase,
    required this.syncPendingUsecase,
    required this.validateCheckpointUsecase,
  }) : super(VideoTrackingState.initial());

  /// Inicializa el tracking para una lección
  Future<void> initializeLesson({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
    required List<CheckpointEntity> checkpoints,
    int totalDurationMs = 0,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      // Configurar checkpoints en el servicio
      trackingService.checkpoints.clear();
      trackingService.checkpoints.addAll(checkpoints);
      checkpointService.setCheckpointsForLesson(lessonId, checkpoints);

      // Obtener progreso existente
      final existingProgress = await initializeUsecase.call(
        userId: userId,
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
        totalDurationMs: totalDurationMs,
      );

      // Obtener posición de reanudación
      final resumePositionMs = await getResumePositionUsecase.call(
        userId: userId,
        lessonId: lessonId,
      );

      // Inicializar servicio de tracking
      await trackingService.initialize(
        userId: userId,
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
        resumePosition: Duration(milliseconds: resumePositionMs),
        totalDurationMs: totalDurationMs,
        existingTracking: existingProgress,
      );

      state = state.copyWith(
        isLoading: false,
        currentTracking: trackingService.currentTracking,
        resumePosition: Duration(milliseconds: resumePositionMs),
        checkpoints: checkpoints,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Maneja cambio de posición del video
  void onPositionChange(Duration position) {
    trackingService.onPositionChange(position);
    state = state.copyWith(currentPosition: position);
  }

  /// Marca el video como reproduciéndose o pausado
  void setPlaying(bool playing) {
    trackingService.setPlaying(playing);
    state = state.copyWith(isPlaying: playing);
  }

  /// Valida respuesta de checkpoint
  Future<CheckpointValidationResult> validateCheckpoint({
    required String checkpointId,
    required int selectedOptionIndex,
  }) async {
    final result = await validateCheckpointUsecase.call(
      checkpointId: checkpointId,
      selectedOptionIndex: selectedOptionIndex,
    );

    if (result.isCorrect) {
      trackingService.markCheckpointPassed(checkpointId);
    } else {
      trackingService.markCheckpointFailed(checkpointId);
    }

    // Actualizar estado
    final updatedTracking = trackingService.currentTracking;
    if (updatedTracking != null) {
      await updateProgressUsecase.call(updatedTracking);
      state = state.copyWith(currentTracking: updatedTracking);
    }

    return result;
  }

  /// Fuerza sincronización con Firestore
  Future<void> forceSync() async {
    state = state.copyWith(isSyncing: true);

    try {
      await syncPendingUsecase.call();
      state = state.copyWith(isSyncing: false);
    } catch (e) {
      state = state.copyWith(isSyncing: false, errorMessage: e.toString());
    }
  }
}

/// Estado del tracking de video
class VideoTrackingState {
  final bool isLoading;
  final bool isInitialized;
  final bool isPlaying;
  final bool isSyncing;
  final String? errorMessage;
  final VideoTrackingEntity? currentTracking;
  final Duration currentPosition;
  final Duration resumePosition;
  final List<CheckpointEntity> checkpoints;

  VideoTrackingState({
    this.isLoading = false,
    this.isInitialized = false,
    this.isPlaying = false,
    this.isSyncing = false,
    this.errorMessage,
    this.currentTracking,
    this.currentPosition = Duration.zero,
    this.resumePosition = Duration.zero,
    this.checkpoints = const [],
  });

  factory VideoTrackingState.initial() {
    return VideoTrackingState();
  }

  VideoTrackingState copyWith({
    bool? isLoading,
    bool? isInitialized,
    bool? isPlaying,
    bool? isSyncing,
    String? errorMessage,
    VideoTrackingEntity? currentTracking,
    Duration? currentPosition,
    Duration? resumePosition,
    List<CheckpointEntity>? checkpoints,
  }) {
    return VideoTrackingState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      isPlaying: isPlaying ?? this.isPlaying,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
      currentTracking: currentTracking ?? this.currentTracking,
      currentPosition: currentPosition ?? this.currentPosition,
      resumePosition: resumePosition ?? this.resumePosition,
      checkpoints: checkpoints ?? this.checkpoints,
    );
  }
}

/// Provider para el VideoTrackingNotifier
final videoTrackingProvider =
    StateNotifierProvider<VideoTrackingNotifier, VideoTrackingState>((ref) {
      return VideoTrackingNotifier(
        trackingService: ref.watch(videoTrackingServiceProvider),
        checkpointService: ref.watch(checkpointServiceProvider),
        initializeUsecase: ref.watch(initializeVideoTrackingUsecaseProvider),
        updateProgressUsecase: ref.watch(updateVideoProgressUsecaseProvider),
        getResumePositionUsecase: ref.watch(getResumePositionUsecaseProvider),
        markCompletedUsecase: ref.watch(markLessonCompletedUsecaseProvider),
        syncPendingUsecase: ref.watch(syncPendingProgressUsecaseProvider),
        validateCheckpointUsecase: ref.watch(validateCheckpointUsecaseProvider),
      );
    });

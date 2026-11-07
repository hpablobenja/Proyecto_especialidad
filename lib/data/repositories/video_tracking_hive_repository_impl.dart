// lib/data/repositories/video_tracking_hive_repository_impl.dart

import '../../domain/entities/video_tracking_entity.dart';
import '../../domain/entities/checkpoint_entity.dart';
import '../../domain/repositories/video_tracking_repository.dart';
import '../datasources/local/video_tracking_hive_datasource.dart';
import '../datasources/local/checkpoint_hive_datasource.dart';
import '../datasources/local/sync_queue_hive_datasource.dart';
import '../datasources/remote/video_tracking_remote_datasource.dart';
import '../../core/services/offline_sync_service.dart' show SyncQueueItem;
import '../../core/utils/logger_service.dart';

/// Implementación del repositorio usando Hive para persistencia local
class VideoTrackingHiveRepositoryImpl implements VideoTrackingRepository {
  final VideoTrackingHiveDataSource localDataSource;
  final VideoTrackingRemoteDataSource remoteDataSource;
  final CheckpointHiveDataSource checkpointLocalDataSource;
  final SyncQueueHiveDataSource syncQueueDataSource;

  VideoTrackingHiveRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.checkpointLocalDataSource,
    required this.syncQueueDataSource,
  });

  @override
  Future<VideoTrackingEntity?> getVideoProgress(
    String userId,
    String lessonId,
  ) async {
    // Priorizar local
    final local = await localDataSource.getVideoProgress(userId, lessonId);
    if (local != null) {
      return local.toEntity();
    }

    // Fallback a remoto
    try {
      final remote = await remoteDataSource.getVideoProgress(userId, lessonId);
      if (remote != null) {
        // Persistir localmente
        await localDataSource.saveVideoProgress(remote);
        return remote;
      }
    } catch (e) {
      // Ignorar error de remoto, retornar null
    }

    return null;
  }

  @override
  Future<void> saveVideoProgress(VideoTrackingEntity tracking) async {
    // Si la lección ya está completada, no guardar más datos
    if (tracking.isCompleted) {
      // Solo guardar si es una actualización de estado de completado
      final existing = await localDataSource.getVideoProgress(
        tracking.userId,
        tracking.lessonId,
      );
      if (existing != null && existing.isCompleted) {
        // Ya estaba completada, no actualizar
        return;
      }
    }

    // Guardar localmente
    await localDataSource.saveVideoProgress(tracking);

    // Agregar a cola de sincronización
    final syncItem = SyncQueueItem.updateVideoProgress(tracking);
    await syncQueueDataSource.enqueue(syncItem.toMap());
  }

  @override
  Future<int> getResumePosition(String userId, String lessonId) async {
    final progress = await getVideoProgress(userId, lessonId);
    if (progress != null) {
      return progress.lastValidPositionMs;
    }
    return 0;
  }

  @override
  Future<void> markLessonCompleted(VideoTrackingEntity tracking) async {
    try {
      final completed = tracking.copyWith(
        isCompleted: true,
        completionPercentage: 90.0,
        lastUpdated: DateTime.now(),
      );

      await localDataSource.saveVideoProgress(completed);
      LoggerService.logInfo('Lesson marked as completed locally');

      // También actualizar en userProgress para que se refleje en la pantalla de progreso
      await remoteDataSource.updateUserProgressWithVideoTracking(completed);
    } catch (e) {
      LoggerService.logError('Error marking lesson as completed', e);
    }
  }

  @override
  Future<void> syncPendingProgress() async {
    final pendingItems = await syncQueueDataSource.getPendingItems();

    for (final item in pendingItems) {
      try {
        await syncQueueDataSource.markAsProcessing(item.syncId);

        switch (item.operation) {
          case 'update_progress':
            final tracking = VideoTrackingEntity.fromMap(item.payload);
            await remoteDataSource.saveVideoProgress(tracking);
            await localDataSource.markAsSynced(
              tracking.userId,
              tracking.lessonId,
            );
            break;
          case 'checkpoint_passed':
            // Los checkpoints se sincronizan como parte del tracking de video
            break;
          case 'lesson_completed':
            final tracking = VideoTrackingEntity.fromMap(item.payload);
            await remoteDataSource.saveVideoProgress(tracking);
            break;
        }

        await syncQueueDataSource.markAsProcessed(item.syncId);
      } catch (e) {
        await syncQueueDataSource.incrementRetryCount(item.syncId);
      }
    }
  }

  @override
  Future<List<VideoTrackingEntity>> getUserVideoProgress(String userId) async {
    final local = await localDataSource.getUserVideoProgress(userId);
    return local.map((item) => item.toEntity()).toList();
  }

  @override
  Future<List<VideoTrackingEntity>> getCourseVideoProgress(
    String userId,
    String courseId,
  ) async {
    final local = await localDataSource.getUserVideoProgress(userId);
    return local
        .where((item) => item.courseId == courseId)
        .map((item) => item.toEntity())
        .toList();
  }

  Future<Map<String, dynamic>> getCourseProgressStats(
    String userId,
    String courseId,
  ) async {
    return await localDataSource.getCourseProgressStats(userId, courseId);
  }

  @override
  Future<void> deleteVideoProgress(String userId, String lessonId) async {
    await localDataSource.deleteVideoProgress(userId, lessonId);
  }
}

/// Implementación del repositorio de checkpoints usando Hive
class CheckpointHiveRepositoryImpl implements CheckpointRepository {
  final CheckpointHiveDataSource localDataSource;

  CheckpointHiveRepositoryImpl({required this.localDataSource});

  @override
  Future<CheckpointEntity?> getCheckpoint(String checkpointId) async {
    final local = await localDataSource.getCheckpoint(checkpointId);
    if (local != null) {
      return CheckpointEntity.fromMap(local.toMap());
    }
    return null;
  }

  @override
  Future<List<CheckpointEntity>> getLessonCheckpoints(String lessonId) async {
    final local = await localDataSource.getLessonCheckpoints(lessonId);
    return local.map((item) => CheckpointEntity.fromMap(item.toMap())).toList();
  }

  @override
  Future<void> saveCheckpoint(CheckpointEntity checkpoint) async {
    await localDataSource.saveCheckpoint(checkpoint);
  }

  @override
  Future<void> markCheckpointPassed(String checkpointId) async {
    await localDataSource.markCheckpointPassed(checkpointId);
  }

  @override
  Future<void> incrementCheckpointAttempts(String checkpointId) async {
    await localDataSource.incrementCheckpointAttempts(checkpointId);
  }

  @override
  Future<List<CheckpointEntity>> getPassedCheckpoints(String lessonId) async {
    final local = await localDataSource.getPassedCheckpoints(lessonId);
    return local.map((item) => CheckpointEntity.fromMap(item.toMap())).toList();
  }

  Future<void> deleteLessonCheckpoints(String lessonId) async {
    await localDataSource.deleteLessonCheckpoints(lessonId);
  }
}

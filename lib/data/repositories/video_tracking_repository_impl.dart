// lib/data/repositories/video_tracking_repository_impl.dart
/*
import 'package:flutter/material.dart';
import '../../domain/entities/video_tracking_entity.dart';
import '../../domain/entities/checkpoint_entity.dart';
import '../../domain/repositories/video_tracking_repository.dart';
import '../datasources/local/video_tracking_local_datasource.dart';
import '../datasources/local/checkpoint_local_datasource.dart';
import '../datasources/remote/video_tracking_remote_datasource.dart';
import '../models/video_progress_local.dart';

/// Implementación del repositorio de tracking de video
/// Coordina entre datasources locales (Isar) y remotos (Firestore)
class VideoTrackingRepositoryImpl implements VideoTrackingRepository {
  final VideoTrackingLocalDataSource localDataSource;
  final VideoTrackingRemoteDataSource remoteDataSource;
  final CheckpointLocalDataSource checkpointLocalDataSource;

  VideoTrackingRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.checkpointLocalDataSource,
  });

  @override
  Future<void> saveVideoProgress(VideoTrackingEntity tracking) async {
    try {
      // 1. Guardar localmente inmediatamente (Nivel 2)
      await localDataSource.saveVideoProgress(tracking);
      
      // 2. Si necesita sincronización, se manejará por el servicio de sync
      // No sincronizamos inmediatamente para optimizar costos
      debugPrint('Video progress saved locally for lesson ${tracking.lessonId}');
    } catch (e) {
      debugPrint('Error saving video progress locally: $e');
      rethrow;
    }
  }

  @override
  Future<VideoTrackingEntity?> getVideoProgress(String userId, String lessonId) async {
    try {
      // 1. Intentar obtener localmente primero (prioridad)
      final local = await localDataSource.getVideoProgress(userId, lessonId);
      
      if (local != null) {
        debugPrint('Video progress found locally for lesson $lessonId');
        return VideoTrackingEntity.fromMap(local.toMap());
      }
      
      // 2. Si no existe local, intentar obtener de Firestore
      debugPrint('Video progress not found locally, checking remote...');
      final remote = await remoteDataSource.getVideoProgress(userId, lessonId);
      
      if (remote != null) {
        // 3. Persistir localmente para futuros accesos
        await localDataSource.saveVideoProgress(remote);
        debugPrint('Video progress synced from remote to local');
        return remote;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting video progress: $e');
      return null;
    }
  }

  @override
  Future<List<VideoTrackingEntity>> getUserVideoProgress(String userId) async {
    try {
      // Priorizar datos locales
      final localList = await localDataSource.getUserVideoProgress(userId);
      
      if (localList.isNotEmpty) {
        return localList.map((local) => VideoTrackingEntity.fromMap(local.toMap())).toList();
      }
      
      // Fallback a remoto
      final remoteList = await remoteDataSource.getUserVideoProgress(userId);
      
      // Persistir localmente
      for (final tracking in remoteList) {
        await localDataSource.saveVideoProgress(tracking);
      }
      
      return remoteList;
    } catch (e) {
      debugPrint('Error getting user video progress: $e');
      return [];
    }
  }

  @override
  Future<List<VideoTrackingEntity>> getCourseVideoProgress(
    String userId,
    String courseId,
  ) async {
    try {
      final localList = await localDataSource.getUserVideoProgress(userId);
      final courseLocal = localList.where((p) => p.courseId == courseId).toList();
      
      if (courseLocal.isNotEmpty) {
        return courseLocal.map((local) => VideoTrackingEntity.fromMap(local.toMap())).toList();
      }
      
      final remoteList = await remoteDataSource.getCourseVideoProgress(userId, courseId);
      
      for (final tracking in remoteList) {
        await localDataSource.saveVideoProgress(tracking);
      }
      
      return remoteList;
    } catch (e) {
      debugPrint('Error getting course video progress: $e');
      return [];
    }
  }

  @override
  Future<void> syncPendingProgress() async {
    try {
      // Obtener progreso pendiente de sincronización
      final pendingList = await localDataSource.getPendingSync();
      
      debugPrint('Syncing ${pendingList.length} pending progress items');
      
      for (final local in pendingList) {
        final tracking = VideoTrackingEntity.fromMap(local.toMap());
        
        try {
          await remoteDataSource.saveVideoProgress(tracking);
          await localDataSource.markAsSynced(tracking.userId, tracking.lessonId);
          debugPrint('Synced progress for lesson ${tracking.lessonId}');
        } catch (e) {
          debugPrint('Failed to sync progress for lesson ${tracking.lessonId}: $e');
          // Continuar con el siguiente
        }
      }
    } catch (e) {
      debugPrint('Error syncing pending progress: $e');
    }
  }

  @override
  Future<void> markLessonCompleted(VideoTrackingEntity tracking) async {
    try {
      final completed = tracking.copyWith(
        isCompleted: true,
        completionPercentage: 90.0,
        needsSync: true,
      );
      
      // Guardar localmente
      await localDataSource.saveVideoProgress(completed);
      
      // Sincronizar inmediatamente al completar
      await remoteDataSource.saveVideoProgress(completed);
      await localDataSource.markAsSynced(tracking.userId, tracking.lessonId);
      
      debugPrint('Lesson ${tracking.lessonId} marked as completed');
    } catch (e) {
      debugPrint('Error marking lesson as completed: $e');
      rethrow;
    }
  }

  @override
  Future<int> getResumePosition(String userId, String lessonId) async {
    try {
      final tracking = await getVideoProgress(userId, lessonId);
      
      if (tracking != null) {
        // Usar lastValidPosition (nunca maxReachedPosition)
        return tracking.lastValidPositionMs;
      }
      
      return 0; // Iniciar desde el inicio
    } catch (e) {
      debugPrint('Error getting resume position: $e');
      return 0;
    }
  }

  @override
  Future<void> deleteVideoProgress(String userId, String lessonId) async {
    try {
      // Eliminar localmente
      await localDataSource.deleteVideoProgress(userId, lessonId);
      
      // Eliminar remotamente
      await remoteDataSource.deleteVideoProgress(userId, lessonId);
      
      debugPrint('Video progress deleted for lesson $lessonId');
    } catch (e) {
      debugPrint('Error deleting video progress: $e');
    }
  }
}

/// Implementación del repositorio de checkpoints
class CheckpointRepositoryImpl implements CheckpointRepository {
  final CheckpointLocalDataSource localDataSource;

  CheckpointRepositoryImpl({required this.localDataSource});

  @override
  Future<void> saveCheckpoint(CheckpointEntity checkpoint) async {
    try {
      await localDataSource.saveCheckpoint(checkpoint);
      debugPrint('Checkpoint ${checkpoint.id} saved locally');
    } catch (e) {
      debugPrint('Error saving checkpoint: $e');
      rethrow;
    }
  }

  @override
  Future<CheckpointEntity?> getCheckpoint(String checkpointId) async {
    try {
      final local = await localDataSource.getCheckpoint(checkpointId);
      
      if (local != null) {
        return CheckpointEntity.fromMap(local.toMap());
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting checkpoint: $e');
      return null;
    }
  }

  @override
  Future<List<CheckpointEntity>> getLessonCheckpoints(String lessonId) async {
    try {
      final localList = await localDataSource.getLessonCheckpoints(lessonId);
      return localList.map((local) => CheckpointEntity.fromMap(local.toMap())).toList();
    } catch (e) {
      debugPrint('Error getting lesson checkpoints: $e');
      return [];
    }
  }

  @override
  Future<void> markCheckpointPassed(String checkpointId) async {
    try {
      await localDataSource.markCheckpointPassed(checkpointId);
      debugPrint('Checkpoint $checkpointId marked as passed');
    } catch (e) {
      debugPrint('Error marking checkpoint as passed: $e');
    }
  }

  @override
  Future<void> incrementCheckpointAttempts(String checkpointId) async {
    try {
      await localDataSource.incrementCheckpointAttempts(checkpointId);
    } catch (e) {
      debugPrint('Error incrementing checkpoint attempts: $e');
    }
  }

  @override
  Future<List<CheckpointEntity>> getPassedCheckpoints(String lessonId) async {
    try {
      final localList = await localDataSource.getPassedCheckpoints(lessonId);
      return localList.map((local) => CheckpointEntity.fromMap(local.toMap())).toList();
    } catch (e) {
      debugPrint('Error getting passed checkpoints: $e');
      return [];
    }
  }
}
*/

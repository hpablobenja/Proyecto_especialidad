// lib/domain/repositories/video_tracking_repository.dart

import '../../../domain/entities/video_tracking_entity.dart';
import '../../../domain/entities/checkpoint_entity.dart';

/// Repositorio para tracking de video
/// Implementa la estrategia híbrida: local, remoto como respaldo
abstract class VideoTrackingRepository {
  /// Guarda el progreso de video (local y remoto)
  Future<void> saveVideoProgress(VideoTrackingEntity tracking);

  /// Obtiene el progreso de video (prioriza local, fallback a remoto)
  Future<VideoTrackingEntity?> getVideoProgress(String userId, String lessonId);

  /// Obtiene todo el progreso de video de un usuario
  Future<List<VideoTrackingEntity>> getUserVideoProgress(String userId);

  /// Obtiene progreso de video de un curso
  Future<List<VideoTrackingEntity>> getCourseVideoProgress(
    String userId,
    String courseId,
  );

  /// Sincroniza progreso pendiente con Firestore
  Future<void> syncPendingProgress();

  /// Marca lección como completada
  Future<void> markLessonCompleted(VideoTrackingEntity tracking);

  /// Obtiene la posición de reanudación (lastValidPosition)
  Future<int> getResumePosition(String userId, String lessonId);

  /// Elimina progreso local y remoto
  Future<void> deleteVideoProgress(String userId, String lessonId);
}

/// Repositorio para checkpoints
abstract class CheckpointRepository {
  /// Guarda o actualiza un checkpoint
  Future<void> saveCheckpoint(CheckpointEntity checkpoint);

  /// Obtiene un checkpoint por ID
  Future<CheckpointEntity?> getCheckpoint(String checkpointId);

  /// Obtiene todos los checkpoints de una lección
  Future<List<CheckpointEntity>> getLessonCheckpoints(String lessonId);

  /// Marca checkpoint como aprobado
  Future<void> markCheckpointPassed(String checkpointId);

  /// Incrementa intentos de checkpoint
  Future<void> incrementCheckpointAttempts(String checkpointId);

  /// Obtiene checkpoints aprobados de una lección
  Future<List<CheckpointEntity>> getPassedCheckpoints(String lessonId);
}

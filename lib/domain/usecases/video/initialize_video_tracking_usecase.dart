// lib/domain/usecases/video/initialize_video_tracking_usecase.dart

import '../../entities/video_tracking_entity.dart';
import '../../repositories/video_tracking_repository.dart';

/// Use case para inicializar el tracking de video para una lección
class InitializeVideoTrackingUsecase {
  final VideoTrackingRepository repository;

  InitializeVideoTrackingUsecase(this.repository);

  /// Ejecuta el use case
  /// Retorna el progreso existente o null si es la primera vez
  Future<VideoTrackingEntity?> call({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
    int totalDurationMs = 0,
  }) async {
    // Intentar obtener progreso existente
    final existingProgress = await repository.getVideoProgress(
      userId,
      lessonId,
    );

    if (existingProgress != null) {
      return existingProgress;
    }

    // No existe progreso, retornar null para indicar que es nuevo
    return null;
  }
}

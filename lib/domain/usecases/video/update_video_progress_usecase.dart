// lib/domain/usecases/video/update_video_progress_usecase.dart

import '../../entities/video_tracking_entity.dart';
import '../../repositories/video_tracking_repository.dart';

/// Use case para actualizar el progreso de video
class UpdateVideoProgressUsecase {
  final VideoTrackingRepository repository;

  UpdateVideoProgressUsecase(this.repository);

  /// Ejecuta el use case
  Future<void> call(VideoTrackingEntity tracking) async {
    await repository.saveVideoProgress(tracking);
  }
}

// lib/domain/usecases/video/mark_lesson_completed_usecase.dart

import '../../entities/video_tracking_entity.dart';
import '../../repositories/video_tracking_repository.dart';

/// Use case para marcar una lección como completada
class MarkLessonCompletedUsecase {
  final VideoTrackingRepository repository;

  MarkLessonCompletedUsecase(this.repository);

  /// Ejecuta el use case
  Future<void> call(VideoTrackingEntity tracking) async {
    await repository.markLessonCompleted(tracking);
  }
}

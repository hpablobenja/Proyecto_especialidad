// lib/domain/usecases/video/get_resume_position_usecase.dart

import '../../repositories/video_tracking_repository.dart';

/// Use case para obtener la posición de reanudación de una lección
class GetResumePositionUsecase {
  final VideoTrackingRepository repository;

  GetResumePositionUsecase(this.repository);

  /// Ejecuta el use case
  /// Retorna la posición en milisegundos para reanudar
  Future<int> call({required String userId, required String lessonId}) async {
    return await repository.getResumePosition(userId, lessonId);
  }
}

// lib/domain/usecases/video/sync_pending_progress_usecase.dart

import '../../repositories/video_tracking_repository.dart';

/// Use case para sincronizar progreso pendiente con Firestore
class SyncPendingProgressUsecase {
  final VideoTrackingRepository repository;

  SyncPendingProgressUsecase(this.repository);

  /// Ejecuta el use case
  Future<void> call() async {
    await repository.syncPendingProgress();
  }
}

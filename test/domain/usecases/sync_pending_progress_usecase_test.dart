import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/video_tracking_entity.dart';
import 'package:redmaestra1/domain/repositories/video_tracking_repository.dart';
import 'package:redmaestra1/domain/usecases/video/sync_pending_progress_usecase.dart';

class MockVideoTrackingRepository implements VideoTrackingRepository {
  bool syncWasCalled = false;
  Exception? errorToThrow;

  @override
  Future<void> saveVideoProgress(VideoTrackingEntity tracking) async {}

  @override
  Future<VideoTrackingEntity?> getVideoProgress(
    String userId,
    String lessonId,
  ) async => null;

  @override
  Future<List<VideoTrackingEntity>> getUserVideoProgress(String userId) async =>
      [];

  @override
  Future<List<VideoTrackingEntity>> getCourseVideoProgress(
    String userId,
    String courseId,
  ) async => [];

  @override
  Future<void> syncPendingProgress() async {
    syncWasCalled = true;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

  @override
  Future<void> markLessonCompleted(VideoTrackingEntity tracking) async {}

  @override
  Future<int> getResumePosition(String userId, String lessonId) async => 0;

  @override
  Future<void> deleteVideoProgress(String userId, String lessonId) async {}
}

void main() {
  group('SyncPendingProgressUsecase Tests', () {
    late SyncPendingProgressUsecase usecase;
    late MockVideoTrackingRepository mockRepository;

    setUp(() {
      mockRepository = MockVideoTrackingRepository();
      usecase = SyncPendingProgressUsecase(mockRepository);
    });

    test(
      'SyncPendingProgressUsecase calls repository syncPendingProgress',
      () async {
        await usecase();

        expect(mockRepository.syncWasCalled, true);
      },
    );

    test(
      'SyncPendingProgressUsecase throws exception when repository throws',
      () async {
        mockRepository.errorToThrow = Exception('Failed to sync progress');

        expect(() => usecase(), throwsException);
      },
    );

    test('SyncPendingProgressUsecase completes successfully', () async {
      await usecase();

      expect(mockRepository.syncWasCalled, true);
    });

    test('SyncPendingProgressUsecase can be called multiple times', () async {
      await usecase();
      await usecase();
      await usecase();

      expect(mockRepository.syncWasCalled, true);
    });
  });
}

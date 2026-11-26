import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/video_tracking_entity.dart';
import 'package:redmaestra1/domain/repositories/video_tracking_repository.dart';
import 'package:redmaestra1/domain/usecases/video/update_video_progress_usecase.dart';

class MockVideoTrackingRepository implements VideoTrackingRepository {
  VideoTrackingEntity? lastSavedTracking;
  Exception? errorToThrow;

  @override
  Future<void> saveVideoProgress(VideoTrackingEntity tracking) async {
    lastSavedTracking = tracking;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

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
  Future<void> syncPendingProgress() async {}

  @override
  Future<void> markLessonCompleted(VideoTrackingEntity tracking) async {}

  @override
  Future<int> getResumePosition(String userId, String lessonId) async => 0;

  @override
  Future<void> deleteVideoProgress(String userId, String lessonId) async {}
}

void main() {
  group('UpdateVideoProgressUsecase Tests', () {
    late UpdateVideoProgressUsecase usecase;
    late MockVideoTrackingRepository mockRepository;

    setUp(() {
      mockRepository = MockVideoTrackingRepository();
      usecase = UpdateVideoProgressUsecase(mockRepository);
    });

    test(
      'UpdateVideoProgressUsecase calls repository with tracking entity',
      () async {
        final now = DateTime.now();
        final tracking = VideoTrackingEntity(
          userId: 'user_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          lastUpdated: now,
        );

        await usecase(tracking);

        expect(mockRepository.lastSavedTracking, isNotNull);
        expect(mockRepository.lastSavedTracking?.userId, 'user_1');
      },
    );

    test('UpdateVideoProgressUsecase preserves tracking data', () async {
      final now = DateTime.now();
      final tracking = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        currentPositionMs: 45000,
        lastValidPositionMs: 45000,
        maxReachedPositionMs: 60000,
        viewedSeconds: 180,
        completionPercentage: 66.7,
        totalDurationMs: 90000,
        lastUpdated: now,
        needsSync: true,
      );

      await usecase(tracking);

      expect(mockRepository.lastSavedTracking?.userId, 'user_1');
      expect(mockRepository.lastSavedTracking?.courseId, 'course_1');
      expect(mockRepository.lastSavedTracking?.moduleId, 'module_1');
      expect(mockRepository.lastSavedTracking?.lessonId, 'lesson_1');
      expect(mockRepository.lastSavedTracking?.currentPositionMs, 45000);
      expect(mockRepository.lastSavedTracking?.completionPercentage, 66.7);
      expect(mockRepository.lastSavedTracking?.needsSync, true);
    });

    test(
      'UpdateVideoProgressUsecase throws exception when repository throws',
      () async {
        mockRepository.errorToThrow = Exception(
          'Failed to save video progress',
        );
        final now = DateTime.now();
        final tracking = VideoTrackingEntity(
          userId: 'user_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          lastUpdated: now,
        );

        expect(() => usecase(tracking), throwsException);
      },
    );

    test(
      'UpdateVideoProgressUsecase handles different tracking entities',
      () async {
        final now = DateTime.now();
        final tracking1 = VideoTrackingEntity(
          userId: 'user_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          currentPositionMs: 10000,
          lastUpdated: now,
        );

        final tracking2 = VideoTrackingEntity(
          userId: 'user_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          currentPositionMs: 20000,
          lastUpdated: now,
        );

        await usecase(tracking1);
        await usecase(tracking2);

        expect(mockRepository.lastSavedTracking?.currentPositionMs, 20000);
      },
    );

    test(
      'UpdateVideoProgressUsecase handles tracking with checkpoints',
      () async {
        final now = DateTime.now();
        final tracking = VideoTrackingEntity(
          userId: 'user_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          checkpointsPassed: ['cp1'],
          checkpointsFailed: [],
          lastUpdated: now,
        );

        await usecase(tracking);

        expect(mockRepository.lastSavedTracking?.checkpointsPassed, ['cp1']);
      },
    );

    test('UpdateVideoProgressUsecase handles completed lessons', () async {
      final now = DateTime.now();
      final tracking = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        isCompleted: true,
        completionPercentage: 100.0,
        lastUpdated: now,
      );

      await usecase(tracking);

      expect(mockRepository.lastSavedTracking?.isCompleted, true);
      expect(mockRepository.lastSavedTracking?.completionPercentage, 100.0);
    });
  });
}

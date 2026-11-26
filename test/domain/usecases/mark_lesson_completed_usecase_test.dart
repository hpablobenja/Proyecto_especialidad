import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/video_tracking_entity.dart';
import 'package:redmaestra1/domain/repositories/video_tracking_repository.dart';
import 'package:redmaestra1/domain/usecases/video/mark_lesson_completed_usecase.dart';

class MockVideoTrackingRepository implements VideoTrackingRepository {
  VideoTrackingEntity? lastMarkedTracking;
  Exception? errorToThrow;

  @override
  Future<void> saveVideoProgress(dynamic tracking) async {}

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
  Future<void> markLessonCompleted(VideoTrackingEntity tracking) async {
    lastMarkedTracking = tracking;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

  @override
  Future<int> getResumePosition(String userId, String lessonId) async => 0;

  @override
  Future<void> deleteVideoProgress(String userId, String lessonId) async {}
}

void main() {
  group('MarkLessonCompletedUsecase Tests', () {
    late MarkLessonCompletedUsecase usecase;
    late MockVideoTrackingRepository mockRepository;

    setUp(() {
      mockRepository = MockVideoTrackingRepository();
      usecase = MarkLessonCompletedUsecase(mockRepository);
    });

    test(
      'MarkLessonCompletedUsecase calls repository with tracking entity',
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

        expect(mockRepository.lastMarkedTracking, isNotNull);
        expect(mockRepository.lastMarkedTracking?.userId, 'user_1');
      },
    );

    test('MarkLessonCompletedUsecase preserves tracking data', () async {
      final now = DateTime.now();
      final tracking = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        currentPositionMs: 90000,
        maxReachedPositionMs: 90000,
        completionPercentage: 100.0,
        isCompleted: true,
        lastUpdated: now,
      );

      await usecase(tracking);

      expect(mockRepository.lastMarkedTracking?.userId, 'user_1');
      expect(mockRepository.lastMarkedTracking?.courseId, 'course_1');
      expect(mockRepository.lastMarkedTracking?.moduleId, 'module_1');
      expect(mockRepository.lastMarkedTracking?.lessonId, 'lesson_1');
      expect(mockRepository.lastMarkedTracking?.currentPositionMs, 90000);
      expect(mockRepository.lastMarkedTracking?.isCompleted, true);
    });

    test(
      'MarkLessonCompletedUsecase throws exception when repository throws',
      () async {
        mockRepository.errorToThrow = Exception(
          'Failed to mark lesson completed',
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
      'MarkLessonCompletedUsecase handles different tracking entities',
      () async {
        final now = DateTime.now();
        final tracking1 = VideoTrackingEntity(
          userId: 'user_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          lastUpdated: now,
        );

        final tracking2 = VideoTrackingEntity(
          userId: 'user_2',
          courseId: 'course_2',
          moduleId: 'module_2',
          lessonId: 'lesson_2',
          lastUpdated: now,
        );

        await usecase(tracking1);
        await usecase(tracking2);

        expect(mockRepository.lastMarkedTracking?.userId, 'user_2');
      },
    );

    test(
      'MarkLessonCompletedUsecase handles tracking with checkpoints',
      () async {
        final now = DateTime.now();
        final tracking = VideoTrackingEntity(
          userId: 'user_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          checkpointsPassed: ['cp1', 'cp2'],
          checkpointsFailed: ['cp3'],
          lastUpdated: now,
        );

        await usecase(tracking);

        expect(mockRepository.lastMarkedTracking?.checkpointsPassed, [
          'cp1',
          'cp2',
        ]);
        expect(mockRepository.lastMarkedTracking?.checkpointsFailed, ['cp3']);
      },
    );
  });
}

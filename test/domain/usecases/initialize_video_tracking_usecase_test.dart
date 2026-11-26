import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/video_tracking_entity.dart';
import 'package:redmaestra1/domain/repositories/video_tracking_repository.dart';
import 'package:redmaestra1/domain/usecases/video/initialize_video_tracking_usecase.dart';

class MockVideoTrackingRepository implements VideoTrackingRepository {
  VideoTrackingEntity? progressToReturn;
  String? lastRequestedUserId;
  String? lastRequestedLessonId;
  Exception? errorToThrow;

  @override
  Future<void> saveVideoProgress(VideoTrackingEntity tracking) async {}

  @override
  Future<VideoTrackingEntity?> getVideoProgress(
    String userId,
    String lessonId,
  ) async {
    lastRequestedUserId = userId;
    lastRequestedLessonId = lessonId;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return progressToReturn;
  }

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
  group('InitializeVideoTrackingUsecase Tests', () {
    late InitializeVideoTrackingUsecase usecase;
    late MockVideoTrackingRepository mockRepository;

    setUp(() {
      mockRepository = MockVideoTrackingRepository();
      usecase = InitializeVideoTrackingUsecase(mockRepository);
    });

    test(
      'InitializeVideoTrackingUsecase calls repository with correct userId',
      () async {
        await usecase(
          userId: 'user_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
        );

        expect(mockRepository.lastRequestedUserId, 'user_1');
      },
    );

    test(
      'InitializeVideoTrackingUsecase calls repository with correct lessonId',
      () async {
        await usecase(
          userId: 'user_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
        );

        expect(mockRepository.lastRequestedLessonId, 'lesson_1');
      },
    );

    test('InitializeVideoTrackingUsecase returns existing progress', () async {
      final now = DateTime.now();
      final existingProgress = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        currentPositionMs: 30000,
        lastUpdated: now,
      );
      mockRepository.progressToReturn = existingProgress;

      final result = await usecase(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
      );

      expect(result, isNotNull);
      expect(result?.userId, 'user_1');
      expect(result?.currentPositionMs, 30000);
    });

    test(
      'InitializeVideoTrackingUsecase returns null when no existing progress',
      () async {
        mockRepository.progressToReturn = null;

        final result = await usecase(
          userId: 'user_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
        );

        expect(result, null);
      },
    );

    test(
      'InitializeVideoTrackingUsecase throws exception when repository throws',
      () async {
        mockRepository.errorToThrow = Exception(
          'Failed to initialize tracking',
        );

        expect(
          () => usecase(
            userId: 'user_1',
            courseId: 'course_1',
            moduleId: 'module_1',
            lessonId: 'lesson_1',
          ),
          throwsException,
        );
      },
    );

    test(
      'InitializeVideoTrackingUsecase handles totalDurationMs parameter',
      () async {
        mockRepository.progressToReturn = null;

        await usecase(
          userId: 'user_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          totalDurationMs: 90000,
        );

        expect(mockRepository.lastRequestedUserId, 'user_1');
      },
    );

    test(
      'InitializeVideoTrackingUsecase handles different course and module IDs',
      () async {
        mockRepository.progressToReturn = null;

        await usecase(
          userId: 'user_1',
          courseId: 'course_xyz',
          moduleId: 'module_abc',
          lessonId: 'lesson_123',
        );

        expect(mockRepository.lastRequestedUserId, 'user_1');
        expect(mockRepository.lastRequestedLessonId, 'lesson_123');
      },
    );
  });
}

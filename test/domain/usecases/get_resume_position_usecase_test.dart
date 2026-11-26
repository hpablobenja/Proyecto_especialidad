import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/video_tracking_entity.dart';
import 'package:redmaestra1/domain/repositories/video_tracking_repository.dart';
import 'package:redmaestra1/domain/usecases/video/get_resume_position_usecase.dart';

class MockVideoTrackingRepository implements VideoTrackingRepository {
  int resumePositionToReturn = 0;
  String? lastRequestedUserId;
  String? lastRequestedLessonId;
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
  Future<void> syncPendingProgress() async {}

  @override
  Future<void> markLessonCompleted(VideoTrackingEntity tracking) async {}

  @override
  Future<int> getResumePosition(String userId, String lessonId) async {
    lastRequestedUserId = userId;
    lastRequestedLessonId = lessonId;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return resumePositionToReturn;
  }

  @override
  Future<void> deleteVideoProgress(String userId, String lessonId) async {}
}

void main() {
  group('GetResumePositionUsecase Tests', () {
    late GetResumePositionUsecase usecase;
    late MockVideoTrackingRepository mockRepository;

    setUp(() {
      mockRepository = MockVideoTrackingRepository();
      usecase = GetResumePositionUsecase(mockRepository);
    });

    test(
      'GetResumePositionUsecase calls repository with correct userId',
      () async {
        await usecase(userId: 'user_1', lessonId: 'lesson_1');

        expect(mockRepository.lastRequestedUserId, 'user_1');
      },
    );

    test(
      'GetResumePositionUsecase calls repository with correct lessonId',
      () async {
        await usecase(userId: 'user_1', lessonId: 'lesson_1');

        expect(mockRepository.lastRequestedLessonId, 'lesson_1');
      },
    );

    test('GetResumePositionUsecase returns position from repository', () async {
      mockRepository.resumePositionToReturn = 30000;

      final result = await usecase(userId: 'user_1', lessonId: 'lesson_1');

      expect(result, 30000);
    });

    test('GetResumePositionUsecase returns 0 when no progress', () async {
      mockRepository.resumePositionToReturn = 0;

      final result = await usecase(userId: 'user_1', lessonId: 'lesson_1');

      expect(result, 0);
    });

    test(
      'GetResumePositionUsecase throws exception when repository throws',
      () async {
        mockRepository.errorToThrow = Exception(
          'Failed to get resume position',
        );

        expect(
          () => usecase(userId: 'user_1', lessonId: 'lesson_1'),
          throwsException,
        );
      },
    );

    test('GetResumePositionUsecase handles different user IDs', () async {
      await usecase(userId: 'user_123', lessonId: 'lesson_1');
      await usecase(userId: 'user_456', lessonId: 'lesson_1');

      expect(mockRepository.lastRequestedUserId, 'user_456');
    });

    test('GetResumePositionUsecase handles different lesson IDs', () async {
      await usecase(userId: 'user_1', lessonId: 'lesson_abc');
      await usecase(userId: 'user_1', lessonId: 'lesson_xyz');

      expect(mockRepository.lastRequestedLessonId, 'lesson_xyz');
    });

    test('GetResumePositionUsecase returns large position values', () async {
      mockRepository.resumePositionToReturn = 3600000; // 1 hour in ms

      final result = await usecase(userId: 'user_1', lessonId: 'lesson_1');

      expect(result, 3600000);
    });
  });
}

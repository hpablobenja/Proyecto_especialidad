import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/repositories/video_tracking_repository.dart';
import 'package:redmaestra1/domain/usecases/video/validate_checkpoint_usecase.dart';
import 'package:redmaestra1/core/services/checkpoint_service.dart';
import 'package:redmaestra1/domain/entities/checkpoint_entity.dart';

class MockCheckpointRepository implements CheckpointRepository {
  String? lastPassedCheckpointId;
  String? lastPassedUserId;
  String? lastIncrementedCheckpointId;
  String? lastIncrementedUserId;
  Exception? errorToThrow;

  @override
  Future<void> saveCheckpoint(dynamic checkpoint, String userId) async {}

  @override
  Future<CheckpointEntity?> getCheckpoint(
    String checkpointId,
    String userId,
  ) async => null;

  @override
  Future<List<CheckpointEntity>> getLessonCheckpoints(
    String lessonId,
    String userId,
  ) async => [];

  @override
  Future<void> markCheckpointPassed(String checkpointId, String userId) async {
    lastPassedCheckpointId = checkpointId;
    lastPassedUserId = userId;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

  @override
  Future<void> incrementCheckpointAttempts(
    String checkpointId,
    String userId,
  ) async {
    lastIncrementedCheckpointId = checkpointId;
    lastIncrementedUserId = userId;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

  @override
  Future<List<CheckpointEntity>> getPassedCheckpoints(
    String lessonId,
    String userId,
  ) async => [];

  @override
  Future<List<CheckpointEntity>> getFailedCheckpoints(
    String lessonId,
    String userId,
  ) async => [];

  @override
  Future<void> clearUserCheckpoints(String userId) async {}
}

class MockCheckpointService implements CheckpointService {
  CheckpointValidationResult resultToReturn = CheckpointValidationResult(
    isCorrect: false,
    message: 'Test result',
    attempts: 0,
  );
  String? lastValidatedCheckpointId;
  int? lastSelectedOptionIndex;

  @override
  CheckpointValidationResult validateAnswer({
    required String checkpointId,
    required int selectedOptionIndex,
  }) {
    lastValidatedCheckpointId = checkpointId;
    lastSelectedOptionIndex = selectedOptionIndex;
    return resultToReturn;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ValidateCheckpointUsecase Tests', () {
    late ValidateCheckpointUsecase usecase;
    late MockCheckpointRepository mockRepository;
    late MockCheckpointService mockService;

    setUp(() {
      mockRepository = MockCheckpointRepository();
      mockService = MockCheckpointService();
      usecase = ValidateCheckpointUsecase(
        checkpointRepository: mockRepository,
        checkpointService: mockService,
      );
    });

    test(
      'ValidateCheckpointUsecase calls service with correct checkpointId',
      () async {
        mockService.resultToReturn = CheckpointValidationResult(
          isCorrect: true,
          message: 'Correct',
          attempts: 1,
        );

        await usecase(
          checkpointId: 'cp_1',
          selectedOptionIndex: 0,
          userId: 'user_1',
        );

        expect(mockService.lastValidatedCheckpointId, 'cp_1');
      },
    );

    test(
      'ValidateCheckpointUsecase calls service with correct selectedOptionIndex',
      () async {
        mockService.resultToReturn = CheckpointValidationResult(
          isCorrect: true,
          message: 'Correct',
          attempts: 1,
        );

        await usecase(
          checkpointId: 'cp_1',
          selectedOptionIndex: 2,
          userId: 'user_1',
        );

        expect(mockService.lastSelectedOptionIndex, 2);
      },
    );

    test(
      'ValidateCheckpointUsecase marks checkpoint as passed when correct',
      () async {
        mockService.resultToReturn = CheckpointValidationResult(
          isCorrect: true,
          message: 'Correct',
          attempts: 1,
        );

        await usecase(
          checkpointId: 'cp_1',
          selectedOptionIndex: 0,
          userId: 'user_1',
        );

        expect(mockRepository.lastPassedCheckpointId, 'cp_1');
        expect(mockRepository.lastPassedUserId, 'user_1');
      },
    );

    test(
      'ValidateCheckpointUsecase increments attempts when incorrect',
      () async {
        mockService.resultToReturn = CheckpointValidationResult(
          isCorrect: false,
          message: 'Incorrect',
          attempts: 1,
        );

        await usecase(
          checkpointId: 'cp_1',
          selectedOptionIndex: 1,
          userId: 'user_1',
        );

        expect(mockRepository.lastIncrementedCheckpointId, 'cp_1');
        expect(mockRepository.lastIncrementedUserId, 'user_1');
      },
    );

    test('ValidateCheckpointUsecase returns result from service', () async {
      mockService.resultToReturn = CheckpointValidationResult(
        isCorrect: true,
        message: 'Great job!',
        attempts: 1,
      );

      final result = await usecase(
        checkpointId: 'cp_1',
        selectedOptionIndex: 0,
        userId: 'user_1',
      );

      expect(result.isCorrect, true);
      expect(result.message, 'Great job!');
    });

    test('ValidateCheckpointUsecase handles checkpoint not found', () async {
      mockService.resultToReturn = CheckpointValidationResult(
        isCorrect: false,
        message: 'Checkpoint no encontrado',
        attempts: 0,
      );

      final result = await usecase(
        checkpointId: 'cp_1',
        selectedOptionIndex: 0,
        userId: 'user_1',
      );

      expect(result.isCorrect, false);
      expect(result.message, 'Checkpoint no encontrado');
      expect(mockRepository.lastPassedCheckpointId, null);
      expect(mockRepository.lastIncrementedCheckpointId, null);
    });

    test(
      'ValidateCheckpointUsecase throws exception when repository throws',
      () async {
        mockService.resultToReturn = CheckpointValidationResult(
          isCorrect: true,
          message: 'Correct',
          attempts: 1,
        );
        mockRepository.errorToThrow = Exception('Failed to update checkpoint');

        expect(
          () => usecase(
            checkpointId: 'cp_1',
            selectedOptionIndex: 0,
            userId: 'user_1',
          ),
          throwsException,
        );
      },
    );

    test(
      'ValidateCheckpointUsecase handles different checkpoint IDs',
      () async {
        mockService.resultToReturn = CheckpointValidationResult(
          isCorrect: true,
          message: 'Correct',
          attempts: 1,
        );

        await usecase(
          checkpointId: 'cp_xyz',
          selectedOptionIndex: 0,
          userId: 'user_1',
        );

        expect(mockService.lastValidatedCheckpointId, 'cp_xyz');
      },
    );

    test('ValidateCheckpointUsecase handles different user IDs', () async {
      mockService.resultToReturn = CheckpointValidationResult(
        isCorrect: true,
        message: 'Correct',
        attempts: 1,
      );

      await usecase(
        checkpointId: 'cp_1',
        selectedOptionIndex: 0,
        userId: 'user_123',
      );

      expect(mockRepository.lastPassedUserId, 'user_123');
    });

    test(
      'ValidateCheckpointUsecase handles different option indices',
      () async {
        mockService.resultToReturn = CheckpointValidationResult(
          isCorrect: false,
          message: 'Incorrect',
          attempts: 1,
        );

        await usecase(
          checkpointId: 'cp_1',
          selectedOptionIndex: 3,
          userId: 'user_1',
        );

        expect(mockService.lastSelectedOptionIndex, 3);
      },
    );
  });
}

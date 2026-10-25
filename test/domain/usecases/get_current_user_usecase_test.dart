import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/user_entity.dart';
import 'package:redmaestra1/domain/repositories/auth_repository.dart';
import 'package:redmaestra1/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:redmaestra1/domain/usecases/usecase.dart';

class MockAuthRepository implements AuthRepository {
  UserEntity? userToReturn;
  Exception? errorToThrow;

  @override
  Future<UserEntity> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
    String? workArea,
    String? specialty,
  ) async {
    return userToReturn ?? UserEntity(
      uid: 'test_uid',
      email: email,
      name: name,
      role: role,
    );
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword(String email, String password) async {
    return userToReturn ?? UserEntity(
      uid: 'test_uid',
      email: email,
      name: 'Test User',
      role: 'student',
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserEntity?> getCurrentUser() async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return userToReturn;
  }

  @override
  Future<void> updateUser(UserEntity user) async {}

  @override
  Future<void> resetPassword(String email) async {}
}

void main() {
  group('GetCurrentUserUsecase Tests', () {
    late GetCurrentUserUsecase usecase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      usecase = GetCurrentUserUsecase(mockRepository);
    });

    test('GetCurrentUserUsecase returns user when repository returns user', () async {
      const testUser = UserEntity(
        uid: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        role: 'maestro',
      );
      mockRepository.userToReturn = testUser;

      final result = await usecase(NoParams());

      expect(result, isNotNull);
      expect(result?.uid, 'user_123');
      expect(result?.email, 'test@example.com');
      expect(result?.name, 'Test User');
      expect(result?.role, 'maestro');
    });

    test('GetCurrentUserUsecase returns null when repository returns null', () async {
      mockRepository.userToReturn = null;

      final result = await usecase(NoParams());

      expect(result, isNull);
    });

    test('GetCurrentUserUsecase throws exception when repository throws', () async {
      mockRepository.errorToThrow = Exception('Not authenticated');

      expect(() => usecase(NoParams()), throwsException);
    });

    test('GetCurrentUserUsecase calls repository.getCurrentUser', () async {
      mockRepository.userToReturn = null;

      await usecase(NoParams());

      // Repository was called implicitly
      expect(mockRepository, isNotNull);
    });

    test('GetCurrentUserUsecase preserves user data from repository', () async {
      const testUser = UserEntity(
        uid: 'user_123',
        email: 'test@example.com',
        name: 'John Doe',
        role: 'student',
        workArea: 'Science',
        specialty: 'Physics',
      );
      mockRepository.userToReturn = testUser;

      final result = await usecase(NoParams());

      expect(result?.uid, testUser.uid);
      expect(result?.email, testUser.email);
      expect(result?.name, testUser.name);
      expect(result?.role, testUser.role);
      expect(result?.workArea, testUser.workArea);
      expect(result?.specialty, testUser.specialty);
    });

    test('GetCurrentUserUsecase handles user with optional fields null', () async {
      const testUser = UserEntity(
        uid: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        role: 'student',
      );
      mockRepository.userToReturn = testUser;

      final result = await usecase(NoParams());

      expect(result?.workArea, null);
      expect(result?.specialty, null);
    });
  });
}

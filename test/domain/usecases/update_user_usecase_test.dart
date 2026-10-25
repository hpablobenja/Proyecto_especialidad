import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/user_entity.dart';
import 'package:redmaestra1/domain/repositories/auth_repository.dart';
import 'package:redmaestra1/domain/usecases/auth/update_user_usecase.dart';

class MockAuthRepository implements AuthRepository {
  Exception? errorToThrow;
  UserEntity? lastUpdatedUser;

  @override
  Future<UserEntity> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
    String? workArea,
    String? specialty,
  ) async {
    return UserEntity(
      uid: 'test_uid',
      email: email,
      name: name,
      role: role,
    );
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword(String email, String password) async {
    return UserEntity(
      uid: 'test_uid',
      email: email,
      name: 'Test User',
      role: 'student',
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserEntity?> getCurrentUser() async => null;

  @override
  Future<void> updateUser(UserEntity user) async {
    lastUpdatedUser = user;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

  @override
  Future<void> resetPassword(String email) async {}
}

void main() {
  group('UpdateUserUsecase Tests', () {
    late UpdateUserUsecase usecase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      usecase = UpdateUserUsecase(mockRepository);
    });

    test('UpdateUserUsecase calls repository with correct user', () async {
      const user = UserEntity(
        uid: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        role: 'student',
      );

      await usecase(user);

      expect(mockRepository.lastUpdatedUser?.uid, 'user_123');
    });

    test('UpdateUserUsecase throws ArgumentError for empty uid', () async {
      const user = UserEntity(
        uid: '',
        email: 'test@example.com',
        name: 'Test User',
        role: 'student',
      );

      expect(() => usecase(user), throwsArgumentError);
    });

    test('UpdateUserUsecase throws ArgumentError for empty email', () async {
      const user = UserEntity(
        uid: 'user_123',
        email: '',
        name: 'Test User',
        role: 'student',
      );

      expect(() => usecase(user), throwsArgumentError);
    });

    test('UpdateUserUsecase throws ArgumentError for empty name', () async {
      const user = UserEntity(
        uid: 'user_123',
        email: 'test@example.com',
        name: '',
        role: 'student',
      );

      expect(() => usecase(user), throwsArgumentError);
    });

    test('UpdateUserUsecase throws exception when repository throws', () async {
      mockRepository.errorToThrow = Exception('Update failed');
      const user = UserEntity(
        uid: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        role: 'student',
      );

      expect(() => usecase(user), throwsException);
    });

    test('UpdateUserUsecase wraps repository error', () async {
      mockRepository.errorToThrow = Exception('Network error');
      const user = UserEntity(
        uid: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        role: 'student',
      );

      try {
        await usecase(user);
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e.toString(), contains('Failed to update user'));
        expect(e.toString(), contains('Network error'));
      }
    });

    test('UpdateUserUsecase completes successfully for valid user', () async {
      const user = UserEntity(
        uid: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        role: 'student',
      );

      await usecase(user);

      expect(mockRepository.lastUpdatedUser?.uid, 'user_123');
    });

    test('UpdateUserUsecase preserves all user fields', () async {
      const user = UserEntity(
        uid: 'user_123',
        email: 'test@example.com',
        name: 'John Doe',
        role: 'maestro',
        workArea: 'Science',
        specialty: 'Physics',
      );

      await usecase(user);

      expect(mockRepository.lastUpdatedUser?.uid, 'user_123');
      expect(mockRepository.lastUpdatedUser?.email, 'test@example.com');
      expect(mockRepository.lastUpdatedUser?.name, 'John Doe');
      expect(mockRepository.lastUpdatedUser?.role, 'maestro');
      expect(mockRepository.lastUpdatedUser?.workArea, 'Science');
      expect(mockRepository.lastUpdatedUser?.specialty, 'Physics');
    });

    test('UpdateUserUsecase handles user with null optional fields', () async {
      const user = UserEntity(
        uid: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        role: 'student',
      );

      await usecase(user);

      expect(mockRepository.lastUpdatedUser?.workArea, null);
      expect(mockRepository.lastUpdatedUser?.specialty, null);
    });

    test('UpdateUserUsecase handles whitespace in uid', () async {
      const user = UserEntity(
        uid: '   ',
        email: 'test@example.com',
        name: 'Test User',
        role: 'student',
      );

      // Should not throw for whitespace-only uid (only empty string throws)
      await usecase(user);
      expect(mockRepository.lastUpdatedUser?.uid, '   ');
    });
  });
}

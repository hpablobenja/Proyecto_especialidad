import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/user_entity.dart';
import 'package:redmaestra1/domain/repositories/auth_repository.dart';
import 'package:redmaestra1/domain/usecases/auth/login_usecase.dart';

class MockAuthRepository implements AuthRepository {
  UserEntity? userToReturn;
  Exception? errorToThrow;
  String? lastSignInEmail;
  String? lastSignInPassword;

  @override
  Future<UserEntity> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
    String? workArea,
    String? specialty,
  ) async {
    return userToReturn ??
        UserEntity(uid: 'test_uid', email: email, name: name, role: role);
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    lastSignInEmail = email;
    lastSignInPassword = password;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return userToReturn ??
        UserEntity(
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
  Future<void> updateUser(UserEntity user) async {}

  @override
  Future<void> resetPassword(String email) async {}
}

void main() {
  group('LoginUsecase Tests', () {
    late LoginUsecase usecase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      usecase = LoginUsecase(mockRepository);
    });

    test('LoginUsecase calls repository with correct email', () async {
      final params = LoginParams(
        email: 'test@example.com',
        password: 'password123',
      );

      await usecase(params);

      expect(mockRepository.lastSignInEmail, params.email);
    });

    test('LoginUsecase calls repository with correct password', () async {
      final params = LoginParams(
        email: 'test@example.com',
        password: 'password123',
      );

      await usecase(params);

      expect(mockRepository.lastSignInPassword, params.password);
    });

    test('LoginUsecase returns user from repository', () async {
      const testUser = UserEntity(
        uid: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        role: 'maestro',
      );
      mockRepository.userToReturn = testUser;
      final params = LoginParams(
        email: 'test@example.com',
        password: 'password123',
      );

      final result = await usecase(params);

      expect(result.uid, 'user_123');
      expect(result.email, 'test@example.com');
      expect(result.name, 'Test User');
      expect(result.role, 'maestro');
    });

    test('LoginUsecase throws exception when repository throws', () async {
      mockRepository.errorToThrow = Exception('Authentication failed');
      final params = LoginParams(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(() => usecase(params), throwsException);
    });

    test('LoginUsecase handles special characters in email', () async {
      final params = LoginParams(
        email: 'test+ñ@example.com',
        password: 'password123',
      );

      final result = await usecase(params);

      expect(result.email, 'test+ñ@example.com');
    });

    test('LoginUsecase handles empty password', () async {
      final params = LoginParams(email: 'test@example.com', password: '');

      final result = await usecase(params);

      expect(result, isNotNull);
    });

    test('LoginUsecase handles long email', () async {
      final longEmail = 'a' * 100 + '@example.com';
      final params = LoginParams(email: longEmail, password: 'password123');

      final result = await usecase(params);

      expect(result.email, longEmail);
    });

    test('LoginParams creates correctly', () {
      final params = LoginParams(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(params.email, 'test@example.com');
      expect(params.password, 'password123');
    });

    test('LoginUsecase preserves user data from repository', () async {
      const testUser = UserEntity(
        uid: 'user_123',
        email: 'test@example.com',
        name: 'John Doe',
        role: 'student',
        workArea: 'Science',
        specialty: 'Physics',
      );
      mockRepository.userToReturn = testUser;
      final params = LoginParams(
        email: 'test@example.com',
        password: 'password123',
      );

      final result = await usecase(params);

      expect(result.uid, testUser.uid);
      expect(result.email, testUser.email);
      expect(result.name, testUser.name);
      expect(result.role, testUser.role);
      expect(result.workArea, testUser.workArea);
      expect(result.specialty, testUser.specialty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/user_entity.dart';
import 'package:redmaestra1/domain/repositories/auth_repository.dart';
import 'package:redmaestra1/domain/usecases/auth/reset_password_usecase.dart';

class MockAuthRepository implements AuthRepository {
  Exception? errorToThrow;
  String? lastResetEmail;

  @override
  Future<UserEntity> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
    String? workArea,
    String? specialty,
  ) async {
    return UserEntity(uid: 'test_uid', email: email, name: name, role: role);
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
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
  Future<void> updateUser(UserEntity user) async {}

  @override
  Future<void> resetPassword(String email) async {
    lastResetEmail = email;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }
}

void main() {
  group('ResetPasswordUsecase Tests', () {
    late ResetPasswordUsecase usecase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      usecase = ResetPasswordUsecase(mockRepository);
    });

    test('ResetPasswordUsecase calls repository with correct email', () async {
      await usecase('test@example.com');

      expect(mockRepository.lastResetEmail, 'test@example.com');
    });

    test('ResetPasswordUsecase throws ArgumentError for empty email', () async {
      expect(() => usecase(''), throwsArgumentError);
    });

    test('ResetPasswordUsecase handles whitespace email', () async {
      await usecase('   ');

      expect(mockRepository.lastResetEmail, '   ');
    });

    test(
      'ResetPasswordUsecase throws exception when repository throws',
      () async {
        mockRepository.errorToThrow = Exception('User not found');

        expect(() => usecase('test@example.com'), throwsException);
      },
    );

    test('ResetPasswordUsecase wraps repository error', () async {
      mockRepository.errorToThrow = Exception('Network error');

      try {
        await usecase('test@example.com');
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e.toString(), contains('Failed to reset password'));
        expect(e.toString(), contains('Network error'));
      }
    });

    test(
      'ResetPasswordUsecase completes successfully for valid email',
      () async {
        await usecase('test@example.com');

        // Should complete without throwing
        expect(mockRepository.lastResetEmail, 'test@example.com');
      },
    );

    test('ResetPasswordUsecase handles special characters in email', () async {
      await usecase('test+ñ@example.com');

      expect(mockRepository.lastResetEmail, 'test+ñ@example.com');
    });

    test('ResetPasswordUsecase handles long email', () async {
      final longEmail = 'a' * 100 + '@example.com';
      await usecase(longEmail);

      expect(mockRepository.lastResetEmail, longEmail);
    });
  });
}

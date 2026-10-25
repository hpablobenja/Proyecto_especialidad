import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/user_entity.dart';
import 'package:redmaestra1/domain/repositories/auth_repository.dart';
import 'package:redmaestra1/domain/usecases/auth/register_usecase.dart';

class MockAuthRepository implements AuthRepository {
  UserEntity? userToReturn;
  Exception? errorToThrow;
  String? lastRegisterEmail;
  String? lastRegisterPassword;
  String? lastRegisterName;
  String? lastRegisterRole;
  String? lastRegisterWorkArea;
  String? lastRegisterSpecialty;

  @override
  Future<UserEntity> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
    String? workArea,
    String? specialty,
  ) async {
    lastRegisterEmail = email;
    lastRegisterPassword = password;
    lastRegisterName = name;
    lastRegisterRole = role;
    lastRegisterWorkArea = workArea;
    lastRegisterSpecialty = specialty;
    
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return userToReturn ?? UserEntity(
      uid: 'test_uid',
      email: email,
      name: name,
      role: role,
      workArea: workArea,
      specialty: specialty,
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
  Future<UserEntity?> getCurrentUser() async => null;

  @override
  Future<void> updateUser(UserEntity user) async {}

  @override
  Future<void> resetPassword(String email) async {}
}

void main() {
  group('RegisterUsecase Tests', () {
    late RegisterUsecase usecase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      usecase = RegisterUsecase(mockRepository);
    });

    test('RegisterUsecase calls repository with correct email', () async {
      final params = RegisterParams(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        role: 'student',
      );

      await usecase(params);

      expect(mockRepository.lastRegisterEmail, 'test@example.com');
    });

    test('RegisterUsecase calls repository with correct password', () async {
      final params = RegisterParams(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        role: 'student',
      );

      await usecase(params);

      expect(mockRepository.lastRegisterPassword, 'password123');
    });

    test('RegisterUsecase calls repository with correct name', () async {
      final params = RegisterParams(
        email: 'test@example.com',
        password: 'password123',
        name: 'John Doe',
        role: 'student',
      );

      await usecase(params);

      expect(mockRepository.lastRegisterName, 'John Doe');
    });

    test('RegisterUsecase calls repository with correct role', () async {
      final params = RegisterParams(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        role: 'maestro',
      );

      await usecase(params);

      expect(mockRepository.lastRegisterRole, 'maestro');
    });

    test('RegisterUsecase calls repository with workArea', () async {
      final params = RegisterParams(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        role: 'maestro',
        workArea: 'Science',
      );

      await usecase(params);

      expect(mockRepository.lastRegisterWorkArea, 'Science');
    });

    test('RegisterUsecase calls repository with specialty', () async {
      final params = RegisterParams(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        role: 'maestro',
        specialty: 'Physics',
      );

      await usecase(params);

      expect(mockRepository.lastRegisterSpecialty, 'Physics');
    });

    test('RegisterUsecase returns user from repository', () async {
      const testUser = UserEntity(
        uid: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        role: 'maestro',
      );
      mockRepository.userToReturn = testUser;
      final params = RegisterParams(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        role: 'maestro',
      );

      final result = await usecase(params);

      expect(result.uid, 'user_123');
      expect(result.email, 'test@example.com');
      expect(result.name, 'Test User');
      expect(result.role, 'maestro');
    });

    test('RegisterUsecase throws exception when repository throws', () async {
      mockRepository.errorToThrow = Exception('Email already in use');
      final params = RegisterParams(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        role: 'student',
      );

      expect(() => usecase(params), throwsException);
    });

    test('RegisterUsecase preserves optional fields', () async {
      const testUser = UserEntity(
        uid: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        role: 'maestro',
        workArea: 'Science',
        specialty: 'Physics',
      );
      mockRepository.userToReturn = testUser;
      final params = RegisterParams(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        role: 'maestro',
        workArea: 'Science',
        specialty: 'Physics',
      );

      final result = await usecase(params);

      expect(result.workArea, 'Science');
      expect(result.specialty, 'Physics');
    });

    test('RegisterUsecase handles null optional fields', () async {
      final params = RegisterParams(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        role: 'student',
      );

      await usecase(params);

      expect(mockRepository.lastRegisterWorkArea, null);
      expect(mockRepository.lastRegisterSpecialty, null);
    });

    test('RegisterParams creates correctly', () {
      final params = RegisterParams(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        role: 'student',
        workArea: 'Science',
        specialty: 'Physics',
      );

      expect(params.email, 'test@example.com');
      expect(params.password, 'password123');
      expect(params.name, 'Test User');
      expect(params.role, 'student');
      expect(params.workArea, 'Science');
      expect(params.specialty, 'Physics');
    });

    test('RegisterParams with null optional fields', () {
      final params = RegisterParams(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        role: 'student',
      );

      expect(params.workArea, null);
      expect(params.specialty, null);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:redmaestra1/domain/usecases/auth/login_usecase.dart';
import 'package:redmaestra1/domain/usecases/auth/register_usecase.dart';
import 'package:redmaestra1/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:redmaestra1/domain/repositories/auth_repository.dart';
import 'package:redmaestra1/domain/entities/user_entity.dart';
import 'package:redmaestra1/domain/usecases/usecase.dart';

@GenerateMocks([AuthRepository])
import 'usecases_test.mocks.dart';

void main() {
  group('LoginUsecase Tests', () {
    late MockAuthRepository mockAuthRepository;
    late LoginUsecase loginUsecase;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      loginUsecase = LoginUsecase(mockAuthRepository);
    });

    test('Login exitoso devuelve UserEntity', () async {
      final mockUser = UserEntity(
        uid: 'test_uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'maestro',
      );

      when(
        mockAuthRepository.signInWithEmailAndPassword(any, any),
      ).thenAnswer((_) async => mockUser);

      final result = await loginUsecase.call(
        LoginParams(email: 'test@example.com', password: 'password123'),
      );

      expect(result, mockUser);
      expect(result.email, 'test@example.com');
      expect(result.uid, 'test_uid');
      expect(result.role, 'maestro');
      verify(
        mockAuthRepository.signInWithEmailAndPassword(
          'test@example.com',
          'password123',
        ),
      ).called(1);
    });

    test('Login fallido lanza excepción', () async {
      when(
        mockAuthRepository.signInWithEmailAndPassword(any, any),
      ).thenThrow(Exception('Credenciales inválidas'));

      expect(
        () => loginUsecase.call(
          LoginParams(email: 'wrong@example.com', password: 'wrongpass'),
        ),
        throwsException,
      );
    });
  });

  group('RegisterUsecase Tests', () {
    late MockAuthRepository mockAuthRepository;
    late RegisterUsecase registerUsecase;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      registerUsecase = RegisterUsecase(mockAuthRepository);
    });

    test('Registro exitoso devuelve UserEntity', () async {
      final mockUser = UserEntity(
        uid: 'new_uid',
        email: 'new@example.com',
        name: 'New User',
        role: 'maestro',
      );

      when(
        mockAuthRepository.registerWithEmailAndPassword(any, any, any, any),
      ).thenAnswer((_) async => mockUser);

      final result = await registerUsecase.call(
        RegisterParams(
          email: 'new@example.com',
          password: 'password123',
          name: 'New User',
          role: 'maestro',
        ),
      );

      expect(result, mockUser);
      expect(result.email, 'new@example.com');
      expect(result.uid, 'new_uid');
      verify(
        mockAuthRepository.registerWithEmailAndPassword(
          'new@example.com',
          'password123',
          'New User',
          'maestro',
        ),
      ).called(1);
    });

    test('Registro fallido lanza excepción', () async {
      when(
        mockAuthRepository.registerWithEmailAndPassword(any, any, any, any),
      ).thenThrow(Exception('Email ya registrado'));

      expect(
        () => registerUsecase.call(
          RegisterParams(
            email: 'existing@example.com',
            password: 'password123',
            name: 'Existing User',
            role: 'maestro',
          ),
        ),
        throwsException,
      );
    });
  });

  group('GetCurrentUserUsecase Tests', () {
    late MockAuthRepository mockAuthRepository;
    late GetCurrentUserUsecase getCurrentUserUsecase;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      getCurrentUserUsecase = GetCurrentUserUsecase(mockAuthRepository);
    });

    test('Devuelve usuario actual cuando existe', () async {
      final mockUser = UserEntity(
        uid: 'current_uid',
        email: 'current@example.com',
        name: 'Current User',
        role: 'maestro',
      );

      when(
        mockAuthRepository.getCurrentUser(),
      ).thenAnswer((_) async => mockUser);

      final result = await getCurrentUserUsecase.call(NoParams());

      expect(result, mockUser);
      expect(result!.email, 'current@example.com');
      verify(mockAuthRepository.getCurrentUser()).called(1);
    });

    test('Devuelve null cuando no hay usuario autenticado', () async {
      when(mockAuthRepository.getCurrentUser()).thenAnswer((_) async => null);

      final result = await getCurrentUserUsecase.call(NoParams());

      expect(result, null);
      verify(mockAuthRepository.getCurrentUser()).called(1);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:redmaestra1/domain/usecases/auth/login_usecase.dart';
import 'package:redmaestra1/domain/usecases/auth/register_usecase.dart';
import 'package:redmaestra1/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:redmaestra1/domain/usecases/auth/reset_password_usecase.dart';
import 'package:redmaestra1/domain/usecases/auth/update_user_usecase.dart';
import 'package:redmaestra1/domain/entities/user_entity.dart';
import 'package:redmaestra1/domain/repositories/auth_repository.dart';
import 'package:redmaestra1/domain/usecases/usecase.dart';

@GenerateMocks([AuthRepository])
import 'auth_usecases_test.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('LoginUsecase Tests', () {
    test('LoginUsecase llama al repositorio con credenciales correctas', () async {
      final loginUsecase = LoginUsecase(mockAuthRepository);
      const email = 'test@example.com';
      const password = 'password123';

      final expectedUser = UserEntity(
        uid: 'user_1',
        email: email,
        name: 'Test User',
        role: 'maestro',
      );

      when(mockAuthRepository.signInWithEmailAndPassword(email, password))
          .thenAnswer((_) async => expectedUser);

      final result = await loginUsecase.call(LoginParams(email: email, password: password));

      expect(result.uid, expectedUser.uid);
      expect(result.email, expectedUser.email);
      verify(mockAuthRepository.signInWithEmailAndPassword(email, password));
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('LoginUsecase lanza excepción cuando falla el login', () async {
      final loginUsecase = LoginUsecase(mockAuthRepository);
      const email = 'test@example.com';
      const password = 'wrong_password';

      when(mockAuthRepository.signInWithEmailAndPassword(email, password))
          .thenThrow(Exception('Credenciales inválidas'));

      expect(
        () => loginUsecase.call(LoginParams(email: email, password: password)),
        throwsException,
      );
    });
  });

  group('RegisterUsecase Tests', () {
    test('RegisterUsecase llama al repositorio con datos correctos', () async {
      final registerUsecase = RegisterUsecase(mockAuthRepository);
      const email = 'new@example.com';
      const password = 'password123';
      const name = 'New User';
      const role = 'maestro';

      final expectedUser = UserEntity(
        uid: 'user_2',
        email: email,
        name: name,
        role: role,
      );

      when(mockAuthRepository.registerWithEmailAndPassword(
        email,
        password,
        name,
        role,
        any,
        any,
      )).thenAnswer((_) async => expectedUser);

      final result = await registerUsecase.call(RegisterParams(
        email: email,
        password: password,
        name: name,
        role: role,
        workArea: null,
        specialty: null,
      ));

      expect(result.uid, expectedUser.uid);
      expect(result.email, expectedUser.email);
      verify(mockAuthRepository.registerWithEmailAndPassword(
        email,
        password,
        name,
        role,
        null,
        null,
      ));
    });

    test('RegisterUsecase maneja campos opcionales', () async {
      final registerUsecase = RegisterUsecase(mockAuthRepository);
      const email = 'new@example.com';
      const password = 'password123';
      const name = 'New User';
      const role = 'maestro';
      const workArea = 'Ciencias';
      const specialty = 'Biología';

      final expectedUser = UserEntity(
        uid: 'user_3',
        email: email,
        name: name,
        role: role,
        workArea: workArea,
        specialty: specialty,
      );

      when(mockAuthRepository.registerWithEmailAndPassword(
        email,
        password,
        name,
        role,
        workArea,
        specialty,
      )).thenAnswer((_) async => expectedUser);

      final result = await registerUsecase.call(RegisterParams(
        email: email,
        password: password,
        name: name,
        role: role,
        workArea: workArea,
        specialty: specialty,
      ));

      expect(result.workArea, workArea);
      expect(result.specialty, specialty);
    });
  });

  group('GetCurrentUserUsecase Tests', () {
    test('GetCurrentUserUsecase retorna usuario actual', () async {
      final getCurrentUserUsecase = GetCurrentUserUsecase(mockAuthRepository);

      final expectedUser = UserEntity(
        uid: 'user_4',
        email: 'current@example.com',
        name: 'Current User',
        role: 'maestro',
      );

      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => expectedUser);

      final result = await getCurrentUserUsecase.call(NoParams());

      expect(result, expectedUser);
      verify(mockAuthRepository.getCurrentUser());
    });

    test('GetCurrentUserUsecase retorna null cuando no hay usuario', () async {
      final getCurrentUserUsecase = GetCurrentUserUsecase(mockAuthRepository);

      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => null);

      final result = await getCurrentUserUsecase.call(NoParams());

      expect(result, null);
      verify(mockAuthRepository.getCurrentUser());
    });
  });

  group('ResetPasswordUsecase Tests', () {
    test('ResetPasswordUsecase llama al repositorio con email', () async {
      final resetPasswordUsecase = ResetPasswordUsecase(mockAuthRepository);
      const email = 'test@example.com';

      when(mockAuthRepository.resetPassword(email))
          .thenAnswer((_) async {});

      await resetPasswordUsecase.call(email);

      verify(mockAuthRepository.resetPassword(email));
    });

    test('ResetPasswordUsecase lanza excepción cuando falla', () async {
      final resetPasswordUsecase = ResetPasswordUsecase(mockAuthRepository);
      const email = 'invalid@example.com';

      when(mockAuthRepository.resetPassword(email))
          .thenThrow(Exception('Usuario no encontrado'));

      expect(
        () => resetPasswordUsecase.call(email),
        throwsException,
      );
    });
  });

  group('UpdateUserUsecase Tests', () {
    test('UpdateUserUsecase actualiza usuario correctamente', () async {
      final updateUserUsecase = UpdateUserUsecase(mockAuthRepository);

      final updatedUser = UserEntity(
        uid: 'user_5',
        email: 'test@example.com',
        name: 'Updated Name',
        role: 'maestro',
        workArea: 'Nueva Área',
        specialty: 'Nueva Especialidad',
      );

      when(mockAuthRepository.updateUser(updatedUser))
          .thenAnswer((_) async {});

      await updateUserUsecase.call(updatedUser);

      verify(mockAuthRepository.updateUser(updatedUser));
    });

    test('UpdateUserUsecase maneja actualización parcial', () async {
      final updateUserUsecase = UpdateUserUsecase(mockAuthRepository);

      final updatedUser = UserEntity(
        uid: 'user_6',
        email: 'test@example.com',
        name: 'Updated Name Only',
        role: 'maestro',
      );

      when(mockAuthRepository.updateUser(updatedUser))
          .thenAnswer((_) async {});

      await updateUserUsecase.call(updatedUser);

      verify(mockAuthRepository.updateUser(updatedUser));
    });
  });
}

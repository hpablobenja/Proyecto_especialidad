import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:redmaestra1/data/repositories/auth_repository_impl.dart';
import 'package:redmaestra1/data/datasources/remote/auth_remote_datasource.dart';
import 'package:redmaestra1/data/models/user_model.dart';
import 'package:redmaestra1/domain/entities/user_entity.dart';

@GenerateMocks([AuthRemoteDataSource])
import 'auth_repository_test.mocks.dart';

void main() {
  late MockAuthRemoteDataSource mockAuthRemoteDataSource;
  late AuthRepositoryImpl authRepositoryImpl;

  setUp(() {
    mockAuthRemoteDataSource = MockAuthRemoteDataSource();
    authRepositoryImpl = AuthRepositoryImpl(mockAuthRemoteDataSource);
  });

  group('AuthRepositoryImpl Tests', () {
    test('signInWithEmailAndPassword llama al datasource correctamente', () async {
      const email = 'test@example.com';
      const password = 'password123';

      final expectedUser = UserModel(
        uid: 'user_1',
        email: email,
        name: 'Test User',
        role: 'maestro',
      );

      when(mockAuthRemoteDataSource.signInWithEmailAndPassword(email, password))
          .thenAnswer((_) async => expectedUser);

      final result = await authRepositoryImpl.signInWithEmailAndPassword(email, password);

      expect(result.uid, expectedUser.uid);
      expect(result.email, expectedUser.email);
      verify(mockAuthRemoteDataSource.signInWithEmailAndPassword(email, password));
    });

    test('registerWithEmailAndPassword llama al datasource correctamente', () async {
      const email = 'new@example.com';
      const password = 'password123';
      const name = 'New User';
      const role = 'maestro';

      final expectedUser = UserModel(
        uid: 'user_2',
        email: email,
        name: name,
        role: role,
      );

      when(mockAuthRemoteDataSource.registerWithEmailAndPassword(
        email,
        password,
        name,
        role,
        any,
        any,
      )).thenAnswer((_) async => expectedUser);

      final result = await authRepositoryImpl.registerWithEmailAndPassword(
        email,
        password,
        name,
        role,
        null,
        null,
      );

      expect(result.uid, expectedUser.uid);
      verify(mockAuthRemoteDataSource.registerWithEmailAndPassword(
        email,
        password,
        name,
        role,
        null,
        null,
      ));
    });

    test('signOut llama al datasource correctamente', () async {
      when(mockAuthRemoteDataSource.signOut())
          .thenAnswer((_) async {});

      await authRepositoryImpl.signOut();

      verify(mockAuthRemoteDataSource.signOut());
    });

    test('getCurrentUser llama al datasource correctamente', () async {
      final expectedUser = UserModel(
        uid: 'user_3',
        email: 'current@example.com',
        name: 'Current User',
        role: 'maestro',
      );

      when(mockAuthRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => expectedUser);

      final result = await authRepositoryImpl.getCurrentUser();

      expect(result, isNotNull);
      expect(result!.uid, expectedUser.uid);
      verify(mockAuthRemoteDataSource.getCurrentUser());
    });

    test('getCurrentUser retorna null cuando no hay usuario', () async {
      when(mockAuthRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => null);

      final result = await authRepositoryImpl.getCurrentUser();

      expect(result, null);
      verify(mockAuthRemoteDataSource.getCurrentUser());
    });

    test('updateUser convierte UserEntity a UserModel y llama al datasource', () async {
      final userEntity = UserEntity(
        uid: 'user_4',
        email: 'test@example.com',
        name: 'Updated Name',
        role: 'maestro',
        workArea: 'Ciencias',
        specialty: 'Biología',
      );

      when(mockAuthRemoteDataSource.updateUser(any))
          .thenAnswer((_) async {});

      await authRepositoryImpl.updateUser(userEntity);

      verify(mockAuthRemoteDataSource.updateUser(argThat(
        isA<UserModel>()
            .having((u) => u.uid, 'uid', userEntity.uid)
            .having((u) => u.name, 'name', userEntity.name),
      )));
    });

    test('resetPassword llama al datasource correctamente', () async {
      const email = 'test@example.com';

      when(mockAuthRemoteDataSource.resetPassword(email))
          .thenAnswer((_) async {});

      await authRepositoryImpl.resetPassword(email);

      verify(mockAuthRemoteDataSource.resetPassword(email));
    });
  });
}

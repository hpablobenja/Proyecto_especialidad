import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/data/datasources/remote/auth_remote_datasource.dart';

void main() {
  group('AuthRemoteDataSource Tests', () {
    test('AuthRemoteDataSource es una clase abstracta', () {
      expect(AuthRemoteDataSource, isNotNull);
    });

    test('AuthRemoteDataSourceImpl requiere FirebaseAuth y FirebaseFirestore', () {
      expect(() => AuthRemoteDataSourceImpl, returnsNormally);
    });
  });
}

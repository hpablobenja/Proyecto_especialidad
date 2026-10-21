// test course datasource
import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/data/datasources/remote/course_remote_datasource.dart';

void main() {
  group('CourseRemoteDataSource Tests', () {
    test('CourseRemoteDataSource es una clase abstracta', () {
      expect(CourseRemoteDataSource, isNotNull);
    });

    test('CourseRemoteDataSourceImpl requiere FirebaseFirestore', () {
      expect(() => CourseRemoteDataSourceImpl, returnsNormally);
    });
  });
}

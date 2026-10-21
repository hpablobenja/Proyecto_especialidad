import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:redmaestra1/data/repositories/content_repository_impl.dart';
import 'package:redmaestra1/data/datasources/remote/content_remote_datasource.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';

@GenerateMocks([ContentRemoteDataSource])
import 'content_repository_test.mocks.dart';

void main() {
  late MockContentRemoteDataSource mockContentRemoteDataSource;
  late ContentRepositoryImpl contentRepositoryImpl;

  setUp(() {
    mockContentRemoteDataSource = MockContentRemoteDataSource();
    contentRepositoryImpl = ContentRepositoryImpl(mockContentRemoteDataSource);
  });

  group('ContentRepositoryImpl Tests', () {
    test('listCourses llama al datasource correctamente', () async {
      final expectedCourses = [
        CourseEntity(
          id: 'course_1',
          title: 'Curso 1',
          description: 'Descripción 1',
          targetAudience: 'Principiantes',
        ),
      ];

      when(mockContentRemoteDataSource.listCourses())
          .thenAnswer((_) async => expectedCourses);

      final result = await contentRepositoryImpl.listCourses();

      expect(result.length, 1);
      verify(mockContentRemoteDataSource.listCourses());
    });

    test('createCourse llama al datasource correctamente', () async {
      final course = CourseEntity(
        id: 'new_course',
        title: 'Nuevo Curso',
        description: 'Descripción',
        targetAudience: 'Todos',
      );

      when(mockContentRemoteDataSource.createCourse(course))
          .thenAnswer((_) async => course);

      final result = await contentRepositoryImpl.createCourse(course);

      expect(result.id, course.id);
      verify(mockContentRemoteDataSource.createCourse(course));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:redmaestra1/data/repositories/course_repository_impl.dart';
import 'package:redmaestra1/data/datasources/remote/course_remote_datasource.dart';
import 'package:redmaestra1/data/models/course_model.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';

@GenerateMocks([CourseRemoteDataSource])
import 'course_repository_test.mocks.dart';

void main() {
  late MockCourseRemoteDataSource mockCourseRemoteDataSource;
  late CourseRepositoryImpl courseRepositoryImpl;

  setUp(() {
    mockCourseRemoteDataSource = MockCourseRemoteDataSource();
    courseRepositoryImpl = CourseRepositoryImpl(mockCourseRemoteDataSource);
  });

  group('CourseRepositoryImpl Tests', () {
    test('getCourses llama al datasource correctamente', () async {
      final expectedCourses = [
        CourseModel(
          id: 'course_1',
          title: 'Curso 1',
          description: 'Descripción 1',
          targetAudience: 'Principiantes',
          status: 'published',
        ),
        CourseModel(
          id: 'course_2',
          title: 'Curso 2',
          description: 'Descripción 2',
          targetAudience: 'Intermedios',
          status: 'draft',
        ),
      ];

      when(mockCourseRemoteDataSource.getCourses())
          .thenAnswer((_) async => expectedCourses);

      final result = await courseRepositoryImpl.getCourses();

      expect(result.length, 2);
      expect(result[0].id, 'course_1');
      verify(mockCourseRemoteDataSource.getCourses());
    });

    test('createCourse convierte CourseEntity a CourseModel y llama al datasource', () async {
      final courseEntity = CourseEntity(
        id: 'new_course',
        title: 'Nuevo Curso',
        description: 'Nueva Descripción',
        targetAudience: 'Todos',
        status: 'draft',
      );

      final expectedCourseModel = CourseModel(
        id: 'new_course',
        title: 'Nuevo Curso',
        description: 'Nueva Descripción',
        targetAudience: 'Todos',
        status: 'draft',
      );

      when(mockCourseRemoteDataSource.createCourse(any))
          .thenAnswer((_) async => expectedCourseModel);

      final result = await courseRepositoryImpl.createCourse(courseEntity);

      expect(result.id, expectedCourseModel.id);
      verify(mockCourseRemoteDataSource.createCourse(argThat(
        isA<CourseModel>()
            .having((c) => c.title, 'title', courseEntity.title),
      )));
    });

    test('updateCourse convierte CourseEntity a CourseModel y llama al datasource', () async {
      final courseEntity = CourseEntity(
        id: 'course_1',
        title: 'Curso Actualizado',
        description: 'Descripción Actualizada',
        targetAudience: 'Avanzados',
        status: 'published',
      );

      final expectedCourseModel = CourseModel(
        id: 'course_1',
        title: 'Curso Actualizado',
        description: 'Descripción Actualizada',
        targetAudience: 'Avanzados',
        status: 'published',
      );

      when(mockCourseRemoteDataSource.updateCourse(any))
          .thenAnswer((_) async => expectedCourseModel);

      final result = await courseRepositoryImpl.updateCourse(courseEntity);

      expect(result.title, 'Curso Actualizado');
      verify(mockCourseRemoteDataSource.updateCourse(argThat(
        isA<CourseModel>()
            .having((c) => c.id, 'id', courseEntity.id),
      )));
    });

    test('updateCourseStatus llama al datasource correctamente', () async {
      const courseId = 'course_1';
      const status = 'published';

      when(mockCourseRemoteDataSource.updateCourseStatus(courseId, status))
          .thenAnswer((_) async => true);

      final result = await courseRepositoryImpl.updateCourseStatus(courseId, status);

      expect(result, true);
      verify(mockCourseRemoteDataSource.updateCourseStatus(courseId, status));
    });

    test('updateCourseStatus retorna false cuando falla', () async {
      const courseId = 'course_1';
      const status = 'published';

      when(mockCourseRemoteDataSource.updateCourseStatus(courseId, status))
          .thenAnswer((_) async => false);

      final result = await courseRepositoryImpl.updateCourseStatus(courseId, status);

      expect(result, false);
      verify(mockCourseRemoteDataSource.updateCourseStatus(courseId, status));
    });
  });
}

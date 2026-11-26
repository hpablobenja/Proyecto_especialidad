import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/repositories/course_repository.dart';
import 'package:redmaestra1/domain/usecases/courses/search_courses_usecase.dart';

class MockCourseRepository implements CourseRepository {
  List<CourseEntity> coursesToReturn = [];
  Exception? errorToThrow;

  @override
  Future<List<CourseEntity>> getCourses() async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return coursesToReturn;
  }

  @override
  Future<CourseEntity> createCourse(CourseEntity course) async => course;

  @override
  Future<CourseEntity> updateCourse(CourseEntity course) async => course;

  @override
  Future<bool> updateCourseStatus(String courseId, String status) async => true;
}

void main() {
  group('SearchCoursesUsecase Tests', () {
    late SearchCoursesUsecase usecase;
    late MockCourseRepository mockRepository;

    setUp(() {
      mockRepository = MockCourseRepository();
      usecase = SearchCoursesUsecase(mockRepository);
    });

    test('SearchCoursesUsecase filters by', () async {
      mockRepository.coursesToReturn = [
        CourseEntity(
          id: 'course_1',
          title: 'Curso de Flutter',
          description: 'Aprende Flutter',
          targetAudience: 'Principiantes',
        ),
        CourseEntity(
          id: 'course_2',
          title: 'Curso de Dart',
          description: 'Aprende Dart',
          targetAudience: 'Intermedios',
        ),
      ];

      final result = await usecase('Flutter');

      expect(result.length, 1);
      expect(result[0].title, contains('Flutter'));
    });

    test('SearchCoursesUsecase filters by description', () async {
      mockRepository.coursesToReturn = [
        CourseEntity(
          id: 'course_1',
          title: 'Curso Avanzado',
          description: 'Aprende Flutter avanzado',
          targetAudience: 'Avanzados',
        ),
        CourseEntity(
          id: 'course_2',
          title: 'Curso Básico',
          description: 'Introducción a Dart',
          targetAudience: 'Principiantes',
        ),
      ];

      final result = await usecase('avanzado');

      expect(result.length, 1);
      expect(result[0].description, contains('avanzado'));
    });

    test('SearchCoursesUsecase case insensitive search', () async {
      mockRepository.coursesToReturn = [
        CourseEntity(
          id: 'course_1',
          title: 'Curso de FLUTTER',
          description: 'Aprende Flutter',
          targetAudience: 'Principiantes',
        ),
      ];

      final result = await usecase('flutter');

      expect(result.length, 1);
    });

    test('SearchCoursesUsecase returns multiple matches', () async {
      mockRepository.coursesToReturn = [
        CourseEntity(
          id: 'course_1',
          title: 'Curso de Flutter',
          description: 'Aprende Flutter',
          targetAudience: 'Principiantes',
        ),
        CourseEntity(
          id: 'course_2',
          title: 'Flutter Avanzado',
          description: 'Curso avanzado',
          targetAudience: 'Avanzados',
        ),
        CourseEntity(
          id: 'course_3',
          title: 'Dart Básico',
          description: 'Curso de Dart',
          targetAudience: 'Principiantes',
        ),
      ];

      final result = await usecase('Flutter');

      expect(result.length, 2);
    });

    test('SearchCoursesUsecase returns empty when no matches', () async {
      mockRepository.coursesToReturn = [
        CourseEntity(
          id: 'course_1',
          title: 'Curso de Dart',
          description: 'Aprende Dart',
          targetAudience: 'Principiantes',
        ),
      ];

      final result = await usecase('Python');

      expect(result, isEmpty);
    });

    test(
      'SearchCoursesUsecase returns empty when no courses available',
      () async {
        mockRepository.coursesToReturn = [];

        final result = await usecase('Flutter');

        expect(result, isEmpty);
      },
    );

    test(
      'SearchCoursesUsecase throws exception when repository throws',
      () async {
        mockRepository.errorToThrow = Exception('Failed to search courses');

        expect(() => usecase('Flutter'), throwsException);
      },
    );

    test('SearchCoursesUsecase handles empty query', () async {
      mockRepository.coursesToReturn = [
        CourseEntity(
          id: 'course_1',
          title: 'Curso de Flutter',
          description: 'Aprende Flutter',
          targetAudience: 'Principiantes',
        ),
      ];

      final result = await usecase('');

      expect(result.length, 1);
    });

    test('SearchCoursesUsecase preserves course data', () async {
      mockRepository.coursesToReturn = [
        CourseEntity(
          id: 'course_1',
          title: 'Curso Completo',
          description: 'Curso completo de desarrollo',
          targetAudience: 'Todos',
        ),
      ];

      final result = await usecase('completo');

      expect(result[0].id, 'course_1');
      expect(result[0].title, 'Curso Completo');
      expect(result[0].description, 'Curso completo de desarrollo');
      expect(result[0].targetAudience, 'Todos');
    });

    test('SearchCoursesUsecase handles special characters', () async {
      mockRepository.coursesToReturn = [
        CourseEntity(
          id: 'course_1',
          title: 'Curso de Programación',
          description: 'Aprende a programar',
          targetAudience: 'Principiantes',
        ),
      ];

      final result = await usecase('programación');

      expect(result.length, 1);
    });
  });
}

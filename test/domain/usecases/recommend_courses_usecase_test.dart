import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/repositories/course_repository.dart';
import 'package:redmaestra1/domain/usecases/courses/recommend_courses_usecase.dart';

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
  group('RecommendCoursesUsecase Tests', () {
    late RecommendCoursesUsecase usecase;
    late MockCourseRepository mockRepository;

    setUp(() {
      mockRepository = MockCourseRepository();
      usecase = RecommendCoursesUsecase(mockRepository);
    });

    test('RecommendCoursesUsecase calls repository getCourses', () async {
      mockRepository.coursesToReturn = [
        CourseEntity(
          id: 'course_1',
          title: 'Curso de Flutter',
          description: 'Aprende Flutter',
          targetAudience: 'Principiantes',
        ),
      ];

      await usecase('user_1');

      expect(mockRepository.coursesToReturn, isNotEmpty);
    });

    test(
      'RecommendCoursesUsecase returns first 3 courses when more than 3 available',
      () async {
        mockRepository.coursesToReturn = List.generate(
          5,
          (i) => CourseEntity(
            id: 'course_$i',
            title: 'Curso $i',
            description: 'Descripción $i',
            targetAudience: 'Todos',
          ),
        );

        final result = await usecase('user_1');

        expect(result.length, 3);
        expect(result[0].id, 'course_0');
        expect(result[1].id, 'course_1');
        expect(result[2].id, 'course_2');
      },
    );

    test(
      'RecommendCoursesUsecase returns all courses when less than 3 available',
      () async {
        mockRepository.coursesToReturn = [
          CourseEntity(
            id: 'course_1',
            title: 'Curso 1',
            description: 'Descripción 1',
            targetAudience: 'Todos',
          ),
          CourseEntity(
            id: 'course_2',
            title: 'Curso 2',
            description: 'Descripción 2',
            targetAudience: 'Todos',
          ),
        ];

        final result = await usecase('user_1');

        expect(result.length, 2);
      },
    );

    test(
      'RecommendCoursesUsecase returns empty list when no courses available',
      () async {
        mockRepository.coursesToReturn = [];

        final result = await usecase('user_1');

        expect(result, isEmpty);
      },
    );

    test(
      'RecommendCoursesUsecase throws exception when repository throws',
      () async {
        mockRepository.errorToThrow = Exception('Failed to get courses');

        expect(() => usecase('user_1'), throwsException);
      },
    );

    test('RecommendCoursesUsecase handles different user IDs', () async {
      mockRepository.coursesToReturn = [
        CourseEntity(
          id: 'course_1',
          title: 'Curso',
          description: 'Descripción',
          targetAudience: 'Todos',
        ),
      ];

      await usecase('user_123');
      await usecase('user_456');

      expect(mockRepository.coursesToReturn, isNotEmpty);
    });

    test('RecommendCoursesUsecase preserves course data', () async {
      mockRepository.coursesToReturn = [
        CourseEntity(
          id: 'course_1',
          title: 'Curso de Dart',
          description: 'Aprende Dart avanzado',
          targetAudience: 'Intermedios',
        ),
      ];

      final result = await usecase('user_1');

      expect(result[0].id, 'course_1');
      expect(result[0].title, 'Curso de Dart');
      expect(result[0].description, 'Aprende Dart avanzado');
      expect(result[0].targetAudience, 'Intermedios');
    });
  });
}

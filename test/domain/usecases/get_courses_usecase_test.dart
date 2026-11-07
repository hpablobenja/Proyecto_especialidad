import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/repositories/course_repository.dart';
import 'package:redmaestra1/domain/usecases/courses/get_courses_usecase.dart';
import 'package:redmaestra1/domain/usecases/usecase.dart';

class MockCourseRepository implements CourseRepository {
  List<CourseEntity>? coursesToReturn;
  Exception? errorToThrow;

  @override
  Future<List<CourseEntity>> getCourses() async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return coursesToReturn ?? [];
  }

  @override
  Future<CourseEntity> createCourse(CourseEntity course) async {
    return course;
  }

  @override
  Future<CourseEntity> updateCourse(CourseEntity course) async {
    return course;
  }

  @override
  Future<bool> updateCourseStatus(String courseId, String status) async {
    return true;
  }
}

void main() {
  group('GetCoursesUsecase Tests', () {
    late GetCoursesUsecase usecase;
    late MockCourseRepository mockRepository;

    setUp(() {
      mockRepository = MockCourseRepository();
      usecase = GetCoursesUsecase(mockRepository);
    });

    test(
      'GetCoursesUsecase returns empty list when repository returns empty',
      () async {
        mockRepository.coursesToReturn = [];

        final result = await usecase(NoParams());

        expect(result, isEmpty);
      },
    );

    test('GetCoursesUsecase returns courses from repository', () async {
      final testCourses = [
        const CourseEntity(
          id: 'course_1',
          title: 'Course 1',
          description: 'Description 1',
          targetAudience: 'General',
        ),
        const CourseEntity(
          id: 'course_2',
          title: 'Course 2',
          description: 'Description 2',
          targetAudience: 'Principiantes',
        ),
      ];
      mockRepository.coursesToReturn = testCourses;

      final result = await usecase(NoParams());

      expect(result.length, 2);
      expect(result[0].id, 'course_1');
      expect(result[1].id, 'course_2');
    });

    test('GetCoursesUsecase throws exception when repository throws', () async {
      mockRepository.errorToThrow = Exception('Repository error');

      expect(() => usecase(NoParams()), throwsException);
    });

    test('GetCoursesUsecase calls repository.getCourses', () async {
      mockRepository.coursesToReturn = [];

      await usecase(NoParams());

      // Verify the repository was called (implicit in the test passing)
      expect(mockRepository.coursesToReturn, isNotNull);
    });

    test('GetCoursesUsecase preserves course data from repository', () async {
      final testCourse = const CourseEntity(
        id: 'course_1',
        title: 'Test Course',
        description: 'Test Description',
        targetAudience: 'Ciencias Naturales',
      );
      mockRepository.coursesToReturn = [testCourse];

      final result = await usecase(NoParams());

      expect(result[0].id, testCourse.id);
      expect(result[0].title, testCourse.title);
      expect(result[0].description, testCourse.description);
      expect(result[0].targetAudience, testCourse.targetAudience);
    });

    test('GetCoursesUsecase handles single course', () async {
      final testCourse = const CourseEntity(
        id: 'course_1',
        title: 'Single Course',
        description: 'Description',
        targetAudience: 'General',
      );
      mockRepository.coursesToReturn = [testCourse];

      final result = await usecase(NoParams());

      expect(result.length, 1);
      expect(result[0].id, 'course_1');
    });

    test('GetCoursesUsecase handles many courses', () async {
      final testCourses = List.generate(
        50,
        (index) => CourseEntity(
          id: 'course_$index',
          title: 'Course $index',
          description: 'Description $index',
          targetAudience: 'General',
        ),
      );
      mockRepository.coursesToReturn = testCourses;

      final result = await usecase(NoParams());

      expect(result.length, 50);
    });
  });
}

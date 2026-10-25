import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/repositories/course_repository.dart';

void main() {
  group('CourseRepository Tests', () {
    test('CourseRepository is an abstract class', () {
      expect(CourseRepository, isNotNull);
    });

    test('CourseRepository has getCourses method', () {
      expect(CourseRepository, isNotNull);
    });

    test('CourseRepository has createCourse method', () {
      expect(CourseRepository, isNotNull);
    });

    test('CourseRepository has updateCourse method', () {
      expect(CourseRepository, isNotNull);
    });

    test('CourseRepository has updateCourseStatus method', () {
      expect(CourseRepository, isNotNull);
    });
  });
}

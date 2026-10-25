import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';

void main() {
  group('CourseEntity Tests', () {
    test('CourseEntity creates correctly with all fields', () {
      const course = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics of Flutter',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        targetAudience: 'General',
        status: 'published',
      );

      expect(course.id, 'course_1');
      expect(course.title, 'Introduction to Flutter');
      expect(course.description, 'Learn the basics of Flutter');
      expect(course.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(course.targetAudience, 'General');
      expect(course.status, 'published');
    });

    test('CourseEntity creates correctly with null thumbnailUrl', () {
      const course = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        targetAudience: 'General',
      );

      expect(course.thumbnailUrl, null);
    });

    test('CourseEntity defaults status to draft', () {
      const course = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        targetAudience: 'General',
      );

      expect(course.status, 'draft');
    });

    test('CourseEntity with equatable works correctly', () {
      const course1 = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        targetAudience: 'General',
        status: 'draft',
      );

      const course2 = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        targetAudience: 'General',
        status: 'draft',
      );

      const course3 = CourseEntity(
        id: 'course_2',
        title: 'Advanced Flutter',
        description: 'Learn advanced concepts',
        targetAudience: 'Principiantes',
        status: 'published',
      );

      expect(course1, course2);
      expect(course1, isNot(course3));
    });

    test('CourseEntity props includes all fields', () {
      const course = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        targetAudience: 'General',
        status: 'published',
      );

      final props = course.props;
      expect(props.length, 6);
      expect(props, contains('course_1'));
      expect(props, contains('Introduction to Flutter'));
      expect(props, contains('Learn the basics'));
      expect(props, contains('https://example.com/thumb.jpg'));
      expect(props, contains('General'));
      expect(props, contains('published'));
    });

    test('CourseEntity with null thumbnailUrl in props', () {
      const course = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        targetAudience: 'General',
      );

      final props = course.props;
      expect(props, contains(null));
    });

    test('CourseEntity handles special characters in title', () {
      const course = CourseEntity(
        id: 'course_1',
        title: 'Introducción a Flutter',
        description: 'Aprende lo básico',
        targetAudience: 'General',
      );

      expect(course.title, contains('Introducción'));
    });

    test('CourseEntity handles empty description', () {
      const course = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: '',
        targetAudience: 'General',
      );

      expect(course.description, '');
    });

    test('CourseEntity with different status are not equal', () {
      const course1 = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        targetAudience: 'General',
        status: 'draft',
      );

      const course2 = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        targetAudience: 'General',
        status: 'published',
      );

      expect(course1, isNot(course2));
    });

    test('CourseEntity with different targetAudience are not equal', () {
      const course1 = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        targetAudience: 'General',
      );

      const course2 = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        targetAudience: 'Ciencias Naturales',
      );

      expect(course1, isNot(course2));
    });

    test('CourseEntity copyWith updates specified fields', () {
      const course = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        targetAudience: 'General',
      );

      final updated = course.copyWith(
        title: 'Advanced Flutter',
        status: 'published',
      );

      expect(updated.id, 'course_1');
      expect(updated.title, 'Advanced Flutter');
      expect(updated.description, 'Learn the basics');
      expect(updated.targetAudience, 'General');
      expect(updated.status, 'published');
    });

    test('CourseEntity copyWith preserves original when no parameters', () {
      const course = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        targetAudience: 'General',
        status: 'published',
      );

      final copied = course.copyWith();

      expect(copied, course);
    });

    test('CourseEntity copyWith updates all fields', () {
      const course = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        targetAudience: 'General',
      );

      final updated = course.copyWith(
        id: 'course_2',
        title: 'Advanced Flutter',
        description: 'Advanced concepts',
        thumbnailUrl: 'https://example.com/new.jpg',
        targetAudience: 'Ciencias Naturales',
        status: 'published',
      );

      expect(updated.id, 'course_2');
      expect(updated.title, 'Advanced Flutter');
      expect(updated.description, 'Advanced concepts');
      expect(updated.thumbnailUrl, 'https://example.com/new.jpg');
      expect(updated.targetAudience, 'Ciencias Naturales');
      expect(updated.status, 'published');
    });

    test('CourseEntity copyWith can set thumbnailUrl to null', () {
      const course = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        targetAudience: 'General',
      );

      final updated = course.copyWith(thumbnailUrl: null);

      expect(updated.thumbnailUrl, null);
    });

    test('CourseEntity handles published status', () {
      const course = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        targetAudience: 'General',
        status: 'published',
      );

      expect(course.status, 'published');
    });

    test('CourseEntity handles draft status', () {
      const course = CourseEntity(
        id: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        targetAudience: 'General',
        status: 'draft',
      );

      expect(course.status, 'draft');
    });
  });
}

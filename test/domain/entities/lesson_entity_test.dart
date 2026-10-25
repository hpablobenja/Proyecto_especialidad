import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';

void main() {
  group('LessonEntity Tests', () {
    test('LessonEntity creates correctly with all fields', () {
      final media = const MediaResource(
        id: 'media_1',
        url: 'https://example.com/video.mp4',
        filename: 'video.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 1024000,
      );
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introduction to Widgets',
        objectives: 'Learn about widgets',
        media: [media],
        orderIndex: 1,
      );

      expect(lesson.id, 'lesson_1');
      expect(lesson.courseId, 'course_1');
      expect(lesson.moduleId, 'module_1');
      expect(lesson.title, 'Introduction to Widgets');
      expect(lesson.objectives, 'Learn about widgets');
      expect(lesson.media.length, 1);
      expect(lesson.orderIndex, 1);
    });

    test('LessonEntity creates correctly with minimal fields', () {
      const lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introduction to Widgets',
        orderIndex: 1,
      );

      expect(lesson.contentDelta, null);
      expect(lesson.objectives, null);
      expect(lesson.media, isEmpty);
      expect(lesson.downloadableResources, isEmpty);
      expect(lesson.strategies, isEmpty);
      expect(lesson.dripUnlockAt, null);
    });

    test('LessonEntity with equatable works correctly', () {
      const lesson1 = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introduction to Widgets',
        orderIndex: 1,
      );

      const lesson2 = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introduction to Widgets',
        orderIndex: 1,
      );

      const lesson3 = LessonEntity(
        id: 'lesson_2',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Advanced Widgets',
        orderIndex: 2,
      );

      expect(lesson1, lesson2);
      expect(lesson1, isNot(lesson3));
    });

    test('LessonEntity props includes all fields', () {
      const lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introduction to Widgets',
        objectives: 'Learn about widgets',
        orderIndex: 1,
      );

      final props = lesson.props;
      expect(props.length, 11);
      expect(props, contains('lesson_1'));
      expect(props, contains('course_1'));
      expect(props, contains('module_1'));
      expect(props, contains('Introduction to Widgets'));
      expect(props, contains('Learn about widgets'));
      expect(props, contains(1));
    });

    test('LessonEntity handles contentDelta', () {
      final contentDelta = [
        {'insert': 'Hello World\n'},
      ];
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introduction',
        contentDelta: contentDelta,
        orderIndex: 1,
      );

      expect(lesson.contentDelta, isNotNull);
      expect(lesson.contentDelta?.length, 1);
    });

    test('LessonEntity handles multiple media resources', () {
      final media1 = const MediaResource(
        id: 'media_1',
        url: 'https://example.com/video.mp4',
        filename: 'video.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 1024000,
      );
      final media2 = const MediaResource(
        id: 'media_2',
        url: 'https://example.com/document.pdf',
        filename: 'document.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 512000,
      );
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introduction',
        media: [media1, media2],
        orderIndex: 1,
      );

      expect(lesson.media.length, 2);
    });

    test('LessonEntity handles downloadable resources', () {
      final resource = const MediaResource(
        id: 'resource_1',
        url: 'https://example.com/file.pdf',
        filename: 'file.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 2048000,
      );
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introduction',
        downloadableResources: [resource],
        orderIndex: 1,
      );

      expect(lesson.downloadableResources.length, 1);
    });

    test('LessonEntity handles strategies', () {
      final strategies = [
        {'name': 'Quiz', 'description': 'Test your knowledge'},
        {'name': 'Discussion', 'description': 'Group discussion'},
      ];
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introduction',
        strategies: strategies,
        orderIndex: 1,
      );

      expect(lesson.strategies.length, 2);
    });

    test('LessonEntity handles dripUnlockAt', () {
      final unlockDate = DateTime(2026, 12, 31);
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introduction',
        dripUnlockAt: unlockDate,
        orderIndex: 1,
      );

      expect(lesson.dripUnlockAt, unlockDate);
    });

    test('LessonEntity handles special characters in title', () {
      const lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introducción a los Widgets',
        objectives: 'Aprende sobre widgets',
        orderIndex: 1,
      );

      expect(lesson.title, contains('Introducción'));
    });

    test('LessonEntity with different orderIndex are not equal', () {
      const lesson1 = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introduction',
        orderIndex: 1,
      );

      const lesson2 = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introduction',
        orderIndex: 2,
      );

      expect(lesson1, isNot(lesson2));
    });

    test('LessonEntity with different moduleId are not equal', () {
      const lesson1 = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introduction',
        orderIndex: 1,
      );

      const lesson2 = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_2',
        title: 'Introduction',
        orderIndex: 1,
      );

      expect(lesson1, isNot(lesson2));
    });

    test('LessonEntity handles zero orderIndex', () {
      const lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introduction',
        orderIndex: 0,
      );

      expect(lesson.orderIndex, 0);
    });

    test('LessonEntity handles large orderIndex', () {
      const lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introduction',
        orderIndex: 100,
      );

      expect(lesson.orderIndex, 100);
    });
  });
}

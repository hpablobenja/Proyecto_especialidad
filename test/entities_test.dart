import 'package:flutter_test/flutter_test.dart';

import 'package:redmaestra1/domain/entities/user_entity.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_progress_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';

void main() {
  group('UserEntity Tests', () {
    test('UserEntity se crea correctamente', () {
      final user = UserEntity(
        uid: 'test_uid',
        email: 'test@example.com',
        role: 'maestro',
        name: 'Test User',
      );

      expect(user.uid, 'test_uid');
      expect(user.email, 'test@example.com');
      expect(user.role, 'maestro');
      expect(user.name, 'Test User');
    });

    test('UserEntity con equatable funciona', () {
      final user1 = UserEntity(
        uid: 'test_uid',
        email: 'test@example.com',
        role: 'maestro',
        name: 'Test User',
      );

      final user2 = UserEntity(
        uid: 'test_uid',
        email: 'test@example.com',
        role: 'maestro',
        name: 'Test User',
      );

      final user3 = UserEntity(
        uid: 'different_uid',
        email: 'test@example.com',
        role: 'maestro',
        name: 'Test User',
      );

      expect(user1, user2);
      expect(user1, isNot(user3));
      expect(user1.hashCode, user2.hashCode);
    });

    test('UserEntity toString funciona', () {
      final user = UserEntity(
        uid: 'test_uid',
        email: 'test@example.com',
        role: 'maestro',
        name: 'Test User',
      );

      final stringRepresentation = user.toString();
      expect(stringRepresentation, contains('UserEntity'));
      expect(stringRepresentation, contains('test_uid'));
      expect(stringRepresentation, contains('test@example.com'));
    });
  });

  group('CourseEntity Tests', () {
    test('CourseEntity se crea correctamente', () {
      final course = CourseEntity(
        id: 'course_1',
        title: 'Curso de Flutter',
        description: 'Aprende Flutter desde cero',
        targetAudience: 'Principiantes',
        thumbnailUrl: 'https://example.com/image.jpg',
      );

      expect(course.id, 'course_1');
      expect(course.title, 'Curso de Flutter');
      expect(course.description, 'Aprende Flutter desde cero');
      expect(course.targetAudience, 'Principiantes');
      expect(course.thumbnailUrl, 'https://example.com/image.jpg');
    });

    test('CourseEntity con valores nulos funciona', () {
      final course = CourseEntity(
        id: 'course_2',
        title: 'Curso de Dart',
        description: 'Aprende Dart avanzado',
        targetAudience: 'Intermedios',
      );

      expect(course.id, 'course_2');
      expect(course.thumbnailUrl, null);
    });

    test('CourseEntity con equatable funciona', () {
      final course1 = CourseEntity(
        id: 'course_1',
        title: 'Curso de Flutter',
        description: 'Aprende Flutter',
        targetAudience: 'Principiantes',
        thumbnailUrl: 'https://example.com/image.jpg',
      );

      final course2 = CourseEntity(
        id: 'course_1',
        title: 'Curso de Flutter',
        description: 'Aprende Flutter',
        targetAudience: 'Principiantes',
        thumbnailUrl: 'https://example.com/image.jpg',
      );

      final course3 = CourseEntity(
        id: 'course_2',
        title: 'Curso de Dart',
        description: 'Aprende Dart',
        targetAudience: 'Intermedios',
      );

      expect(course1, course2);
      expect(course1, isNot(course3));
    });

    test('CourseEntity copyWith funciona', () {
      final originalCourse = CourseEntity(
        id: 'course_1',
        title: 'Curso Original',
        description: 'Descripción original',
        targetAudience: 'Todos',
      );

      final updatedCourse = originalCourse.copyWith(
        title: 'Curso Actualizado',
        description: 'Descripción actualizada',
      );

      expect(updatedCourse.id, originalCourse.id);
      expect(updatedCourse.title, 'Curso Actualizado');
      expect(updatedCourse.description, 'Descripción actualizada');
      expect(updatedCourse.targetAudience, originalCourse.targetAudience);
    });
  });

  group('LessonEntity Tests', () {
    test('LessonEntity se crea correctamente', () {
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Introducción a Flutter',
        orderIndex: 1,
      );

      expect(lesson.id, 'lesson_1');
      expect(lesson.courseId, 'course_1');
      expect(lesson.moduleId, 'module_1');
      expect(lesson.title, 'Introducción a Flutter');
      expect(lesson.orderIndex, 1);
      expect(lesson.media, isEmpty);
      expect(lesson.downloadableResources, isEmpty);
      expect(lesson.strategies, isEmpty);
    });

    test('LessonEntity con valores opcionales funciona', () {
      final now = DateTime.now();
      final lesson = LessonEntity(
        id: 'lesson_2',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Lección avanzada',
        orderIndex: 2,
        objectives: 'Aprender conceptos avanzados',
        dripUnlockAt: now,
        contentDelta: [
          {'insert': 'Contenido de ejemplo\n'},
        ],
      );

      expect(lesson.objectives, 'Aprender conceptos avanzados');
      expect(lesson.dripUnlockAt, now);
      expect(lesson.contentDelta, isNotNull);
    });

    test('LessonEntity con equatable funciona', () {
      final lesson1 = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Lección de prueba',
        orderIndex: 1,
      );

      final lesson2 = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Lección de prueba',
        orderIndex: 1,
      );

      final lesson3 = LessonEntity(
        id: 'lesson_2',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Otra lección',
        orderIndex: 2,
      );

      expect(lesson1, lesson2);
      expect(lesson1, isNot(lesson3));
    });
  });

  group('LessonProgressEntity Tests', () {
    test('LessonProgressEntity se crea correctamente', () {
      final progress = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.notStarted,
      );

      expect(progress.userId, 'user_1');
      expect(progress.courseId, 'course_1');
      expect(progress.moduleId, 'module_1');
      expect(progress.lessonId, 'lesson_1');
      expect(progress.status, LessonProgressStatus.notStarted);
      expect(progress.hasViewedVideo, false);
      expect(progress.hasCompletedQuiz, false);
      expect(progress.quizScore, null);
    });

    test('LessonProgressEntity con progreso funciona', () {
      final now = DateTime.now();
      final progress = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.completed,
        lastUpdated: now,
        hasViewedVideo: true,
        hasCompletedQuiz: true,
        quizScore: 85,
        maxQuizScore: 100,
      );

      expect(progress.status, LessonProgressStatus.completed);
      expect(progress.lastUpdated, now);
      expect(progress.hasViewedVideo, true);
      expect(progress.hasCompletedQuiz, true);
      expect(progress.quizScore, 85);
      expect(progress.maxQuizScore, 100);
    });

    test('LessonProgressEntity con equatable funciona', () {
      final progress1 = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.inProgress,
      );

      final progress2 = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.inProgress,
      );

      final progress3 = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_2',
        status: LessonProgressStatus.notStarted,
      );

      expect(progress1, progress2);
      expect(progress1, isNot(progress3));
    });
  });

  group('MediaResource Tests', () {
    test('MediaResource se crea correctamente', () {
      final media = MediaResource(
        id: 'media_1',
        url: 'https://example.com/video.mp4',
        filename: 'video.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 1024000,
        duration: const Duration(seconds: 300),
      );

      expect(media.id, 'media_1');
      expect(media.url, 'https://example.com/video.mp4');
      expect(media.filename, 'video.mp4');
      expect(media.mimeType, 'video/mp4');
      expect(media.sizeBytes, 1024000);
      expect(media.duration, const Duration(seconds: 300));
    });

    test('MediaResource con valores opcionales funciona', () {
      final media = MediaResource(
        id: 'media_2',
        url: 'https://example.com/document.pdf',
        filename: 'document.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 512000,
      );

      expect(media.duration, null);
      expect(media.metadata, null);
    });

    test('MediaResource con metadata funciona', () {
      final media = MediaResource(
        id: 'media_3',
        url: 'https://example.com/image.jpg',
        filename: 'image.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 256000,
        metadata: {
          'width': 1920,
          'height': 1080,
          'thumbnail': 'https://example.com/thumb.jpg',
        },
      );

      expect(media.metadata, isNotNull);
      expect(media.metadata!['width'], 1920);
      expect(media.metadata!['height'], 1080);
    });
  });
}

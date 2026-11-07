import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/lesson_progress_entity.dart';

void main() {
  group('LessonProgressEntity Tests', () {
    test('LessonProgressEntity creates correctly with all fields', () {
      final now = DateTime.now();
      final progress = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.inProgress,
        lastUpdated: now,
        hasViewedVideo: true,
        hasCompletedQuiz: false,
        quizScore: 80,
        maxQuizScore: 100,
      );

      expect(progress.userId, 'user_1');
      expect(progress.courseId, 'course_1');
      expect(progress.moduleId, 'module_1');
      expect(progress.lessonId, 'lesson_1');
      expect(progress.status, LessonProgressStatus.inProgress);
      expect(progress.lastUpdated, now);
      expect(progress.hasViewedVideo, true);
      expect(progress.hasCompletedQuiz, false);
      expect(progress.quizScore, 80);
      expect(progress.maxQuizScore, 100);
    });

    test('LessonProgressEntity creates with default values', () {
      final progress = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.notStarted,
      );

      expect(progress.hasViewedVideo, false);
      expect(progress.hasCompletedQuiz, false);
      expect(progress.quizScore, null);
      expect(progress.maxQuizScore, null);
      expect(progress.lastUpdated, null);
    });

    test('LessonProgressEntity equatable comparison', () {
      final now = DateTime.now();
      final progress1 = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.inProgress,
        lastUpdated: now,
      );

      final progress2 = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.inProgress,
        lastUpdated: now,
      );

      expect(progress1, equals(progress2));
    });

    test('LessonProgressEntity not equal with different status', () {
      final progress1 = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.notStarted,
      );

      final progress2 = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.completed,
      );

      expect(progress1, isNot(equals(progress2)));
    });

    test('LessonProgressEntity toMap includes all fields', () {
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
        quizScore: 90,
        maxQuizScore: 100,
      );

      final map = progress.toMap();

      expect(map['userId'], 'user_1');
      expect(map['courseId'], 'course_1');
      expect(map['moduleId'], 'module_1');
      expect(map['lessonId'], 'lesson_1');
      expect(map['status'], 'completed');
      expect(map['lastUpdated'], now.toIso8601String());
      expect(map['hasViewedVideo'], true);
      expect(map['hasCompletedQuiz'], true);
      expect(map['quizScore'], 90);
      expect(map['maxQuizScore'], 100);
    });

    test('LessonProgressEntity toMap excludes null lastUpdated', () {
      final progress = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.notStarted,
      );

      final map = progress.toMap();

      expect(map['lastUpdated'], null);
    });

    test('LessonProgressEntity fromMap with complete data', () {
      final now = DateTime.now();
      final map = {
        'userId': 'user_1',
        'courseId': 'course_1',
        'moduleId': 'module_1',
        'lessonId': 'lesson_1',
        'status': 'inProgress',
        'lastUpdated': now.toIso8601String(),
        'hasViewedVideo': true,
        'hasCompletedQuiz': false,
        'quizScore': 75,
        'maxQuizScore': 100,
      };

      final progress = LessonProgressEntity.fromMap(map);

      expect(progress.userId, 'user_1');
      expect(progress.courseId, 'course_1');
      expect(progress.moduleId, 'module_1');
      expect(progress.lessonId, 'lesson_1');
      expect(progress.status, LessonProgressStatus.inProgress);
      expect(progress.hasViewedVideo, true);
      expect(progress.hasCompletedQuiz, false);
      expect(progress.quizScore, 75);
      expect(progress.maxQuizScore, 100);
    });

    test('LessonProgressEntity fromMap with DateTime lastUpdated', () {
      final now = DateTime.now();
      final map = {
        'userId': 'user_1',
        'courseId': 'course_1',
        'moduleId': 'module_1',
        'lessonId': 'lesson_1',
        'status': 'notStarted',
        'lastUpdated': now,
        'hasViewedVideo': false,
        'hasCompletedQuiz': false,
      };

      final progress = LessonProgressEntity.fromMap(map);

      expect(progress.lastUpdated, now);
    });

    test('LessonProgressEntity fromMap with Timestamp lastUpdated', () {
      final now = DateTime.now();
      final map = {
        'userId': 'user_1',
        'courseId': 'course_1',
        'moduleId': 'module_1',
        'lessonId': 'lesson_1',
        'status': 'completed',
        'lastUpdated': Timestamp.fromDate(now),
        'hasViewedVideo': true,
        'hasCompletedQuiz': true,
      };

      final progress = LessonProgressEntity.fromMap(map);

      expect(progress.lastUpdated, isNotNull);
    });

    test('LessonProgressEntity fromMap with null values', () {
      final map = {
        'userId': 'user_1',
        'courseId': 'course_1',
        'moduleId': 'module_1',
        'lessonId': 'lesson_1',
        'status': 'notStarted',
        'lastUpdated': null,
        'hasViewedVideo': null,
        'hasCompletedQuiz': null,
        'quizScore': null,
        'maxQuizScore': null,
      };

      final progress = LessonProgressEntity.fromMap(map);

      expect(progress.lastUpdated, null);
      expect(progress.hasViewedVideo, false);
      expect(progress.hasCompletedQuiz, false);
      expect(progress.quizScore, null);
      expect(progress.maxQuizScore, null);
    });

    test(
      'LessonProgressEntity fromMap with invalid status defaults to notStarted',
      () {
        final map = {
          'userId': 'user_1',
          'courseId': 'course_1',
          'moduleId': 'module_1',
          'lessonId': 'lesson_1',
          'status': 'invalid_status',
          'hasViewedVideo': false,
          'hasCompletedQuiz': false,
        };

        final progress = LessonProgressEntity.fromMap(map);

        expect(progress.status, LessonProgressStatus.notStarted);
      },
    );

    test('LessonProgressEntity round-trip conversion', () {
      final now = DateTime.now();
      final original = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.inProgress,
        lastUpdated: now,
        hasViewedVideo: true,
        hasCompletedQuiz: true,
        quizScore: 85,
        maxQuizScore: 100,
      );

      final map = original.toMap();
      final restored = LessonProgressEntity.fromMap(map);

      expect(restored.userId, original.userId);
      expect(restored.courseId, original.courseId);
      expect(restored.moduleId, original.moduleId);
      expect(restored.lessonId, original.lessonId);
      expect(restored.status, original.status);
      expect(restored.hasViewedVideo, original.hasViewedVideo);
      expect(restored.hasCompletedQuiz, original.hasCompletedQuiz);
      expect(restored.quizScore, original.quizScore);
      expect(restored.maxQuizScore, original.maxQuizScore);
    });

    test('LessonProgressStatus enum has correct values', () {
      expect(LessonProgressStatus.notStarted, isNotNull);
      expect(LessonProgressStatus.inProgress, isNotNull);
      expect(LessonProgressStatus.completed, isNotNull);
    });

    test('LessonProgressEntity with all status values', () {
      final notStarted = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.notStarted,
      );

      final inProgress = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.inProgress,
      );

      final completed = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.completed,
      );

      expect(notStarted.status, LessonProgressStatus.notStarted);
      expect(inProgress.status, LessonProgressStatus.inProgress);
      expect(completed.status, LessonProgressStatus.completed);
    });

    test('LessonProgressEntity props includes all fields', () {
      final now = DateTime.now();
      final progress = LessonProgressEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        status: LessonProgressStatus.inProgress,
        lastUpdated: now,
        hasViewedVideo: true,
        hasCompletedQuiz: true,
        quizScore: 100,
        maxQuizScore: 100,
      );

      final props = progress.props;

      expect(props.length, 10);
      expect(props.contains('user_1'), true);
      expect(props.contains('course_1'), true);
      expect(props.contains('module_1'), true);
      expect(props.contains('lesson_1'), true);
      expect(props.contains(LessonProgressStatus.inProgress), true);
      expect(props.contains(now), true);
      expect(props.contains(true), true); // hasViewedVideo
      expect(props.contains(true), true); // hasCompletedQuiz
      expect(props.contains(100), true); // quizScore
      expect(props.contains(100), true); // maxQuizScore
    });
  });
}

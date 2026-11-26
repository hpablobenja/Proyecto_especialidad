import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/video_tracking_entity.dart';

void main() {
  group('VideoTrackingEntity Tests', () {
    test('VideoTrackingEntity se crea correctamente', () {
      final now = DateTime.now();
      final tracking = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        lastUpdated: now,
      );

      expect(tracking.userId, 'user_1');
      expect(tracking.courseId, 'course_1');
      expect(tracking.moduleId, 'module_1');
      expect(tracking.lessonId, 'lesson_1');
      expect(tracking.currentPositionMs, 0);
      expect(tracking.lastValidPositionMs, 0);
      expect(tracking.maxReachedPositionMs, 0);
      expect(tracking.viewedSeconds, 0);
      expect(tracking.completionPercentage, 0.0);
      expect(tracking.totalDurationMs, 0);
      expect(tracking.checkpointsPassed, isEmpty);
      expect(tracking.checkpointsFailed, isEmpty);
      expect(tracking.isCompleted, false);
      expect(tracking.lastUpdated, now);
      expect(tracking.needsSync, false);
    });

    test('VideoTrackingEntity con progreso funciona', () {
      final now = DateTime.now();
      final tracking = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        currentPositionMs: 30000,
        lastValidPositionMs: 30000,
        maxReachedPositionMs: 45000,
        viewedSeconds: 120,
        completionPercentage: 50.0,
        totalDurationMs: 90000,
        checkpointsPassed: ['cp1', 'cp2'],
        checkpointsFailed: ['cp3'],
        isCompleted: false,
        lastUpdated: now,
        needsSync: true,
      );

      expect(tracking.currentPositionMs, 30000);
      expect(tracking.lastValidPositionMs, 30000);
      expect(tracking.maxReachedPositionMs, 45000);
      expect(tracking.viewedSeconds, 120);
      expect(tracking.completionPercentage, 50.0);
      expect(tracking.totalDurationMs, 90000);
      expect(tracking.checkpointsPassed.length, 2);
      expect(tracking.checkpointsFailed.length, 1);
      expect(tracking.needsSync, true);
    });

    test('VideoTrackingEntity con equatable funciona', () {
      final now = DateTime.now();
      final tracking1 = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        lastUpdated: now,
      );

      final tracking2 = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        lastUpdated: now,
      );

      final tracking3 = VideoTrackingEntity(
        userId: 'user_2',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        lastUpdated: now,
      );

      expect(tracking1, tracking2);
      expect(tracking1, isNot(tracking3));
    });

    test('VideoTrackingEntity copyWith funciona', () {
      final now = DateTime.now();
      final original = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        lastUpdated: now,
      );

      final updated = original.copyWith(
        currentPositionMs: 60000,
        isCompleted: true,
        needsSync: true,
      );

      expect(updated.currentPositionMs, 60000);
      expect(updated.isCompleted, true);
      expect(updated.needsSync, true);
      expect(updated.userId, original.userId);
    });

    test('VideoTrackingEntity toMap funciona', () {
      final now = DateTime.now();
      final tracking = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        currentPositionMs: 30000,
        lastValidPositionMs: 30000,
        maxReachedPositionMs: 45000,
        viewedSeconds: 120,
        completionPercentage: 50.0,
        totalDurationMs: 90000,
        checkpointsPassed: ['cp1'],
        checkpointsFailed: ['cp2'],
        isCompleted: false,
        lastUpdated: now,
        needsSync: true,
      );

      final map = tracking.toMap();

      expect(map['userId'], 'user_1');
      expect(map['courseId'], 'course_1');
      expect(map['moduleId'], 'module_1');
      expect(map['lessonId'], 'lesson_1');
      expect(map['currentPositionMs'], 30000);
      expect(map['lastValidPositionMs'], 30000);
      expect(map['maxReachedPositionMs'], 45000);
      expect(map['viewedSeconds'], 120);
      expect(map['completionPercentage'], 50.0);
      expect(map['totalDurationMs'], 90000);
      expect(map['checkpointsPassed'], ['cp1']);
      expect(map['checkpointsFailed'], ['cp2']);
      expect(map['isCompleted'], false);
      expect(map['lastUpdated'], now.toIso8601String());
      expect(map['needsSync'], true);
    });

    test('VideoTrackingEntity fromMap funciona', () {
      final now = DateTime.now();
      final map = {
        'userId': 'user_1',
        'courseId': 'course_1',
        'moduleId': 'module_1',
        'lessonId': 'lesson_1',
        'currentPositionMs': 30000,
        'lastValidPositionMs': 30000,
        'maxReachedPositionMs': 45000,
        'viewedSeconds': 120,
        'completionPercentage': 50.0,
        'totalDurationMs': 90000,
        'checkpointsPassed': ['cp1'],
        'checkpointsFailed': ['cp2'],
        'isCompleted': false,
        'lastUpdated': now.toIso8601String(),
        'needsSync': true,
      };

      final tracking = VideoTrackingEntity.fromMap(map);

      expect(tracking.userId, 'user_1');
      expect(tracking.courseId, 'course_1');
      expect(tracking.moduleId, 'module_1');
      expect(tracking.lessonId, 'lesson_1');
      expect(tracking.currentPositionMs, 30000);
      expect(tracking.lastValidPositionMs, 30000);
      expect(tracking.maxReachedPositionMs, 45000);
      expect(tracking.viewedSeconds, 120);
      expect(tracking.completionPercentage, 50.0);
      expect(tracking.totalDurationMs, 90000);
      expect(tracking.checkpointsPassed, ['cp1']);
      expect(tracking.checkpointsFailed, ['cp2']);
      expect(tracking.isCompleted, false);
      expect(tracking.needsSync, true);
    });

    test('VideoTrackingEntity fromMap con DateTime funciona', () {
      final now = DateTime.now();
      final map = {
        'userId': 'user_1',
        'courseId': 'course_1',
        'moduleId': 'module_1',
        'lessonId': 'lesson_1',
        'lastUpdated': now,
      };

      final tracking = VideoTrackingEntity.fromMap(map);

      expect(tracking.lastUpdated, now);
    });

    test('VideoTrackingEntity fromMap con valores nulos usa defaults', () {
      final map = {
        'userId': 'user_1',
        'courseId': 'course_1',
        'moduleId': 'module_1',
        'lessonId': 'lesson_1',
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final tracking = VideoTrackingEntity.fromMap(map);

      expect(tracking.currentPositionMs, 0);
      expect(tracking.lastValidPositionMs, 0);
      expect(tracking.maxReachedPositionMs, 0);
      expect(tracking.viewedSeconds, 0);
      expect(tracking.completionPercentage, 0.0);
      expect(tracking.totalDurationMs, 0);
      expect(tracking.checkpointsPassed, isEmpty);
      expect(tracking.checkpointsFailed, isEmpty);
      expect(tracking.isCompleted, false);
      expect(tracking.needsSync, false);
    });

    test('VideoTrackingEntity calculateCompletionPercentage funciona', () {
      final now = DateTime.now();
      final tracking = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        maxReachedPositionMs: 45000,
        totalDurationMs: 90000,
        lastUpdated: now,
      );

      final percentage = tracking.calculateCompletionPercentage();

      expect(percentage, 50.0);
    });

    test('VideoTrackingEntity calculateCompletionPercentage con duración 0', () {
      final now = DateTime.now();
      final tracking = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        maxReachedPositionMs: 45000,
        totalDurationMs: 0,
        lastUpdated: now,
      );

      final percentage = tracking.calculateCompletionPercentage();

      expect(percentage, 0.0);
    });

    test('VideoTrackingEntity calculateCompletionPercentage clamp a 100', () {
      final now = DateTime.now();
      final tracking = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        maxReachedPositionMs: 150000,
        totalDurationMs: 100000,
        lastUpdated: now,
      );

      final percentage = tracking.calculateCompletionPercentage();

      expect(percentage, 100.0);
    });

    test('VideoTrackingEntity isLessonCompleted con 90% o más', () {
      final now = DateTime.now();
      final tracking = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        maxReachedPositionMs: 90000,
        totalDurationMs: 100000,
        lastUpdated: now,
      );

      expect(tracking.isLessonCompleted(), true);
    });

    test('VideoTrackingEntity isLessonCompleted con menos de 90%', () {
      final now = DateTime.now();
      final tracking = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        maxReachedPositionMs: 80000,
        totalDurationMs: 100000,
        lastUpdated: now,
      );

      expect(tracking.isLessonCompleted(), false);
    });

    test('VideoTrackingEntity con completionPercentage como int en fromMap', () {
      final map = {
        'userId': 'user_1',
        'courseId': 'course_1',
        'moduleId': 'module_1',
        'lessonId': 'lesson_1',
        'completionPercentage': 50,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final tracking = VideoTrackingEntity.fromMap(map);

      expect(tracking.completionPercentage, 50.0);
    });

    test('VideoTrackingEntity maneja múltiples checkpoints', () {
      final now = DateTime.now();
      final tracking = VideoTrackingEntity(
        userId: 'user_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        checkpointsPassed: ['cp1', 'cp2', 'cp3', 'cp4'],
        checkpointsFailed: ['cp5', 'cp6'],
        lastUpdated: now,
      );

      expect(tracking.checkpointsPassed.length, 4);
      expect(tracking.checkpointsFailed.length, 2);
    });
  });
}

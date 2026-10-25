import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';

void main() {
  group('CommentEntity Tests', () {
    test('CommentEntity creates correctly with all fields', () {
      final now = DateTime.now();
      final comment = CommentEntity(
        id: 'comment_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'Test User',
        text: 'This is a test comment',
        createdAt: now,
        updatedAt: now.add(const Duration(minutes: 5)),
      );

      expect(comment.id, 'comment_1');
      expect(comment.courseId, 'course_1');
      expect(comment.moduleId, 'module_1');
      expect(comment.lessonId, 'lesson_1');
      expect(comment.userId, 'user_1');
      expect(comment.userName, 'Test User');
      expect(comment.text, 'This is a test comment');
      expect(comment.createdAt, now);
      expect(comment.updatedAt, isNotNull);
    });

    test('CommentEntity creates correctly with null updatedAt', () {
      final now = DateTime.now();
      final comment = CommentEntity(
        id: 'comment_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'Test User',
        text: 'This is a test comment',
        createdAt: now,
      );

      expect(comment.updatedAt, null);
    });

    test('CommentEntity with equatable works correctly', () {
      final now = DateTime.now();
      final comment1 = CommentEntity(
        id: 'comment_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'Test User',
        text: 'This is a test comment',
        createdAt: now,
      );

      final comment2 = CommentEntity(
        id: 'comment_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'Test User',
        text: 'This is a test comment',
        createdAt: now,
      );

      final comment3 = CommentEntity(
        id: 'comment_2',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'Test User',
        text: 'This is a test comment',
        createdAt: now,
      );

      expect(comment1, comment2);
      expect(comment1, isNot(comment3));
    });

    test('CommentEntity props includes all fields', () {
      final now = DateTime.now();
      final comment = CommentEntity(
        id: 'comment_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'Test User',
        text: 'This is a test comment',
        createdAt: now,
        updatedAt: now.add(const Duration(minutes: 5)),
      );

      final props = comment.props;
      expect(props.length, 10);
      expect(props, contains('comment_1'));
      expect(props, contains('course_1'));
      expect(props, contains('module_1'));
      expect(props, contains('lesson_1'));
      expect(props, contains('user_1'));
      expect(props, contains('Test User'));
      expect(props, contains('This is a test comment'));
      expect(props, contains(now));
    });

    test('CommentEntity handles long text', () {
      final now = DateTime.now();
      final longText = 'A' * 500;
      final comment = CommentEntity(
        id: 'comment_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'Test User',
        text: longText,
        createdAt: now,
      );

      expect(comment.text.length, 500);
    });

    test('CommentEntity handles empty text', () {
      final now = DateTime.now();
      final comment = CommentEntity(
        id: 'comment_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'Test User',
        text: '',
        createdAt: now,
      );

      expect(comment.text, '');
    });

    test('CommentEntity handles special characters in text', () {
      final now = DateTime.now();
      final comment = CommentEntity(
        id: 'comment_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'Test User',
        text: 'Special chars: ñáéíóú !@#\$%',
        createdAt: now,
      );

      expect(comment.text, contains('ñáéíóú'));
    });

    test('CommentEntity with different updatedAt are not equal', () {
      final now = DateTime.now();
      final comment1 = CommentEntity(
        id: 'comment_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'Test User',
        text: 'This is a test comment',
        createdAt: now,
        updatedAt: now,
      );

      final comment2 = CommentEntity(
        id: 'comment_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'Test User',
        text: 'This is a test comment',
        createdAt: now,
        updatedAt: now.add(const Duration(minutes: 5)),
      );

      expect(comment1, isNot(comment2));
    });
  });
}

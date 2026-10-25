import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/add_comment_usecase.dart';

class MockContentRepository implements ContentRepository {
  CommentEntity? commentToReturn;
  Exception? errorToThrow;
  CommentEntity? lastAddedComment;

  @override
  Future<List<CourseEntity>> listCourses() async => [];

  @override
  Future<CourseEntity> createCourse(CourseEntity course) async => course;

  @override
  Future<CourseEntity> updateCourse(CourseEntity course) async => course;

  @override
  Future<void> deleteCourse(String courseId) async {}

  @override
  Future<List<ModuleEntity>> listModules(String courseId) async => [];

  @override
  Future<ModuleEntity> createModule(ModuleEntity module) async => module;

  @override
  Future<void> updateModule(ModuleEntity module) async {}

  @override
  Future<void> deleteModule(String courseId, String moduleId) async {}

  @override
  Future<void> reorderModules(String courseId, List<String> orderedModuleIds) async {}

  @override
  Future<List<LessonEntity>> listLessons(String courseId, String moduleId) async => [];

  @override
  Future<LessonEntity> createLesson(LessonEntity lesson) async => lesson;

  @override
  Future<void> updateLesson(LessonEntity lesson) async {}

  @override
  Future<void> deleteLesson(String courseId, String moduleId, String lessonId) async {}

  @override
  Future<void> reorderLessons(String courseId, String moduleId, List<String> orderedLessonIds) async {}

  @override
  Future<MediaResource> uploadMedia({required String courseId, required String? moduleId, required String? lessonId, required MediaUploadRequest request}) async {
    return MediaResource(
      id: 'media_1',
      url: 'https://example.com/file',
      filename: request.filename,
      mimeType: request.mimeType,
      sizeBytes: request.bytes.length,
    );
  }

  @override
  Future<void> deleteMedia({required String courseId, required String? moduleId, required String? lessonId, required String mediaId}) async {}

  @override
  Future<List<CommentEntity>> listComments({required String courseId, required String moduleId, required String lessonId}) async => [];

  @override
  Future<CommentEntity> addComment(CommentEntity comment) async {
    lastAddedComment = comment;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return commentToReturn ?? comment;
  }

  @override
  Future<void> deleteComment({required String courseId, required String moduleId, required String lessonId, required String commentId}) async {}
}

void main() {
  group('AddCommentUsecase Tests', () {
    late AddCommentUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = AddCommentUsecase(mockRepository);
    });

    test('AddCommentUsecase calls repository with correct comment', () async {
      final comment = CommentEntity(
        id: 'comment_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'User 1',
        text: 'Test comment',
        createdAt: DateTime.now(),
      );

      await usecase(comment);

      expect(mockRepository.lastAddedComment?.id, 'comment_1');
    });

    test('AddCommentUsecase returns comment from repository', () async {
      final comment = CommentEntity(
        id: 'comment_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'User 1',
        text: 'Test comment',
        createdAt: DateTime.now(),
      );

      final result = await usecase(comment);

      expect(result.id, 'comment_1');
    });

    test('AddCommentUsecase throws exception when repository throws', () async {
      mockRepository.errorToThrow = Exception('Add failed');
      final comment = CommentEntity(
        id: 'comment_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'User 1',
        text: 'Test',
        createdAt: DateTime.now(),
      );

      expect(() => usecase(comment), throwsException);
    });

    test('AddCommentUsecase preserves all comment fields', () async {
      final comment = CommentEntity(
        id: 'comment_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'User 1',
        text: 'Test comment',
        createdAt: DateTime(2026, 1, 1),
      );

      await usecase(comment);

      expect(mockRepository.lastAddedComment?.id, 'comment_1');
      expect(mockRepository.lastAddedComment?.courseId, 'course_1');
      expect(mockRepository.lastAddedComment?.moduleId, 'module_1');
      expect(mockRepository.lastAddedComment?.lessonId, 'lesson_1');
      expect(mockRepository.lastAddedComment?.userId, 'user_1');
      expect(mockRepository.lastAddedComment?.userName, 'User 1');
      expect(mockRepository.lastAddedComment?.text, 'Test comment');
    });

    test('AddCommentUsecase handles special characters in text', () async {
      final comment = CommentEntity(
        id: 'comment_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'User 1',
        text: 'Comentario ñáéíóú',
        createdAt: DateTime.now(),
      );

      await usecase(comment);

      expect(mockRepository.lastAddedComment?.text, 'Comentario ñáéíóú');
    });
  });
}

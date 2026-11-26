import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/delete_comment_usecase.dart';

class MockContentRepository implements ContentRepository {
  String? lastDeletedCourseId;
  String? lastDeletedModuleId;
  String? lastDeletedLessonId;
  String? lastDeletedCommentId;
  Exception? errorToThrow;

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
  Future<void> reorderModules(
    String courseId,
    List<String> orderedModuleIds,
  ) async {}

  @override
  Future<List<LessonEntity>> listLessons(
    String courseId,
    String moduleId,
  ) async => [];

  @override
  Future<LessonEntity> createLesson(LessonEntity lesson) async => lesson;

  @override
  Future<void> updateLesson(LessonEntity lesson) async {}

  @override
  Future<void> deleteLesson(
    String courseId,
    String moduleId,
    String lessonId,
  ) async {}

  @override
  Future<void> reorderLessons(
    String courseId,
    String moduleId,
    List<String> orderedLessonIds,
  ) async {}

  @override
  Future<MediaResource> uploadMedia({
    required String courseId,
    String? moduleId,
    String? lessonId,
    required MediaUploadRequest request,
  }) async {
    return MediaResource(
      id: 'media_1',
      url: '',
      filename: request.filename,
      mimeType: request.mimeType,
      sizeBytes: request.bytes.length,
    );
  }

  @override
  Future<void> deleteMedia({
    required String courseId,
    String? moduleId,
    String? lessonId,
    required String mediaId,
  }) async {}

  @override
  Future<List<CommentEntity>> listComments({
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async => [];

  @override
  Future<CommentEntity> addComment(CommentEntity comment) async => comment;

  @override
  Future<void> deleteComment({
    required String courseId,
    required String moduleId,
    required String lessonId,
    required String commentId,
  }) async {
    lastDeletedCourseId = courseId;
    lastDeletedModuleId = moduleId;
    lastDeletedLessonId = lessonId;
    lastDeletedCommentId = commentId;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }
}

void main() {
  group('DeleteCommentUsecase Tests', () {
    late DeleteCommentUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = DeleteCommentUsecase(mockRepository);
    });

    test(
      'DeleteCommentUsecase calls repository with correct parameters',
      () async {
        final params = DeleteCommentParams(
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          commentId: 'comment_1',
        );

        await usecase(params);

        expect(mockRepository.lastDeletedCourseId, 'course_1');
        expect(mockRepository.lastDeletedModuleId, 'module_1');
        expect(mockRepository.lastDeletedLessonId, 'lesson_1');
        expect(mockRepository.lastDeletedCommentId, 'comment_1');
      },
    );

    test(
      'DeleteCommentUsecase throws exception when repository throws',
      () async {
        mockRepository.errorToThrow = Exception('Failed to delete comment');
        final params = DeleteCommentParams(
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          commentId: 'comment_1',
        );

        expect(() => usecase(params), throwsException);
      },
    );

    test('DeleteCommentParams creates correctly', () {
      final params = DeleteCommentParams(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        commentId: 'comment_1',
      );

      expect(params.courseId, 'course_1');
      expect(params.moduleId, 'module_1');
      expect(params.lessonId, 'lesson_1');
      expect(params.commentId, 'comment_1');
    });

    test('DeleteCommentUsecase handles different IDs', () async {
      final params = DeleteCommentParams(
        courseId: 'course_xyz',
        moduleId: 'module_abc',
        lessonId: 'lesson_123',
        commentId: 'comment_456',
      );

      await usecase(params);

      expect(mockRepository.lastDeletedCourseId, 'course_xyz');
      expect(mockRepository.lastDeletedModuleId, 'module_abc');
      expect(mockRepository.lastDeletedLessonId, 'lesson_123');
      expect(mockRepository.lastDeletedCommentId, 'comment_456');
    });
  });
}

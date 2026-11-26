import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/list_comments_usecase.dart';

class MockContentRepository implements ContentRepository {
  List<CommentEntity> commentsToReturn = [];
  String? lastListedCourseId;
  String? lastListedModuleId;
  String? lastListedLessonId;
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
  }) async {
    lastListedCourseId = courseId;
    lastListedModuleId = moduleId;
    lastListedLessonId = lessonId;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return commentsToReturn;
  }

  @override
  Future<CommentEntity> addComment(CommentEntity comment) async => comment;

  @override
  Future<void> deleteComment({
    required String courseId,
    required String moduleId,
    required String lessonId,
    required String commentId,
  }) async {}
}

void main() {
  group('ListCommentsUsecase Tests', () {
    late ListCommentsUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = ListCommentsUsecase(mockRepository);
    });

    test(
      'ListCommentsUsecase calls repository with correct parameters',
      () async {
        await usecase(
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
        );

        expect(mockRepository.lastListedCourseId, 'course_1');
        expect(mockRepository.lastListedModuleId, 'module_1');
        expect(mockRepository.lastListedLessonId, 'lesson_1');
      },
    );

    test('ListCommentsUsecase returns comments from repository', () async {
      final comments = [
        CommentEntity(
          id: 'comment_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          userId: 'user_1',
          userName: 'User 1',
          text: 'Great lesson!',
          createdAt: DateTime.now(),
        ),
        CommentEntity(
          id: 'comment_2',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          userId: 'user_2',
          userName: 'User 2',
          text: 'Very helpful',
          createdAt: DateTime.now(),
        ),
      ];
      mockRepository.commentsToReturn = comments;

      final result = await usecase(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
      );

      expect(result.length, 2);
      expect(result[0].id, 'comment_1');
      expect(result[1].id, 'comment_2');
    });

    test(
      'ListCommentsUsecase returns empty list when repository returns empty',
      () async {
        mockRepository.commentsToReturn = [];

        final result = await usecase(
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
        );

        expect(result, isEmpty);
      },
    );

    test(
      'ListCommentsUsecase throws exception when repository throws',
      () async {
        mockRepository.errorToThrow = Exception('Failed to list comments');

        expect(
          () => usecase(
            courseId: 'course_1',
            moduleId: 'module_1',
            lessonId: 'lesson_1',
          ),
          throwsException,
        );
      },
    );

    test('ListCommentsUsecase handles different IDs', () async {
      await usecase(
        courseId: 'course_xyz',
        moduleId: 'module_abc',
        lessonId: 'lesson_123',
      );

      expect(mockRepository.lastListedCourseId, 'course_xyz');
      expect(mockRepository.lastListedModuleId, 'module_abc');
      expect(mockRepository.lastListedLessonId, 'lesson_123');
    });

    test('ListCommentsUsecase preserves comment data', () async {
      final now = DateTime.now();
      final comments = [
        CommentEntity(
          id: 'comment_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          userId: 'user_1',
          userName: 'Test User',
          text: 'Test comment',
          createdAt: now,
        ),
      ];
      mockRepository.commentsToReturn = comments;

      final result = await usecase(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
      );

      expect(result[0].id, 'comment_1');
      expect(result[0].userId, 'user_1');
      expect(result[0].text, 'Test comment');
      expect(result[0].createdAt, now);
    });
  });
}

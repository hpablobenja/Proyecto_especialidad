import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/list_comments_usecase.dart'
    as uc_list_comments;
import 'package:redmaestra1/domain/usecases/content/add_comment_usecase.dart'
    as uc_add_comment;
import 'package:redmaestra1/domain/usecases/content/delete_comment_usecase.dart'
    as uc_delete_comment;
import 'package:redmaestra1/presentation/providers/comments_provider.dart';

class FakeListCommentsUsecase extends uc_list_comments.ListCommentsUsecase {
  List<CommentEntity>? commentsToReturn;
  Exception? errorToThrow;

  FakeListCommentsUsecase() : super(FakeContentRepository());

  void setResponse(List<CommentEntity> comments) {
    commentsToReturn = comments;
  }

  void setError(Object error) {
    errorToThrow = Exception(error);
  }

  @override
  Future<List<CommentEntity>> call({
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return commentsToReturn ?? [];
  }
}

class FakeAddCommentUsecase extends uc_add_comment.AddCommentUsecase {
  CommentEntity? commentToReturn;
  Exception? errorToThrow;

  FakeAddCommentUsecase() : super(FakeContentRepository());

  void setResponse(CommentEntity comment) {
    commentToReturn = comment;
  }

  void setError(Object error) {
    errorToThrow = Exception(error);
  }

  @override
  Future<CommentEntity> call(CommentEntity params) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return commentToReturn ?? params;
  }
}

class FakeDeleteCommentUsecase extends uc_delete_comment.DeleteCommentUsecase {
  Exception? errorToThrow;

  FakeDeleteCommentUsecase() : super(FakeContentRepository());

  void setError(Object error) {
    errorToThrow = Exception(error);
  }

  @override
  Future<void> call(uc_delete_comment.DeleteCommentParams params) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }
}

class FakeContentRepository implements ContentRepository {
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
    required String? moduleId,
    required String? lessonId,
    required MediaUploadRequest request,
  }) async {
    return MediaResource(
      id: 'media_1',
      url: 'https://example.com/file',
      filename: request.filename,
      mimeType: request.mimeType,
      sizeBytes: request.bytes.length,
    );
  }

  @override
  Future<void> deleteMedia({
    required String courseId,
    required String? moduleId,
    required String? lessonId,
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
  }) async {}
}

void main() {
  group('CommentsProvider Tests', () {
    late CommentsProvider provider;
    late FakeListCommentsUsecase fakeListCommentsUsecase;
    late FakeAddCommentUsecase fakeAddCommentUsecase;
    late FakeDeleteCommentUsecase fakeDeleteCommentUsecase;

    setUp(() {
      fakeListCommentsUsecase = FakeListCommentsUsecase();
      fakeAddCommentUsecase = FakeAddCommentUsecase();
      fakeDeleteCommentUsecase = FakeDeleteCommentUsecase();

      provider = CommentsProvider(
        listCommentsUsecase: fakeListCommentsUsecase,
        addCommentUsecase: fakeAddCommentUsecase,
        deleteCommentUsecase: fakeDeleteCommentUsecase,
      );
    });

    test('CommentsProvider initializes with default values', () {
      expect(provider.isLoading, false);
      expect(provider.error, null);
      expect(provider.items, isEmpty);
    });

    test('load loads comments successfully', () async {
      final testComments = [
        CommentEntity(
          id: 'comment_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          userId: 'user_1',
          userName: 'User 1',
          text: 'Test comment',
          createdAt: DateTime.now(),
        ),
      ];
      fakeListCommentsUsecase.setResponse(testComments);

      await provider.load(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
      );

      expect(provider.items.length, 1);
      expect(provider.items[0].id, 'comment_1');
      expect(provider.isLoading, false);
    });

    test('load sets error on failure', () async {
      fakeListCommentsUsecase.setError('Network error');

      await provider.load(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
      );

      expect(provider.error, isNotNull);
      expect(provider.error, contains('Error al cargar comentarios'));
      expect(provider.isLoading, false);
    });

    test('add adds comment to list', () async {
      final newComment = CommentEntity(
        id: 'new_comment',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'User 1',
        text: 'New comment',
        createdAt: DateTime.now(),
      );
      fakeAddCommentUsecase.setResponse(newComment);

      final result = await provider.add(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'User 1',
        text: 'New comment',
      );

      expect(result, true);
      expect(provider.items.length, 1);
      expect(provider.items[0].id, 'new_comment');
    });

    test('add trims text', () async {
      final newComment = CommentEntity(
        id: 'new_comment',
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'User 1',
        text: '  Trimmed  ',
        createdAt: DateTime.now(),
      );
      fakeAddCommentUsecase.setResponse(newComment);

      await provider.add(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'User 1',
        text: '  Trimmed  ',
      );

      expect(provider.items[0].text, 'Trimmed');
    });

    test('add sets error on failure', () async {
      fakeAddCommentUsecase.setError('Add failed');

      final result = await provider.add(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        userId: 'user_1',
        userName: 'User 1',
        text: 'Test',
      );

      expect(result, false);
      expect(provider.error, isNotNull);
    });

    test('remove removes comment from list', () async {
      final comments = [
        CommentEntity(
          id: 'comment_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          userId: 'user_1',
          userName: 'User 1',
          text: 'Comment 1',
          createdAt: DateTime.now(),
        ),
        CommentEntity(
          id: 'comment_2',
          courseId: 'course_1',
          moduleId: 'module_1',
          lessonId: 'lesson_1',
          userId: 'user_1',
          userName: 'User 1',
          text: 'Comment 2',
          createdAt: DateTime.now(),
        ),
      ];
      fakeListCommentsUsecase.setResponse(comments);

      await provider.load(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
      );
      final result = await provider.remove(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        commentId: 'comment_1',
      );

      expect(result, true);
      expect(provider.items.length, 1);
      expect(provider.items[0].id, 'comment_2');
    });

    test('remove sets error on failure', () async {
      fakeDeleteCommentUsecase.setError('Delete failed');

      final result = await provider.remove(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        commentId: 'comment_1',
      );

      expect(result, false);
      expect(provider.error, contains('Error al eliminar comentario'));
    });
  });
}

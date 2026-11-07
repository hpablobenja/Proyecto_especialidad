import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/create_lesson_usecase.dart';

class MockContentRepository implements ContentRepository {
  LessonEntity? lessonToReturn;
  Exception? errorToThrow;
  LessonEntity? lastCreatedLesson;

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
  Future<LessonEntity> createLesson(LessonEntity lesson) async {
    lastCreatedLesson = lesson;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return lessonToReturn ?? lesson;
  }

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
  group('CreateLessonUsecase Tests', () {
    late CreateLessonUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = CreateLessonUsecase(mockRepository);
    });

    test('CreateLessonUsecase calls repository with correct lesson', () async {
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Lesson 1',
        objectives: 'Description',
        orderIndex: 1,
      );

      await usecase(lesson);

      expect(mockRepository.lastCreatedLesson?.id, 'lesson_1');
    });

    test('CreateLessonUsecase returns lesson from repository', () async {
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Lesson 1',
        objectives: 'Description',
        orderIndex: 1,
      );

      final result = await usecase(lesson);

      expect(result.id, 'lesson_1');
    });

    test(
      'CreateLessonUsecase throws exception when repository throws',
      () async {
        mockRepository.errorToThrow = Exception('Create failed');
        final lesson = LessonEntity(
          id: 'lesson_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          title: 'Lesson 1',
          objectives: 'Description',
          orderIndex: 1,
        );

        expect(() => usecase(lesson), throwsException);
      },
    );

    test('CreateLessonUsecase preserves all lesson fields', () async {
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Test Lesson',
        objectives: 'Test Description',
        orderIndex: 5,
      );

      await usecase(lesson);

      expect(mockRepository.lastCreatedLesson?.id, 'lesson_1');
      expect(mockRepository.lastCreatedLesson?.courseId, 'course_1');
      expect(mockRepository.lastCreatedLesson?.moduleId, 'module_1');
      expect(mockRepository.lastCreatedLesson?.title, 'Test Lesson');
      expect(mockRepository.lastCreatedLesson?.objectives, 'Test Description');
      expect(mockRepository.lastCreatedLesson?.orderIndex, 5);
    });

    test('CreateLessonUsecase handles lesson with null description', () async {
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Lesson 1',
        orderIndex: 1,
      );

      await usecase(lesson);

      expect(mockRepository.lastCreatedLesson?.objectives, null);
    });

    test('CreateLessonUsecase handles special characters in title', () async {
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Lección de Matemáticas ñáéíóú',
        objectives: 'Description',
        orderIndex: 1,
      );

      await usecase(lesson);

      expect(
        mockRepository.lastCreatedLesson?.title,
        'Lección de Matemáticas ñáéíóú',
      );
    });
  });
}

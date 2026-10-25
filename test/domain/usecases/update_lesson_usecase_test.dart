import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/update_lesson_usecase.dart';

class MockContentRepository implements ContentRepository {
  Exception? errorToThrow;
  LessonEntity? lastUpdatedLesson;

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
  Future<void> updateLesson(LessonEntity lesson) async {
    lastUpdatedLesson = lesson;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

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
  Future<CommentEntity> addComment(CommentEntity comment) async => comment;

  @override
  Future<void> deleteComment({required String courseId, required String moduleId, required String lessonId, required String commentId}) async {}
}

void main() {
  group('UpdateLessonUsecase Tests', () {
    late UpdateLessonUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = UpdateLessonUsecase(mockRepository);
    });

    test('UpdateLessonUsecase calls repository with correct lesson', () async {
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Updated Title',
        objectives: 'Updated Objectives',
        orderIndex: 1,
      );

      await usecase(lesson);

      expect(mockRepository.lastUpdatedLesson?.id, 'lesson_1');
    });

    test('UpdateLessonUsecase completes successfully', () async {
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Updated Title',
        orderIndex: 1,
      );

      await usecase(lesson);

      expect(mockRepository.lastUpdatedLesson?.id, 'lesson_1');
    });

    test('UpdateLessonUsecase throws exception when repository throws', () async {
      mockRepository.errorToThrow = Exception('Update failed');
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Title',
        orderIndex: 1,
      );

      expect(() => usecase(lesson), throwsException);
    });

    test('UpdateLessonUsecase preserves all lesson fields', () async {
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Test Lesson',
        objectives: 'Test Objectives',
        orderIndex: 5,
      );

      await usecase(lesson);

      expect(mockRepository.lastUpdatedLesson?.id, 'lesson_1');
      expect(mockRepository.lastUpdatedLesson?.courseId, 'course_1');
      expect(mockRepository.lastUpdatedLesson?.moduleId, 'module_1');
      expect(mockRepository.lastUpdatedLesson?.title, 'Test Lesson');
      expect(mockRepository.lastUpdatedLesson?.objectives, 'Test Objectives');
      expect(mockRepository.lastUpdatedLesson?.orderIndex, 5);
    });

    test('UpdateLessonUsecase handles lesson with null objectives', () async {
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Test Lesson',
        orderIndex: 1,
      );

      await usecase(lesson);

      expect(mockRepository.lastUpdatedLesson?.objectives, null);
    });

    test('UpdateLessonUsecase handles special characters in title', () async {
      final lesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Lección de Matemáticas ñáéíóú',
        objectives: 'Description',
        orderIndex: 1,
      );

      await usecase(lesson);

      expect(mockRepository.lastUpdatedLesson?.title, 'Lección de Matemáticas ñáéíóú');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/delete_lesson_usecase.dart';

class MockContentRepository implements ContentRepository {
  Exception? errorToThrow;
  String? lastDeletedCourseId;
  String? lastDeletedModuleId;
  String? lastDeletedLessonId;

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
  Future<void> deleteLesson(String courseId, String moduleId, String lessonId) async {
    lastDeletedCourseId = courseId;
    lastDeletedModuleId = moduleId;
    lastDeletedLessonId = lessonId;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

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
  group('DeleteLessonUsecase Tests', () {
    late DeleteLessonUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = DeleteLessonUsecase(mockRepository);
    });

    test('DeleteLessonUsecase calls repository with correct courseId', () async {
      final params = DeleteLessonParams(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
      );

      await usecase(params);

      expect(mockRepository.lastDeletedCourseId, 'course_1');
    });

    test('DeleteLessonUsecase calls repository with correct moduleId', () async {
      final params = DeleteLessonParams(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
      );

      await usecase(params);

      expect(mockRepository.lastDeletedModuleId, 'module_1');
    });

    test('DeleteLessonUsecase calls repository with correct lessonId', () async {
      final params = DeleteLessonParams(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
      );

      await usecase(params);

      expect(mockRepository.lastDeletedLessonId, 'lesson_1');
    });

    test('DeleteLessonUsecase completes successfully', () async {
      final params = DeleteLessonParams(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
      );

      await usecase(params);

      expect(mockRepository.lastDeletedCourseId, 'course_1');
      expect(mockRepository.lastDeletedModuleId, 'module_1');
      expect(mockRepository.lastDeletedLessonId, 'lesson_1');
    });

    test('DeleteLessonUsecase throws exception when repository throws', () async {
      mockRepository.errorToThrow = Exception('Delete failed');
      final params = DeleteLessonParams(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
      );

      expect(() => usecase(params), throwsException);
    });

    test('DeleteLessonUsecase handles empty courseId', () async {
      final params = DeleteLessonParams(
        courseId: '',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
      );

      await usecase(params);

      expect(mockRepository.lastDeletedCourseId, '');
    });

    test('DeleteLessonParams creates correctly', () {
      final params = DeleteLessonParams(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
      );

      expect(params.courseId, 'course_1');
      expect(params.moduleId, 'module_1');
      expect(params.lessonId, 'lesson_1');
    });
  });
}

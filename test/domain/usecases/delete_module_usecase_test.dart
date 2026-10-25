import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/delete_module_usecase.dart';

class MockContentRepository implements ContentRepository {
  Exception? errorToThrow;
  String? lastDeletedCourseId;
  String? lastDeletedModuleId;

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
  Future<void> deleteModule(String courseId, String moduleId) async {
    lastDeletedCourseId = courseId;
    lastDeletedModuleId = moduleId;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

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
  Future<CommentEntity> addComment(CommentEntity comment) async => comment;

  @override
  Future<void> deleteComment({required String courseId, required String moduleId, required String lessonId, required String commentId}) async {}
}

void main() {
  group('DeleteModuleUsecase Tests', () {
    late DeleteModuleUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = DeleteModuleUsecase(mockRepository);
    });

    test('DeleteModuleUsecase calls repository with correct courseId', () async {
      final params = DeleteModuleParams(courseId: 'course_1', moduleId: 'module_1');

      await usecase(params);

      expect(mockRepository.lastDeletedCourseId, 'course_1');
    });

    test('DeleteModuleUsecase calls repository with correct moduleId', () async {
      final params = DeleteModuleParams(courseId: 'course_1', moduleId: 'module_1');

      await usecase(params);

      expect(mockRepository.lastDeletedModuleId, 'module_1');
    });

    test('DeleteModuleUsecase completes successfully', () async {
      final params = DeleteModuleParams(courseId: 'course_1', moduleId: 'module_1');

      await usecase(params);

      expect(mockRepository.lastDeletedCourseId, 'course_1');
      expect(mockRepository.lastDeletedModuleId, 'module_1');
    });

    test('DeleteModuleUsecase throws exception when repository throws', () async {
      mockRepository.errorToThrow = Exception('Delete failed');
      final params = DeleteModuleParams(courseId: 'course_1', moduleId: 'module_1');

      expect(() => usecase(params), throwsException);
    });

    test('DeleteModuleUsecase handles empty courseId', () async {
      final params = DeleteModuleParams(courseId: '', moduleId: 'module_1');

      await usecase(params);

      expect(mockRepository.lastDeletedCourseId, '');
    });

    test('DeleteModuleUsecase handles empty moduleId', () async {
      final params = DeleteModuleParams(courseId: 'course_1', moduleId: '');

      await usecase(params);

      expect(mockRepository.lastDeletedModuleId, '');
    });

    test('DeleteModuleUsecase handles special characters in courseId', () async {
      final params = DeleteModuleParams(courseId: 'course_ñáéíóú', moduleId: 'module_1');

      await usecase(params);

      expect(mockRepository.lastDeletedCourseId, 'course_ñáéíóú');
    });

    test('DeleteModuleParams creates correctly', () {
      final params = DeleteModuleParams(courseId: 'course_1', moduleId: 'module_1');

      expect(params.courseId, 'course_1');
      expect(params.moduleId, 'module_1');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/update_module_usecase.dart';

class MockContentRepository implements ContentRepository {
  Exception? errorToThrow;
  ModuleEntity? lastUpdatedModule;

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
  Future<void> updateModule(ModuleEntity module) async {
    lastUpdatedModule = module;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

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
  Future<CommentEntity> addComment(CommentEntity comment) async => comment;

  @override
  Future<void> deleteComment({required String courseId, required String moduleId, required String lessonId, required String commentId}) async {}
}

void main() {
  group('UpdateModuleUsecase Tests', () {
    late UpdateModuleUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = UpdateModuleUsecase(mockRepository);
    });

    test('UpdateModuleUsecase calls repository with correct module', () async {
      final module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Updated Title',
        description: 'Updated Description',
        orderIndex: 1,
      );

      await usecase(module);

      expect(mockRepository.lastUpdatedModule?.id, 'module_1');
    });

    test('UpdateModuleUsecase completes successfully', () async {
      final module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Updated Title',
        orderIndex: 1,
      );

      await usecase(module);

      expect(mockRepository.lastUpdatedModule?.id, 'module_1');
    });

    test('UpdateModuleUsecase throws exception when repository throws', () async {
      mockRepository.errorToThrow = Exception('Update failed');
      final module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Title',
        orderIndex: 1,
      );

      expect(() => usecase(module), throwsException);
    });

    test('UpdateModuleUsecase preserves all module fields', () async {
      final module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Test Module',
        description: 'Test Description',
        orderIndex: 5,
      );

      await usecase(module);

      expect(mockRepository.lastUpdatedModule?.id, 'module_1');
      expect(mockRepository.lastUpdatedModule?.courseId, 'course_1');
      expect(mockRepository.lastUpdatedModule?.title, 'Test Module');
      expect(mockRepository.lastUpdatedModule?.description, 'Test Description');
      expect(mockRepository.lastUpdatedModule?.orderIndex, 5);
    });

    test('UpdateModuleUsecase handles module with null description', () async {
      final module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Test Module',
        orderIndex: 1,
      );

      await usecase(module);

      expect(mockRepository.lastUpdatedModule?.description, null);
    });

    test('UpdateModuleUsecase handles special characters in title', () async {
      final module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Módulo de Matemáticas ñáéíóú',
        description: 'Description',
        orderIndex: 1,
      );

      await usecase(module);

      expect(mockRepository.lastUpdatedModule?.title, 'Módulo de Matemáticas ñáéíóú');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/create_module_usecase.dart';

class MockContentRepository implements ContentRepository {
  ModuleEntity? moduleToReturn;
  Exception? errorToThrow;
  ModuleEntity? lastCreatedModule;

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
  Future<ModuleEntity> createModule(ModuleEntity module) async {
    lastCreatedModule = module;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return moduleToReturn ?? module;
  }

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
  Future<CommentEntity> addComment(CommentEntity comment) async => comment;

  @override
  Future<void> deleteComment({required String courseId, required String moduleId, required String lessonId, required String commentId}) async {}
}

void main() {
  group('CreateModuleUsecase Tests', () {
    late CreateModuleUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = CreateModuleUsecase(mockRepository);
    });

    test('CreateModuleUsecase calls repository with correct module', () async {
      final module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Module 1',
        description: 'Description',
        orderIndex: 1,
      );

      await usecase(module);

      expect(mockRepository.lastCreatedModule?.id, 'module_1');
    });

    test('CreateModuleUsecase returns module from repository', () async {
      final module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Module 1',
        description: 'Description',
        orderIndex: 1,
      );

      final result = await usecase(module);

      expect(result.id, 'module_1');
    });

    test('CreateModuleUsecase throws exception when repository throws', () async {
      mockRepository.errorToThrow = Exception('Create failed');
      final module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Module 1',
        description: 'Description',
        orderIndex: 1,
      );

      expect(() => usecase(module), throwsException);
    });

    test('CreateModuleUsecase preserves all module fields', () async {
      final module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Test Module',
        description: 'Test Description',
        orderIndex: 5,
      );

      await usecase(module);

      expect(mockRepository.lastCreatedModule?.id, 'module_1');
      expect(mockRepository.lastCreatedModule?.courseId, 'course_1');
      expect(mockRepository.lastCreatedModule?.title, 'Test Module');
      expect(mockRepository.lastCreatedModule?.description, 'Test Description');
      expect(mockRepository.lastCreatedModule?.orderIndex, 5);
    });

    test('CreateModuleUsecase handles module with null description', () async {
      final module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Module 1',
        orderIndex: 1,
      );

      await usecase(module);

      expect(mockRepository.lastCreatedModule?.description, null);
    });

    test('CreateModuleUsecase handles special characters in title', () async {
      final module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Módulo de Matemáticas ñáéíóú',
        description: 'Description',
        orderIndex: 1,
      );

      await usecase(module);

      expect(mockRepository.lastCreatedModule?.title, 'Módulo de Matemáticas ñáéíóú');
    });
  });
}

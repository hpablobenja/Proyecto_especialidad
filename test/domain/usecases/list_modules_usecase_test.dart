import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/list_modules_usecase.dart';

class MockContentRepository implements ContentRepository {
  List<ModuleEntity>? modulesToReturn;
  Exception? errorToThrow;
  String? lastListModulesCourseId;

  @override
  Future<List<CourseEntity>> listCourses() async => [];

  @override
  Future<CourseEntity> createCourse(CourseEntity course) async => course;

  @override
  Future<CourseEntity> updateCourse(CourseEntity course) async => course;

  @override
  Future<void> deleteCourse(String courseId) async {}

  @override
  Future<List<ModuleEntity>> listModules(String courseId) async {
    lastListModulesCourseId = courseId;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return modulesToReturn ?? [];
  }

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
  group('ListModulesUsecase Tests', () {
    late ListModulesUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = ListModulesUsecase(mockRepository);
    });

    test(
      'ListModulesUsecase returns empty list when repository returns empty',
      () async {
        mockRepository.modulesToReturn = [];

        final result = await usecase('course_1');

        expect(result, isEmpty);
      },
    );

    test('ListModulesUsecase returns modules from repository', () async {
      final testModules = [
        ModuleEntity(
          id: 'module_1',
          courseId: 'course_1',
          title: 'Module 1',
          orderIndex: 1,
        ),
        ModuleEntity(
          id: 'module_2',
          courseId: 'course_1',
          title: 'Module 2',
          orderIndex: 2,
        ),
      ];
      mockRepository.modulesToReturn = testModules;

      final result = await usecase('course_1');

      expect(result.length, 2);
      expect(result[0].id, 'module_1');
      expect(result[1].id, 'module_2');
    });

    test('ListModulesUsecase calls repository with correct courseId', () async {
      mockRepository.modulesToReturn = [];

      await usecase('course_1');

      expect(mockRepository.lastListModulesCourseId, 'course_1');
    });

    test(
      'ListModulesUsecase throws exception when repository throws',
      () async {
        mockRepository.errorToThrow = Exception('Network error');

        expect(() => usecase('course_1'), throwsException);
      },
    );

    test('ListModulesUsecase handles single module', () async {
      final testModule = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Single Module',
        orderIndex: 1,
      );
      mockRepository.modulesToReturn = [testModule];

      final result = await usecase('course_1');

      expect(result.length, 1);
      expect(result[0].id, 'module_1');
    });

    test('ListModulesUsecase handles many modules', () async {
      final testModules = List.generate(
        50,
        (index) => ModuleEntity(
          id: 'module_$index',
          courseId: 'course_1',
          title: 'Module $index',
          orderIndex: index,
        ),
      );
      mockRepository.modulesToReturn = testModules;

      final result = await usecase('course_1');

      expect(result.length, 50);
    });

    test('ListModulesUsecase preserves module data from repository', () async {
      final testModule = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Test Module',
        description: 'Test Description',
        orderIndex: 1,
      );
      mockRepository.modulesToReturn = [testModule];

      final result = await usecase('course_1');

      expect(result[0].id, testModule.id);
      expect(result[0].courseId, testModule.courseId);
      expect(result[0].title, testModule.title);
      expect(result[0].description, testModule.description);
      expect(result[0].orderIndex, testModule.orderIndex);
    });

    test('ListModulesUsecase handles special characters in courseId', () async {
      mockRepository.modulesToReturn = [];

      await usecase('course_ñáéíóú');

      expect(mockRepository.lastListModulesCourseId, 'course_ñáéíóú');
    });
  });
}

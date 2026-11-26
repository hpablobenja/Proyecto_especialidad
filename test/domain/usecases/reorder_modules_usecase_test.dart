import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/reorder_modules_usecase.dart';

class MockContentRepository implements ContentRepository {
  String? lastReorderedCourseId;
  List<String>? lastOrderedModuleIds;
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
  ) async {
    lastReorderedCourseId = courseId;
    lastOrderedModuleIds = orderedModuleIds;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

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
  }) async {}
}

void main() {
  group('ReorderModulesUsecase Tests', () {
    late ReorderModulesUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = ReorderModulesUsecase(mockRepository);
    });

    test(
      'ReorderModulesUsecase calls repository with correct parameters',
      () async {
        final params = ReorderModulesParams(
          courseId: 'course_1',
          orderedModuleIds: ['module_3', 'module_1', 'module_2'],
        );

        await usecase(params);

        expect(mockRepository.lastReorderedCourseId, 'course_1');
        expect(mockRepository.lastOrderedModuleIds, [
          'module_3',
          'module_1',
          'module_2',
        ]);
      },
    );

    test(
      'ReorderModulesUsecase throws exception when repository throws',
      () async {
        mockRepository.errorToThrow = Exception('Failed to reorder modules');
        final params = ReorderModulesParams(
          courseId: 'course_1',
          orderedModuleIds: ['module_1', 'module_2'],
        );

        expect(() => usecase(params), throwsException);
      },
    );

    test('ReorderModulesParams creates correctly', () {
      final params = ReorderModulesParams(
        courseId: 'course_1',
        orderedModuleIds: ['module_1', 'module_2', 'module_3'],
      );

      expect(params.courseId, 'course_1');
      expect(params.orderedModuleIds, ['module_1', 'module_2', 'module_3']);
    });

    test('ReorderModulesUsecase handles single module', () async {
      final params = ReorderModulesParams(
        courseId: 'course_1',
        orderedModuleIds: ['module_1'],
      );

      await usecase(params);

      expect(mockRepository.lastOrderedModuleIds?.length, 1);
      expect(mockRepository.lastOrderedModuleIds?[0], 'module_1');
    });

    test('ReorderModulesUsecase handles many modules', () async {
      final moduleIds = List.generate(15, (i) => 'module_$i');
      final params = ReorderModulesParams(
        courseId: 'course_1',
        orderedModuleIds: moduleIds,
      );

      await usecase(params);

      expect(mockRepository.lastOrderedModuleIds?.length, 15);
    });

    test('ReorderModulesUsecase handles different course ID', () async {
      final params = ReorderModulesParams(
        courseId: 'course_xyz',
        orderedModuleIds: ['module_a', 'module_b'],
      );

      await usecase(params);

      expect(mockRepository.lastReorderedCourseId, 'course_xyz');
    });

    test('ReorderModulesUsecase preserves order', () async {
      final params = ReorderModulesParams(
        courseId: 'course_1',
        orderedModuleIds: ['module_5', 'module_2', 'module_8', 'module_1'],
      );

      await usecase(params);

      expect(mockRepository.lastOrderedModuleIds, [
        'module_5',
        'module_2',
        'module_8',
        'module_1',
      ]);
    });
  });
}

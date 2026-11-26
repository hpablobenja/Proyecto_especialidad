import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/reorder_lessons_usecase.dart';

class MockContentRepository implements ContentRepository {
  String? lastReorderedCourseId;
  String? lastReorderedModuleId;
  List<String>? lastOrderedLessonIds;
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
  ) async {
    lastReorderedCourseId = courseId;
    lastReorderedModuleId = moduleId;
    lastOrderedLessonIds = orderedLessonIds;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

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
  group('ReorderLessonsUsecase Tests', () {
    late ReorderLessonsUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = ReorderLessonsUsecase(mockRepository);
    });

    test(
      'ReorderLessonsUsecase calls repository with correct parameters',
      () async {
        final params = ReorderLessonsParams(
          courseId: 'course_1',
          moduleId: 'module_1',
          orderedLessonIds: ['lesson_3', 'lesson_1', 'lesson_2'],
        );

        await usecase(params);

        expect(mockRepository.lastReorderedCourseId, 'course_1');
        expect(mockRepository.lastReorderedModuleId, 'module_1');
        expect(mockRepository.lastOrderedLessonIds, [
          'lesson_3',
          'lesson_1',
          'lesson_2',
        ]);
      },
    );

    test(
      'ReorderLessonsUsecase throws exception when repository throws',
      () async {
        mockRepository.errorToThrow = Exception('Failed to reorder lessons');
        final params = ReorderLessonsParams(
          courseId: 'course_1',
          moduleId: 'module_1',
          orderedLessonIds: ['lesson_1', 'lesson_2'],
        );

        expect(() => usecase(params), throwsException);
      },
    );

    test('ReorderLessonsParams creates correctly', () {
      final params = ReorderLessonsParams(
        courseId: 'course_1',
        moduleId: 'module_1',
        orderedLessonIds: ['lesson_1', 'lesson_2', 'lesson_3'],
      );

      expect(params.courseId, 'course_1');
      expect(params.moduleId, 'module_1');
      expect(params.orderedLessonIds, ['lesson_1', 'lesson_2', 'lesson_3']);
    });

    test('ReorderLessonsUsecase handles single lesson', () async {
      final params = ReorderLessonsParams(
        courseId: 'course_1',
        moduleId: 'module_1',
        orderedLessonIds: ['lesson_1'],
      );

      await usecase(params);

      expect(mockRepository.lastOrderedLessonIds?.length, 1);
      expect(mockRepository.lastOrderedLessonIds?[0], 'lesson_1');
    });

    test('ReorderLessonsUsecase handles many lessons', () async {
      final lessonIds = List.generate(10, (i) => 'lesson_$i');
      final params = ReorderLessonsParams(
        courseId: 'course_1',
        moduleId: 'module_1',
        orderedLessonIds: lessonIds,
      );

      await usecase(params);

      expect(mockRepository.lastOrderedLessonIds?.length, 10);
    });

    test(
      'ReorderLessonsUsecase handles different course and module IDs',
      () async {
        final params = ReorderLessonsParams(
          courseId: 'course_xyz',
          moduleId: 'module_abc',
          orderedLessonIds: ['lesson_a', 'lesson_b'],
        );

        await usecase(params);

        expect(mockRepository.lastReorderedCourseId, 'course_xyz');
        expect(mockRepository.lastReorderedModuleId, 'module_abc');
      },
    );
  });
}

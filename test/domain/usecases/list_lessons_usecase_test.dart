import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/list_lessons_usecase.dart';

class MockContentRepository implements ContentRepository {
  List<LessonEntity>? lessonsToReturn;
  Exception? errorToThrow;
  String? lastListLessonsCourseId;
  String? lastListLessonsModuleId;

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
  ) async {
    lastListLessonsCourseId = courseId;
    lastListLessonsModuleId = moduleId;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return lessonsToReturn ?? [];
  }

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
  group('ListLessonsUsecase Tests', () {
    late ListLessonsUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = ListLessonsUsecase(mockRepository);
    });

    test(
      'ListLessonsUsecase returns empty list when repository returns empty',
      () async {
        mockRepository.lessonsToReturn = [];

        final result = await usecase(
          courseId: 'course_1',
          moduleId: 'module_1',
        );

        expect(result, isEmpty);
      },
    );

    test('ListLessonsUsecase returns lessons from repository', () async {
      final testLessons = [
        LessonEntity(
          id: 'lesson_1',
          courseId: 'course_1',
          moduleId: 'module_1',
          title: 'Lesson 1',
          orderIndex: 1,
        ),
        LessonEntity(
          id: 'lesson_2',
          courseId: 'course_1',
          moduleId: 'module_1',
          title: 'Lesson 2',
          orderIndex: 2,
        ),
      ];
      mockRepository.lessonsToReturn = testLessons;

      final result = await usecase(courseId: 'course_1', moduleId: 'module_1');

      expect(result.length, 2);
      expect(result[0].id, 'lesson_1');
      expect(result[1].id, 'lesson_2');
    });

    test('ListLessonsUsecase calls repository with correct courseId', () async {
      mockRepository.lessonsToReturn = [];

      await usecase(courseId: 'course_1', moduleId: 'module_1');

      expect(mockRepository.lastListLessonsCourseId, 'course_1');
    });

    test('ListLessonsUsecase calls repository with correct moduleId', () async {
      mockRepository.lessonsToReturn = [];

      await usecase(courseId: 'course_1', moduleId: 'module_1');

      expect(mockRepository.lastListLessonsModuleId, 'module_1');
    });

    test(
      'ListLessonsUsecase throws exception when repository throws',
      () async {
        mockRepository.errorToThrow = Exception('Network error');

        expect(
          () => usecase(courseId: 'course_1', moduleId: 'module_1'),
          throwsException,
        );
      },
    );

    test('ListLessonsUsecase handles single lesson', () async {
      final testLesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Single Lesson',
        orderIndex: 1,
      );
      mockRepository.lessonsToReturn = [testLesson];

      final result = await usecase(courseId: 'course_1', moduleId: 'module_1');

      expect(result.length, 1);
      expect(result[0].id, 'lesson_1');
    });

    test('ListLessonsUsecase handles many lessons', () async {
      final testLessons = List.generate(
        50,
        (index) => LessonEntity(
          id: 'lesson_$index',
          courseId: 'course_1',
          moduleId: 'module_1',
          title: 'Lesson $index',
          orderIndex: index,
        ),
      );
      mockRepository.lessonsToReturn = testLessons;

      final result = await usecase(courseId: 'course_1', moduleId: 'module_1');

      expect(result.length, 50);
    });

    test('ListLessonsUsecase preserves lesson data from repository', () async {
      final testLesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Test Lesson',
        objectives: 'Test Objectives',
        orderIndex: 1,
      );
      mockRepository.lessonsToReturn = [testLesson];

      final result = await usecase(courseId: 'course_1', moduleId: 'module_1');

      expect(result[0].id, testLesson.id);
      expect(result[0].courseId, testLesson.courseId);
      expect(result[0].moduleId, testLesson.moduleId);
      expect(result[0].title, testLesson.title);
      expect(result[0].objectives, testLesson.objectives);
      expect(result[0].orderIndex, testLesson.orderIndex);
    });

    test('ListLessonsUsecase handles special characters in courseId', () async {
      mockRepository.lessonsToReturn = [];

      await usecase(courseId: 'course_ñáéíóú', moduleId: 'module_1');

      expect(mockRepository.lastListLessonsCourseId, 'course_ñáéíóú');
    });

    test('ListLessonsUsecase handles special characters in moduleId', () async {
      mockRepository.lessonsToReturn = [];

      await usecase(courseId: 'course_1', moduleId: 'module_ñáéíóú');

      expect(mockRepository.lastListLessonsModuleId, 'module_ñáéíóú');
    });
  });
}

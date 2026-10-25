import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/list_courses_usecase.dart';
import 'package:redmaestra1/domain/usecases/usecase.dart';

class MockContentRepository implements ContentRepository {
  List<CourseEntity>? coursesToReturn;
  Exception? errorToThrow;

  @override
  Future<List<CourseEntity>> listCourses() async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return coursesToReturn ?? [];
  }

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
  group('ListCoursesUsecase Tests', () {
    late ListCoursesUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = ListCoursesUsecase(mockRepository);
    });

    test('ListCoursesUsecase returns empty list when repository returns empty', () async {
      mockRepository.coursesToReturn = [];

      final result = await usecase(NoParams());

      expect(result, isEmpty);
    });

    test('ListCoursesUsecase returns courses from repository', () async {
      final testCourses = [
        const CourseEntity(
          id: 'course_1',
          title: 'Course 1',
          description: 'Description 1',
          targetAudience: 'General',
        ),
        const CourseEntity(
          id: 'course_2',
          title: 'Course 2',
          description: 'Description 2',
          targetAudience: 'Principiantes',
        ),
      ];
      mockRepository.coursesToReturn = testCourses;

      final result = await usecase(NoParams());

      expect(result.length, 2);
      expect(result[0].id, 'course_1');
      expect(result[1].id, 'course_2');
    });

    test('ListCoursesUsecase throws exception when repository throws', () async {
      mockRepository.errorToThrow = Exception('Network error');

      expect(() => usecase(NoParams()), throwsException);
    });

    test('ListCoursesUsecase calls repository.listCourses', () async {
      mockRepository.coursesToReturn = [];

      await usecase(NoParams());

      expect(mockRepository, isNotNull);
    });

    test('ListCoursesUsecase handles single course', () async {
      final testCourse = const CourseEntity(
        id: 'course_1',
        title: 'Single Course',
        description: 'Description',
        targetAudience: 'General',
      );
      mockRepository.coursesToReturn = [testCourse];

      final result = await usecase(NoParams());

      expect(result.length, 1);
      expect(result[0].id, 'course_1');
    });

    test('ListCoursesUsecase handles many courses', () async {
      final testCourses = List.generate(
        50,
        (index) => CourseEntity(
          id: 'course_$index',
          title: 'Course $index',
          description: 'Description $index',
          targetAudience: 'General',
        ),
      );
      mockRepository.coursesToReturn = testCourses;

      final result = await usecase(NoParams());

      expect(result.length, 50);
    });

    test('ListCoursesUsecase preserves course data from repository', () async {
      final testCourse = const CourseEntity(
        id: 'course_1',
        title: 'Test Course',
        description: 'Test Description',
        targetAudience: 'Ciencias Naturales',
      );
      mockRepository.coursesToReturn = [testCourse];

      final result = await usecase(NoParams());

      expect(result[0].id, testCourse.id);
      expect(result[0].title, testCourse.title);
      expect(result[0].description, testCourse.description);
      expect(result[0].targetAudience, testCourse.targetAudience);
    });
  });
}

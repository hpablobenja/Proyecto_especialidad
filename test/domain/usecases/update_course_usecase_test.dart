import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/update_course_usecase.dart';

class MockContentRepository implements ContentRepository {
  CourseEntity? courseToReturn;
  Exception? errorToThrow;
  CourseEntity? lastUpdatedCourse;

  @override
  Future<List<CourseEntity>> listCourses() async => [];

  @override
  Future<CourseEntity> createCourse(CourseEntity course) async => course;

  @override
  Future<CourseEntity> updateCourse(CourseEntity course) async {
    lastUpdatedCourse = course;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return courseToReturn ?? course;
  }

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
  group('UpdateCourseUsecase Tests', () {
    late UpdateCourseUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = UpdateCourseUsecase(mockRepository);
    });

    test('UpdateCourseUsecase calls repository with correct course', () async {
      final course = CourseEntity(
        id: 'course_1',
        title: 'Updated Title',
        description: 'Updated Description',
        targetAudience: 'General',
      );

      await usecase(course);

      expect(mockRepository.lastUpdatedCourse?.id, 'course_1');
    });

    test('UpdateCourseUsecase returns course from repository', () async {
      final course = CourseEntity(
        id: 'course_1',
        title: 'Updated Title',
        description: 'Updated Description',
        targetAudience: 'General',
      );

      final result = await usecase(course);

      expect(result.id, 'course_1');
    });

    test('UpdateCourseUsecase throws exception when repository throws', () async {
      mockRepository.errorToThrow = Exception('Update failed');
      final course = CourseEntity(
        id: 'course_1',
        title: 'Title',
        description: 'Description',
        targetAudience: 'General',
      );

      expect(() => usecase(course), throwsException);
    });

    test('UpdateCourseUsecase preserves all course fields', () async {
      final course = CourseEntity(
        id: 'course_1',
        title: 'Test Course',
        description: 'Test Description',
        targetAudience: 'Ciencias Naturales',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        status: 'published',
      );

      await usecase(course);

      expect(mockRepository.lastUpdatedCourse?.id, 'course_1');
      expect(mockRepository.lastUpdatedCourse?.title, 'Test Course');
      expect(mockRepository.lastUpdatedCourse?.description, 'Test Description');
      expect(mockRepository.lastUpdatedCourse?.targetAudience, 'Ciencias Naturales');
      expect(mockRepository.lastUpdatedCourse?.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(mockRepository.lastUpdatedCourse?.status, 'published');
    });

    test('UpdateCourseUsecase handles course with null thumbnailUrl', () async {
      final course = CourseEntity(
        id: 'course_1',
        title: 'Test Course',
        description: 'Description',
        targetAudience: 'General',
      );

      await usecase(course);

      expect(mockRepository.lastUpdatedCourse?.thumbnailUrl, null);
    });

    test('UpdateCourseUsecase handles special characters in title', () async {
      final course = CourseEntity(
        id: 'course_1',
        title: 'Curso de Matemáticas ñáéíóú',
        description: 'Description',
        targetAudience: 'General',
      );

      await usecase(course);

      expect(mockRepository.lastUpdatedCourse?.title, 'Curso de Matemáticas ñáéíóú');
    });
  });
}

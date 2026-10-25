import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/list_courses_usecase.dart' as content_list;
import 'package:redmaestra1/domain/usecases/content/create_course_usecase.dart' as content_create_course;
import 'package:redmaestra1/domain/usecases/content/update_course_usecase.dart' as content_update_course;
import 'package:redmaestra1/domain/usecases/content/delete_course_usecase.dart' as content_delete_course;
import 'package:redmaestra1/domain/usecases/usecase.dart';
import 'package:redmaestra1/presentation/providers/content_provider.dart';

class FakeListCoursesUsecase extends content_list.ListCoursesUsecase {
  List<CourseEntity>? coursesToReturn;
  Exception? errorToThrow;

  FakeListCoursesUsecase() : super(FakeContentRepository());

  void setResponse(List<CourseEntity> courses) {
    coursesToReturn = courses;
  }

  void setError(Object error) {
    errorToThrow = Exception(error);
  }

  @override
  Future<List<CourseEntity>> call(NoParams params) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return coursesToReturn ?? [];
  }
}

class FakeCreateCourseUsecase extends content_create_course.CreateCourseUsecase {
  CourseEntity? courseToReturn;
  Exception? errorToThrow;

  FakeCreateCourseUsecase() : super(FakeContentRepository());

  void setResponse(CourseEntity course) {
    courseToReturn = course;
  }

  void setError(Object error) {
    errorToThrow = Exception(error);
  }

  @override
  Future<CourseEntity> call(CourseEntity params) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return courseToReturn ?? params;
  }
}

class FakeUpdateCourseUsecase extends content_update_course.UpdateCourseUsecase {
  CourseEntity? courseToReturn;
  Exception? errorToThrow;

  FakeUpdateCourseUsecase() : super(FakeContentRepository());

  void setResponse(CourseEntity course) {
    courseToReturn = course;
  }

  void setError(Object error) {
    errorToThrow = Exception(error);
  }

  @override
  Future<CourseEntity> call(CourseEntity params) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return courseToReturn ?? params;
  }
}

class FakeDeleteCourseUsecase extends content_delete_course.DeleteCourseUsecase {
  Exception? errorToThrow;

  FakeDeleteCourseUsecase() : super(FakeContentRepository());

  void setError(Object error) {
    errorToThrow = Exception(error);
  }

  @override
  Future<void> call(content_delete_course.DeleteCourseParams params) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }
}

class FakeContentRepository implements ContentRepository {
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
  group('ContentProvider Tests', () {
    late ContentProvider provider;
    late FakeListCoursesUsecase fakeListCoursesUsecase;
    late FakeCreateCourseUsecase fakeCreateCourseUsecase;
    late FakeUpdateCourseUsecase fakeUpdateCourseUsecase;
    late FakeDeleteCourseUsecase fakeDeleteCourseUsecase;

    setUp(() {
      fakeListCoursesUsecase = FakeListCoursesUsecase();
      fakeCreateCourseUsecase = FakeCreateCourseUsecase();
      fakeUpdateCourseUsecase = FakeUpdateCourseUsecase();
      fakeDeleteCourseUsecase = FakeDeleteCourseUsecase();
      
      provider = ContentProvider(
        listCoursesUsecase: fakeListCoursesUsecase,
        createCourseUsecase: fakeCreateCourseUsecase,
        updateCourseUsecase: fakeUpdateCourseUsecase,
        deleteCourseUsecase: fakeDeleteCourseUsecase,
      );
    });

    test('ContentProvider initializes with default values', () {
      expect(provider.isLoading, false);
      expect(provider.errorMessage, null);
      expect(provider.courses, isEmpty);
    });

    test('loadCourses loads courses successfully', () async {
      final testCourses = [
        const CourseEntity(
          id: 'course_1',
          title: 'Course 1',
          description: 'Description 1',
          targetAudience: 'General',
        ),
      ];
      fakeListCoursesUsecase.setResponse(testCourses);

      await provider.loadCourses();

      expect(provider.courses.length, 1);
      expect(provider.courses[0].id, 'course_1');
      expect(provider.isLoading, false);
    });

    test('loadCourses sets error on failure', () async {
      fakeListCoursesUsecase.setError('Network error');

      await provider.loadCourses();

      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('No se pudieron cargar los cursos'));
      expect(provider.isLoading, false);
    });

    test('createCourse adds course to list', () async {
      final newCourse = CourseEntity(
        id: 'new_course',
        title: 'New Course',
        description: 'Description',
        targetAudience: 'General',
      );
      fakeCreateCourseUsecase.setResponse(newCourse);

      final result = await provider.createCourse(newCourse);

      expect(result?.id, 'new_course');
      expect(provider.courses.length, 1);
      expect(provider.isLoading, false);
    });

    test('createCourse sets error on failure', () async {
      fakeCreateCourseUsecase.setError('Create failed');
      final course = CourseEntity(
        id: 'new_course',
        title: 'New Course',
        description: 'Description',
        targetAudience: 'General',
      );

      final result = await provider.createCourse(course);

      expect(result, null);
      expect(provider.errorMessage, contains('No se pudo crear el curso'));
    });

    test('updateCourse updates course in list', () async {
      final originalCourse = CourseEntity(
        id: 'course_1',
        title: 'Original Title',
        description: 'Description',
        targetAudience: 'General',
      );
      final updatedCourse = CourseEntity(
        id: 'course_1',
        title: 'Updated Title',
        description: 'Description',
        targetAudience: 'General',
      );
      fakeListCoursesUsecase.setResponse([originalCourse]);
      fakeUpdateCourseUsecase.setResponse(updatedCourse);

      await provider.loadCourses();
      final result = await provider.updateCourse(updatedCourse);

      expect(result?.title, 'Updated Title');
      expect(provider.courses[0].title, 'Updated Title');
    });

    test('updateCourse sets error on failure', () async {
      fakeUpdateCourseUsecase.setError('Update failed');
      final course = CourseEntity(
        id: 'course_1',
        title: 'Title',
        description: 'Description',
        targetAudience: 'General',
      );

      final result = await provider.updateCourse(course);

      expect(result, null);
      expect(provider.errorMessage, contains('No se pudo actualizar el curso'));
    });

    test('deleteCourse removes course from list', () async {
      final courses = [
        CourseEntity(
          id: 'course_1',
          title: 'Course 1',
          description: 'Description',
          targetAudience: 'General',
        ),
        CourseEntity(
          id: 'course_2',
          title: 'Course 2',
          description: 'Description',
          targetAudience: 'General',
        ),
      ];
      fakeListCoursesUsecase.setResponse(courses);

      await provider.loadCourses();
      final result = await provider.deleteCourse('course_1');

      expect(result, true);
      expect(provider.courses.length, 1);
      expect(provider.courses[0].id, 'course_2');
    });

    test('deleteCourse sets error on failure', () async {
      fakeDeleteCourseUsecase.setError('Delete failed');

      final result = await provider.deleteCourse('course_1');

      expect(result, false);
      expect(provider.errorMessage, contains('No se pudo eliminar el curso'));
    });
  });
}

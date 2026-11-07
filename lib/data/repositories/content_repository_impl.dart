// lib/data/repositories/content_repository_impl.dart

import '../../domain/entities/course_entity.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/media_resource.dart';
import '../../domain/entities/module_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/content_repository.dart';
import '../datasources/remote/content_remote_datasource.dart';

class ContentRepositoryImpl implements ContentRepository {
  final ContentRemoteDataSource remote;
  ContentRepositoryImpl(this.remote);

  // Courses
  @override
  Future<CourseEntity> createCourse(CourseEntity course) =>
      remote.createCourse(course);

  @override
  Future<void> deleteCourse(String courseId) => remote.deleteCourse(courseId);

  @override
  Future<List<CourseEntity>> listCourses() => remote.listCourses();

  @override
  Future<CourseEntity> updateCourse(CourseEntity course) =>
      remote.updateCourse(course);

  // Modules
  @override
  Future<List<ModuleEntity>> listModules(String courseId) =>
      remote.listModules(courseId);

  @override
  Future<ModuleEntity> createModule(ModuleEntity module) =>
      remote.createModule(module);

  @override
  Future<void> deleteModule(String courseId, String moduleId) =>
      remote.deleteModule(courseId, moduleId);

  @override
  Future<void> reorderModules(String courseId, List<String> orderedModuleIds) =>
      remote.reorderModules(courseId, orderedModuleIds);

  @override
  Future<void> updateModule(ModuleEntity module) => remote.updateModule(module);

  // Lessons
  @override
  Future<List<LessonEntity>> listLessons(String courseId, String moduleId) =>
      remote.listLessons(courseId, moduleId);

  @override
  Future<LessonEntity> createLesson(LessonEntity lesson) =>
      remote.createLesson(lesson);

  @override
  Future<void> deleteLesson(
    String courseId,
    String moduleId,
    String lessonId,
  ) => remote.deleteLesson(courseId, moduleId, lessonId);

  @override
  Future<void> reorderLessons(
    String courseId,
    String moduleId,
    List<String> orderedLessonIds,
  ) => remote.reorderLessons(courseId, moduleId, orderedLessonIds);

  @override
  Future<void> updateLesson(LessonEntity lesson) => remote.updateLesson(lesson);

  // Media
  @override
  Future<void> deleteMedia({
    required String courseId,
    required String? moduleId,
    required String? lessonId,
    required String mediaId,
  }) => remote.deleteMedia(
    courseId: courseId,
    moduleId: moduleId,
    lessonId: lessonId,
    mediaId: mediaId,
  );

  @override
  Future<MediaResource> uploadMedia({
    required String courseId,
    required String? moduleId,
    required String? lessonId,
    required MediaUploadRequest request,
  }) => remote.uploadMedia(
    courseId: courseId,
    moduleId: moduleId,
    lessonId: lessonId,
    request: request,
  );

  // Comments
  @override
  Future<List<CommentEntity>> listComments({
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) => remote.listComments(
    courseId: courseId,
    moduleId: moduleId,
    lessonId: lessonId,
  );

  @override
  Future<CommentEntity> addComment(CommentEntity comment) =>
      remote.addComment(comment);

  @override
  Future<void> deleteComment({
    required String courseId,
    required String moduleId,
    required String lessonId,
    required String commentId,
  }) => remote.deleteComment(
    courseId: courseId,
    moduleId: moduleId,
    lessonId: lessonId,
    commentId: commentId,
  );
}

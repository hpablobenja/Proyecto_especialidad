// lib/domain/repositories/content_repository.dart

import '../entities/course_entity.dart';
import '../entities/module_entity.dart';
import '../entities/lesson_entity.dart';
import '../entities/media_resource.dart';
import '../entities/comment_entity.dart';

abstract class ContentRepository {
  // Courses
  Future<List<CourseEntity>> listCourses();
  Future<CourseEntity> createCourse(CourseEntity course);
  Future<CourseEntity> updateCourse(CourseEntity course);
  Future<void> deleteCourse(String courseId);

  // Modules
  Future<List<ModuleEntity>> listModules(String courseId);
  Future<ModuleEntity> createModule(ModuleEntity module);
  Future<void> updateModule(ModuleEntity module);
  Future<void> deleteModule(String courseId, String moduleId);
  Future<void> reorderModules(String courseId, List<String> orderedModuleIds);

  // Lessons
  Future<List<LessonEntity>> listLessons(String courseId, String moduleId);
  Future<LessonEntity> createLesson(LessonEntity lesson);
  Future<void> updateLesson(LessonEntity lesson);
  Future<void> deleteLesson(String courseId, String moduleId, String lessonId);
  Future<void> reorderLessons(
    String courseId,
    String moduleId,
    List<String> orderedLessonIds,
  );

  // Media uploads
  Future<MediaResource> uploadMedia({
    required String courseId,
    required String? moduleId,
    required String? lessonId,
    required MediaUploadRequest request,
  });
  Future<void> deleteMedia({
    required String courseId,
    required String? moduleId,
    required String? lessonId,
    required String mediaId,
  });

  // Comments
  Future<List<CommentEntity>> listComments({
    required String courseId,
    required String moduleId,
    required String lessonId,
  });
  Future<CommentEntity> addComment(CommentEntity comment);
  Future<void> deleteComment({
    required String courseId,
    required String moduleId,
    required String lessonId,
    required String commentId,
  });
}

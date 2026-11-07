// lib/core/services/offline_cache_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../domain/entities/course_entity.dart';
import '../../domain/entities/module_entity.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/media_resource.dart';
import '../../domain/entities/checkpoint_entity.dart';
import '../../domain/entities/question_entity.dart';

class OfflineCacheService {
  static const String _lastCourseKey = 'last_accessed_course';
  static const String _lastModuleKey = 'last_accessed_module';
  static const String _lastLessonKey = 'last_accessed_lesson';
  static const String _lastModulesKey = 'last_accessed_modules';
  static const String _lastLessonsKey = 'last_accessed_lessons';
  static const String _quizQuestionsKey = 'cached_quiz_questions';

  // Cache last accessed course
  Future<void> cacheLastCourse(CourseEntity course) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final courseJson = jsonEncode({
        'id': course.id,
        'title': course.title,
        'description': course.description,
        'targetAudience': course.targetAudience,
        'status': course.status,
      });
      await prefs.setString(_lastCourseKey, courseJson);
    } catch (e) {
      // Silently fail
    }
  }

  // Cache last accessed module
  Future<void> cacheLastModule(ModuleEntity module) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final moduleJson = jsonEncode({
        'id': module.id,
        'courseId': module.courseId,
        'title': module.title,
        'description': module.description,
        'orderIndex': module.orderIndex,
      });
      await prefs.setString(_lastModuleKey, moduleJson);
    } catch (e) {
      // Silently fail
    }
  }

  // Cache last accessed lesson (including media, checkpoints, strategies)
  Future<void> cacheLastLesson(LessonEntity lesson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lessonJson = jsonEncode({
        'id': lesson.id,
        'courseId': lesson.courseId,
        'moduleId': lesson.moduleId,
        'title': lesson.title,
        'objectives': lesson.objectives,
        'strategies': lesson.strategies,
        'orderIndex': lesson.orderIndex,
        'media': lesson.media.map((m) => m.toMap()).toList(),
        'checkpoints': lesson.checkpoints?.map((c) => c.toMap()).toList(),
      });
      await prefs.setString(_lastLessonKey, lessonJson);
      // Also cache specifically by lesson id
      await prefs.setString('${_lastLessonKey}_${lesson.id}', lessonJson);
    } catch (e) {
      // Silently fail
    }
  }

  // Cache modules for a course
  Future<void> cacheModules(String courseId, List<ModuleEntity> modules) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modulesJson =
          modules
              .map(
                (m) => {
                  'id': m.id,
                  'courseId': m.courseId,
                  'title': m.title,
                  'description': m.description,
                  'orderIndex': m.orderIndex,
                },
              )
              .toList();
      await prefs.setString(
        '${_lastModulesKey}_$courseId',
        jsonEncode(modulesJson),
      );
    } catch (e) {
      // Silently fail
    }
  }

  // Cache lessons for a module
  Future<void> cacheLessonsForModule(
    String moduleId,
    List<LessonEntity> lessons,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lessonsJson =
          lessons
              .map(
                (l) => {
                  'id': l.id,
                  'courseId': l.courseId,
                  'moduleId': l.moduleId,
                  'title': l.title,
                  'objectives': l.objectives,
                  'strategies': l.strategies,
                  'orderIndex': l.orderIndex,
                  'media': l.media.map((m) => m.toMap()).toList(),
                  'checkpoints': l.checkpoints?.map((c) => c.toMap()).toList(),
                },
              )
              .toList();
      await prefs.setString(
        '${_lastLessonsKey}_$moduleId',
        jsonEncode(lessonsJson),
      );
    } catch (e) {
      // Silently fail
    }
  }

  // Cache quiz questions for a lesson
  Future<void> cacheQuizQuestions(
    String lessonId,
    List<QuestionEntity> questions,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final questionsJson = questions.map((q) => q.toMap()).toList();
      await prefs.setString(
        '${_quizQuestionsKey}_$lessonId',
        jsonEncode(questionsJson),
      );
    } catch (e) {
      // Silently fail
    }
  }

  // Get cached quiz questions for a lesson
  Future<List<QuestionEntity>> getCachedQuizQuestions(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('${_quizQuestionsKey}_$lessonId');
      if (jsonStr == null) return [];
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((q) => QuestionEntity.fromMap(q as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get last accessed course
  Future<CourseEntity?> getLastCourse() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final courseJson = prefs.getString(_lastCourseKey);
      if (courseJson == null) return null;

      final data = jsonDecode(courseJson);
      return CourseEntity(
        id: data['id'],
        title: data['title'],
        description: data['description'],
        targetAudience: data['targetAudience'] ?? 'General',
        status: data['status'] ?? 'published',
      );
    } catch (e) {
      return null;
    }
  }

  // Get last accessed module
  Future<ModuleEntity?> getLastModule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final moduleJson = prefs.getString(_lastModuleKey);
      if (moduleJson == null) return null;

      final data = jsonDecode(moduleJson);
      return ModuleEntity(
        id: data['id'],
        courseId: data['courseId'],
        title: data['title'],
        description: data['description'],
        orderIndex: data['orderIndex'],
      );
    } catch (e) {
      return null;
    }
  }

  // Get last accessed lesson
  Future<LessonEntity?> getLastLesson({String? lessonId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key =
          lessonId != null ? '${_lastLessonKey}_$lessonId' : _lastLessonKey;
      final lessonJson = prefs.getString(key);
      if (lessonJson == null) return null;

      final data = jsonDecode(lessonJson);
      return _parseLesson(data);
    } catch (e) {
      return null;
    }
  }

  // Get cached lessons for a module
  Future<List<LessonEntity>> getCachedLessons(String moduleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('${_lastLessonsKey}_$moduleId');
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((item) => _parseLesson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get cached modules for a course
  Future<List<ModuleEntity>> getCachedModules(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modulesJson = prefs.getString('${_lastModulesKey}_$courseId');
      if (modulesJson == null) return [];

      final List<dynamic> data = jsonDecode(modulesJson);
      return data
          .map(
            (m) => ModuleEntity(
              id: m['id'],
              courseId: m['courseId'],
              title: m['title'],
              description: m['description'],
              orderIndex: m['orderIndex'],
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  LessonEntity _parseLesson(Map<String, dynamic> data) {
    return LessonEntity(
      id: data['id'],
      courseId: data['courseId'],
      moduleId: data['moduleId'],
      title: data['title'],
      objectives: data['objectives'],
      media:
          (data['media'] as List<dynamic>?)
              ?.map((m) => MediaResource.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      strategies:
          (data['strategies'] as List<dynamic>?)
              ?.map(
                (e) => (e as Map).map(
                  (key, value) => MapEntry(key.toString(), value.toString()),
                ),
              )
              .toList() ??
          [],
      orderIndex: data['orderIndex'],
      checkpoints:
          (data['checkpoints'] as List<dynamic>?)
              ?.map((c) => CheckpointEntity.fromMap(c as Map<String, dynamic>))
              .toList(),
    );
  }
}

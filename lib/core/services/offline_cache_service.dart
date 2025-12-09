// lib/core/services/offline_cache_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../domain/entities/course_entity.dart';
import '../../domain/entities/module_entity.dart';
import '../../domain/entities/lesson_entity.dart';

class OfflineCacheService {
  static const String _lastCourseKey = 'last_accessed_course';
  static const String _lastModuleKey = 'last_accessed_module';
  static const String _lastLessonKey = 'last_accessed_lesson';
  static const String _lastModulesKey = 'last_accessed_modules';

  // Cache last accessed course
  Future<void> cacheLastCourse(CourseEntity course) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final courseJson = jsonEncode({
        'id': course.id,
        'title': course.title,
        'description': course.description,
        'thumbnailUrl': course.thumbnailUrl,
        'targetAudience': course.targetAudience,
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

  // Cache last accessed lesson
  Future<void> cacheLastLesson(LessonEntity lesson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lessonJson = jsonEncode({
        'id': lesson.id,
        'courseId': lesson.courseId,
        'moduleId': lesson.moduleId,
        'title': lesson.title,
        'contentDelta': lesson.contentDelta,
        'objectives': lesson.objectives,
        'strategies': lesson.strategies,
        'orderIndex': lesson.orderIndex,
      });
      await prefs.setString(_lastLessonKey, lessonJson);
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
        thumbnailUrl: data['thumbnailUrl'],
        targetAudience: data['targetAudience'],
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
  Future<LessonEntity?> getLastLesson() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lessonJson = prefs.getString(_lastLessonKey);
      if (lessonJson == null) return null;

      final data = jsonDecode(lessonJson);
      return LessonEntity(
        id: data['id'],
        courseId: data['courseId'],
        moduleId: data['moduleId'],
        title: data['title'],
        contentDelta: data['contentDelta'],
        objectives: data['objectives'],
        media: [], // Not cached for offline
        downloadableResources: [], // Not cached for offline
        //strategies: (data['strategies'] as List?)?.cast<Map<String, dynamic>>() ?? [],
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
      );
    } catch (e) {
      return null;
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
}

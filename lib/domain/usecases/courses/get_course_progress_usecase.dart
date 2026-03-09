// lib/domain/usecases/courses/get_course_progress_usecase.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../usecase.dart';
import '../../entities/course_entity.dart';
import '../../entities/lesson_progress_entity.dart';
import '../../repositories/course_repository.dart';

class CourseProgressDetail {
  final CourseEntity course;
  final Map<String, String> moduleTitles; // moduleId -> title
  final Map<String, Map<String, String>> lessonTitles; // moduleId -> lessonId -> title
  final Map<String, Map<String, LessonProgressEntity>> progress; // moduleId -> lessonId -> progress

  CourseProgressDetail({
    required this.course,
    required this.moduleTitles,
    required this.lessonTitles,
    required this.progress,
  });
}

class UserProgress {
  final List<CourseProgressDetail> completedCourses;
  final List<CourseProgressDetail> inProgressCourses;

  UserProgress({
    required this.completedCourses,
    required this.inProgressCourses,
  });
}

class GetCourseProgressUsecase implements Usecase<UserProgress, String> {
  final CourseRepository repository;
  final FirebaseFirestore firestore;

  GetCourseProgressUsecase(this.repository, {FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserProgress> call(String userId) async {
    final allCourses = await repository.getCourses();
    
    // Obtener el progreso del usuario
    final progressSnapshot = await firestore
        .collection('userProgress')
        .where('userId', isEqualTo: userId)
        .get();

    final progressMap = <String, LessonProgressEntity>{};
    for (var doc in progressSnapshot.docs) {
      final data = doc.data();
      progressMap[doc.id] = LessonProgressEntity.fromMap(data);
    }

    final courseProgressMap = <String, Map<String, Map<String, LessonProgressEntity>>>{};
    for (var progress in progressMap.values) {
      if (!courseProgressMap.containsKey(progress.courseId)) {
        courseProgressMap[progress.courseId] = {};
      }
      if (!courseProgressMap[progress.courseId]!.containsKey(progress.moduleId)) {
        courseProgressMap[progress.courseId]![progress.moduleId] = {};
      }
      courseProgressMap[progress.courseId]![progress.moduleId]![progress.lessonId] = progress;
    }

    List<CourseProgressDetail> allStructuredCourses = [];

    for (var course in allCourses) {
      if (!courseProgressMap.containsKey(course.id)) continue;
      
      final moduleTitles = <String, String>{};
      final lessonTitles = <String, Map<String, String>>{};
      
      // Modules still live nested under courses/{courseId}/modules
      final modulesSnapshot = await firestore
          .collection('courses')
          .doc(course.id)
          .collection('modules')
          .get();

      final sortedModules = modulesSnapshot.docs.toList()
        ..sort((a, b) =>
            ((a.data()['orderIndex'] as num?) ?? 0)
                .compareTo((b.data()['orderIndex'] as num?) ?? 0));
          
      for (var moduleDoc in sortedModules) {
        final moduleId = moduleDoc.id;
        moduleTitles[moduleId] = moduleDoc.data()['title'] as String? ?? 'Sin título';
        
        // Lessons are now in the root /lecciones collection
        final lessonsSnapshot = await firestore
            .collection('lecciones')
            .where('courseId', isEqualTo: course.id)
            .where('moduleId', isEqualTo: moduleId)
            .get();

        final sortedLessons = lessonsSnapshot.docs.toList()
          ..sort((a, b) =>
              ((a.data()['orderIndex'] as num?) ?? 0)
                  .compareTo((b.data()['orderIndex'] as num?) ?? 0));
            
        lessonTitles[moduleId] = {};
        for (var lessonDoc in sortedLessons) {
          lessonTitles[moduleId]![lessonDoc.id] = lessonDoc.data()['title'] as String? ?? 'Sin título';
        }
      }
      
      allStructuredCourses.add(CourseProgressDetail(
        course: course,
        moduleTitles: moduleTitles,
        lessonTitles: lessonTitles,
        progress: courseProgressMap[course.id]!,
      ));
    }
    
    List<CourseProgressDetail> completed = [];
    List<CourseProgressDetail> inProgress = [];
    
    for (var cp in allStructuredCourses) {
      bool allLessonsCompleted = true;
      bool hasAnyProgress = false;
      
      for (var moduleId in cp.lessonTitles.keys) {
        for (var lessonId in cp.lessonTitles[moduleId]!.keys) {
           final prog = cp.progress[moduleId]?[lessonId];
           if (prog == null || prog.status != LessonProgressStatus.completed) {
             allLessonsCompleted = false;
           }
           if (prog != null) {
             hasAnyProgress = true;
           }
        }
      }
      
      if (allLessonsCompleted && hasAnyProgress && cp.moduleTitles.isNotEmpty) {
        completed.add(cp);
      } else if (hasAnyProgress || cp.progress.isNotEmpty) {
        inProgress.add(cp);
      }
    }

    return UserProgress(
      completedCourses: completed,
      inProgressCourses: inProgress,
    );
  }
}

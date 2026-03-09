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
    // 1. Ejecutar en paralelo: cursos + progreso del usuario
    final results = await Future.wait([
      repository.getCourses(),
      firestore
          .collection('userProgress')
          .where('userId', isEqualTo: userId)
          .get(),
    ]);

    final allCourses = results[0] as List<CourseEntity>;
    final progressSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;

    // Mapear progreso por (courseId -> moduleId -> lessonId)
    final courseProgressMap =
        <String, Map<String, Map<String, LessonProgressEntity>>>{};
    for (var doc in progressSnapshot.docs) {
      final progress = LessonProgressEntity.fromMap(doc.data());
      courseProgressMap
          .putIfAbsent(progress.courseId, () => {})
          .putIfAbsent(progress.moduleId, () => {})[progress.lessonId] =
          progress;
    }

    // 2. Filtrar solo cursos con progreso y cargar sus módulos EN PARALELO
    final coursesWithProgress =
        allCourses.where((c) => courseProgressMap.containsKey(c.id)).toList();

    final modulesSnapshots = await Future.wait(
      coursesWithProgress.map(
        (course) => firestore
            .collection('courses')
            .doc(course.id)
            .collection('modules')
            .get(),
      ),
    );

    // 3. Construir lista de consultas de lecciones TODAS en paralelo
    // Primero recolectamos qué lecciones necesitamos consultar
    final lessonQueries = <({String courseId, String moduleId, Future<QuerySnapshot<Map<String, dynamic>>> query})>[];

    final courseModuleMap = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (var i = 0; i < coursesWithProgress.length; i++) {
      final course = coursesWithProgress[i];
      final sortedModules = modulesSnapshots[i].docs.toList()
        ..sort((a, b) =>
            ((a.data()['orderIndex'] as num?) ?? 0)
                .compareTo((b.data()['orderIndex'] as num?) ?? 0));
      courseModuleMap[course.id] = sortedModules;

      for (var moduleDoc in sortedModules) {
        lessonQueries.add((
          courseId: course.id,
          moduleId: moduleDoc.id,
          query: firestore
              .collection('lecciones')
              .where('courseId', isEqualTo: course.id)
              .where('moduleId', isEqualTo: moduleDoc.id)
              .get(),
        ));
      }
    }

    // Ejecutar TODAS las consultas de lecciones en paralelo
    final lessonSnapshots = await Future.wait(
      lessonQueries.map((q) => q.query),
    );

    // Indexar resultados de lecciones por (courseId, moduleId)
    final lessonResultMap =
        <String, Map<String, QuerySnapshot<Map<String, dynamic>>>>{};
    for (var i = 0; i < lessonQueries.length; i++) {
      final q = lessonQueries[i];
      lessonResultMap
          .putIfAbsent(q.courseId, () => {})[q.moduleId] = lessonSnapshots[i];
    }

    // 4. Armar CourseProgressDetail para cada curso
    final List<CourseProgressDetail> allStructuredCourses = [];

    for (var course in coursesWithProgress) {
      final moduleTitles = <String, String>{};
      final lessonTitles = <String, Map<String, String>>{};

      for (var moduleDoc in courseModuleMap[course.id]!) {
        final moduleId = moduleDoc.id;
        moduleTitles[moduleId] =
            moduleDoc.data()['title'] as String? ?? 'Sin título';

        final lessonsSnap = lessonResultMap[course.id]?[moduleId];
        if (lessonsSnap != null) {
          final sortedLessons = lessonsSnap.docs.toList()
            ..sort((a, b) =>
                ((a.data()['orderIndex'] as num?) ?? 0)
                    .compareTo((b.data()['orderIndex'] as num?) ?? 0));
          lessonTitles[moduleId] = {
            for (var doc in sortedLessons)
              doc.id: doc.data()['title'] as String? ?? 'Sin título',
          };
        } else {
          lessonTitles[moduleId] = {};
        }
      }

      allStructuredCourses.add(CourseProgressDetail(
        course: course,
        moduleTitles: moduleTitles,
        lessonTitles: lessonTitles,
        progress: courseProgressMap[course.id]!,
      ));
    }

    // 5. Clasificar en completados vs en curso
    final List<CourseProgressDetail> completed = [];
    final List<CourseProgressDetail> inProgress = [];

    for (var cp in allStructuredCourses) {
      bool allLessonsCompleted = true;
      bool hasAnyProgress = false;

      for (var moduleId in cp.lessonTitles.keys) {
        for (var lessonId in cp.lessonTitles[moduleId]!.keys) {
          final prog = cp.progress[moduleId]?[lessonId];
          if (prog == null || prog.status != LessonProgressStatus.completed) {
            allLessonsCompleted = false;
          }
          if (prog != null) hasAnyProgress = true;
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

// lib/domain/usecases/reports/generate_pdf_report_usecase.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../usecase.dart';
import '../../repositories/course_repository.dart';
import '../../entities/lesson_progress_entity.dart';

class GeneratePdfReportUsecase implements Usecase<List<int>, String> {
  final CourseRepository courseRepository;
  final FirebaseFirestore firestore;

  GeneratePdfReportUsecase(this.courseRepository, {FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<int>> call(String userId) async {
    final pdf = pw.Document();

    // Obtener todos los cursos
    final allCourses = await courseRepository.getCourses();

    // Obtener información del usuario
    String userName = 'Usuario desconocido';
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        userName = userData?['name'] as String? ?? 'Usuario desconocido';
      }
    } catch (e) {
      // Si hay error al obtener el usuario, usar el ID
      userName = 'Usuario ID: $userId';
    }

    // Obtener el progreso del usuario desde Firebase
    final progressSnapshot = await firestore
        .collection('userProgress')
        .where('userId', isEqualTo: userId)
        .get();

    final progressMap = <String, LessonProgressEntity>{};
    for (var doc in progressSnapshot.docs) {
      final data = doc.data();
      progressMap[doc.id] = LessonProgressEntity.fromMap(data);
    }

    // Organizar progreso por curso, módulo y lección
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

    // Obtener información de módulos y lecciones
    final courseTitles = <String, String>{};
    final moduleTitles = <String, Map<String, String>>{}; // courseId -> {moduleId: title}
    final lessonTitles = <String, Map<String, String>>{}; // moduleId -> {lessonId: title}

    for (var course in allCourses) {
      if (!courseProgressMap.containsKey(course.id)) continue;
      courseTitles[course.id] = course.title;

      // Obtener módulos
      final modulesSnapshot = await firestore
          .collection('courses')
          .doc(course.id)
          .collection('modules')
          .orderBy('orderIndex')
          .get();

      if (!moduleTitles.containsKey(course.id)) {
        moduleTitles[course.id] = {};
      }

      for (var moduleDoc in modulesSnapshot.docs) {
        final moduleData = moduleDoc.data();
        final moduleId = moduleDoc.id;
        final moduleTitle = moduleData['title'] as String? ?? 'Sin título';
        moduleTitles[course.id]![moduleId] = moduleTitle;

        // Obtener lecciones
        final lessonsSnapshot = await firestore
            .collection('courses')
            .doc(course.id)
            .collection('modules')
            .doc(moduleId)
            .collection('lessons')
            .orderBy('orderIndex')
            .get();

        if (!lessonTitles.containsKey(moduleId)) {
          lessonTitles[moduleId] = {};
        }

        for (var lessonDoc in lessonsSnapshot.docs) {
          final lessonData = lessonDoc.data();
          final lessonId = lessonDoc.id;
          final lessonTitle = lessonData['title'] as String? ?? 'Sin título';
          lessonTitles[moduleId]![lessonId] = lessonTitle;
        }
      }
    }

    // Generar el PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Reporte de Progreso de Microformaciones',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Usuario: $userName',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 30),

            // Desglose por curso
            ...courseProgressMap.entries.map((courseEntry) {
              final courseId = courseEntry.key;
              final courseTitle = courseTitles[courseId] ?? 'Curso $courseId';
              final moduleProgress = courseEntry.value;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 1,
                    child: pw.Text(
                      'Curso: $courseTitle',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // Desglose por módulo
                  ...moduleProgress.entries.map((moduleEntry) {
                    final moduleId = moduleEntry.key;
                    final moduleTitle = moduleTitles[courseId]?[moduleId] ?? 'Módulo $moduleId';
                    final lessonProgress = moduleEntry.value;

                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Header(
                          level: 2,
                          child: pw.Text(
                            'Módulo: $moduleTitle',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 5),

                        // Desglose por lección
                        ...lessonProgress.entries.map((lessonEntry) {
                          final lessonId = lessonEntry.key;
                          final progress = lessonEntry.value;
                          final lessonTitle = lessonTitles[moduleId]?[lessonId] ?? 'Lección $lessonId';

                          String statusText;
                          switch (progress.status) {
                            case LessonProgressStatus.completed:
                              statusText = 'Completado';
                              break;
                            case LessonProgressStatus.inProgress:
                              statusText = 'En Curso';
                              break;
                            default:
                              statusText = 'No Iniciado';
                          }

                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 20, bottom: 5),
                            child: pw.Row(
                              children: [
                                pw.Text(
                                  '• $lessonTitle: ',
                                  style: pw.TextStyle(fontSize: 12),
                                ),
                                pw.Text(
                                  statusText,
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: progress.status == LessonProgressStatus.completed
                                        ? pw.FontWeight.bold
                                        : pw.FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        pw.SizedBox(height: 10),
                      ],
                    );
                  }),
                  pw.SizedBox(height: 20),
                ],
              );
            }),
          ];
        },
      ),
    );

    return pdf.save();
  }
}

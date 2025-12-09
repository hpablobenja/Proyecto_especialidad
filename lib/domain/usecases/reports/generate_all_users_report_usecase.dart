// lib/domain/usecases/reports/generate_all_users_report_usecase.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

import '../usecase.dart';
import '../../repositories/course_repository.dart';
import '../../entities/lesson_progress_entity.dart';

class GenerateAllUsersReportUsecase implements Usecase<String, NoParams> {
  final CourseRepository courseRepository;
  final FirebaseFirestore firestore;

  GenerateAllUsersReportUsecase(this.courseRepository, {FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> call(NoParams params) async {
    final pdf = pw.Document();

    // Obtener todos los usuarios
    final usersSnapshot = await firestore.collection('users').get();
    final users = <Map<String, dynamic>>[];
    
    for (var userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      users.add({
        'uid': userDoc.id,
        'name': userData['name'] as String? ?? 'Usuario desconocido',
        'email': userData['email'] as String? ?? '',
        'role': userData['role'] as String? ?? '',
      });
    }

    // Filtrar solo maestros si es necesario, o incluir todos
    final maestros = users.where((u) => u['role'] == 'maestro').toList();
    final usersToReport = maestros.isNotEmpty ? maestros : users;

    // Obtener todos los cursos
    final allCourses = await courseRepository.getCourses();

    // Estadísticas generales
    int totalUsers = usersToReport.length;
    int usersWithProgress = 0;
    int totalLessonsCompleted = 0;

    // Generar reporte para cada usuario
    final userReports = <Map<String, dynamic>>[];

    for (var user in usersToReport) {
      final userId = user['uid'] as String;
      final userName = user['name'] as String;

      // Obtener el progreso del usuario
      final progressSnapshot = await firestore
          .collection('userProgress')
          .where('userId', isEqualTo: userId)
          .get();

      if (progressSnapshot.docs.isEmpty) continue;

      usersWithProgress++;

      final progressMap = <String, LessonProgressEntity>{};
      for (var doc in progressSnapshot.docs) {
        final data = doc.data();
        progressMap[doc.id] = LessonProgressEntity.fromMap(data);
      }

      // Organizar progreso por curso
      final courseProgressMap = <String, Map<String, Map<String, LessonProgressEntity>>>{};

      for (var progress in progressMap.values) {
        if (!courseProgressMap.containsKey(progress.courseId)) {
          courseProgressMap[progress.courseId] = {};
        }
        if (!courseProgressMap[progress.courseId]!.containsKey(progress.moduleId)) {
          courseProgressMap[progress.courseId]![progress.moduleId] = {};
        }
        courseProgressMap[progress.courseId]![progress.moduleId]![progress.lessonId] = progress;

        if (progress.status == LessonProgressStatus.completed) {
          totalLessonsCompleted++;
        }
      }

      // Obtener información de módulos y lecciones
      final courseTitles = <String, String>{};
      final moduleTitles = <String, Map<String, String>>{};
      final lessonTitles = <String, Map<String, String>>{};

      for (var course in allCourses) {
        if (!courseProgressMap.containsKey(course.id)) continue;
        courseTitles[course.id] = course.title;

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

      userReports.add({
        'userName': userName,
        'courseProgressMap': courseProgressMap,
        'courseTitles': courseTitles,
        'moduleTitles': moduleTitles,
        'lessonTitles': lessonTitles,
      });
    }

    // Generar el PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Título principal
            pw.Header(
              level: 0,
              child: pw.Text(
                'Reporte General de Progreso',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Estadísticas generales
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Resumen General',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Total de usuarios: $totalUsers'),
                  pw.Text('Usuarios con progreso: $usersWithProgress'),
                  pw.Text('Total de lecciones completadas: $totalLessonsCompleted'),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Reporte por usuario
            ...userReports.map((report) {
              final userName = report['userName'] as String;
              final courseProgressMap = report['courseProgressMap'] as Map<String, Map<String, Map<String, LessonProgressEntity>>>;
              final courseTitles = report['courseTitles'] as Map<String, String>;
              final moduleTitles = report['moduleTitles'] as Map<String, Map<String, String>>;
              final lessonTitles = report['lessonTitles'] as Map<String, Map<String, String>>;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 1,
                    child: pw.Text(
                      'Usuario: $userName',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // Desglose por curso
                  ...courseProgressMap.entries.map((courseEntry) {
                    final courseId = courseEntry.key;
                    final courseTitle = courseTitles[courseId] ?? 'Curso $courseId';
                    final moduleProgress = courseEntry.value;

                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Curso: $courseTitle',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),

                        // Desglose por módulo
                        ...moduleProgress.entries.map((moduleEntry) {
                          final moduleId = moduleEntry.key;
                          final moduleTitle = moduleTitles[courseId]?[moduleId] ?? 'Módulo $moduleId';
                          final lessonProgress = moduleEntry.value;

                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 15, bottom: 5),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Módulo: $moduleTitle',
                                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                                ),
                                pw.SizedBox(height: 3),

                                // Desglose por lección
                                ...lessonProgress.entries.map((lessonEntry) {
                                  final lessonId = lessonEntry.key;
                                  final progress = lessonEntry.value;
                                  final lessonTitle = lessonTitles[moduleId]?[lessonId] ?? 'Lección $lessonId';

                                  String statusText;
                                  switch (progress.status) {
                                    case LessonProgressStatus.completed:
                                      statusText = '✓ Completado';
                                      break;
                                    case LessonProgressStatus.inProgress:
                                      statusText = '⋯ En Curso';
                                      break;
                                    default:
                                      statusText = '○ No Iniciado';
                                  }

                                  return pw.Padding(
                                    padding: const pw.EdgeInsets.only(left: 20, bottom: 2),
                                    child: pw.Text(
                                      '• $lessonTitle: $statusText',
                                      style: pw.TextStyle(fontSize: 10),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }),
                        pw.SizedBox(height: 8),
                      ],
                    );
                  }),
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 15),
                ],
              );
            }),
          ];
        },
      ),
    );

    // Guardar el PDF
    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/documentos/reporte_general_usuarios.pdf');
    
    // Crear directorio si no existe
    await file.parent.create(recursive: true);
    
    await file.writeAsBytes(bytes);

    return file.path;
  }
}

class NoParams {}

// lib/domain/usecases/reports/generate_all_users_report_usecase.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

import '../usecase.dart';
import '../../repositories/course_repository.dart';
import '../../entities/lesson_progress_entity.dart';

class GenerateAllUsersReportUsecase implements Usecase<String, dynamic> {
  final CourseRepository courseRepository;
  final FirebaseFirestore firestore;

  GenerateAllUsersReportUsecase(this.courseRepository, {FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> call(dynamic params) async {
    final pdf = pw.Document();

    String? targetUserId;
    if (params is String && params.isNotEmpty) {
      targetUserId = params;
    }

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

    // Filtrar usuarios: Si se especifica targetUserId, filtrar ese usuario; si no, todos los maestros
    List<Map<String, dynamic>> usersToReport;
    if (targetUserId != null) {
      usersToReport = users.where((u) => u['uid'] == targetUserId).toList();
    } else {
      final maestros = users.where((u) => u['role'] == 'maestro').toList();
      usersToReport = maestros.isNotEmpty ? maestros : users;
    }

    // Obtener todos los cursos
    final allCourses = await courseRepository.getCourses();

    // Estadísticas generales
    int totalUsers = usersToReport.length;
    int usersWithProgress = 0;
    int totalLessonsCompleted = 0;

    // Pre-cargar títulos para TODOS los cursos, módulos y lecciones (una sola vez)
    final courseTitles = <String, String>{};
    final moduleTitles = <String, Map<String, String>>{};
    final lessonTitles = <String, Map<String, Map<String, String>>>{};
    // Mapa plano de fallback: lessonId -> título
    final flatLessonTitles = <String, String>{};

    for (var course in allCourses) {
      courseTitles[course.id] = course.title;
      moduleTitles[course.id] = {};
      lessonTitles[course.id] = {};

      // Obtener módulos (subcolección courses/{id}/modules)
      final modulesSnapshot = await firestore
          .collection('courses')
          .doc(course.id)
          .collection('modules')
          .orderBy('orderIndex')
          .get();

      for (var moduleDoc in modulesSnapshot.docs) {
        final moduleData = moduleDoc.data();
        final moduleId = moduleDoc.id;
        final moduleTitle = moduleData['title'] as String? ?? 'Sin título';
        moduleTitles[course.id]![moduleId] = moduleTitle;
        lessonTitles[course.id]![moduleId] = {};

        // 1. Intentar cargar lecciones desde la colección raíz /lecciones
        final rootLessonsSnapshot = await firestore
            .collection('lecciones')
            .where('courseId', isEqualTo: course.id)
            .where('moduleId', isEqualTo: moduleId)
            .get();

        for (var lessonDoc in rootLessonsSnapshot.docs) {
          final lessonData = lessonDoc.data();
          final lessonId = lessonDoc.id;
          final lessonTitle = lessonData['title'] as String? ??
              lessonData['name'] as String? ??
              lessonData['lessonTitle'] as String? ??
              'Sin título';
          lessonTitles[course.id]![moduleId]![lessonId] = lessonTitle;
          flatLessonTitles[lessonId] = lessonTitle;
        }

        // 2. Si no encontró lecciones en /lecciones, consultar en la subcolección anidada
        if (lessonTitles[course.id]![moduleId]!.isEmpty) {
          final subLessonsSnapshot = await firestore
              .collection('courses')
              .doc(course.id)
              .collection('modules')
              .doc(moduleId)
              .collection('lessons')
              .orderBy('orderIndex')
              .get();

          for (var lessonDoc in subLessonsSnapshot.docs) {
            final lessonData = lessonDoc.data();
            final lessonId = lessonDoc.id;
            final lessonTitle = lessonData['title'] as String? ??
                lessonData['name'] as String? ??
                lessonData['lessonTitle'] as String? ??
                'Sin título';
            lessonTitles[course.id]![moduleId]![lessonId] = lessonTitle;
            flatLessonTitles[lessonId] = lessonTitle;
          }
        }
      }
    }

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

      userReports.add({
        'userName': userName,
        'courseProgressMap': courseProgressMap,
        'courseTitles': courseTitles,
        'moduleTitles': moduleTitles,
        'lessonTitles': lessonTitles,
        'flatLessonTitles': flatLessonTitles,
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
                targetUserId != null
                    ? 'Reporte Individual de Progreso'
                    : 'Reporte General de Progreso',
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

            // Gráfica de barras simple para estadísticas
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
                    'Estadísticas Visuales',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  
                  // Barra de usuarios con progreso
                  pw.Text('Usuarios con progreso vs Sin progreso'),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          height: 30,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.green,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            '$usersWithProgress',
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 12),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Expanded(
                        child: pw.Container(
                          height: 30,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey300,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            '${totalUsers - usersWithProgress}',
                            style: pw.TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('Con progreso', style: pw.TextStyle(fontSize: 10))),
                      pw.SizedBox(width: 4),
                      pw.Expanded(child: pw.Text('Sin progreso', style: pw.TextStyle(fontSize: 10))),
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  // Barra de lecciones completadas
                  pw.Text('Lecciones completadas'),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    height: 30,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      '$totalLessonsCompleted lecciones completadas',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 12),
                    ),
                  ),
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
              final lessonTitles = report['lessonTitles'] as Map<String, Map<String, Map<String, String>>>;
              final flatLessonTitles = (report['flatLessonTitles'] as Map<String, String>?) ?? {};

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
                                  final lessonTitle = lessonTitles[courseId]?[moduleId]?[lessonId] ??
                                      flatLessonTitles[lessonId] ??
                                      'Lección $lessonId';

                                  String statusText;
                                  String bullet;
                                  switch (progress.status) {
                                    case LessonProgressStatus.completed:
                                      statusText = 'Completado';
                                      bullet = '•';
                                      break;
                                    case LessonProgressStatus.inProgress:
                                      statusText = 'En Curso';
                                      bullet = '•';
                                      break;
                                    default:
                                      statusText = 'No Iniciado';
                                      bullet = '•';
                                  }

                                  return pw.Padding(
                                    padding: const pw.EdgeInsets.only(left: 20, bottom: 5),
                                    child: pw.Text(
                                      '$bullet $lessonTitle - $statusText',
                                      style: pw.TextStyle(
                                        fontSize: 12,
                                        fontWeight: progress.status == LessonProgressStatus.completed
                                            ? pw.FontWeight.bold
                                            : pw.FontWeight.normal,
                                      ),
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
    final fileName = targetUserId != null
        ? 'reporte_individual_${targetUserId}.pdf'
        : 'reporte_general_usuarios.pdf';
    final file = File('${directory.path}/documentos/$fileName');
    
    // Crear directorio si no existe
    await file.parent.create(recursive: true);
    
    await file.writeAsBytes(bytes);

    return file.path;
  }
}

class NoParams {}

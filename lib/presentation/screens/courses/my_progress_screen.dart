// lib/presentation/screens/courses/my_progress_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../providers/progress_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/injection_container.dart' as di;
import '../../../domain/usecases/reports/generate_pdf_report_usecase.dart';
import '../../widgets/app_drawer.dart';
import '../../../domain/usecases/courses/get_course_progress_usecase.dart';
import '../../../domain/entities/lesson_progress_entity.dart';

class MyProgressScreen extends StatefulWidget {
  @override
  _MyProgressScreenState createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar el progreso del usuario al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progressProvider = Provider.of<ProgressProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        progressProvider.loadUserProgress(authProvider.currentUser!.uid);
      }
    });
  }

  Future<void> _generateReport() async {
    final generatePdfReportUsecase = di.sl<GeneratePdfReportUsecase>();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Mostrar indicador de carga
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Generando reporte PDF...'),
        backgroundColor: AppColors.primaryColor,
      ),
    );

    try {
      final pdfBytes = await generatePdfReportUsecase.call(
        authProvider.currentUser!.uid,
      );

      // Guardar el archivo PDF
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/documentos/reporte_usuario.pdf');
      await file.create(recursive: true);
      await file.writeAsBytes(pdfBytes);

      // Abrir el archivo PDF
      await OpenFilex.open(file.path);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Reporte PDF generado exitosamente.'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error al generar el reporte: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = Provider.of<ProgressProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Progreso')),
      drawer: const AppDrawer(),
      body:
          progressProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (progressProvider.completedCourses.isEmpty && progressProvider.inProgressCourses.isEmpty)
                      _buildEmptyState()
                    else ...[
                      _buildCourseProgressSection(
                        progressProvider.completedCourses,
                        'Microformaciones Completadas',
                        Icons.emoji_events,
                      ),
                      _buildCourseProgressSection(
                        progressProvider.inProgressCourses,
                        'Microformaciones en Curso',
                        Icons.trending_up,
                      ),
                    ],
                    
                    const SizedBox(height: 32),

                    // Botón de Generar Reporte
                    Center(
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _generateReport,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text(
                              'Generar Reporte PDF',
                              style: AppStyles.buttonText,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Descargará el documento solicitado',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildCourseProgressSection(List<CourseProgressDetail> courses, String title, IconData headerIcon) {
    if (courses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(headerIcon, color: AppColors.primaryColor, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppStyles.headline1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...courses.map((courseDetail) => _buildCourseItem(courseDetail)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCourseItem(CourseProgressDetail detail) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          detail.course.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: const Icon(Icons.school, color: AppColors.primaryColor),
        children: detail.moduleTitles.entries.map((moduleEntry) {
          final moduleId = moduleEntry.key;
          final moduleTitle = moduleEntry.value;
          final lessons = detail.lessonTitles[moduleId] ?? {};

          if (lessons.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moduleTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                ...lessons.entries.map((lessonEntry) {
                  final lessonId = lessonEntry.key;
                  final lessonTitle = lessonEntry.value;
                  final progress = detail.progress[moduleId]?[lessonId];

                  String statusText = 'No Iniciado';
                  IconData statusIcon = Icons.radio_button_unchecked;
                  Color statusColor = Colors.grey;

                  if (progress != null) {
                    if (progress.status == LessonProgressStatus.completed) {
                      statusText = 'Completado';
                      statusIcon = Icons.check_circle;
                      statusColor = AppColors.successColor;
                    } else if (progress.status == LessonProgressStatus.inProgress) {
                      statusText = 'En Curso';
                      statusIcon = Icons.access_time;
                      statusColor = AppColors.accentColor;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lessonTitle,
                                style: const TextStyle(fontSize: 14),
                              ),
                              Row(
                                children: [
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                  if (progress?.quizScore != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      progress!.maxQuizScore != null
                                          ? '• Nota: ${progress!.quizScore} / ${progress!.maxQuizScore}'
                                          : '• Nota: ${progress!.quizScore}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey[700],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aún no has completado ninguna microformación',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Completa al menos una microformación para ver tu progreso aquí',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

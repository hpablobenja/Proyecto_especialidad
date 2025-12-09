// lib/presentation/screens/courses/course_details_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/course_entity.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/offline_cache_service.dart';
import '../../providers/connectivity_provider.dart';
import 'course_content_view_screen.dart';
import 'lesson_documentation_screen.dart';

class CourseDetailsScreen extends StatelessWidget {
  final CourseEntity course;

  const CourseDetailsScreen({Key? key, required this.course}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              course.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Descripción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              course.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final cacheService = OfflineCacheService();
                  final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
                  
                  // Cache course for offline access
                  await cacheService.cacheLastCourse(course);
                  
                  // Check if offline
                  if (!connectivity.isOnline) {
                    // Try to get cached lesson for this course
                    final cachedLesson = await cacheService.getLastLesson();
                    
                    if (cachedLesson != null && cachedLesson.courseId == course.id) {
                      // Navigate directly to the lesson documentation (not options)
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LessonDocumentationScreen(lesson: cachedLesson),
                        ),
                      );
                      return;
                    } else {
                      // No cached lesson for this course
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No hay contenido guardado para este curso. Accede online primero.'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                  }
                  
                  // Online: show normal course content
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => CourseContentViewScreen(
                            courseId: course.id,
                            courseTitle: course.title,
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_fill),
                label: const Text('Comenzar Microformación'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/presentation/screens/courses/lesson_options_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/lesson_entity.dart';
import '../../providers/progress_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import 'lesson_player_screen.dart';
import 'lesson_documentation_screen.dart';
import 'quiz_screen.dart';

class LessonOptionsScreen extends StatelessWidget {
  final LessonEntity lesson;

  const LessonOptionsScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final connectivity = Provider.of<ConnectivityProvider>(context);
    final isOffline = !connectivity.isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selecciona una opción',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (isOffline)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: Text(
                  'Modo offline: Solo documentación disponible',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),
            _OptionCard(
              icon: Icons.play_circle_filled,
              title: 'Reproducir el video',
              description: 'Ver la lección en video',
              color: Colors.blue,
              isEnabled: !isOffline,
              onTap: () {
                // Marcar como "en curso" cuando se selecciona reproducir video
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final progress = Provider.of<ProgressProvider>(
                  context,
                  listen: false,
                );
                if (auth.currentUser != null) {
                  progress.markLessonInProgress(
                    userId: auth.currentUser!.uid,
                    courseId: lesson.courseId,
                    moduleId: lesson.moduleId,
                    lessonId: lesson.id,
                  );
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LessonPlayerScreen(lesson: lesson),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _OptionCard(
              icon: Icons.description,
              title: 'Ver la documentación de la lección',
              description: 'Leer el contenido escrito de la lección',
              color: Colors.green,
              isEnabled: true, // Always enabled
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LessonDocumentationScreen(lesson: lesson),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _OptionCard(
              icon: Icons.quiz,
              title: 'Cuestionario de conocimientos',
              description: 'Evaluar tu comprensión de la lección',
              color: Colors.orange,
              isEnabled: !isOffline,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => QuizScreen(lesson: lesson)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Card(
        elevation: isEnabled ? 4 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isEnabled ? Colors.grey[400] : Colors.grey[300],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

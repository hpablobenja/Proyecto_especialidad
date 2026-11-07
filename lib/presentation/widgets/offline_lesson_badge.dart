// lib/presentation/widgets/offline_lesson_badge.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../core/di/riverpod_providers.dart';

/// Widget que muestra un badge indicando la lección disponible offline
class OfflineLessonBadge extends ConsumerWidget {
  const OfflineLessonBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityStateProvider);
    final isOffline = !connectivity.isOnline;

    if (!isOffline) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<LessonEntity?>(
      future: ref.read(offlineCacheServiceProvider).getLastLesson(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final lesson = snapshot.data!;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.orange.shade200, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.offline_pin, size: 20, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lección disponible offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lesson.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

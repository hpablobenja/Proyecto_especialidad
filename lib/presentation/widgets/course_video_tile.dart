import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/course_entity.dart';
import '../../domain/entities/module_entity.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/media_resource.dart';
import '../../core/di/riverpod_providers.dart';
import 'video_preview_card.dart';

/// Fetches and shows the thumbnail for the first lesson's first video of a course.
/// Results are cached in-memory to avoid repeated network calls.
class CourseVideoTile extends ConsumerStatefulWidget {
  final CourseEntity course;
  final VoidCallback? onTap;

  const CourseVideoTile({super.key, required this.course, this.onTap});

  @override
  ConsumerState<CourseVideoTile> createState() => _CourseVideoTileState();
}

class _CourseVideoTileState extends ConsumerState<CourseVideoTile> {
  static final Map<String, MediaResource> _cache = {};
  Future<MediaResource>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _future = _resolveFirstLessonMedia(widget.course);
      });
    });
  }

  @override
  void didUpdateWidget(covariant CourseVideoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.course.id != widget.course.id) {
      setState(() {
        _future = _resolveFirstLessonMedia(widget.course);
      });
    }
  }

  Future<MediaResource> _resolveFirstLessonMedia(CourseEntity course) async {
    if (_cache.containsKey(course.id)) {
      return _cache[course.id]!;
    }

    // Si está offline o falla la red, intentar usar los datos cacheados
    final connectivity = ref.read(connectivityStateProvider);
    if (!connectivity.isOnline) {
      final cachedLesson =
          await ref.read(offlineCacheServiceProvider).getLastLesson();
      if (cachedLesson != null &&
          cachedLesson.courseId == course.id &&
          cachedLesson.media.isNotEmpty) {
        _cache[course.id] = cachedLesson.media.first;
        return cachedLesson.media.first;
      }
      return _fallbackMedia(course);
    }

    try {
      final admin = ref.read(adminContentStateProvider);
      final List<ModuleEntity> modules = await admin.fetchModules(course.id);
      if (modules.isEmpty) {
        return _fallbackMedia(course);
      }
      final firstModule = modules.first;
      final List<LessonEntity> lessons = await admin.fetchLessons(
        courseId: course.id,
        moduleId: firstModule.id,
      );
      if (lessons.isEmpty) {
        return _fallbackMedia(course);
      }
      final firstLesson = lessons.first;
      if (firstLesson.media.isEmpty) {
        return _fallbackMedia(course);
      }
      final firstMedia = firstLesson.media.first;
      _cache[course.id] = firstMedia;
      return firstMedia;
    } catch (_) {
      final cachedLesson =
          await ref.read(offlineCacheServiceProvider).getLastLesson();
      if (cachedLesson != null &&
          cachedLesson.courseId == course.id &&
          cachedLesson.media.isNotEmpty) {
        return cachedLesson.media.first;
      }
      return _fallbackMedia(course);
    }
  }

  MediaResource _fallbackMedia(CourseEntity course) {
    return MediaResource(
      id: course.id,
      url: 'https://youtu.be/dQw4w9WgXcQ',
      filename: course.title,
      mimeType: 'video/youtube',
      sizeBytes: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MediaResource>(
      future: _future,
      builder: (context, snapshot) {
        final media = snapshot.data;
        if (_future == null || media == null) {
          return const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0x0A000000),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    widget.course.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: VideoPreviewCard(
                    video: media,
                    onTap: widget.onTap,
                    isCard: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

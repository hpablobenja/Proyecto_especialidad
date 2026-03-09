// lib/presentation/widgets/course_video_tile.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/course_entity.dart';
import '../../domain/entities/module_entity.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/media_resource.dart';
import '../providers/admin_content_provider.dart';
import 'video_preview_card.dart';

/// Fetches and shows the thumbnail for the first lesson's first video of a course.
/// Results are cached in-memory to avoid repeated network calls.
class CourseVideoTile extends StatefulWidget {
  final CourseEntity course;
  final VoidCallback? onTap;

  const CourseVideoTile({super.key, required this.course, this.onTap});

  @override
  State<CourseVideoTile> createState() => _CourseVideoTileState();
}

class _CourseVideoTileState extends State<CourseVideoTile> {
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

    final admin = Provider.of<AdminContentProvider>(context, listen: false);
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course title above the video preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.course.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
              ),
            ),
            // Video preview
            VideoPreviewCard(video: media, onTap: widget.onTap),
          ],
        );
      },
    );
  }
}

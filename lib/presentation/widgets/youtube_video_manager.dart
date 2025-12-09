// lib/presentation/widgets/youtube_video_manager.dart

import 'package:flutter/material.dart';

import '../../domain/entities/media_resource.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import 'youtube_player_widget.dart';

class YouTubeVideoManager extends StatefulWidget {
  final LessonEntity lesson;
  final Function(LessonEntity) onLessonUpdated;
  final bool isAdmin;

  const YouTubeVideoManager({
    super.key,
    required this.lesson,
    required this.onLessonUpdated,
    this.isAdmin = false,
  });

  @override
  State<YouTubeVideoManager> createState() => _YouTubeVideoManagerState();
}

class _YouTubeVideoManagerState extends State<YouTubeVideoManager> {
  List<MediaResource> get youtubeVideos =>
      widget.lesson.media
          .where((media) => media.mimeType == 'video/youtube')
          .toList();

  String? _extractVideoId(MediaResource media) {
    // 1) Prefer explicit metadata
    final meta = media.metadata;
    final metaId = meta is Map<String, dynamic> ? meta['videoId'] : null;
    if (metaId is String &&
        metaId.isNotEmpty &&
        RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(metaId)) {
      return metaId;
    }

    // 2) Try to parse from URL
    final url = media.url;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // watch?v=ID
    final v = uri.queryParameters['v'];
    if (v != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(v)) return v;

    // youtu.be/ID or /embed/ID or /shorts/ID
    final path = uri.pathSegments;
    if (path.isNotEmpty) {
      if ((uri.host.contains('youtu.be') ||
              path.first == 'embed' ||
              path.first == 'shorts') &&
          RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(path.last)) {
        return path.last;
      }
    }
    return null;
  }

  String? _extractVideoIdFromUrl(String url) {
    final u = url.trim();
    final patterns = <RegExp>[
      RegExp(r'^https?:\/\/(?:www\.)?youtu\.be\/([A-Za-z0-9_-]{11})'),
      RegExp(
        r'^https?:\/\/(?:www\.)?youtube\.com\/watch\?v=([A-Za-z0-9_-]{11})',
      ),
      RegExp(r'^https?:\/\/(?:www\.)?youtube\.com\/embed\/([A-Za-z0-9_-]{11})'),
      RegExp(
        r'^https?:\/\/(?:www\.)?youtube\.com\/shorts\/([A-Za-z0-9_-]{11})',
      ),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(u);
      if (m != null) return m.group(1);
    }
    // Fallback: try to parse any v= param
    final uri = Uri.tryParse(u);
    final v = uri?.queryParameters['v'];
    if (v != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(v)) return v;
    return null;
  }

  Future<void> _addVideo() async {
    final urlCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Agregar video de YouTube'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL de YouTube',
                  hintText: 'https://youtu.be/XXXXXXXXXXX',
                ),
                validator: (v) {
                  final id = v == null ? null : _extractVideoIdFromUrl(v);
                  if (id == null) return 'Ingrese una URL válida de YouTube';
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate())
                    Navigator.pop(context, true);
                },
                child: const Text('Agregar'),
              ),
            ],
          ),
    );

    if (ok != true) return;

    final id = _extractVideoIdFromUrl(urlCtrl.text);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('URL de YouTube no válida'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    try {
      final media = MediaResource(
        id: 'youtube:$id',
        url: 'https://www.youtube.com/watch?v=$id',
        filename: 'YouTube $id',
        mimeType: 'video/youtube',
        sizeBytes: 0,
        duration: null,
        metadata: {'provider': 'youtube', 'videoId': id},
      );

      final updated = LessonEntity(
        id: widget.lesson.id,
        courseId: widget.lesson.courseId,
        moduleId: widget.lesson.moduleId,
        title: widget.lesson.title,
        contentDelta: widget.lesson.contentDelta,
        objectives: widget.lesson.objectives,
        media: [...widget.lesson.media, media],
        downloadableResources: widget.lesson.downloadableResources,
        orderIndex: widget.lesson.orderIndex,
        dripUnlockAt: widget.lesson.dripUnlockAt,
      );

      widget.onLessonUpdated(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video agregado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar video: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _removeVideo(MediaResource video) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar video'),
            content: const Text(
              '¿Está seguro de que desea eliminar este video?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorColor,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (ok != true) return;

    try {
      final updated = LessonEntity(
        id: widget.lesson.id,
        courseId: widget.lesson.courseId,
        moduleId: widget.lesson.moduleId,
        title: widget.lesson.title,
        contentDelta: widget.lesson.contentDelta,
        objectives: widget.lesson.objectives,
        media: widget.lesson.media.where((m) => m.id != video.id).toList(),
        downloadableResources: widget.lesson.downloadableResources,
        orderIndex: widget.lesson.orderIndex,
        dripUnlockAt: widget.lesson.dripUnlockAt,
      );

      widget.onLessonUpdated(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video eliminado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar video: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _editVideo(MediaResource video) async {
    final urlCtrl = TextEditingController(text: video.url);
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Editar video de YouTube'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL de YouTube',
                  hintText: 'https://youtu.be/XXXXXXXXXXX',
                ),
                validator: (v) {
                  final id = v == null ? null : _extractVideoIdFromUrl(v);
                  if (id == null) return 'Ingrese una URL válida de YouTube';
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate())
                    Navigator.pop(context, true);
                },
                child: const Text('Actualizar'),
              ),
            ],
          ),
    );

    if (ok != true) return;

    final id = _extractVideoIdFromUrl(urlCtrl.text);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('URL de YouTube no válida'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    try {
      final updatedMedia = MediaResource(
        id: 'youtube:$id',
        url: 'https://www.youtube.com/watch?v=$id',
        filename: 'YouTube $id',
        mimeType: 'video/youtube',
        sizeBytes: 0,
        duration: null,
        metadata: {'provider': 'youtube', 'videoId': id},
      );

      final updated = LessonEntity(
        id: widget.lesson.id,
        courseId: widget.lesson.courseId,
        moduleId: widget.lesson.moduleId,
        title: widget.lesson.title,
        contentDelta: widget.lesson.contentDelta,
        objectives: widget.lesson.objectives,
        media:
            widget.lesson.media
                .map((m) => m.id == video.id ? updatedMedia : m)
                .toList(),
        downloadableResources: widget.lesson.downloadableResources,
        orderIndex: widget.lesson.orderIndex,
        dripUnlockAt: widget.lesson.dripUnlockAt,
      );

      widget.onLessonUpdated(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video actualizado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar video: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (youtubeVideos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.video_library,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text('Videos de YouTube', style: AppStyles.subhead1),
                ],
              ),
              const SizedBox(height: 8),
              const Text('No hay videos de YouTube en esta lección.'),
              if (widget.isAdmin) ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _addVideo,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar video'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.video_library, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text('Videos de YouTube', style: AppStyles.subhead1),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            ...youtubeVideos.map((video) {
              final videoId = _extractVideoId(video);
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (videoId != null) ...[
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: YouTubePlayerWidget(
                          videoId: videoId,
                          autoPlay: false,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.filename,
                                  style: AppStyles.bodyText1.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  video.url,
                                  style: AppStyles.bodyText1.copyWith(
                                    fontSize: 12,
                                    color: AppColors.textColor.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (widget.isAdmin) ...[
                            IconButton(
                              onPressed: () => _editVideo(video),
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Editar video',
                            ),
                            IconButton(
                              onPressed: () => _removeVideo(video),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Eliminar video',
                              color: AppColors.errorColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

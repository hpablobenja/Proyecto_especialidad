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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')} min';
  }

  Future<void> _addVideo() async {
    final urlCtrl = TextEditingController();
    final durationMinutesCtrl = TextEditingController();
    final durationSecondsCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Agregar video de YouTube'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: urlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL de YouTube *',
                        hintText: 'https://youtu.be/XXXXXXXXXXX',
                      ),
                      validator: (v) {
                        final id = v == null ? null : _extractVideoIdFromUrl(v);
                        if (id == null) return 'Ingrese una URL válida de YouTube';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Duración del video (máximo 16:00 min):',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: durationMinutesCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Minutos *',
                              hintText: '0 - 16',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Obligatorio';
                              }
                              final mins = int.tryParse(v.trim());
                              if (mins == null || mins < 0) {
                                return 'Inválido';
                              }
                              if (mins > 16) {
                                return 'Máx 16';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: durationSecondsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Segundos',
                              hintText: '0 - 59',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final secs = int.tryParse(v.trim());
                              if (secs == null || secs < 0 || secs >= 60) {
                                return '0-59';
                              }
                              final mins = int.tryParse(durationMinutesCtrl.text.trim()) ?? 0;
                              if (mins == 16 && secs > 0) {
                                return 'Excede 16m';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nota: Por política de la plataforma, ningún video de lección debe superar los 16 minutos.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final mins = int.tryParse(durationMinutesCtrl.text.trim()) ?? 0;
                    final secs = int.tryParse(durationSecondsCtrl.text.trim()) ?? 0;
                    final totalSeconds = (mins * 60) + secs;
                    if (totalSeconds > 16 * 60) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('El video no debe superar los 16 minutos de duración'),
                          backgroundColor: AppColors.errorColor,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Agregar'),
              ),
            ],
          ),
    );

    if (ok != true) return;

    final id = _extractVideoIdFromUrl(urlCtrl.text);
    if (id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('URL de YouTube no válida'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final mins = int.tryParse(durationMinutesCtrl.text.trim()) ?? 0;
    final secs = int.tryParse(durationSecondsCtrl.text.trim()) ?? 0;
    final totalDuration = Duration(minutes: mins, seconds: secs);

    if (totalDuration > const Duration(minutes: 16)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El video no puede superar los 16 minutos de duración.'),
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
        duration: totalDuration,
        metadata: {
          'provider': 'youtube',
          'videoId': id,
          'durationSeconds': totalDuration.inSeconds,
        },
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video agregado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video eliminado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
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
    final Map<String, dynamic>? meta = video.metadata;
    final metaDurationSecs = meta != null ? (meta['durationSeconds'] as num?)?.toInt() : null;
    final initialMinutes = video.duration?.inMinutes ?? (metaDurationSecs != null ? (metaDurationSecs / 60).floor() : null);
    final initialSeconds = video.duration != null
        ? (video.duration!.inSeconds % 60)
        : (metaDurationSecs != null ? (metaDurationSecs % 60) : 0);
    
    final durationMinutesCtrl = TextEditingController(
      text: initialMinutes != null ? initialMinutes.toString() : '',
    );
    final durationSecondsCtrl = TextEditingController(
      text: initialSeconds > 0 ? initialSeconds.toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Editar video de YouTube'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: urlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL de YouTube *',
                        hintText: 'https://youtu.be/XXXXXXXXXXX',
                      ),
                      validator: (v) {
                        final id = v == null ? null : _extractVideoIdFromUrl(v);
                        if (id == null) return 'Ingrese una URL válida de YouTube';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Duración del video (máximo 16:00 min):',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: durationMinutesCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Minutos *',
                              hintText: '0 - 16',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Obligatorio';
                              }
                              final mins = int.tryParse(v.trim());
                              if (mins == null || mins < 0) {
                                return 'Inválido';
                              }
                              if (mins > 16) {
                                return 'Máx 16';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: durationSecondsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Segundos',
                              hintText: '0 - 59',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final secs = int.tryParse(v.trim());
                              if (secs == null || secs < 0 || secs >= 60) {
                                return '0-59';
                              }
                              final mins = int.tryParse(durationMinutesCtrl.text.trim()) ?? 0;
                              if (mins == 16 && secs > 0) {
                                return 'Excede 16m';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nota: Por política de la plataforma, ningún video de lección debe superar los 16 minutos.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final mins = int.tryParse(durationMinutesCtrl.text.trim()) ?? 0;
                    final secs = int.tryParse(durationSecondsCtrl.text.trim()) ?? 0;
                    final totalSeconds = (mins * 60) + secs;
                    if (totalSeconds > 16 * 60) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('El video no debe superar los 16 minutos de duración'),
                          backgroundColor: AppColors.errorColor,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Actualizar'),
              ),
            ],
          ),
    );

    if (ok != true) return;

    final id = _extractVideoIdFromUrl(urlCtrl.text);
    if (id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('URL de YouTube no válida'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final mins = int.tryParse(durationMinutesCtrl.text.trim()) ?? 0;
    final secs = int.tryParse(durationSecondsCtrl.text.trim()) ?? 0;
    final totalDuration = Duration(minutes: mins, seconds: secs);

    if (totalDuration > const Duration(minutes: 16)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El video no puede superar los 16 minutos de duración.'),
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
        duration: totalDuration,
        metadata: {
          'provider': 'youtube',
          'videoId': id,
          'durationSeconds': totalDuration.inSeconds,
        },
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video actualizado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
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
                          onDurationLoaded: (detectedDuration) {
                            if (detectedDuration > const Duration(minutes: 16)) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Atención: El video supera los 16 minutos permitidos (${_formatDuration(detectedDuration)}). Debe reemplazarlo.',
                                  ),
                                  backgroundColor: AppColors.errorColor,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          },
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        video.filename,
                                        style: AppStyles.bodyText1.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (video.duration != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: video.duration! > const Duration(minutes: 16)
                                              ? AppColors.errorColor.withValues(alpha: 0.15)
                                              : AppColors.primaryColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: video.duration! > const Duration(minutes: 16)
                                                ? AppColors.errorColor
                                                : AppColors.primaryColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _formatDuration(video.duration!),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: video.duration! > const Duration(minutes: 16)
                                                ? AppColors.errorColor
                                                : AppColors.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  video.url,
                                  style: AppStyles.bodyText1.copyWith(
                                    fontSize: 12,
                                    color: AppColors.textColor.withValues(
                                      alpha: 0.7,
                                    ),
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
            }),
          ],
        ),
      ),
    );
  }
}

// lib/presentation/widgets/video_download_button.dart

import 'package:flutter/material.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/video_download_service.dart';
import '../../data/models/downloaded_video_hive.dart';

class VideoDownloadButton extends StatefulWidget {
  final String videoId;
  final String courseId;
  final String downloadUrl;
  final int totalDurationSeconds;

  const VideoDownloadButton({
    super.key,
    required this.videoId,
    required this.courseId,
    required this.downloadUrl,
    this.totalDurationSeconds = 0,
  });

  @override
  State<VideoDownloadButton> createState() => _VideoDownloadButtonState();
}

class _VideoDownloadButtonState extends State<VideoDownloadButton> {
  final _service = VideoDownloadService();
  double? _downloadProgress;

  @override
  Widget build(BuildContext context) {
    if (widget.downloadUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    if (!Hive.isBoxOpen(VideoDownloadService.boxName)) {
      return FutureBuilder<Box<DownloadedVideoHive>>(
        future: Hive.openBox<DownloadedVideoHive>(VideoDownloadService.boxName),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          return _buildButton(snapshot.data!);
        },
      );
    }

    return _buildButton(
      Hive.box<DownloadedVideoHive>(VideoDownloadService.boxName),
    );
  }

  Widget _buildButton(Box<DownloadedVideoHive> box) {
    return ValueListenableBuilder<Box<DownloadedVideoHive>>(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
        final downloaded = box.get(widget.videoId);

        if (downloaded == null ||
            downloaded.downloadStatus == 'canceled' ||
            downloaded.downloadStatus == 'failed') {
          return IconButton(
            tooltip: 'Descargar para ver sin conexión',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () async {
              await _service.startDownload(
                videoId: widget.videoId,
                courseId: widget.courseId,
                downloadUrl: widget.downloadUrl,
                totalDurationSeconds: widget.totalDurationSeconds,
              );
            },
          );
        }

        if (downloaded.downloadStatus == 'completed') {
          final sizeMb = (downloaded.fileSize / (1024 * 1024)).toStringAsFixed(
            1,
          );
          return PopupMenuButton<String>(
            tooltip: 'Video descargado ($sizeMb MB)',
            icon: const Icon(Icons.offline_pin, color: Colors.green),
            onSelected: (val) async {
              if (val == 'delete') {
                await _service.deleteLocalVideo(widget.videoId);
              }
            },
            itemBuilder:
                (ctx) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: const [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar descarga'),
                      ],
                    ),
                  ),
                ],
          );
        }

        // Descargando o pausado
        return StreamBuilder<TaskProgressUpdate>(
          stream: _service.progressStream,
          builder: (context, snapshot) {
            if (snapshot.hasData &&
                snapshot.data!.task.taskId == widget.videoId) {
              _downloadProgress = snapshot.data!.progress;
            }

            final progress = _downloadProgress ?? 0.0;
            final isPaused = downloaded.downloadStatus == 'paused';

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress > 0 ? progress : null,
                      strokeWidth: 2.5,
                      color:
                          isPaused
                              ? Colors.amber
                              : Theme.of(context).colorScheme.primary,
                    ),
                    IconButton(
                      iconSize: 18,
                      icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                      onPressed: () {
                        if (isPaused) {
                          _service.resumeDownload(widget.videoId);
                        } else {
                          _service.pauseDownload(widget.videoId);
                        }
                      },
                    ),
                  ],
                ),
                IconButton(
                  iconSize: 18,
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancelar descarga',
                  onPressed: () {
                    _service.cancelDownload(widget.videoId);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

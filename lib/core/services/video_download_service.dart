// lib/core/services/video_download_service.dart

import 'dart:async';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../data/models/downloaded_video_hive.dart';

class VideoDownloadService {
  static const String boxName = 'downloadedVideos';
  final _fileDownloader = FileDownloader();
  final StreamController<TaskProgressUpdate> _progressController =
      StreamController<TaskProgressUpdate>.broadcast();

  Stream<TaskProgressUpdate> get progressStream => _progressController.stream;

  static final VideoDownloadService _instance =
      VideoDownloadService._internal();
  factory VideoDownloadService() => _instance;
  VideoDownloadService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox<DownloadedVideoHive>(boxName);
      }

      _fileDownloader.registerCallbacks(
        taskProgressCallback: (update) {
          if (!_progressController.isClosed) {
            _progressController.add(update);
          }
        },
        taskStatusCallback: (update) async {
          await _handleStatusUpdate(update);
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('VideoDownloadService init error: $e');
    }
  }

  Future<void> _handleStatusUpdate(TaskStatusUpdate update) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<DownloadedVideoHive>(boxName);
    }
    final box = Hive.box<DownloadedVideoHive>(boxName);
    final videoId = update.task.taskId;
    final item = box.get(videoId);

    if (item != null) {
      switch (update.status) {
        case TaskStatus.complete:
          item.downloadStatus = 'completed';
          final file = File(item.localPath);
          if (await file.exists()) {
            item.fileSize = await file.length();
          }
          item.downloadedAt = DateTime.now();
          await item.save();
          break;
        case TaskStatus.failed:
          item.downloadStatus = 'failed';
          await item.save();
          break;
        case TaskStatus.canceled:
          item.downloadStatus = 'canceled';
          await item.save();
          break;
        case TaskStatus.paused:
          item.downloadStatus = 'paused';
          await item.save();
          break;
        default:
          break;
      }
    }
  }

  /// Resuelve la URL directa de stream MP4 (Muxed: Video + Audio)
  Future<String?> resolveDirectStreamUrl(String urlOrId) async {
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient.getManifest(urlOrId);
      // MuxedStreamInfo contiene video y audio combinados en un único archivo MP4
      final muxedStreams = manifest.muxed.sortByVideoQuality();
      if (muxedStreams.isNotEmpty) {
        // Seleccionamos la mejor calidad muxed disponible (típicamente 720p o 360p)
        final bestMuxed = muxedStreams.first;
        return bestMuxed.url.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Error resolviendo stream de YouTube: $e');
      return null;
    } finally {
      yt.close();
    }
  }

  Future<void> startDownload({
    required String videoId,
    required String courseId,
    required String downloadUrl,
    int totalDurationSeconds = 0,
  }) async {
    await init();
    final box = Hive.box<DownloadedVideoHive>(boxName);
    final dir = await getApplicationDocumentsDirectory();
    final filename = '${courseId}_$videoId.mp4';
    final fullPath = '${dir.path}/videos/$filename';

    final videosDir = Directory('${dir.path}/videos');
    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }

    final entity = DownloadedVideoHive(
      videoId: videoId,
      courseId: courseId,
      localPath: fullPath,
      downloadStatus: 'downloading',
      downloadedAt: DateTime.now(),
      fileSize: 0,
      totalSeconds: totalDurationSeconds,
    );
    await box.put(videoId, entity);

    // Obtener la URL directa de streaming (si es YouTube) o usar la URL directa
    String directDownloadUrl = downloadUrl;
    if (downloadUrl.contains('youtube.com') ||
        downloadUrl.contains('youtu.be') ||
        RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(downloadUrl)) {
      final resolved = await resolveDirectStreamUrl(downloadUrl);
      if (resolved != null && resolved.isNotEmpty) {
        directDownloadUrl = resolved;
      } else {
        entity.downloadStatus = 'failed';
        await entity.save();
        debugPrint(
          'No se pudo extraer el stream directo de YouTube para $downloadUrl',
        );
        return;
      }
    }

    final task = DownloadTask(
      taskId: videoId,
      url: directDownloadUrl,
      filename: filename,
      directory: 'videos',
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
      allowPause: true,
      retries: 3,
    );

    await _fileDownloader.enqueue(task);
  }

  Future<void> pauseDownload(String videoId) async {
    final task = await _fileDownloader.taskForId(videoId);
    if (task is DownloadTask) {
      await _fileDownloader.pause(task);
    }
  }

  Future<void> resumeDownload(String videoId) async {
    final task = await _fileDownloader.taskForId(videoId);
    if (task is DownloadTask) {
      await _fileDownloader.resume(task);
    }
  }

  Future<void> cancelDownload(String videoId) async {
    final task = await _fileDownloader.taskForId(videoId);
    if (task is DownloadTask) {
      await _fileDownloader.cancelTaskWithId(task.taskId);
    }
    await deleteLocalVideo(videoId);
  }

  Future<void> deleteLocalVideo(String videoId) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<DownloadedVideoHive>(boxName);
    }
    final box = Hive.box<DownloadedVideoHive>(boxName);
    final item = box.get(videoId);
    if (item != null) {
      final file = File(item.localPath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('Error deleting file: $e');
        }
      }
      await box.delete(videoId);
    }
  }

  DownloadedVideoHive? getDownloadedVideo(String videoId) {
    if (!Hive.isBoxOpen(boxName)) return null;
    final box = Hive.box<DownloadedVideoHive>(boxName);
    final item = box.get(videoId);
    if (item != null && item.isCompleted && File(item.localPath).existsSync()) {
      return item;
    }
    return null;
  }

  Future<void> updateWatchedProgress({
    required String videoId,
    required int watchedSeconds,
    required int totalSeconds,
    bool pendingSync = true,
  }) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<DownloadedVideoHive>(boxName);
    }
    final box = Hive.box<DownloadedVideoHive>(boxName);
    final item = box.get(videoId);
    if (item != null) {
      item.watchedSeconds = watchedSeconds;
      if (totalSeconds > 0) {
        item.totalSeconds = totalSeconds;
      }
      item.pendingSync = pendingSync;
      await item.save();
    }
  }

  void dispose() {
    _progressController.close();
  }
}

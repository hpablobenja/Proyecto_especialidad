// lib/data/models/downloaded_video_hive.dart

import 'package:hive/hive.dart';

part 'downloaded_video_hive.g.dart';

@HiveType(typeId: 6)
class DownloadedVideoHive extends HiveObject {
  @HiveField(0)
  String videoId;

  @HiveField(1)
  String courseId;

  @HiveField(2)
  String localPath;

  @HiveField(3)
  String downloadStatus; // 'pending', 'downloading', 'paused', 'completed', 'failed', 'canceled'

  @HiveField(4)
  DateTime downloadedAt;

  @HiveField(5)
  int fileSize;

  @HiveField(6)
  int watchedSeconds;

  @HiveField(7)
  int totalSeconds;

  @HiveField(8)
  bool pendingSync;

  DownloadedVideoHive({
    required this.videoId,
    required this.courseId,
    required this.localPath,
    required this.downloadStatus,
    required this.downloadedAt,
    required this.fileSize,
    this.watchedSeconds = 0,
    this.totalSeconds = 0,
    this.pendingSync = false,
  });

  bool get isCompleted => downloadStatus == 'completed';
}

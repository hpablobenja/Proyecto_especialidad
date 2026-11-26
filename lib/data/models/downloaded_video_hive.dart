// lib/data/models/downloaded_video_hive.dart

import 'package:hive/hive.dart';

part 'downloaded_video_hive.g.dart';

@HiveType(typeId: 6)
class DownloadedVideoHive extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  String videoId;

  @HiveField(2)
  String courseId;

  @HiveField(3)
  String localPath;

  @HiveField(4)
  String downloadStatus; // 'pending', 'downloading', 'paused', 'completed', 'failed', 'canceled'

  @HiveField(5)
  DateTime downloadedAt;

  @HiveField(6)
  int fileSize;

  @HiveField(7)
  int watchedSeconds;

  @HiveField(8)
  int totalSeconds;

  @HiveField(9)
  bool pendingSync;

  DownloadedVideoHive({
    required this.userId,
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

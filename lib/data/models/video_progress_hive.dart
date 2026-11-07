// lib/data/models/video_progress_hive.dart

import 'package:hive/hive.dart';
import '../../../domain/entities/video_tracking_entity.dart';

part 'video_progress_hive.g.dart';

/// Modelo Hive para persistencia local de progreso de video
/// Este es el Nivel 2 de la arquitectura híbrida de tracking
@HiveType(typeId: 1)
class VideoProgressHive {
  @HiveField(0)
  String userId;

  @HiveField(1)
  String courseId;

  @HiveField(2)
  String moduleId;

  @HiveField(3)
  String lessonId;

  @HiveField(4)
  int currentPositionMs;

  @HiveField(5)
  int lastValidPositionMs;

  @HiveField(6)
  int maxReachedPositionMs;

  @HiveField(7)
  int viewedSeconds;

  @HiveField(8)
  double completionPercentage;

  @HiveField(9)
  int totalDurationMs;

  @HiveField(10)
  List<String> checkpointsPassed;

  @HiveField(11)
  List<String> checkpointsFailed;

  @HiveField(12)
  bool isCompleted;

  @HiveField(13)
  DateTime lastUpdated;

  @HiveField(14)
  bool needsSync;

  VideoProgressHive({
    required this.userId,
    required this.courseId,
    required this.moduleId,
    required this.lessonId,
    required this.currentPositionMs,
    required this.lastValidPositionMs,
    required this.maxReachedPositionMs,
    required this.viewedSeconds,
    required this.completionPercentage,
    required this.totalDurationMs,
    required this.checkpointsPassed,
    required this.checkpointsFailed,
    required this.isCompleted,
    required this.lastUpdated,
    required this.needsSync,
  });

  /// Convierte desde VideoTrackingEntity
  factory VideoProgressHive.fromEntity(VideoTrackingEntity entity) {
    return VideoProgressHive(
      userId: entity.userId,
      courseId: entity.courseId,
      moduleId: entity.moduleId,
      lessonId: entity.lessonId,
      currentPositionMs: entity.currentPositionMs,
      lastValidPositionMs: entity.lastValidPositionMs,
      maxReachedPositionMs: entity.maxReachedPositionMs,
      viewedSeconds: entity.viewedSeconds,
      completionPercentage: entity.completionPercentage,
      totalDurationMs: entity.totalDurationMs,
      checkpointsPassed: entity.checkpointsPassed,
      checkpointsFailed: entity.checkpointsFailed,
      isCompleted: entity.isCompleted,
      lastUpdated: entity.lastUpdated,
      needsSync: entity.needsSync,
    );
  }

  /// Convierte a VideoTrackingEntity
  VideoTrackingEntity toEntity() {
    return VideoTrackingEntity(
      userId: userId,
      courseId: courseId,
      moduleId: moduleId,
      lessonId: lessonId,
      currentPositionMs: currentPositionMs,
      lastValidPositionMs: lastValidPositionMs,
      maxReachedPositionMs: maxReachedPositionMs,
      viewedSeconds: viewedSeconds,
      completionPercentage: completionPercentage,
      totalDurationMs: totalDurationMs,
      checkpointsPassed: checkpointsPassed,
      checkpointsFailed: checkpointsFailed,
      isCompleted: isCompleted,
      lastUpdated: lastUpdated,
      needsSync: needsSync,
    );
  }

  /// Convierte a Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseId': courseId,
      'moduleId': moduleId,
      'lessonId': lessonId,
      'currentPositionMs': currentPositionMs,
      'lastValidPositionMs': lastValidPositionMs,
      'maxReachedPositionMs': maxReachedPositionMs,
      'viewedSeconds': viewedSeconds,
      'completionPercentage': completionPercentage,
      'totalDurationMs': totalDurationMs,
      'checkpointsPassed': checkpointsPassed,
      'checkpointsFailed': checkpointsFailed,
      'isCompleted': isCompleted,
      'lastUpdated': lastUpdated.toIso8601String(),
      'needsSync': needsSync,
    };
  }

  /// Genera una clave única para este progreso
  String get key => '${userId}_$lessonId';
}

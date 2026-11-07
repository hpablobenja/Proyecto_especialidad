// lib/domain/entities/video_tracking_entity.dart

import 'package:equatable/equatable.dart';

class VideoTrackingEntity extends Equatable {
  final String userId;
  final String courseId;
  final String moduleId;
  final String lessonId;

  // Posiciones en milisegundos
  final int currentPositionMs;
  final int lastValidPositionMs;
  final int maxReachedPositionMs;

  // Métricas de tiempo
  final int viewedSeconds;
  final double completionPercentage;
  final int totalDurationMs;

  // Checkpoints
  final List<String> checkpointsPassed;
  final List<String> checkpointsFailed;

  // Estado
  final bool isCompleted;
  final DateTime lastUpdated;
  final bool needsSync;

  const VideoTrackingEntity({
    required this.userId,
    required this.courseId,
    required this.moduleId,
    required this.lessonId,
    this.currentPositionMs = 0,
    this.lastValidPositionMs = 0,
    this.maxReachedPositionMs = 0,
    this.viewedSeconds = 0,
    this.completionPercentage = 0.0,
    this.totalDurationMs = 0,
    this.checkpointsPassed = const [],
    this.checkpointsFailed = const [],
    this.isCompleted = false,
    required this.lastUpdated,
    this.needsSync = false,
  });

  @override
  List<Object?> get props => [
    userId,
    courseId,
    moduleId,
    lessonId,
    currentPositionMs,
    lastValidPositionMs,
    maxReachedPositionMs,
    viewedSeconds,
    completionPercentage,
    totalDurationMs,
    checkpointsPassed,
    checkpointsFailed,
    isCompleted,
    lastUpdated,
    needsSync,
  ];

  VideoTrackingEntity copyWith({
    String? userId,
    String? courseId,
    String? moduleId,
    String? lessonId,
    int? currentPositionMs,
    int? lastValidPositionMs,
    int? maxReachedPositionMs,
    int? viewedSeconds,
    double? completionPercentage,
    int? totalDurationMs,
    List<String>? checkpointsPassed,
    List<String>? checkpointsFailed,
    bool? isCompleted,
    DateTime? lastUpdated,
    bool? needsSync,
  }) {
    return VideoTrackingEntity(
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      moduleId: moduleId ?? this.moduleId,
      lessonId: lessonId ?? this.lessonId,
      currentPositionMs: currentPositionMs ?? this.currentPositionMs,
      lastValidPositionMs: lastValidPositionMs ?? this.lastValidPositionMs,
      maxReachedPositionMs: maxReachedPositionMs ?? this.maxReachedPositionMs,
      viewedSeconds: viewedSeconds ?? this.viewedSeconds,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      checkpointsPassed: checkpointsPassed ?? this.checkpointsPassed,
      checkpointsFailed: checkpointsFailed ?? this.checkpointsFailed,
      isCompleted: isCompleted ?? this.isCompleted,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      needsSync: needsSync ?? this.needsSync,
    );
  }

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

  factory VideoTrackingEntity.fromMap(Map<String, dynamic> map) {
    return VideoTrackingEntity(
      userId: map['userId'] as String,
      courseId: map['courseId'] as String,
      moduleId: map['moduleId'] as String,
      lessonId: map['lessonId'] as String,
      currentPositionMs: map['currentPositionMs'] as int? ?? 0,
      lastValidPositionMs: map['lastValidPositionMs'] as int? ?? 0,
      maxReachedPositionMs: map['maxReachedPositionMs'] as int? ?? 0,
      viewedSeconds: map['viewedSeconds'] as int? ?? 0,
      completionPercentage:
          (map['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      totalDurationMs: map['totalDurationMs'] as int? ?? 0,
      checkpointsPassed: List<String>.from(
        map['checkpointsPassed'] as List? ?? [],
      ),
      checkpointsFailed: List<String>.from(
        map['checkpointsFailed'] as List? ?? [],
      ),
      isCompleted: map['isCompleted'] as bool? ?? false,
      lastUpdated:
          map['lastUpdated'] is DateTime
              ? map['lastUpdated'] as DateTime
              : DateTime.parse(map['lastUpdated'] as String),
      needsSync: map['needsSync'] as bool? ?? false,
    );
  }

  /// Calcula el porcentaje de completado basado en maxReachedPosition
  double calculateCompletionPercentage() {
    if (totalDurationMs <= 0) return 0.0;
    return (maxReachedPositionMs / totalDurationMs * 100).clamp(0.0, 100.0);
  }

  /// Verifica si la lección está completada (≥90%)
  bool isLessonCompleted() {
    return calculateCompletionPercentage() >= 90.0;
  }
}

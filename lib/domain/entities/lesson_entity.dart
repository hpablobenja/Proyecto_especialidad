// lib/domain/entities/lesson_entity.dart

import 'package:equatable/equatable.dart';

import 'media_resource.dart';

class LessonEntity extends Equatable {
  final String id;
  final String courseId;
  final String moduleId;
  final String title;
  final List<dynamic>? contentDelta; // Quill Delta JSON
  final String? objectives;
  final List<MediaResource> media;
  final List<MediaResource> downloadableResources;
  final List<Map<String, String>> strategies;
  final int orderIndex;
  final DateTime? dripUnlockAt;

  const LessonEntity({
    required this.id,
    required this.courseId,
    required this.moduleId,
    required this.title,
    this.contentDelta,
    this.objectives,
    this.media = const [],
    this.downloadableResources = const [],
    this.strategies = const [],
    required this.orderIndex,
    this.dripUnlockAt,
  });

  @override
  List<Object?> get props => [
        id,
        courseId,
        moduleId,
        title,
        contentDelta,
        objectives,
        media,
        downloadableResources,
        strategies,
        orderIndex,
        dripUnlockAt,
      ];
}

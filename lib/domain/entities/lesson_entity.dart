// lib/domain/entities/lesson_entity.dart

import 'package:equatable/equatable.dart';

import 'media_resource.dart';
import 'checkpoint_entity.dart';

class LessonEntity extends Equatable {
  final String id;
  final String courseId;
  final String moduleId;
  final String title;
  final String? objectives;
  final List<MediaResource> media;
  final List<Map<String, String>> strategies;
  final int orderIndex;
  final List<CheckpointEntity>? checkpoints; // Checkpoints educativos

  const LessonEntity({
    required this.id,
    required this.courseId,
    required this.moduleId,
    required this.title,
    this.objectives,
    this.media = const [],
    this.strategies = const [],
    required this.orderIndex,
    this.checkpoints,
  });

  @override
  List<Object?> get props => [
    id,
    courseId,
    moduleId,
    title,
    objectives,
    media,
    strategies,
    orderIndex,
    checkpoints,
  ];

  /// Crea una copia con algunos campos modificados
  LessonEntity copyWith({
    String? id,
    String? courseId,
    String? moduleId,
    String? title,
    String? objectives,
    List<MediaResource>? media,
    List<Map<String, String>>? strategies,
    int? orderIndex,
    List<CheckpointEntity>? checkpoints,
  }) {
    return LessonEntity(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      objectives: objectives ?? this.objectives,
      media: media ?? this.media,
      strategies: strategies ?? this.strategies,
      orderIndex: orderIndex ?? this.orderIndex,
      checkpoints: checkpoints ?? this.checkpoints,
    );
  }

  /// Convierte desde Map (Firestore)
  factory LessonEntity.fromMap(Map<String, dynamic> map) {
    return LessonEntity(
      id: map['id'] as String,
      courseId: map['courseId'] as String,
      moduleId: map['moduleId'] as String,
      title: map['title'] as String,
      objectives: map['objectives'] as String?,
      media:
          (map['media'] as List<dynamic>?)
              ?.map((e) => MediaResource.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      strategies:
          (map['strategies'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map<String, dynamic>))
              .toList() ??
          [],
      orderIndex: map['orderIndex'] as int? ?? 0,
      checkpoints:
          (map['checkpoints'] as List<dynamic>?)
              ?.map((e) => CheckpointEntity.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convierte a Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'moduleId': moduleId,
      'title': title,
      'objectives': objectives,
      'media': media.map((e) => e.toMap()).toList(),
      'strategies': strategies,
      'orderIndex': orderIndex,
      'checkpoints': checkpoints?.map((e) => e.toMap()).toList(),
    };
  }
}

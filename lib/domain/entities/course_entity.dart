// lib/domain/entities/course_entity.dart

import 'package:equatable/equatable.dart';

class CourseEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String targetAudience;

  const CourseEntity({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.targetAudience,
  });

  @override
  List<Object?> get props => [id, title, description, thumbnailUrl, targetAudience];

  CourseEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? targetAudience,
  }) {
    return CourseEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      targetAudience: targetAudience ?? this.targetAudience,
    );
  }
}

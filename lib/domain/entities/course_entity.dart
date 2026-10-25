// lib/domain/entities/course_entity.dart

import 'package:equatable/equatable.dart';

class CourseEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String targetAudience;
  final String status; // 'draft' o 'published'

  const CourseEntity({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.targetAudience,
    this.status = 'draft',
  });

  @override
  List<Object?> get props => [id, title, description, thumbnailUrl, targetAudience, status];

  /// Sentinel for [copyWith] when [thumbnailUrl] should not be changed.
  static const Object copyWithUnset = Object();

  CourseEntity copyWith({
    String? id,
    String? title,
    String? description,
    Object? thumbnailUrl = copyWithUnset,
    String? targetAudience,
    String? status,
  }) {
    return CourseEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: identical(thumbnailUrl, copyWithUnset)
          ? this.thumbnailUrl
          : thumbnailUrl as String?,
      targetAudience: targetAudience ?? this.targetAudience,
      status: status ?? this.status,
    );
  }
}

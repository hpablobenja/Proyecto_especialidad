// lib/domain/entities/comment_entity.dart

import 'package:equatable/equatable.dart';

class CommentEntity extends Equatable {
  final String id;
  final String courseId;
  final String moduleId;
  final String lessonId;
  final String userId;
  final String userName;
  final String text; // <= 500 chars
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CommentEntity({
    required this.id,
    required this.courseId,
    required this.moduleId,
    required this.lessonId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    courseId,
    moduleId,
    lessonId,
    userId,
    userName,
    text,
    createdAt,
    updatedAt,
  ];
}

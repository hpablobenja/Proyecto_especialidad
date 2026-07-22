import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? courseId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.courseId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'info',
      courseId: data['courseId'],
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      if (courseId != null) 'courseId': courseId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      if (readAt != null) 'readAt': Timestamp.fromDate(readAt!),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? courseId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      courseId: courseId ?? this.courseId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/data/models/notification_model.dart';

class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  FakeDocumentSnapshot({required this.id, required Map<String, dynamic>? data})
      : _data = data ?? const {};

  @override
  final String id;
  final Map<String, dynamic> _data;

  @override
  bool get exists => true;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic get(Object field) => _data[field.toString()];

  @override
  dynamic operator [](Object field) => _data[field.toString()];

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  DocumentReference<Map<String, dynamic>> get reference =>
      throw UnimplementedError();
}

void main() {
  group('NotificationModel Tests', () {
    test('NotificationModel creates correctly with all fields', () {
      final now = DateTime.now();
      final notification = NotificationModel(
        id: 'notif_1',
        title: 'Test Notification',
        body: 'This is a test notification',
        type: 'info',
        courseId: 'course_1',
        isRead: false,
        createdAt: now,
        readAt: null,
      );

      expect(notification.id, 'notif_1');
      expect(notification.title, 'Test Notification');
      expect(notification.body, 'This is a test notification');
      expect(notification.type, 'info');
      expect(notification.courseId, 'course_1');
      expect(notification.isRead, false);
      expect(notification.createdAt, now);
      expect(notification.readAt, null);
    });

    test('NotificationModel creates correctly with optional fields null', () {
      final now = DateTime.now();
      final notification = NotificationModel(
        id: 'notif_1',
        title: 'Test Notification',
        body: 'This is a test notification',
        type: 'info',
        isRead: false,
        createdAt: now,
      );

      expect(notification.courseId, null);
      expect(notification.readAt, null);
    });

    test('NotificationModel toMap includes all fields', () {
      final now = DateTime.now();
      final readAt = now.add(const Duration(hours: 1));
      final notification = NotificationModel(
        id: 'notif_1',
        title: 'Test Notification',
        body: 'This is a test notification',
        type: 'info',
        courseId: 'course_1',
        isRead: true,
        createdAt: now,
        readAt: readAt,
      );

      final map = notification.toMap();

      expect(map['title'], 'Test Notification');
      expect(map['body'], 'This is a test notification');
      expect(map['type'], 'info');
      expect(map['courseId'], 'course_1');
      expect(map['isRead'], true);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['readAt'], isA<Timestamp>());
    });

    test('NotificationModel toMap excludes null courseId', () {
      final now = DateTime.now();
      final notification = NotificationModel(
        id: 'notif_1',
        title: 'Test Notification',
        body: 'This is a test notification',
        type: 'info',
        isRead: false,
        createdAt: now,
      );

      final map = notification.toMap();

      expect(map.containsKey('courseId'), false);
    });

    test('NotificationModel toMap excludes null readAt', () {
      final now = DateTime.now();
      final notification = NotificationModel(
        id: 'notif_1',
        title: 'Test Notification',
        body: 'This is a test notification',
        type: 'info',
        courseId: 'course_1',
        isRead: false,
        createdAt: now,
      );

      final map = notification.toMap();

      expect(map.containsKey('readAt'), false);
    });

    test('NotificationModel copyWith updates specified fields', () {
      final now = DateTime.now();
      final original = NotificationModel(
        id: 'notif_1',
        title: 'Original Title',
        body: 'Original Body',
        type: 'info',
        isRead: false,
        createdAt: now,
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        isRead: true,
      );

      expect(updated.id, original.id);
      expect(updated.title, 'Updated Title');
      expect(updated.body, original.body);
      expect(updated.type, original.type);
      expect(updated.isRead, true);
      expect(updated.createdAt, original.createdAt);
    });

    test('NotificationModel copyWith preserves original when null', () {
      final now = DateTime.now();
      final original = NotificationModel(
        id: 'notif_1',
        title: 'Test Notification',
        body: 'This is a test notification',
        type: 'info',
        isRead: false,
        createdAt: now,
      );

      final updated = original.copyWith();

      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.body, original.body);
      expect(updated.type, original.type);
      expect(updated.isRead, original.isRead);
      expect(updated.createdAt, original.createdAt);
    });

    test('NotificationModel copyWith updates all fields', () {
      final now = DateTime.now();
      final readAt = now.add(const Duration(hours: 1));
      final original = NotificationModel(
        id: 'notif_1',
        title: 'Original',
        body: 'Original body',
        type: 'info',
        isRead: false,
        createdAt: now,
      );

      final updated = original.copyWith(
        id: 'notif_2',
        title: 'Updated',
        body: 'Updated body',
        type: 'warning',
        courseId: 'course_2',
        isRead: true,
        createdAt: now.add(const Duration(days: 1)),
        readAt: readAt,
      );

      expect(updated.id, 'notif_2');
      expect(updated.title, 'Updated');
      expect(updated.body, 'Updated body');
      expect(updated.type, 'warning');
      expect(updated.courseId, 'course_2');
      expect(updated.isRead, true);
      expect(updated.readAt, readAt);
    });
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/data/models/data_user_model.dart';

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
  group('DataUserModel Tests', () {
    test('DataUserModel creates correctly with all fields', () {
      final now = DateTime.now();
      final dataUser = DataUserModel(
        userId: 'user_1',
        currentSessionMinutes: 30,
        totalSessionMinutes: 120,
        sessionStartTime: now,
        lastSessionEnd: now.subtract(const Duration(hours: 1)),
        categoryProgress: {
          'Ciencias Sociales': 0.5,
          'Ciencias Naturales': 0.3,
        },
        overallProgress: 0.4,
        unlockedAchievements: ['achievement1', 'achievement2'],
        updatedAt: now,
      );

      expect(dataUser.userId, 'user_1');
      expect(dataUser.currentSessionMinutes, 30);
      expect(dataUser.totalSessionMinutes, 120);
      expect(dataUser.sessionStartTime, now);
      expect(dataUser.overallProgress, 0.4);
      expect(dataUser.unlockedAchievements.length, 2);
    });

    test('DataUserModel creates with default session minutes', () {
      final now = DateTime.now();
      final dataUser = DataUserModel(
        userId: 'user_1',
        lastSessionEnd: now,
        categoryProgress: {},
        overallProgress: 0.0,
        unlockedAchievements: [],
        updatedAt: now,
      );

      expect(dataUser.currentSessionMinutes, 0);
      expect(dataUser.totalSessionMinutes, 0);
    });

    test('DataUserModel toMap includes all fields', () {
      final now = DateTime.now();
      final dataUser = DataUserModel(
        userId: 'user_1',
        currentSessionMinutes: 30,
        totalSessionMinutes: 120,
        sessionStartTime: now,
        lastSessionEnd: now.subtract(const Duration(hours: 1)),
        categoryProgress: {
          'Ciencias Sociales': 0.5,
          'Ciencias Naturales': 0.3,
        },
        overallProgress: 0.4,
        unlockedAchievements: ['achievement1'],
        updatedAt: now,
      );

      final map = dataUser.toMap();

      expect(map['userId'], 'user_1');
      expect(map['currentSessionMinutes'], 30);
      expect(map['totalSessionMinutes'], 120);
      expect(map['categoryProgress'], isA<Map<String, double>>());
      expect(map['overallProgress'], 0.4);
      expect(map['unlockedAchievements'], ['achievement1']);
    });

    test('DataUserModel toMap excludes null sessionStartTime', () {
      final now = DateTime.now();
      final dataUser = DataUserModel(
        userId: 'user_1',
        sessionStartTime: null,
        lastSessionEnd: now,
        categoryProgress: {},
        overallProgress: 0.0,
        unlockedAchievements: [],
        updatedAt: now,
      );

      final map = dataUser.toMap();

      expect(map.containsKey('sessionStartTime'), false);
    });

    test('DataUserModel copyWith updates specified fields', () {
      final now = DateTime.now();
      final original = DataUserModel(
        userId: 'user_1',
        currentSessionMinutes: 30,
        totalSessionMinutes: 120,
        lastSessionEnd: now,
        categoryProgress: {},
        overallProgress: 0.4,
        unlockedAchievements: [],
        updatedAt: now,
      );

      final updated = original.copyWith(
        currentSessionMinutes: 45,
        overallProgress: 0.5,
      );

      expect(updated.userId, original.userId);
      expect(updated.currentSessionMinutes, 45);
      expect(updated.totalSessionMinutes, original.totalSessionMinutes);
      expect(updated.overallProgress, 0.5);
    });

    test('DataUserModel copyWith preserves original when null', () {
      final now = DateTime.now();
      final original = DataUserModel(
        userId: 'user_1',
        lastSessionEnd: now,
        categoryProgress: {},
        overallProgress: 0.0,
        unlockedAchievements: [],
        updatedAt: now,
      );

      final updated = original.copyWith();

      expect(updated.userId, original.userId);
      expect(updated.currentSessionMinutes, original.currentSessionMinutes);
      expect(updated.totalSessionMinutes, original.totalSessionMinutes);
    });

    test('formatMinutes formats correctly with hours and minutes', () {
      final now = DateTime.now();
      final dataUser = DataUserModel(
        userId: 'user_1',
        lastSessionEnd: now,
        categoryProgress: {},
        overallProgress: 0.0,
        unlockedAchievements: [],
        updatedAt: now,
      );

      expect(dataUser.formatMinutes(125), '2h 5m');
      expect(dataUser.formatMinutes(60), '1h 0m');
      expect(dataUser.formatMinutes(90), '1h 30m');
    });

    test('formatMinutes formats correctly with only minutes', () {
      final now = DateTime.now();
      final dataUser = DataUserModel(
        userId: 'user_1',
        lastSessionEnd: now,
        categoryProgress: {},
        overallProgress: 0.0,
        unlockedAchievements: [],
        updatedAt: now,
      );

      expect(dataUser.formatMinutes(45), '45m');
      expect(dataUser.formatMinutes(1), '1m');
      expect(dataUser.formatMinutes(0), '0m');
    });

    test('currentSessionFormatted returns formatted current session', () {
      final now = DateTime.now();
      final dataUser = DataUserModel(
        userId: 'user_1',
        currentSessionMinutes: 65,
        lastSessionEnd: now,
        categoryProgress: {},
        overallProgress: 0.0,
        unlockedAchievements: [],
        updatedAt: now,
      );

      expect(dataUser.currentSessionFormatted, '1h 5m');
    });

    test('totalSessionFormatted includes current session', () {
      final now = DateTime.now();
      final dataUser = DataUserModel(
        userId: 'user_1',
        currentSessionMinutes: 30,
        totalSessionMinutes: 90,
        lastSessionEnd: now,
        categoryProgress: {},
        overallProgress: 0.0,
        unlockedAchievements: [],
        updatedAt: now,
      );

      expect(dataUser.totalSessionFormatted, '2h 0m');
    });
  });
}

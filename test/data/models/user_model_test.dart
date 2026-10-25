import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/data/models/user_model.dart';
import 'package:redmaestra1/domain/entities/user_entity.dart';

void main() {
  group('UserModel Tests', () {
    test('UserModel creates correctly with all fields', () {
      final userModel = const UserModel(
        uid: 'test_uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'maestro',
        workArea: 'Education',
        specialty: 'Mathematics',
      );

      expect(userModel.uid, 'test_uid');
      expect(userModel.email, 'test@example.com');
      expect(userModel.name, 'Test User');
      expect(userModel.role, 'maestro');
      expect(userModel.workArea, 'Education');
      expect(userModel.specialty, 'Mathematics');
    });

    test('UserModel creates correctly with optional fields null', () {
      final userModel = const UserModel(
        uid: 'test_uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'maestro',
      );

      expect(userModel.uid, 'test_uid');
      expect(userModel.workArea, null);
      expect(userModel.specialty, null);
    });

    test('UserModel fromMap creates correctly', () {
      final map = {
        'uid': 'test_uid',
        'email': 'test@example.com',
        'name': 'Test User',
        'role': 'maestro',
        'workArea': 'Education',
        'specialty': 'Mathematics',
      };

      final userModel = UserModel.fromMap(map);

      expect(userModel.uid, 'test_uid');
      expect(userModel.email, 'test@example.com');
      expect(userModel.name, 'Test User');
      expect(userModel.role, 'maestro');
      expect(userModel.workArea, 'Education');
      expect(userModel.specialty, 'Mathematics');
    });

    test('UserModel fromMap handles null name', () {
      final map = {
        'uid': 'test_uid',
        'email': 'test@example.com',
        'name': null,
        'role': 'maestro',
      };

      final userModel = UserModel.fromMap(map);

      expect(userModel.name, 'Usuario');
    });

    test('UserModel fromMap handles null optional fields', () {
      final map = {
        'uid': 'test_uid',
        'email': 'test@example.com',
        'name': 'Test User',
        'role': 'maestro',
        'workArea': null,
        'specialty': null,
      };

      final userModel = UserModel.fromMap(map);

      expect(userModel.workArea, null);
      expect(userModel.specialty, null);
    });

    test('UserModel toMap includes all fields', () {
      final userModel = const UserModel(
        uid: 'test_uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'maestro',
        workArea: 'Education',
        specialty: 'Mathematics',
      );

      final map = userModel.toMap();

      expect(map['uid'], 'test_uid');
      expect(map['email'], 'test@example.com');
      expect(map['name'], 'Test User');
      expect(map['role'], 'maestro');
      expect(map['workArea'], 'Education');
      expect(map['specialty'], 'Mathematics');
    });

    test('UserModel toMap excludes null optional fields', () {
      final userModel = const UserModel(
        uid: 'test_uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'maestro',
      );

      final map = userModel.toMap();

      expect(map.containsKey('workArea'), false);
      expect(map.containsKey('specialty'), false);
    });

    test('UserModel extends UserEntity', () {
      final userModel = const UserModel(
        uid: 'test_uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'maestro',
      );

      expect(userModel, isA<UserEntity>());
    });

    test('UserModel round-trip fromMap toMap', () {
      final originalMap = {
        'uid': 'test_uid',
        'email': 'test@example.com',
        'name': 'Test User',
        'role': 'maestro',
        'workArea': 'Education',
        'specialty': 'Mathematics',
      };

      final userModel = UserModel.fromMap(originalMap);
      final resultMap = userModel.toMap();

      expect(resultMap['uid'], originalMap['uid']);
      expect(resultMap['email'], originalMap['email']);
      expect(resultMap['name'], originalMap['name']);
      expect(resultMap['role'], originalMap['role']);
      expect(resultMap['workArea'], originalMap['workArea']);
      expect(resultMap['specialty'], originalMap['specialty']);
    });
  });
}

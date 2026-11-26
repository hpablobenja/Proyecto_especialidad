import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/system_config_entity.dart';

void main() {
  group('SystemConfigEntity Tests', () {
    test('SystemConfigEntity se crea con valores por defecto', () {
      final config = const SystemConfigEntity();

      expect(config.seekToleranceSeconds, 5);
      expect(config.trackingIntervalSeconds, 1);
      expect(config.syncIntervalSeconds, 60);
      expect(config.completionThreshold, 90.0);
      expect(config.maxQuestionsForTeacher, 5);
      expect(config.maxQuestionsBank, 20);
      expect(config.maxCheckpointAttempts, 3);
      expect(config.enableCheckpoints, true);
      expect(config.sessionWarningMinutes, 5);
      expect(config.maxSessionDurationMinutes, 120);
      expect(config.maxSyncRetries, 5);
      expect(config.enableOfflineMode, true);
      expect(config.enableAnimations, true);
      expect(config.defaultTheme, 'system');
      expect(config.enableLocalDataClearForTeachers, false);
    });

    test('SystemConfigEntity se crea con valores personalizados', () {
      final config = const SystemConfigEntity(
        seekToleranceSeconds: 10,
        trackingIntervalSeconds: 2,
        syncIntervalSeconds: 30,
        completionThreshold: 95.0,
        maxQuestionsForTeacher: 10,
        maxQuestionsBank: 50,
        maxCheckpointAttempts: 5,
        enableCheckpoints: false,
        sessionWarningMinutes: 10,
        maxSessionDurationMinutes: 180,
        maxSyncRetries: 10,
        enableOfflineMode: false,
        enableAnimations: false,
        defaultTheme: 'dark',
        enableLocalDataClearForTeachers: true,
      );

      expect(config.seekToleranceSeconds, 10);
      expect(config.trackingIntervalSeconds, 2);
      expect(config.syncIntervalSeconds, 30);
      expect(config.completionThreshold, 95.0);
      expect(config.maxQuestionsForTeacher, 10);
      expect(config.maxQuestionsBank, 50);
      expect(config.maxCheckpointAttempts, 5);
      expect(config.enableCheckpoints, false);
      expect(config.sessionWarningMinutes, 10);
      expect(config.maxSessionDurationMinutes, 180);
      expect(config.maxSyncRetries, 10);
      expect(config.enableOfflineMode, false);
      expect(config.enableAnimations, false);
      expect(config.defaultTheme, 'dark');
      expect(config.enableLocalDataClearForTeachers, true);
    });

    test('SystemConfigEntity con equatable funciona', () {
      final config1 = const SystemConfigEntity(
        seekToleranceSeconds: 10,
        completionThreshold: 95.0,
      );

      final config2 = const SystemConfigEntity(
        seekToleranceSeconds: 10,
        completionThreshold: 95.0,
      );

      final config3 = const SystemConfigEntity(
        seekToleranceSeconds: 5,
        completionThreshold: 90.0,
      );

      expect(config1, config2);
      expect(config1, isNot(config3));
    });

    test('SystemConfigEntity copyWith funciona', () {
      final original = const SystemConfigEntity();
      final updated = original.copyWith(
        seekToleranceSeconds: 15,
        completionThreshold: 85.0,
        enableCheckpoints: false,
      );

      expect(updated.seekToleranceSeconds, 15);
      expect(updated.completionThreshold, 85.0);
      expect(updated.enableCheckpoints, false);
      expect(updated.trackingIntervalSeconds, original.trackingIntervalSeconds);
    });

    test('SystemConfigEntity toMap funciona', () {
      final config = const SystemConfigEntity(
        seekToleranceSeconds: 10,
        completionThreshold: 95.0,
      );

      final map = config.toMap();

      expect(map['seekToleranceSeconds'], 10);
      expect(map['completionThreshold'], 95.0);
      expect(map['trackingIntervalSeconds'], 1);
      expect(map.containsKey('updatedAt'), true);
    });

    test('SystemConfigEntity fromMap funciona', () {
      final map = {
        'seekToleranceSeconds': 15,
        'trackingIntervalSeconds': 3,
        'syncIntervalSeconds': 45,
        'completionThreshold': 88.5,
        'maxQuestionsForTeacher': 8,
        'maxQuestionsBank': 30,
        'maxCheckpointAttempts': 4,
        'enableCheckpoints': true,
        'sessionWarningMinutes': 7,
        'maxSessionDurationMinutes': 150,
        'maxSyncRetries': 7,
        'enableOfflineMode': true,
        'enableAnimations': true,
        'defaultTheme': 'light',
        'enableLocalDataClearForTeachers': false,
      };

      final config = SystemConfigEntity.fromMap(map);

      expect(config.seekToleranceSeconds, 15);
      expect(config.trackingIntervalSeconds, 3);
      expect(config.syncIntervalSeconds, 45);
      expect(config.completionThreshold, 88.5);
      expect(config.maxQuestionsForTeacher, 8);
      expect(config.maxQuestionsBank, 30);
      expect(config.maxCheckpointAttempts, 4);
      expect(config.enableCheckpoints, true);
      expect(config.sessionWarningMinutes, 7);
      expect(config.maxSessionDurationMinutes, 150);
      expect(config.maxSyncRetries, 7);
      expect(config.enableOfflineMode, true);
      expect(config.enableAnimations, true);
      expect(config.defaultTheme, 'light');
      expect(config.enableLocalDataClearForTeachers, false);
    });

    test('SystemConfigEntity fromMap con valores nulos usa defaults', () {
      final map = <String, dynamic>{};

      final config = SystemConfigEntity.fromMap(map);

      expect(config.seekToleranceSeconds, 5);
      expect(config.trackingIntervalSeconds, 1);
      expect(config.syncIntervalSeconds, 60);
      expect(config.completionThreshold, 90.0);
    });

    test('SystemConfigEntity fromMap con completionThreshold como int', () {
      final map = {
        'completionThreshold': 95,
      };

      final config = SystemConfigEntity.fromMap(map);

      expect(config.completionThreshold, 95.0);
    });

    test('SystemConfigEntity maneja diferentes temas', () {
      final lightConfig = const SystemConfigEntity(defaultTheme: 'light');
      final darkConfig = const SystemConfigEntity(defaultTheme: 'dark');
      final systemConfig = const SystemConfigEntity(defaultTheme: 'system');

      expect(lightConfig.defaultTheme, 'light');
      expect(darkConfig.defaultTheme, 'dark');
      expect(systemConfig.defaultTheme, 'system');
    });

    test('SystemConfigEntity maneja configuración de video tracking', () {
      final config = const SystemConfigEntity(
        seekToleranceSeconds: 20,
        trackingIntervalSeconds: 5,
        syncIntervalSeconds: 120,
        completionThreshold: 80.0,
      );

      expect(config.seekToleranceSeconds, 20);
      expect(config.trackingIntervalSeconds, 5);
      expect(config.syncIntervalSeconds, 120);
      expect(config.completionThreshold, 80.0);
    });

    test('SystemConfigEntity maneja configuración de checkpoints', () {
      final config = const SystemConfigEntity(
        maxCheckpointAttempts: 10,
        enableCheckpoints: true,
      );

      expect(config.maxCheckpointAttempts, 10);
      expect(config.enableCheckpoints, true);
    });

    test('SystemConfigEntity maneja configuración de sesión', () {
      final config = const SystemConfigEntity(
        sessionWarningMinutes: 15,
        maxSessionDurationMinutes: 240,
      );

      expect(config.sessionWarningMinutes, 15);
      expect(config.maxSessionDurationMinutes, 240);
    });
  });
}

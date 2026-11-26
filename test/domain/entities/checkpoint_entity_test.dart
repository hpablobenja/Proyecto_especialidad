import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/checkpoint_entity.dart';

void main() {
  group('CheckpointEntity Tests', () {
    test('CheckpointEntity se crea correctamente', () {
      final checkpoint = CheckpointEntity(
        id: 'checkpoint_1',
        lessonId: 'lesson_1',
        triggerPositionSeconds: 30,
        question: '¿Cuál es el concepto principal?',
        options: ['Opción A', 'Opción B', 'Opción C', 'Opción D'],
        correctOptionIndex: 1,
      );

      expect(checkpoint.id, 'checkpoint_1');
      expect(checkpoint.lessonId, 'lesson_1');
      expect(checkpoint.triggerPositionSeconds, 30);
      expect(checkpoint.question, '¿Cuál es el concepto principal?');
      expect(checkpoint.options.length, 4);
      expect(checkpoint.correctOptionIndex, 1);
      expect(checkpoint.attempts, 0);
      expect(checkpoint.isPassed, false);
    });

    test('CheckpointEntity con tracking de intentos funciona', () {
      final now = DateTime.now();
      final checkpoint = CheckpointEntity(
        id: 'checkpoint_2',
        lessonId: 'lesson_1',
        triggerPositionSeconds: 60,
        question: '¿Qué es Flutter?',
        options: ['Framework', 'Lenguaje', 'Database', 'OS'],
        correctOptionIndex: 0,
        attempts: 2,
        firstAttemptAt: now,
        passedAt: now,
        isPassed: true,
      );

      expect(checkpoint.attempts, 2);
      expect(checkpoint.firstAttemptAt, now);
      expect(checkpoint.passedAt, now);
      expect(checkpoint.isPassed, true);
    });

    test('CheckpointEntity con equatable funciona', () {
      final checkpoint1 = CheckpointEntity(
        id: 'checkpoint_1',
        lessonId: 'lesson_1',
        triggerPositionSeconds: 30,
        question: 'Test',
        options: ['A', 'B'],
        correctOptionIndex: 0,
      );

      final checkpoint2 = CheckpointEntity(
        id: 'checkpoint_1',
        lessonId: 'lesson_1',
        triggerPositionSeconds: 30,
        question: 'Test',
        options: ['A', 'B'],
        correctOptionIndex: 0,
      );

      final checkpoint3 = CheckpointEntity(
        id: 'checkpoint_2',
        lessonId: 'lesson_1',
        triggerPositionSeconds: 30,
        question: 'Test',
        options: ['A', 'B'],
        correctOptionIndex: 0,
      );

      expect(checkpoint1, checkpoint2);
      expect(checkpoint1, isNot(checkpoint3));
    });

    test('CheckpointEntity copyWith funciona', () {
      final original = CheckpointEntity(
        id: 'checkpoint_1',
        lessonId: 'lesson_1',
        triggerPositionSeconds: 30,
        question: 'Test',
        options: ['A', 'B'],
        correctOptionIndex: 0,
      );

      final updated = original.copyWith(
        attempts: 3,
        isPassed: true,
      );

      expect(updated.id, original.id);
      expect(updated.attempts, 3);
      expect(updated.isPassed, true);
    });

    test('CheckpointEntity toMap funciona', () {
      final now = DateTime.now();
      final checkpoint = CheckpointEntity(
        id: 'checkpoint_1',
        lessonId: 'lesson_1',
        triggerPositionSeconds: 30,
        question: 'Test',
        options: ['A', 'B'],
        correctOptionIndex: 0,
        attempts: 2,
        firstAttemptAt: now,
        passedAt: now,
        isPassed: true,
      );

      final map = checkpoint.toMap();

      expect(map['id'], 'checkpoint_1');
      expect(map['lessonId'], 'lesson_1');
      expect(map['triggerPositionSeconds'], 30);
      expect(map['question'], 'Test');
      expect(map['options'], ['A', 'B']);
      expect(map['correctOptionIndex'], 0);
      expect(map['attempts'], 2);
      expect(map['firstAttemptAt'], now.toIso8601String());
      expect(map['passedAt'], now.toIso8601String());
      expect(map['isPassed'], true);
    });

    test('CheckpointEntity fromMap funciona', () {
      final now = DateTime.now();
      final map = {
        'id': 'checkpoint_1',
        'lessonId': 'lesson_1',
        'triggerPositionSeconds': 30,
        'question': 'Test',
        'options': ['A', 'B'],
        'correctOptionIndex': 0,
        'attempts': 2,
        'firstAttemptAt': now.toIso8601String(),
        'passedAt': now.toIso8601String(),
        'isPassed': true,
      };

      final checkpoint = CheckpointEntity.fromMap(map);

      expect(checkpoint.id, 'checkpoint_1');
      expect(checkpoint.lessonId, 'lesson_1');
      expect(checkpoint.triggerPositionSeconds, 30);
      expect(checkpoint.question, 'Test');
      expect(checkpoint.options, ['A', 'B']);
      expect(checkpoint.correctOptionIndex, 0);
      expect(checkpoint.attempts, 2);
      expect(checkpoint.firstAttemptAt, now);
      expect(checkpoint.passedAt, now);
      expect(checkpoint.isPassed, true);
    });

    test('CheckpointEntity fromMap con valores opcionales nulos funciona', () {
      final map = {
        'id': 'checkpoint_1',
        'lessonId': 'lesson_1',
        'triggerPositionSeconds': 30,
        'question': 'Test',
        'options': ['A', 'B'],
        'correctOptionIndex': 0,
      };

      final checkpoint = CheckpointEntity.fromMap(map);

      expect(checkpoint.attempts, 0);
      expect(checkpoint.firstAttemptAt, null);
      expect(checkpoint.passedAt, null);
      expect(checkpoint.isPassed, false);
    });

    test('CheckpointEntity con múltiples opciones funciona', () {
      final checkpoint = CheckpointEntity(
        id: 'checkpoint_1',
        lessonId: 'lesson_1',
        triggerPositionSeconds: 30,
        question: 'Test',
        options: ['A', 'B', 'C', 'D', 'E'],
        correctOptionIndex: 4,
      );

      expect(checkpoint.options.length, 5);
      expect(checkpoint.correctOptionIndex, 4);
    });
  });
}

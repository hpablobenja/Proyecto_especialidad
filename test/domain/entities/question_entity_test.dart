import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/question_entity.dart';

void main() {
  group('QuestionEntity Tests', () {
    test('QuestionEntity creates correctly with all fields', () {
      final question = const QuestionEntity(
        id: 'question_1',
        text: 'What is Flutter?',
        options: ['A framework', 'A language', 'A database'],
        correctAnswerIndex: 0,
      );

      expect(question.id, 'question_1');
      expect(question.text, 'What is Flutter?');
      expect(question.options.length, 3);
      expect(question.options[0], 'A framework');
      expect(question.options[1], 'A language');
      expect(question.options[2], 'A database');
      expect(question.correctAnswerIndex, 0);
    });

    test('QuestionEntity with equatable works correctly', () {
      const question1 = QuestionEntity(
        id: 'question_1',
        text: 'What is Flutter?',
        options: ['A framework', 'A language', 'A database'],
        correctAnswerIndex: 0,
      );

      const question2 = QuestionEntity(
        id: 'question_1',
        text: 'What is Flutter?',
        options: ['A framework', 'A language', 'A database'],
        correctAnswerIndex: 0,
      );

      const question3 = QuestionEntity(
        id: 'question_2',
        text: 'What is Flutter?',
        options: ['A framework', 'A language', 'A database'],
        correctAnswerIndex: 0,
      );

      expect(question1, question2);
      expect(question1, isNot(question3));
    });

    test('QuestionEntity props includes all fields', () {
      const question = QuestionEntity(
        id: 'question_1',
        text: 'What is Flutter?',
        options: ['A framework', 'A language', 'A database'],
        correctAnswerIndex: 0,
      );

      final props = question.props;
      expect(props.length, 4);
      expect(props, contains('question_1'));
      expect(props, contains('What is Flutter?'));
    });

    test('QuestionEntity toMap returns correct map', () {
      const question = QuestionEntity(
        id: 'question_1',
        text: 'What is Flutter?',
        options: ['A framework', 'A language', 'A database'],
        correctAnswerIndex: 0,
      );

      final map = question.toMap();

      expect(map['id'], 'question_1');
      expect(map['text'], 'What is Flutter?');
      expect(map['options'], ['A framework', 'A language', 'A database']);
      expect(map['correctAnswerIndex'], 0);
    });

    test('QuestionEntity fromMap creates correctly', () {
      final map = {
        'id': 'question_1',
        'text': 'What is Flutter?',
        'options': ['A framework', 'A language', 'A database'],
        'correctAnswerIndex': 0,
      };

      final question = QuestionEntity.fromMap(map);

      expect(question.id, 'question_1');
      expect(question.text, 'What is Flutter?');
      expect(question.options.length, 3);
      expect(question.correctAnswerIndex, 0);
    });

    test('QuestionEntity round-trip fromMap toMap', () {
      const original = QuestionEntity(
        id: 'question_1',
        text: 'What is Flutter?',
        options: ['A framework', 'A language', 'A database'],
        correctAnswerIndex: 0,
      );

      final map = original.toMap();
      final recreated = QuestionEntity.fromMap(map);

      expect(recreated.id, original.id);
      expect(recreated.text, original.text);
      expect(recreated.options, original.options);
      expect(recreated.correctAnswerIndex, original.correctAnswerIndex);
    });

    test('QuestionEntity with different correctAnswerIndex are not equal', () {
      const question1 = QuestionEntity(
        id: 'question_1',
        text: 'What is Flutter?',
        options: ['A framework', 'A language', 'A database'],
        correctAnswerIndex: 0,
      );

      const question2 = QuestionEntity(
        id: 'question_1',
        text: 'What is Flutter?',
        options: ['A framework', 'A language', 'A database'],
        correctAnswerIndex: 1,
      );

      expect(question1, isNot(question2));
    });

    test('QuestionEntity with different options are not equal', () {
      const question1 = QuestionEntity(
        id: 'question_1',
        text: 'What is Flutter?',
        options: ['A framework', 'A language', 'A database'],
        correctAnswerIndex: 0,
      );

      const question2 = QuestionEntity(
        id: 'question_1',
        text: 'What is Flutter?',
        options: ['A framework', 'A tool', 'A database'],
        correctAnswerIndex: 0,
      );

      expect(question1, isNot(question2));
    });

    test('QuestionEntity handles special characters in text', () {
      const question = QuestionEntity(
        id: 'question_1',
        text: '¿Qué es Flutter?',
        options: ['Un framework', 'Un lenguaje', 'Una base de datos'],
        correctAnswerIndex: 0,
      );

      expect(question.text, contains('¿Qué'));
    });

    test('QuestionEntity handles empty options list', () {
      const question = QuestionEntity(
        id: 'question_1',
        text: 'What is Flutter?',
        options: [],
        correctAnswerIndex: 0,
      );

      expect(question.options, isEmpty);
    });

    test('QuestionEntity handles single option', () {
      const question = QuestionEntity(
        id: 'question_1',
        text: 'What is Flutter?',
        options: ['A framework'],
        correctAnswerIndex: 0,
      );

      expect(question.options.length, 1);
    });

    test('QuestionEntity handles more than 3 options', () {
      const question = QuestionEntity(
        id: 'question_1',
        text: 'What is Flutter?',
        options: [
          'A framework',
          'A language',
          'A database',
          'A tool',
          'A library',
        ],
        correctAnswerIndex: 0,
      );

      expect(question.options.length, 5);
    });
  });
}

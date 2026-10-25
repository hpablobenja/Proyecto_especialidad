import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/quiz_entity.dart';
import 'package:redmaestra1/domain/entities/question_entity.dart';

void main() {
  group('QuizEntity Tests', () {
    test('QuizEntity creates correctly with all fields', () {
      final questions = [
        const QuestionEntity(
          id: 'q1',
          text: 'Question 1',
          options: ['A', 'B', 'C'],
          correctAnswerIndex: 0,
        ),
        const QuestionEntity(
          id: 'q2',
          text: 'Question 2',
          options: ['A', 'B', 'C'],
          correctAnswerIndex: 1,
        ),
      ];

      final quiz = QuizEntity(
        id: 'quiz_1',
        lessonId: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        questions: questions,
      );

      expect(quiz.id, 'quiz_1');
      expect(quiz.lessonId, 'lesson_1');
      expect(quiz.courseId, 'course_1');
      expect(quiz.moduleId, 'module_1');
      expect(quiz.questions.length, 2);
    });

    test('QuizEntity with equatable works correctly', () {
      final questions = [
        const QuestionEntity(
          id: 'q1',
          text: 'Question 1',
          options: ['A', 'B', 'C'],
          correctAnswerIndex: 0,
        ),
      ];

      final quiz1 = QuizEntity(
        id: 'quiz_1',
        lessonId: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        questions: questions,
      );

      final quiz2 = QuizEntity(
        id: 'quiz_1',
        lessonId: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        questions: questions,
      );

      final questions2 = [
        const QuestionEntity(
          id: 'q2',
          text: 'Question 2',
          options: ['A', 'B', 'C'],
          correctAnswerIndex: 0,
        ),
      ];

      final quiz3 = QuizEntity(
        id: 'quiz_2',
        lessonId: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        questions: questions2,
      );

      expect(quiz1, quiz2);
      expect(quiz1, isNot(quiz3));
    });

    test('QuizEntity props includes all fields', () {
      final questions = [
        const QuestionEntity(
          id: 'q1',
          text: 'Question 1',
          options: ['A', 'B', 'C'],
          correctAnswerIndex: 0,
        ),
      ];

      final quiz = QuizEntity(
        id: 'quiz_1',
        lessonId: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        questions: questions,
      );

      final props = quiz.props;
      expect(props.length, 5);
      expect(props, contains('quiz_1'));
      expect(props, contains('lesson_1'));
      expect(props, contains('course_1'));
      expect(props, contains('module_1'));
    });

    test('QuizEntity toMap returns correct map', () {
      final questions = [
        const QuestionEntity(
          id: 'q1',
          text: 'Question 1',
          options: ['A', 'B', 'C'],
          correctAnswerIndex: 0,
        ),
      ];

      final quiz = QuizEntity(
        id: 'quiz_1',
        lessonId: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        questions: questions,
      );

      final map = quiz.toMap();

      expect(map['id'], 'quiz_1');
      expect(map['lessonId'], 'lesson_1');
      expect(map['courseId'], 'course_1');
      expect(map['moduleId'], 'module_1');
      expect(map['questions'], isA<List>());
    });

    test('QuizEntity fromMap creates correctly', () {
      final map = {
        'id': 'quiz_1',
        'lessonId': 'lesson_1',
        'courseId': 'course_1',
        'moduleId': 'module_1',
        'questions': [
          {
            'id': 'q1',
            'text': 'Question 1',
            'options': ['A', 'B', 'C'],
            'correctAnswerIndex': 0,
          },
        ],
      };

      final quiz = QuizEntity.fromMap(map);

      expect(quiz.id, 'quiz_1');
      expect(quiz.lessonId, 'lesson_1');
      expect(quiz.courseId, 'course_1');
      expect(quiz.moduleId, 'module_1');
      expect(quiz.questions.length, 1);
    });

    test('QuizEntity round-trip fromMap toMap', () {
      final questions = [
        const QuestionEntity(
          id: 'q1',
          text: 'Question 1',
          options: ['A', 'B', 'C'],
          correctAnswerIndex: 0,
        ),
      ];

      final original = QuizEntity(
        id: 'quiz_1',
        lessonId: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        questions: questions,
      );

      final map = original.toMap();
      final recreated = QuizEntity.fromMap(map);

      expect(recreated.id, original.id);
      expect(recreated.lessonId, original.lessonId);
      expect(recreated.courseId, original.courseId);
      expect(recreated.moduleId, original.moduleId);
      expect(recreated.questions.length, original.questions.length);
    });

    test('QuizEntity with empty questions list', () {
      const quiz = QuizEntity(
        id: 'quiz_1',
        lessonId: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        questions: [],
      );

      expect(quiz.questions, isEmpty);
    });

    test('QuizEntity with many questions', () {
      final questions = List.generate(
        20,
        (index) => QuestionEntity(
          id: 'q$index',
          text: 'Question $index',
          options: ['A', 'B', 'C'],
          correctAnswerIndex: 0,
        ),
      );

      final quiz = QuizEntity(
        id: 'quiz_1',
        lessonId: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        questions: questions,
      );

      expect(quiz.questions.length, 20);
    });

    test('QuizEntity with different questions are not equal', () {
      final questions1 = [
        const QuestionEntity(
          id: 'q1',
          text: 'Question 1',
          options: ['A', 'B', 'C'],
          correctAnswerIndex: 0,
        ),
      ];

      final questions2 = [
        const QuestionEntity(
          id: 'q2',
          text: 'Question 2',
          options: ['A', 'B', 'C'],
          correctAnswerIndex: 0,
        ),
      ];

      final quiz1 = QuizEntity(
        id: 'quiz_1',
        lessonId: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        questions: questions1,
      );

      final quiz2 = QuizEntity(
        id: 'quiz_1',
        lessonId: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        questions: questions2,
      );

      expect(quiz1, isNot(quiz2));
    });

    test('QuizEntity toMap serializes questions correctly', () {
      final questions = [
        const QuestionEntity(
          id: 'q1',
          text: 'Question 1',
          options: ['A', 'B', 'C'],
          correctAnswerIndex: 0,
        ),
      ];

      final quiz = QuizEntity(
        id: 'quiz_1',
        lessonId: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        questions: questions,
      );

      final map = quiz.toMap();
      final serializedQuestions = map['questions'] as List;

      expect(serializedQuestions.length, 1);
      expect(serializedQuestions[0]['id'], 'q1');
      expect(serializedQuestions[0]['text'], 'Question 1');
    });
  });
}

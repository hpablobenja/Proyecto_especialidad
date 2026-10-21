import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/presentation/widgets/course_card.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';

void main() {
  group('CourseCard Widget Tests', () {
    testWidgets('CourseCard muestra el título del curso', (WidgetTester tester) async {
      final course = CourseEntity(
        id: 'course_1',
        title: 'Curso de Flutter',
        description: 'Aprende Flutter desde cero',
        targetAudience: 'Principiantes',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(course: course),
          ),
        ),
      );

      expect(find.text('Curso de Flutter'), findsOneWidget);
    });

    testWidgets('CourseCard muestra la descripción del curso', (WidgetTester tester) async {
      final course = CourseEntity(
        id: 'course_1',
        title: 'Curso de Flutter',
        description: 'Aprende Flutter desde cero',
        targetAudience: 'Principiantes',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(course: course),
          ),
        ),
      );

      expect(find.text('Aprende Flutter desde cero'), findsOneWidget);
    });

    testWidgets('CourseCard tiene botón "Ver Curso"', (WidgetTester tester) async {
      final course = CourseEntity(
        id: 'course_1',
        title: 'Curso de Flutter',
        description: 'Aprende Flutter desde cero',
        targetAudience: 'Principiantes',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(course: course),
          ),
        ),
      );

      expect(find.text('Ver Curso'), findsOneWidget);
    });

    testWidgets('CourseCard tiene Card con elevación', (WidgetTester tester) async {
      final course = CourseEntity(
        id: 'course_1',
        title: 'Curso de Flutter',
        description: 'Aprende Flutter desde cero',
        targetAudience: 'Principiantes',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(course: course),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 4);
    });

    testWidgets('CourseCard tiene bordes redondeados', (WidgetTester tester) async {
      final course = CourseEntity(
        id: 'course_1',
        title: 'Curso de Flutter',
        description: 'Aprende Flutter desde cero',
        targetAudience: 'Principiantes',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(course: course),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(10));
    });
  });
}

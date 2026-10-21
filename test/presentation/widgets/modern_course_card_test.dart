import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/presentation/widgets/modern_course_card.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';

void main() {
  group('ModernCourseCard Widget Tests', () {
    testWidgets('ModernCourseCard acepta parámetros requeridos', (WidgetTester tester) async {
      final course = CourseEntity(
        id: 'course_1',
        title: 'Curso',
        description: 'Descripción',
        targetAudience: 'Todos',
      );

      expect(() => ModernCourseCard(course: course), returnsNormally);
    });

    testWidgets('ModernCourseCard acepta parámetros opcionales', (WidgetTester tester) async {
      final course = CourseEntity(
        id: 'course_1',
        title: 'Curso',
        description: 'Descripción',
        targetAudience: 'Todos',
      );

      expect(() => ModernCourseCard(
        course: course,
        onTap: () {},
        showProgress: true,
        progress: 0.5,
        isEnrolled: true,
        showBadge: true,
      ), returnsNormally);
    });

    testWidgets('ModernCourseCard es un StatelessWidget', (WidgetTester tester) async {
      final course = CourseEntity(
        id: 'course_1',
        title: 'Curso',
        description: 'Descripción',
        targetAudience: 'Todos',
      );

      final widget = ModernCourseCard(course: course);
      expect(widget, isA<StatelessWidget>());
    });
  });
}

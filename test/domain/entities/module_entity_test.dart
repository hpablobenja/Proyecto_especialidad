import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';

void main() {
  group('ModuleEntity Tests', () {
    test('ModuleEntity creates correctly with all fields', () {
      const module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        orderIndex: 1,
      );

      expect(module.id, 'module_1');
      expect(module.courseId, 'course_1');
      expect(module.title, 'Introduction to Flutter');
      expect(module.description, 'Learn the basics');
      expect(module.orderIndex, 1);
    });

    test('ModuleEntity creates correctly with null description', () {
      const module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Introduction to Flutter',
        orderIndex: 1,
      );

      expect(module.description, null);
    });

    test('ModuleEntity with equatable works correctly', () {
      const module1 = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        orderIndex: 1,
      );

      const module2 = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        orderIndex: 1,
      );

      const module3 = ModuleEntity(
        id: 'module_2',
        courseId: 'course_1',
        title: 'Advanced Flutter',
        description: 'Learn advanced concepts',
        orderIndex: 2,
      );

      expect(module1, module2);
      expect(module1, isNot(module3));
    });

    test('ModuleEntity props includes all fields', () {
      const module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Introduction to Flutter',
        description: 'Learn the basics',
        orderIndex: 1,
      );

      final props = module.props;
      expect(props.length, 5);
      expect(props, contains('module_1'));
      expect(props, contains('course_1'));
      expect(props, contains('Introduction to Flutter'));
      expect(props, contains('Learn the basics'));
      expect(props, contains(1));
    });

    test('ModuleEntity with null description in props', () {
      const module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Introduction to Flutter',
        orderIndex: 1,
      );

      final props = module.props;
      expect(props, contains(null));
    });

    test('ModuleEntity handles special characters in title', () {
      const module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Introducción a Flutter',
        description: 'Aprende lo básico',
        orderIndex: 1,
      );

      expect(module.title, contains('Introducción'));
    });

    test('ModuleEntity handles empty description', () {
      const module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Introduction to Flutter',
        description: '',
        orderIndex: 1,
      );

      expect(module.description, '');
    });

    test('ModuleEntity with different orderIndex are not equal', () {
      const module1 = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Introduction to Flutter',
        orderIndex: 1,
      );

      const module2 = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Introduction to Flutter',
        orderIndex: 2,
      );

      expect(module1, isNot(module2));
    });

    test('ModuleEntity with different courseId are not equal', () {
      const module1 = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Introduction to Flutter',
        orderIndex: 1,
      );

      const module2 = ModuleEntity(
        id: 'module_1',
        courseId: 'course_2',
        title: 'Introduction to Flutter',
        orderIndex: 1,
      );

      expect(module1, isNot(module2));
    });

    test('ModuleEntity handles zero orderIndex', () {
      const module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Introduction to Flutter',
        orderIndex: 0,
      );

      expect(module.orderIndex, 0);
    });

    test('ModuleEntity handles large orderIndex', () {
      const module = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Introduction to Flutter',
        orderIndex: 100,
      );

      expect(module.orderIndex, 100);
    });
  });
}

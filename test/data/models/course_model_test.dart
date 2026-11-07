import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/data/models/course_model.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';

void main() {
  group('CourseModel Tests', () {
    test('CourseModel creates correctly with all fields', () {
      const courseModel = CourseModel(
        id: 'course_1',
        title: 'Curso de Flutter',
        description: 'Aprende Flutter desde cero',
        targetAudience: 'Principiantes',
        status: 'published',
      );

      expect(courseModel.id, 'course_1');
      expect(courseModel.title, 'Curso de Flutter');
      expect(courseModel.description, 'Aprende Flutter desde cero');
      expect(courseModel.targetAudience, 'Principiantes');
      expect(courseModel.status, 'published');
    });

    test('CourseModel creates correctly with default status', () {
      const courseModel = CourseModel(
        id: 'course_1',
        title: 'Curso de Flutter',
        description: 'Aprende Flutter desde cero',
        targetAudience: 'Principiantes',
      );

      expect(courseModel.status, 'draft');
    });

    test('CourseModel fromMap creates correctly', () {
      final map = {
        'id': 'course_1',
        'title': 'Curso de Flutter',
        'description': 'Aprende Flutter desde cero',
        'targetAudience': 'Principiantes',
        'status': 'published',
      };

      final courseModel = CourseModel.fromMap(map);

      expect(courseModel.id, 'course_1');
      expect(courseModel.title, 'Curso de Flutter');
      expect(courseModel.description, 'Aprende Flutter desde cero');
      expect(courseModel.targetAudience, 'Principiantes');
      expect(courseModel.status, 'published');
    });

    test('CourseModel fromMap uses default for null targetAudience', () {
      final map = {
        'id': 'course_1',
        'title': 'Curso de Flutter',
        'description': 'Aprende Flutter desde cero',
        'targetAudience': null,
      };

      final courseModel = CourseModel.fromMap(map);

      expect(courseModel.targetAudience, 'Otro(Especificar)');
    });

    test('CourseModel fromMap uses default for null status', () {
      final map = {
        'id': 'course_1',
        'title': 'Curso de Flutter',
        'description': 'Aprende Flutter desde cero',
        'targetAudience': 'Principiantes',
        'status': null,
      };

      final courseModel = CourseModel.fromMap(map);

      expect(courseModel.status, 'draft');
    });

    test('CourseModel toMap includes all fields', () {
      const courseModel = CourseModel(
        id: 'course_1',
        title: 'Curso de Flutter',
        description: 'Aprende Flutter desde cero',
        targetAudience: 'Principiantes',
        status: 'published',
      );

      final map = courseModel.toMap();

      expect(map['id'], 'course_1');
      expect(map['title'], 'Curso de Flutter');
      expect(map['description'], 'Aprende Flutter desde cero');
      expect(map['targetAudience'], 'Principiantes');
      expect(map['status'], 'published');
    });

    test('CourseModel copyWith updates specified fields', () {
      const original = CourseModel(
        id: 'course_1',
        title: 'Curso Original',
        description: 'Descripción original',
        targetAudience: 'Todos',
        status: 'draft',
      );

      final updated = original.copyWith(
        title: 'Curso Actualizado',
        description: 'Descripción actualizada',
        status: 'published',
      );

      expect(updated.id, original.id);
      expect(updated.title, 'Curso Actualizado');
      expect(updated.description, 'Descripción actualizada');
      expect(updated.targetAudience, original.targetAudience);
      expect(updated.status, 'published');
    });

    test('CourseModel copyWith preserves original when null', () {
      const original = CourseModel(
        id: 'course_1',
        title: 'Curso Original',
        description: 'Descripción original',
        targetAudience: 'Todos',
        status: 'draft',
      );

      final updated = original.copyWith();

      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.description, original.description);
      expect(updated.targetAudience, original.targetAudience);
      expect(updated.status, original.status);
    });

    test('CourseModel copyWith updates all fields', () {
      const original = CourseModel(
        id: 'course_1',
        title: 'Curso Original',
        description: 'Descripción original',
        targetAudience: 'Todos',
        status: 'draft',
      );

      final updated = original.copyWith(
        id: 'course_2',
        title: 'Nuevo Curso',
        description: 'Nueva descripción',
        targetAudience: 'Avanzados',
        status: 'published',
      );

      expect(updated.id, 'course_2');
      expect(updated.title, 'Nuevo Curso');
      expect(updated.description, 'Nueva descripción');
      expect(updated.targetAudience, 'Avanzados');
      expect(updated.status, 'published');
    });

    test('CourseModel extends CourseEntity', () {
      const courseModel = CourseModel(
        id: 'course_1',
        title: 'Curso de Flutter',
        description: 'Aprende Flutter',
        targetAudience: 'Principiantes',
      );

      expect(courseModel, isA<CourseEntity>());
    });

    test('CourseModel round-trip fromMap toMap', () {
      final originalMap = {
        'id': 'course_1',
        'title': 'Curso de Flutter',
        'description': 'Aprende Flutter',
        'targetAudience': 'Principiantes',
        'status': 'published',
      };

      final courseModel = CourseModel.fromMap(originalMap);
      final resultMap = courseModel.toMap();

      expect(resultMap['id'], originalMap['id']);
      expect(resultMap['title'], originalMap['title']);
      expect(resultMap['description'], originalMap['description']);
      expect(resultMap['targetAudience'], originalMap['targetAudience']);
      expect(resultMap['status'], originalMap['status']);
    });
  });
}

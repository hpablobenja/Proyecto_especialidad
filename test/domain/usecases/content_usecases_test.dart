import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:redmaestra1/domain/usecases/content/list_courses_usecase.dart';
import 'package:redmaestra1/domain/usecases/content/create_course_usecase.dart';
import 'package:redmaestra1/domain/usecases/content/update_course_usecase.dart';
import 'package:redmaestra1/domain/usecases/content/delete_course_usecase.dart';
import 'package:redmaestra1/domain/usecases/content/create_module_usecase.dart';
import 'package:redmaestra1/domain/usecases/content/create_lesson_usecase.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/usecase.dart';

@GenerateMocks([ContentRepository])
import 'content_usecases_test.mocks.dart';

void main() {
  late MockContentRepository mockContentRepository;

  setUp(() {
    mockContentRepository = MockContentRepository();
  });

  group('ListCoursesUsecase Tests', () {
    test('ListCoursesUsecase retorna lista de cursos', () async {
      final listCoursesUsecase = ListCoursesUsecase(mockContentRepository);

      final expectedCourses = [
        CourseEntity(
          id: 'course_1',
          title: 'Curso 1',
          description: 'Descripción 1',
          targetAudience: 'Principiantes',
        ),
        CourseEntity(
          id: 'course_2',
          title: 'Curso 2',
          description: 'Descripción 2',
          targetAudience: 'Intermedios',
        ),
      ];

      when(mockContentRepository.listCourses())
          .thenAnswer((_) async => expectedCourses);

      final result = await listCoursesUsecase.call(NoParams());

      expect(result.length, 2);
      expect(result[0].id, 'course_1');
      expect(result[1].id, 'course_2');
      verify(mockContentRepository.listCourses());
    });

    test('ListCoursesUsecase retorna lista vacía', () async {
      final listCoursesUsecase = ListCoursesUsecase(mockContentRepository);

      when(mockContentRepository.listCourses())
          .thenAnswer((_) async => []);

      final result = await listCoursesUsecase.call(NoParams());

      expect(result, isEmpty);
      verify(mockContentRepository.listCourses());
    });
  });

  group('CreateCourseUsecase Tests', () {
    test('CreateCourseUsecase crea curso correctamente', () async {
      final createCourseUsecase = CreateCourseUsecase(mockContentRepository);

      final newCourse = CourseEntity(
        id: 'new_course',
        title: 'Nuevo Curso',
        description: 'Nueva Descripción',
        targetAudience: 'Todos',
      );

      when(mockContentRepository.createCourse(newCourse))
          .thenAnswer((_) async => newCourse);

      final result = await createCourseUsecase.call(newCourse);

      expect(result.id, newCourse.id);
      expect(result.title, newCourse.title);
      verify(mockContentRepository.createCourse(newCourse));
    });
  });

  group('UpdateCourseUsecase Tests', () {
    test('UpdateCourseUsecase actualiza curso correctamente', () async {
      final updateCourseUsecase = UpdateCourseUsecase(mockContentRepository);

      final updatedCourse = CourseEntity(
        id: 'course_1',
        title: 'Curso Actualizado',
        description: 'Descripción Actualizada',
        targetAudience: 'Avanzados',
      );

      when(mockContentRepository.updateCourse(updatedCourse))
          .thenAnswer((_) async => updatedCourse);

      final result = await updateCourseUsecase.call(updatedCourse);

      expect(result.title, 'Curso Actualizado');
      verify(mockContentRepository.updateCourse(updatedCourse));
    });
  });

  group('DeleteCourseUsecase Tests', () {
    test('DeleteCourseUsecase elimina curso correctamente', () async {
      final deleteCourseUsecase = DeleteCourseUsecase(mockContentRepository);
      const courseId = 'course_1';

      when(mockContentRepository.deleteCourse(courseId))
          .thenAnswer((_) async {});

      await deleteCourseUsecase.call(DeleteCourseParams(courseId));

      verify(mockContentRepository.deleteCourse(courseId));
    });

    test('DeleteCourseUsecase lanza excepción cuando falla', () async {
      final deleteCourseUsecase = DeleteCourseUsecase(mockContentRepository);
      const courseId = 'invalid_course';

      when(mockContentRepository.deleteCourse(courseId))
          .thenThrow(Exception('Curso no encontrado'));

      expect(
        () => deleteCourseUsecase.call(DeleteCourseParams(courseId)),
        throwsException,
      );
    });
  });

  group('CreateModuleUsecase Tests', () {
    test('CreateModuleUsecase crea módulo correctamente', () async {
      final createModuleUsecase = CreateModuleUsecase(mockContentRepository);

      final newModule = ModuleEntity(
        id: 'module_1',
        courseId: 'course_1',
        title: 'Módulo 1',
        orderIndex: 1,
      );

      when(mockContentRepository.createModule(newModule))
          .thenAnswer((_) async => newModule);

      final result = await createModuleUsecase.call(newModule);

      expect(result.id, newModule.id);
      expect(result.title, newModule.title);
      verify(mockContentRepository.createModule(newModule));
    });
  });

  group('CreateLessonUsecase Tests', () {
    test('CreateLessonUsecase crea lección correctamente', () async {
      final createLessonUsecase = CreateLessonUsecase(mockContentRepository);

      final newLesson = LessonEntity(
        id: 'lesson_1',
        courseId: 'course_1',
        moduleId: 'module_1',
        title: 'Lección 1',
        orderIndex: 1,
      );

      when(mockContentRepository.createLesson(newLesson))
          .thenAnswer((_) async => newLesson);

      final result = await createLessonUsecase.call(newLesson);

      expect(result.id, newLesson.id);
      expect(result.title, newLesson.title);
      verify(mockContentRepository.createLesson(newLesson));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/repositories/course_repository.dart';
import 'package:redmaestra1/domain/usecases/courses/create_course_usecase.dart';
import 'package:redmaestra1/domain/usecases/courses/get_courses_usecase.dart';
import 'package:redmaestra1/domain/usecases/usecase.dart';
import 'package:redmaestra1/presentation/providers/course_provider.dart';

class FakeCourseRepository implements CourseRepository {
  @override
  Future<List<CourseEntity>> getCourses() async => const [];

  @override
  Future<CourseEntity> createCourse(CourseEntity course) async => course;

  @override
  Future<CourseEntity> updateCourse(CourseEntity course) async => course;

  @override
  Future<bool> updateCourseStatus(String courseId, String status) async => true;
}

class FakeGetCoursesUsecase extends GetCoursesUsecase {
  Future<List<CourseEntity>> Function(NoParams)? handler;

  FakeGetCoursesUsecase() : super(FakeCourseRepository());

  void setResponse(List<CourseEntity> courses) {
    handler = (_) async => courses;
  }

  void setError(Object error) {
    handler = (_) async => throw error;
  }

  @override
  Future<List<CourseEntity>> call(NoParams params) async {
    if (handler != null) {
      return handler!(params);
    }
    return const [];
  }
}

class FakeCreateCourseUsecase extends CreateCourseUsecase {
  Future<CourseEntity> Function(CreateCourseParams)? handler;
  CreateCourseParams? lastParams;

  FakeCreateCourseUsecase() : super(FakeCourseRepository());

  void setResponse(CourseEntity course) {
    handler = (_) async => course;
  }

  void setError(Object error) {
    handler = (_) async => throw error;
  }

  @override
  Future<CourseEntity> call(CreateCourseParams params) async {
    lastParams = params;
    if (handler != null) {
      return handler!(params);
    }
    return const CourseEntity(
      id: 'default_course',
      title: 'Default Course',
      description: 'Default Description',
      targetAudience: 'General',
    );
  }
}

void main() {
  group('CourseProvider Tests', () {
    late CourseProvider courseProvider;
    late FakeGetCoursesUsecase fakeGetCoursesUsecase;
    late FakeCreateCourseUsecase fakeCreateCourseUsecase;

    setUp(() {
      fakeGetCoursesUsecase = FakeGetCoursesUsecase();
      fakeCreateCourseUsecase = FakeCreateCourseUsecase();

      courseProvider = CourseProvider(
        getCoursesUsecase: fakeGetCoursesUsecase,
        createCourseUsecase: fakeCreateCourseUsecase,
      );
    });

    tearDown(() {
      courseProvider.dispose();
    });

    test('CourseProvider initializes with default values', () {
      expect(courseProvider.isLoading, false);
      expect(courseProvider.errorMessage, null);
      expect(courseProvider.courses, isEmpty);
    });

    test('isLoading getter returns boolean', () {
      expect(courseProvider.isLoading, isA<bool>());
    });

    test('errorMessage getter returns nullable string', () {
      expect(courseProvider.errorMessage, isA<String?>());
    });

    test('courses getter returns list', () {
      expect(courseProvider.courses, isA<List<CourseEntity>>());
    });

    test('loadCourses sets isLoading to true initially', () async {
      fakeGetCoursesUsecase.setResponse([]);

      final future = courseProvider.loadCourses();
      expect(courseProvider.isLoading, true);

      await future;
    });

    test('loadCourses sets isLoading to false after completion', () async {
      fakeGetCoursesUsecase.setResponse([]);

      await courseProvider.loadCourses();
      expect(courseProvider.isLoading, false);
    });

    test('loadCourses populates courses on success', () async {
      final testCourses = [
        const CourseEntity(
          id: 'course_1',
          title: 'Test Course 1',
          description: 'Description 1',
          targetAudience: 'General',
        ),
        const CourseEntity(
          id: 'course_2',
          title: 'Test Course 2',
          description: 'Description 2',
          targetAudience: 'General',
        ),
      ];

      fakeGetCoursesUsecase.setResponse(testCourses);

      await courseProvider.loadCourses();

      expect(courseProvider.courses.length, 2);
      expect(courseProvider.courses[0].id, 'course_1');
      expect(courseProvider.courses[1].id, 'course_2');
    });

    test('loadCourses sets errorMessage on failure', () async {
      fakeGetCoursesUsecase.setError(Exception('Test error'));

      await courseProvider.loadCourses();

      expect(courseProvider.errorMessage, isNotNull);
      expect(
        courseProvider.errorMessage,
        contains('No se pudieron cargar los cursos'),
      );
    });

    test('loadCourses clears previous errorMessage', () async {
      fakeGetCoursesUsecase.setError(Exception('First error'));

      await courseProvider.loadCourses();
      expect(courseProvider.errorMessage, isNotNull);

      fakeGetCoursesUsecase.setResponse([]);
      await courseProvider.loadCourses();

      expect(courseProvider.errorMessage, null);
    });

    test('createCourse sets isLoading to true initially', () async {
      fakeCreateCourseUsecase.setResponse(
        const CourseEntity(
          id: 'new_course',
          title: 'New Course',
          description: 'Description',
          targetAudience: 'General',
        ),
      );

      final future = courseProvider.createCourse('Title', 'Description');
      expect(courseProvider.isLoading, true);

      await future;
    });

    test('createCourse sets isLoading to false after completion', () async {
      fakeCreateCourseUsecase.setResponse(
        const CourseEntity(
          id: 'new_course',
          title: 'New Course',
          description: 'Description',
          targetAudience: 'General',
        ),
      );

      await courseProvider.createCourse('Title', 'Description');
      expect(courseProvider.isLoading, false);
    });

    test('createCourse returns true on success', () async {
      fakeCreateCourseUsecase.setResponse(
        const CourseEntity(
          id: 'new_course',
          title: 'New Course',
          description: 'Description',
          targetAudience: 'General',
        ),
      );

      final result = await courseProvider.createCourse('Title', 'Description');
      expect(result, true);
    });

    test('createCourse adds new course to courses list', () async {
      final newCourse = const CourseEntity(
        id: 'new_course',
        title: 'New Course',
        description: 'Description',
        targetAudience: 'General',
      );

      fakeCreateCourseUsecase.setResponse(newCourse);

      await courseProvider.createCourse('Title', 'Description');

      expect(courseProvider.courses.contains(newCourse), true);
    });

    test(
      'createCourse uses default targetAudience when not provided',
      () async {
        fakeCreateCourseUsecase.setResponse(
          const CourseEntity(
            id: 'new_course',
            title: 'New Course',
            description: 'Description',
            targetAudience: 'General',
          ),
        );

        await courseProvider.createCourse('Title', 'Description');

        expect(fakeCreateCourseUsecase.lastParams?.targetAudience, 'General');
      },
    );

    test('createCourse uses custom targetAudience when provided', () async {
      fakeCreateCourseUsecase.setResponse(
        const CourseEntity(
          id: 'new_course',
          title: 'New Course',
          description: 'Description',
          targetAudience: 'Principiantes',
        ),
      );

      await courseProvider.createCourse(
        'Title',
        'Description',
        targetAudience: 'Principiantes',
      );

      expect(
        fakeCreateCourseUsecase.lastParams?.targetAudience,
        'Principiantes',
      );
    });

    test('createCourse returns false on failure', () async {
      fakeCreateCourseUsecase.setError(Exception('Test error'));

      final result = await courseProvider.createCourse('Title', 'Description');
      expect(result, false);
    });

    test('createCourse sets errorMessage on failure', () async {
      fakeCreateCourseUsecase.setError(Exception('Test error'));

      await courseProvider.createCourse('Title', 'Description');

      expect(courseProvider.errorMessage, isNotNull);
      expect(courseProvider.errorMessage, contains('Error al crear el curso'));
    });

    test('createCourse clears previous errorMessage', () async {
      fakeCreateCourseUsecase.setError(Exception('First error'));

      await courseProvider.createCourse('Title', 'Description');
      expect(courseProvider.errorMessage, isNotNull);

      fakeCreateCourseUsecase.setResponse(
        const CourseEntity(
          id: 'new_course',
          title: 'New Course',
          description: 'Description',
          targetAudience: 'General',
        ),
      );

      await courseProvider.createCourse('Title 2', 'Description 2');
      expect(courseProvider.errorMessage, null);
    });
  });
}

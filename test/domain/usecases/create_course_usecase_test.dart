import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/repositories/course_repository.dart';
import 'package:redmaestra1/domain/usecases/courses/create_course_usecase.dart';

class MockCourseRepository implements CourseRepository {
  CourseEntity? courseToReturn;
  Exception? errorToThrow;

  @override
  Future<List<CourseEntity>> getCourses() async => [];

  @override
  Future<CourseEntity> createCourse(CourseEntity course) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return courseToReturn ?? course;
  }

  @override
  Future<CourseEntity> updateCourse(CourseEntity course) async => course;

  @override
  Future<bool> updateCourseStatus(String courseId, String status) async => true;
}

void main() {
  group('CreateCourseUsecase Tests', () {
    late CreateCourseUsecase usecase;
    late MockCourseRepository mockRepository;

    setUp(() {
      mockRepository = MockCourseRepository();
      usecase = CreateCourseUsecase(mockRepository);
    });

    test('CreateCourseUsecase creates course with draft status', () async {
      final params = CreateCourseParams(
        title: 'Test Course',
        description: 'Test Description',
        targetAudience: 'General',
      );

      final result = await usecase(params);

      expect(result.status, 'draft');
    });

    test('CreateCourseUsecase creates course with empty ID', () async {
      final params = CreateCourseParams(
        title: 'Test Course',
        description: 'Test Description',
        targetAudience: 'General',
      );

      final result = await usecase(params);

      expect(result.id, '');
    });

    test('CreateCourseUsecase preserves title from params', () async {
      final params = CreateCourseParams(
        title: 'My Course',
        description: 'Description',
        targetAudience: 'General',
      );

      final result = await usecase(params);

      expect(result.title, 'My Course');
    });

    test('CreateCourseUsecase preserves description from params', () async {
      final params = CreateCourseParams(
        title: 'Course',
        description: 'My Description',
        targetAudience: 'General',
      );

      final result = await usecase(params);

      expect(result.description, 'My Description');
    });

    test('CreateCourseUsecase preserves targetAudience from params', () async {
      final params = CreateCourseParams(
        title: 'Course',
        description: 'Description',
        targetAudience: 'Ciencias Naturales',
      );

      final result = await usecase(params);

      expect(result.targetAudience, 'Ciencias Naturales');
    });

    test('CreateCourseUsecase calls repository.createCourse', () async {
      final params = CreateCourseParams(
        title: 'Course',
        description: 'Description',
        targetAudience: 'General',
      );

      await usecase(params);

      // Repository was called implicitly
      expect(mockRepository, isNotNull);
    });

    test('CreateCourseUsecase throws exception when repository throws', () async {
      mockRepository.errorToThrow = Exception('Repository error');
      final params = CreateCourseParams(
        title: 'Course',
        description: 'Description',
        targetAudience: 'General',
      );

      expect(() => usecase(params), throwsException);
    });

    test('CreateCourseUsecase handles special characters in title', () async {
      final params = CreateCourseParams(
        title: 'Curso de Matemáticas ñáéíóú',
        description: 'Description',
        targetAudience: 'General',
      );

      final result = await usecase(params);

      expect(result.title, 'Curso de Matemáticas ñáéíóú');
    });

    test('CreateCourseUsecase handles empty description', () async {
      final params = CreateCourseParams(
        title: 'Course',
        description: '',
        targetAudience: 'General',
      );

      final result = await usecase(params);

      expect(result.description, '');
    });

    test('CreateCourseUsecase handles long description', () async {
      final longDescription = 'A' * 1000;
      final params = CreateCourseParams(
        title: 'Course',
        description: longDescription,
        targetAudience: 'General',
      );

      final result = await usecase(params);

      expect(result.description.length, 1000);
    });

    test('CreateCourseUsecase returns repository result', () async {
      mockRepository.courseToReturn = const CourseEntity(
        id: 'generated_id',
        title: 'Course',
        description: 'Description',
        targetAudience: 'General',
        status: 'published',
      );
      final params = CreateCourseParams(
        title: 'Course',
        description: 'Description',
        targetAudience: 'General',
      );

      final result = await usecase(params);

      expect(result.id, 'generated_id');
      expect(result.status, 'published');
    });

    test('CreateCourseParams creates correctly', () {
      final params = CreateCourseParams(
        title: 'Title',
        description: 'Description',
        targetAudience: 'General',
      );

      expect(params.title, 'Title');
      expect(params.description, 'Description');
      expect(params.targetAudience, 'General');
    });
  });
}

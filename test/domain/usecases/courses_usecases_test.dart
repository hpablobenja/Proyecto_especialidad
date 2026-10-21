import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:redmaestra1/domain/usecases/courses/get_courses_usecase.dart';
import 'package:redmaestra1/domain/usecases/courses/create_course_usecase.dart';
import 'package:redmaestra1/domain/usecases/courses/get_course_progress_usecase.dart';
import 'package:redmaestra1/domain/usecases/courses/search_courses_usecase.dart';
import 'package:redmaestra1/domain/usecases/courses/recommend_courses_usecase.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/repositories/course_repository.dart';
import 'package:redmaestra1/domain/usecases/usecase.dart';

@GenerateMocks(
  [CourseRepository, FirebaseFirestore],
  customMocks: [
    MockSpec<CollectionReference<Map<String, dynamic>>>(
      as: #MockMapCollectionReference,
    ),
    MockSpec<Query<Map<String, dynamic>>>(as: #MockMapQuery),
    MockSpec<QuerySnapshot<Map<String, dynamic>>>(as: #MockMapQuerySnapshot),
  ],
)
import 'courses_usecases_test.mocks.dart';

void main() {
  late MockCourseRepository mockCourseRepository;

  CourseEntity buildCourse({
    required String id,
    required String title,
    String description = 'Descripción',
    String targetAudience = 'Todos',
  }) {
    return CourseEntity(
      id: id,
      title: title,
      description: description,
      targetAudience: targetAudience,
    );
  }

  setUp(() {
    mockCourseRepository = MockCourseRepository();
  });

  group('GetCoursesUsecase Tests', () {
    test('GetCoursesUsecase retorna lista de cursos', () async {
      final getCoursesUsecase = GetCoursesUsecase(mockCourseRepository);

      final expectedCourses = [
        buildCourse(
          id: 'course_1',
          title: 'Curso de Flutter',
          description: 'Aprende Flutter',
          targetAudience: 'Principiantes',
        ),
        buildCourse(
          id: 'course_2',
          title: 'Curso de Dart',
          description: 'Aprende Dart',
          targetAudience: 'Intermedios',
        ),
      ];

      when(mockCourseRepository.getCourses())
          .thenAnswer((_) async => expectedCourses);

      final result = await getCoursesUsecase.call(NoParams());

      expect(result.length, 2);
      expect(result[0].title, 'Curso de Flutter');
      verify(mockCourseRepository.getCourses());
    });

    test('GetCoursesUsecase retorna lista vacía cuando no hay cursos', () async {
      final getCoursesUsecase = GetCoursesUsecase(mockCourseRepository);

      when(mockCourseRepository.getCourses()).thenAnswer((_) async => []);

      final result = await getCoursesUsecase.call(NoParams());

      expect(result, isEmpty);
      verify(mockCourseRepository.getCourses());
    });
  });

  group('CreateCourseUsecase Tests', () {
    test('CreateCourseUsecase crea curso como borrador', () async {
      final createCourseUsecase = CreateCourseUsecase(mockCourseRepository);
      final params = CreateCourseParams(
        title: 'Nuevo Curso',
        description: 'Descripción',
        targetAudience: 'Todos',
      );
      final createdCourse = buildCourse(
        id: 'generated_id',
        title: params.title,
        description: params.description,
        targetAudience: params.targetAudience,
      );

      when(mockCourseRepository.createCourse(any))
          .thenAnswer((_) async => createdCourse);

      final result = await createCourseUsecase.call(params);

      expect(result.id, createdCourse.id);
      expect(result.title, params.title);
      final captured = verify(
        mockCourseRepository.createCourse(captureAny),
      ).captured.single as CourseEntity;
      expect(captured.id, isEmpty);
      expect(captured.status, 'draft');
    });
  });

  group('GetCourseProgressUsecase Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockMapCollectionReference mockProgressCollection;
    late MockMapQuery mockProgressQuery;
    late MockMapQuerySnapshot mockProgressSnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockProgressCollection = MockMapCollectionReference();
      mockProgressQuery = MockMapQuery();
      mockProgressSnapshot = MockMapQuerySnapshot();

      when(mockFirestore.collection('userProgress'))
          .thenReturn(mockProgressCollection);
      when(
        mockProgressCollection.where('userId', isEqualTo: anyNamed('isEqualTo')),
      ).thenReturn(mockProgressQuery);
      when(mockProgressQuery.get()).thenAnswer((_) async => mockProgressSnapshot);
      when(mockProgressSnapshot.docs).thenReturn([]);
    });

    test('GetCourseProgressUsecase retorna progreso vacío sin cursos', () async {
      final usecase = GetCourseProgressUsecase(
        mockCourseRepository,
        firestore: mockFirestore,
      );

      when(mockCourseRepository.getCourses()).thenAnswer((_) async => []);

      final result = await usecase.call('user_1');

      expect(result.completedCourses, isEmpty);
      expect(result.inProgressCourses, isEmpty);
      verify(mockCourseRepository.getCourses());
    });

    test('GetCourseProgressUsecase retorna vacío cuando no hay progreso', () async {
      final usecase = GetCourseProgressUsecase(
        mockCourseRepository,
        firestore: mockFirestore,
      );

      when(mockCourseRepository.getCourses()).thenAnswer(
        (_) async => [
          buildCourse(id: 'course_1', title: 'Curso de Flutter'),
        ],
      );

      final result = await usecase.call('user_1');

      expect(result.completedCourses, isEmpty);
      expect(result.inProgressCourses, isEmpty);
      verify(mockCourseRepository.getCourses());
    });
  });

  group('SearchCoursesUsecase Tests', () {
    test('SearchCoursesUsecase busca cursos por término', () async {
      final searchCoursesUsecase = SearchCoursesUsecase(mockCourseRepository);
      const searchTerm = 'Flutter';
      final allCourses = [
        buildCourse(
          id: 'course_1',
          title: 'Curso de Flutter',
          description: 'Aprende Flutter',
          targetAudience: 'Principiantes',
        ),
        buildCourse(
          id: 'course_2',
          title: 'Curso de Dart',
          description: 'Aprende Dart',
          targetAudience: 'Intermedios',
        ),
      ];

      when(mockCourseRepository.getCourses()).thenAnswer((_) async => allCourses);

      final result = await searchCoursesUsecase.call(searchTerm);

      expect(result.length, 1);
      expect(result[0].title, contains('Flutter'));
      verify(mockCourseRepository.getCourses());
    });

    test('SearchCoursesUsecase retorna lista vacía cuando no hay resultados', () async {
      final searchCoursesUsecase = SearchCoursesUsecase(mockCourseRepository);

      when(mockCourseRepository.getCourses()).thenAnswer(
        (_) async => [
          buildCourse(id: 'course_1', title: 'Curso de Dart'),
        ],
      );

      final result = await searchCoursesUsecase.call('TérminoInexistente');

      expect(result, isEmpty);
      verify(mockCourseRepository.getCourses());
    });
  });

  group('RecommendCoursesUsecase Tests', () {
    test('RecommendCoursesUsecase recomienda hasta 3 cursos', () async {
      final recommendCoursesUsecase =
          RecommendCoursesUsecase(mockCourseRepository);
      final allCourses = [
        buildCourse(id: 'course_1', title: 'Curso 1'),
        buildCourse(id: 'course_2', title: 'Curso 2'),
        buildCourse(id: 'course_3', title: 'Curso 3'),
        buildCourse(id: 'course_4', title: 'Curso 4'),
      ];

      when(mockCourseRepository.getCourses()).thenAnswer((_) async => allCourses);

      final result = await recommendCoursesUsecase.call('user_1');

      expect(result.length, 3);
      expect(result.map((c) => c.id), ['course_1', 'course_2', 'course_3']);
      verify(mockCourseRepository.getCourses());
    });

    test('RecommendCoursesUsecase retorna lista vacía cuando no hay cursos', () async {
      final recommendCoursesUsecase =
          RecommendCoursesUsecase(mockCourseRepository);

      when(mockCourseRepository.getCourses()).thenAnswer((_) async => []);

      final result = await recommendCoursesUsecase.call('user_1');

      expect(result, isEmpty);
      verify(mockCourseRepository.getCourses());
    });
  });
}

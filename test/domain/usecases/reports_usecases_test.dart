import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:redmaestra1/domain/repositories/course_repository.dart';
import 'package:redmaestra1/domain/usecases/reports/generate_all_users_report_usecase.dart';
import 'package:redmaestra1/domain/usecases/reports/generate_pdf_report_usecase.dart';

@GenerateMocks([CourseRepository, FirebaseFirestore])
import 'reports_usecases_test.mocks.dart';

void main() {
  late MockCourseRepository mockCourseRepository;
  late MockFirebaseFirestore mockFirestore;

  setUp(() {
    mockCourseRepository = MockCourseRepository();
    mockFirestore = MockFirebaseFirestore();
  });

  group('GeneratePdfReportUsecase Tests', () {
    test('GeneratePdfReportUsecase se puede instanciar', () {
      expect(
        () => GeneratePdfReportUsecase(
          mockCourseRepository,
          firestore: mockFirestore,
        ),
        returnsNormally,
      );
    });
  });

  group('GenerateAllUsersReportUsecase Tests', () {
    test('GenerateAllUsersReportUsecase se puede instanciar', () {
      expect(
        () => GenerateAllUsersReportUsecase(
          mockCourseRepository,
          firestore: mockFirestore,
        ),
        returnsNormally,
      );
    });
  });
}

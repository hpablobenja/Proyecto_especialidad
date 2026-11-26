import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/core/services/excel_import_service.dart';
import 'package:redmaestra1/domain/usecases/content/import_excel_usecase.dart';

class MockExcelImportService implements ExcelImportService {
  ExcelImportResult? resultToReturn;
  Exception? errorToThrow;

  @override
  Future<ExcelImportResult?> importFromExcel() async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return resultToReturn;
  }
}

void main() {
  group('ImportExcelUsecase Tests', () {
    late ImportExcelUsecase usecase;
    late MockExcelImportService mockService;

    setUp(() {
      mockService = MockExcelImportService();
      usecase = ImportExcelUsecase(mockService);
    });

    test('ImportExcelUsecase returns result from service', () async {
      final mockResult = ExcelImportResult(
        courses: [],
        modules: [],
        lessons: [],
        errors: [],
      );
      mockService.resultToReturn = mockResult;

      final params = ImportExcelParams();
      final result = await usecase(params);

      expect(result, mockResult);
    });

    test(
      'ImportExcelUsecase throws exception when service returns null',
      () async {
        mockService.resultToReturn = null;

        final params = ImportExcelParams();

        expect(() => usecase(params), throwsException);
      },
    );

    test('ImportExcelUsecase throws exception when service throws', () async {
      mockService.errorToThrow = Exception('Import failed');

      final params = ImportExcelParams();

      expect(() => usecase(params), throwsException);
    });

    test('ImportExcelParams creates correctly with defaults', () {
      final params = ImportExcelParams();

      expect(params.importCourses, true);
      expect(params.importModules, true);
      expect(params.importLessons, true);
    });

    test('ImportExcelParams creates correctly with custom values', () {
      final params = ImportExcelParams(
        importCourses: false,
        importModules: true,
        importLessons: false,
      );

      expect(params.importCourses, false);
      expect(params.importModules, true);
      expect(params.importLessons, false);
    });

    test('ImportExcelParams with only courses enabled', () {
      final params = ImportExcelParams(
        importCourses: true,
        importModules: false,
        importLessons: false,
      );

      expect(params.importCourses, true);
      expect(params.importModules, false);
      expect(params.importLessons, false);
    });

    test('ImportExcelUsecase calls service', () async {
      final mockResult = ExcelImportResult(
        courses: [],
        modules: [],
        lessons: [],
        errors: [],
      );
      mockService.resultToReturn = mockResult;

      final params = ImportExcelParams();
      await usecase(params);

      expect(mockService.resultToReturn, mockResult);
    });
  });
}

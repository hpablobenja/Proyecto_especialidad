// lib/domain/usecases/content/import_excel_usecase.dart

import '../usecase.dart';
import '../../entities/course_entity.dart';
import '../../entities/module_entity.dart';
import '../../entities/lesson_entity.dart';
import '../../../core/services/excel_import_service.dart';

class ImportExcelUsecase
    implements Usecase<ExcelImportResult, ImportExcelParams> {
  final ExcelImportService excelImportService;

  ImportExcelUsecase(this.excelImportService);

  @override
  Future<ExcelImportResult> call(ImportExcelParams params) async {
    final result = await excelImportService.importFromExcel();

    if (result == null) {
      throw Exception('No se seleccionó ningún archivo');
    }

    return result;
  }
}

class ImportExcelParams {
  final bool importCourses;
  final bool importModules;
  final bool importLessons;

  ImportExcelParams({
    this.importCourses = true,
    this.importModules = true,
    this.importLessons = true,
  });
}

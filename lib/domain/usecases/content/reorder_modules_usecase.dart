// lib/domain/usecases/content/reorder_modules_usecase.dart

import '../../repositories/content_repository.dart';
import '../usecase.dart';

class ReorderModulesParams {
  final String courseId;
  final List<String> orderedModuleIds;
  ReorderModulesParams({
    required this.courseId,
    required this.orderedModuleIds,
  });
}

class ReorderModulesUsecase implements Usecase<void, ReorderModulesParams> {
  final ContentRepository repository;
  ReorderModulesUsecase(this.repository);

  @override
  Future<void> call(ReorderModulesParams params) {
    return repository.reorderModules(params.courseId, params.orderedModuleIds);
  }
}

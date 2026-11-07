// lib/domain/usecases/content/reorder_lessons_usecase.dart

import '../../repositories/content_repository.dart';
import '../usecase.dart';

class ReorderLessonsParams {
  final String courseId;
  final String moduleId;
  final List<String> orderedLessonIds;
  ReorderLessonsParams({
    required this.courseId,
    required this.moduleId,
    required this.orderedLessonIds,
  });
}

class ReorderLessonsUsecase implements Usecase<void, ReorderLessonsParams> {
  final ContentRepository repository;
  ReorderLessonsUsecase(this.repository);

  @override
  Future<void> call(ReorderLessonsParams params) {
    return repository.reorderLessons(
      params.courseId,
      params.moduleId,
      params.orderedLessonIds,
    );
  }
}

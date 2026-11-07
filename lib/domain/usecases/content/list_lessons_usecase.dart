// lib/domain/usecases/content/list_lessons_usecase.dart

import '../../entities/lesson_entity.dart';
import '../../repositories/content_repository.dart';

class ListLessonsUsecase {
  final ContentRepository repo;
  ListLessonsUsecase(this.repo);

  Future<List<LessonEntity>> call({
    required String courseId,
    required String moduleId,
  }) async {
    return repo.listLessons(courseId, moduleId);
  }
}

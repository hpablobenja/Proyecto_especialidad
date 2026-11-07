// lib/domain/usecases/content/delete_lesson_usecase.dart

import '../../repositories/content_repository.dart';
import '../usecase.dart';

class DeleteLessonParams {
  final String courseId;
  final String moduleId;
  final String lessonId;
  DeleteLessonParams({
    required this.courseId,
    required this.moduleId,
    required this.lessonId,
  });
}

class DeleteLessonUsecase implements Usecase<void, DeleteLessonParams> {
  final ContentRepository repository;
  DeleteLessonUsecase(this.repository);

  @override
  Future<void> call(DeleteLessonParams params) {
    return repository.deleteLesson(
      params.courseId,
      params.moduleId,
      params.lessonId,
    );
  }
}

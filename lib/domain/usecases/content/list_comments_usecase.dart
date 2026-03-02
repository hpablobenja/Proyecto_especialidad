// lib/domain/usecases/content/list_comments_usecase.dart
//import '../usecase.dart';
import '../../entities/comment_entity.dart';
import '../../repositories/content_repository.dart';

class ListCommentsUsecase {
  final ContentRepository repo;
  ListCommentsUsecase(this.repo);

  Future<List<CommentEntity>> call({
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) {
    return repo.listComments(
      courseId: courseId,
      moduleId: moduleId,
      lessonId: lessonId,
    );
  }
}
/*
class ListCommentsUsecase
    implements Usecase<List<CommentEntity>, ListCommentsParams> {
  final ContentRepository repo;
  ListCommentsUsecase(this.repo);

  @override
  Future<List<CommentEntity>> call(ListCommentsParams params) {
    return repo.listComments(
      courseId: params.courseId,
      moduleId: params.moduleId,
      lessonId: params.lessonId,
    );
  }
}

class ListCommentsParams {
  final String courseId;
  final String moduleId;
  final String lessonId;
  ListCommentsParams(this.courseId, this.moduleId, this.lessonId);
}
*/
// lib/presentation/providers/comments_provider.dart

import 'package:flutter/material.dart';

import '../../domain/entities/comment_entity.dart';
import '../../domain/usecases/content/list_comments_usecase.dart' as uc_list_comments;
import '../../domain/usecases/content/add_comment_usecase.dart' as uc_add_comment;
import '../../domain/usecases/content/delete_comment_usecase.dart' as uc_delete_comment;

class CommentsProvider extends ChangeNotifier {
  final uc_list_comments.ListCommentsUsecase listCommentsUsecase;
  final uc_add_comment.AddCommentUsecase addCommentUsecase;
  final uc_delete_comment.DeleteCommentUsecase deleteCommentUsecase;

  CommentsProvider({
    required this.listCommentsUsecase,
    required this.addCommentUsecase,
    required this.deleteCommentUsecase,
  });

  bool _loading = false;
  String? _error;
  List<CommentEntity> _items = [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<CommentEntity> get items => List.unmodifiable(_items);

  void _setLoading(bool v) { _loading = v; notifyListeners(); }
  void _setError(String? e) { _error = e; notifyListeners(); }

  Future<void> load({
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      _items = await listCommentsUsecase.call(courseId: courseId, moduleId: moduleId, lessonId: lessonId);
    } catch (e) {
      _setError('Error al cargar comentarios: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> add({
    required String courseId,
    required String moduleId,
    required String lessonId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    _setError(null);
    try {
      final c = CommentEntity(
        id: '',
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
        userId: userId,
        userName: userName,
        text: text.trim(),
        createdAt: DateTime.now(),
      );
      final created = await addCommentUsecase.call(c);
      final stored = CommentEntity(
        id: created.id,
        courseId: created.courseId,
        moduleId: created.moduleId,
        lessonId: created.lessonId,
        userId: created.userId,
        userName: created.userName,
        text: c.text,
        createdAt: created.createdAt,
        updatedAt: created.updatedAt,
      );
      _items = [stored, ..._items];
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> remove({
    required String courseId,
    required String moduleId,
    required String lessonId,
    required String commentId,
  }) async {
    _setError(null);
    try {
      await deleteCommentUsecase.call(
        uc_delete_comment.DeleteCommentParams(
          courseId: courseId,
          moduleId: moduleId,
          lessonId: lessonId,
          commentId: commentId,
        ),
      );
      _items = _items.where((e) => e.id != commentId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar comentario: $e');
      return false;
    }
  }
}

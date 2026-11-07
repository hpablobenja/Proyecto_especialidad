// lib/core/services/quiz_offline_service.dart

import 'package:hive/hive.dart';
import '../../data/models/quiz_progress_hive.dart';

/// Servicio para manejar almacenamiento local de quiz con Hive
/// Permite responder cuestionarios offline y sincronizar después
class QuizOfflineService {
  static const String _boxName = 'quiz_progress';
  late final Box<QuizProgressHive> _box;

  /// Inicializa el servicio
  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<QuizProgressHive>(_boxName);
    } else {
      _box = Hive.box<QuizProgressHive>(_boxName);
    }
  }

  /// Guarda el progreso del quiz localmente
  Future<void> saveQuizProgress(QuizProgressHive progress) async {
    await _box.put(progress.key, progress);
  }

  /// Obtiene el progreso de un quiz específico
  QuizProgressHive? getQuizProgress(String userId, String quizId) {
    final key = '${userId}_$quizId';
    return _box.get(key);
  }

  /// Obtiene el progreso del quiz para una lección específica
  QuizProgressHive? getQuizProgressByLesson(String userId, String lessonId) {
    try {
      final matches = _box.values.where(
        (quiz) => quiz.userId == userId && quiz.lessonId == lessonId,
      );
      if (matches.isEmpty) return null;
      return matches.last;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene todos los quizzes pendientes de sincronización
  List<QuizProgressHive> getPendingSyncQuizzes(String userId) {
    return _box.values
        .where((quiz) => quiz.userId == userId && quiz.needsSync)
        .toList();
  }

  /// Marca un quiz como sincronizado
  Future<void> markAsSynced(String userId, String quizId) async {
    final key = '${userId}_$quizId';
    final quiz = _box.get(key);
    if (quiz != null) {
      quiz.needsSync = false;
      await _box.put(key, quiz);
    }
  }

  /// Elimina un quiz del almacenamiento local
  Future<void> deleteQuizProgress(String userId, String quizId) async {
    final key = '${userId}_$quizId';
    await _box.delete(key);
  }

  /// Obtiene todos los quizzes de un usuario
  List<QuizProgressHive> getUserQuizzes(String userId) {
    return _box.values.where((quiz) => quiz.userId == userId).toList();
  }

  /// Limpia todos los datos (útil para testing o logout)
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Cierra el box
  Future<void> close() async {
    await _box.close();
  }
}

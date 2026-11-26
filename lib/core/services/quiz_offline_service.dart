// lib/core/services/quiz_offline_service.dart

import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/quiz_progress_hive.dart';
import 'hive_encryption_service.dart';

/// Servicio para manejar almacenamiento local de quiz con Hive
/// Permite responder cuestionarios offline y sincronizar después
class QuizOfflineService {
  static const String _boxName = HiveEncryptionService.quizResultsBox;
  late final Box<QuizProgressHive> _box;

  /// Inicializa el servicio
  Future<void> init() async {
    // Borrar el box completamente debido a cambio incompatible en el modelo
    // (agregado del campo questionIds que desplazó los campos)
    // Los datos antiguos no pueden ser migrados automáticamente
    try {
      if (Hive.isBoxOpen(_boxName)) {
        await Hive.box(_boxName).close();
      }
      await Hive.deleteBoxFromDisk(_boxName);
      debugPrint('QuizOfflineService: Box de datos antiguos eliminado debido a cambio de estructura');
    } catch (e) {
      debugPrint('QuizOfflineService: Error al eliminar box antiguo (puede no existir): $e');
    }
    
    _box = await HiveEncryptionService.instance.openBox<QuizProgressHive>(
      _boxName,
    );
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

  /// Elimina todos los quizzes de un usuario
  Future<void> clearUserQuizzes(String userId) async {
    final keysToDelete = _box.keys.where((key) {
      final quiz = _box.get(key);
      return quiz?.userId == userId;
    }).toList();

    for (final key in keysToDelete) {
      await _box.delete(key);
    }
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

// lib/data/datasources/local/video_tracking_hive_datasource.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../../models/video_progress_hive.dart';
import '../../../domain/entities/video_tracking_entity.dart';

/// DataSource local para persistencia de tracking de video usando Hive
/// Este es el Nivel 2 de la arquitectura híbrida
class VideoTrackingHiveDataSource {
  static const String _boxName = 'videoProgress';

  /// Guarda o actualiza el progreso de video
  Future<void> saveVideoProgress(VideoTrackingEntity tracking) async {
    final box = await Hive.openBox<VideoProgressHive>(_boxName);
    final hive = VideoProgressHive.fromEntity(tracking);
    await box.put(hive.key, hive);
  }

  /// Obtiene el progreso de video para una lección específica
  Future<VideoProgressHive?> getVideoProgress(
    String userId,
    String lessonId,
  ) async {
    final box = await Hive.openBox<VideoProgressHive>(_boxName);
    final key = '${userId}_$lessonId';
    return box.get(key);
  }

  /// Obtiene todo el progreso de video de un usuario
  Future<List<VideoProgressHive>> getUserVideoProgress(String userId) async {
    final box = await Hive.openBox<VideoProgressHive>(_boxName);
    return box.values.where((item) => item.userId == userId).toList();
  }

  /// Obtiene progreso que necesita sincronización
  Future<List<VideoProgressHive>> getPendingSync() async {
    final box = await Hive.openBox<VideoProgressHive>(_boxName);
    return box.values.where((item) => item.needsSync).toList();
  }

  /// Marca como sincronizado
  Future<void> markAsSynced(String userId, String lessonId) async {
    final box = await Hive.openBox<VideoProgressHive>(_boxName);
    final key = '${userId}_$lessonId';
    final existing = box.get(key);

    if (existing != null) {
      existing.needsSync = false;
      await box.put(key, existing);
    }
  }

  /// Elimina el progreso de una lección
  Future<void> deleteVideoProgress(String userId, String lessonId) async {
    final box = await Hive.openBox<VideoProgressHive>(_boxName);
    final key = '${userId}_$lessonId';
    await box.delete(key);
  }

  /// Elimina todo el progreso de un usuario
  Future<void> deleteUserProgress(String userId) async {
    final box = await Hive.openBox<VideoProgressHive>(_boxName);
    final keysToDelete =
        box.keys
            .where((key) => key.toString().startsWith('${userId}_'))
            .toList();

    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// Obtiene estadísticas de progreso de un usuario en un curso
  Future<Map<String, dynamic>> getCourseProgressStats(
    String userId,
    String courseId,
  ) async {
    final box = await Hive.openBox<VideoProgressHive>(_boxName);
    final progressList =
        box.values
            .where((item) => item.userId == userId && item.courseId == courseId)
            .toList();

    final totalLessons = progressList.length;
    final completedLessons = progressList.where((p) => p.isCompleted).length;
    final totalViewedSeconds = progressList.fold<int>(
      0,
      (sum, item) => sum + item.viewedSeconds,
    );
    final averageCompletion =
        totalLessons > 0
            ? progressList.fold<double>(
                  0,
                  (sum, item) => sum + item.completionPercentage,
                ) /
                totalLessons
            : 0.0;

    return {
      'totalLessons': totalLessons,
      'completedLessons': completedLessons,
      'totalViewedSeconds': totalViewedSeconds,
      'averageCompletionPercentage': averageCompletion,
    };
  }

  /// Limpia todos los datos (útil para testing)
  Future<void> clearAll() async {
    final box = await Hive.openBox<VideoProgressHive>(_boxName);
    await box.clear();
  }
}

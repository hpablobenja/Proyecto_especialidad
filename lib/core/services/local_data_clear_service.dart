// lib/core/services/local_data_clear_service.dart

import 'package:flutter/foundation.dart';
import '../../data/datasources/local/video_tracking_hive_datasource.dart';
import '../../data/datasources/local/checkpoint_hive_datasource.dart';
import '../../data/datasources/local/sync_queue_hive_datasource.dart';
import '../../core/services/quiz_offline_service.dart';
import '../../core/services/video_download_service.dart';

/// Servicio para limpiar todos los datos locales del sistema
/// Debe usarse manualmente desde la configuración del sistema (solo admin)
class LocalDataClearService {
  static final LocalDataClearService _instance =
      LocalDataClearService._internal();
  factory LocalDataClearService() => _instance;
  LocalDataClearService._internal();

  final VideoTrackingHiveDataSource _videoTrackingDataSource =
      VideoTrackingHiveDataSource();
  final CheckpointHiveDataSource _checkpointDataSource =
      CheckpointHiveDataSource();
  final SyncQueueHiveDataSource _syncQueueDataSource =
      SyncQueueHiveDataSource();
  final QuizOfflineService _quizOfflineService = QuizOfflineService();
  final VideoDownloadService _videoDownloadService = VideoDownloadService();

  /// Limpia todos los datos locales del sistema
  Future<bool> clearAllLocalData() async {
    try {
      debugPrint('Iniciando limpieza de datos locales...');

      // Limpiar progreso de videos
      await _videoTrackingDataSource.clearAll();
      debugPrint('✓ Progreso de videos limpiado');

      // Limpiar checkpoints
      await _checkpointDataSource.clearAll();
      debugPrint('✓ Checkpoints limpiados');

      // Limpiar cola de sincronización
      await _syncQueueDataSource.clearAll();
      debugPrint('✓ Cola de sincronización limpiada');

      // Limpiar quizzes offline
      try {
        await _quizOfflineService.init();
        await _quizOfflineService.clearAll();
        debugPrint('✓ Quizzes offline limpiados');
      } catch (e) {
        debugPrint('Error al limpiar quizzes offline: $e');
      }

      // Limpiar videos descargados
      try {
        await _videoDownloadService.clearAllDownloadedVideos();
        debugPrint('✓ Videos descargados limpiados');
      } catch (e) {
        debugPrint('Error al limpiar videos descargados: $e');
      }

      debugPrint('✓ Todos los datos locales han sido limpiados exitosamente');
      return true;
    } catch (e) {
      debugPrint('Error al limpiar datos locales: $e');
      return false;
    }
  }

  /// Obtiene información sobre los datos locales actuales
  Future<Map<String, int>> getLocalDataStats() async {
    try {
      final videoProgress = await _videoTrackingDataSource.getUserVideoProgress(
        'dummy',
      );
      final checkpoints = await _checkpointDataSource.getAllCheckpoints('dummy');
      final syncQueue = await _syncQueueDataSource.getAllItems();
      final quizzes = _quizOfflineService.getPendingSyncQuizzes('dummy');

      return {
        'videoProgress': videoProgress.length,
        'checkpoints': checkpoints.length,
        'syncQueue': syncQueue.length,
        'quizzes': quizzes.length,
      };
    } catch (e) {
      debugPrint('Error al obtener estadísticas de datos locales: $e');
      return {
        'videoProgress': 0,
        'checkpoints': 0,
        'syncQueue': 0,
        'quizzes': 0,
      };
    }
  }

  /// Limpia todos los datos de un usuario específico
  Future<bool> clearUserData(String userId) async {
    try {
      debugPrint('Iniciando limpieza de datos locales para usuario $userId...');

      // Limpiar progreso de videos del usuario
      await _videoTrackingDataSource.deleteUserProgress(userId);
      debugPrint('✓ Progreso de videos limpiado para usuario $userId');

      // Limpiar checkpoints del usuario
      await _checkpointDataSource.clearUserCheckpoints(userId);
      debugPrint('✓ Checkpoints limpiados para usuario $userId');

      // Limpiar quizzes offline del usuario
      try {
        await _quizOfflineService.init();
        await _quizOfflineService.clearUserQuizzes(userId);
        debugPrint('✓ Quizzes offline limpiados para usuario $userId');
      } catch (e) {
        debugPrint('Error al limpiar quizzes offline: $e');
      }

      // Limpiar videos descargados del usuario
      try {
        await _videoDownloadService.clearUserData(userId);
        debugPrint('✓ Videos descargados limpiados para usuario $userId');
      } catch (e) {
        debugPrint('Error al limpiar videos descargados: $e');
      }

      debugPrint('✓ Datos locales del usuario $userId han sido limpiados exitosamente');
      return true;
    } catch (e) {
      debugPrint('Error al limpiar datos del usuario $userId: $e');
      return false;
    }
  }
}

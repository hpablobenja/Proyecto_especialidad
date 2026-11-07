// lib/core/services/dashboard_sync_service.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/local/data_user_hive_datasource.dart';
import '../../data/models/data_user_hive.dart';
import '../../data/models/data_user_model.dart';
import '../../data/repositories/data_user_repository.dart';

/// Servicio para sincronizar datos del dashboard entre Hive local y Firestore
class DashboardSyncService {
  static final DashboardSyncService _instance =
      DashboardSyncService._internal();
  factory DashboardSyncService() => _instance;
  DashboardSyncService._internal();

  final DataUserHiveDataSource _localDataSource =
      DataUserHiveDataSource();
  final DataUserRepository _dataUserRepository = DataUserRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sincroniza datos desde Firestore hacia Hive local
  Future<bool> syncFromFirestore(String userId) async {
    try {
      debugPrint('Sincronizando dashboard desde Firestore para usuario $userId');

      // Obtener datos de Firestore
      final userData = await _dataUserRepository.getUserData();
      if (userData == null) {
        debugPrint('No se encontraron datos del usuario en Firestore');
        return false;
      }

      // Calcular estadísticas de cursos
      final courseStats = await _calculateCourseStats(userId);

      // Crear modelo Hive
      final hiveData = DataUserHive.fromDataUserModel(
        userData,
        totalCourses: courseStats['total'] ?? 0,
        completedCourses: courseStats['completed'] ?? 0,
        inProgressCourses: courseStats['inProgress'] ?? 0,
      );

      // Guardar localmente
      await _localDataSource.saveDashboardData(hiveData);
      debugPrint('✓ Dashboard sincronizado desde Firestore');
      return true;
    } catch (e) {
      debugPrint('Error al sincronizar desde Firestore: $e');
      return false;
    }
  }

  /// Sincroniza datos desde Hive local hacia Firestore
  Future<bool> syncToFirestore(String userId) async {
    try {
      debugPrint('Sincronizando dashboard hacia Firestore para usuario $userId');

      // Obtener datos locales
      final localData = await _localDataSource.getDashboardData(userId);
      if (localData == null) {
        debugPrint('No hay datos locales para sincronizar');
        return false;
      }

      // Actualizar en Firestore
      await _firestore.collection('dataUser').doc(userId).update({
        'currentSessionMinutes': localData.currentSessionMinutes,
        'totalSessionMinutes': localData.totalSessionMinutes,
        'categoryProgress': localData.categoryProgress,
        'overallProgress': localData.overallProgress,
        'unlockedAchievements': localData.unlockedAchievements,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✓ Dashboard sincronizado hacia Firestore');
      return true;
    } catch (e) {
      debugPrint('Error al sincronizar hacia Firestore: $e');
      return false;
    }
  }

  /// Obtiene datos locales del dashboard
  Future<DataUserHive?> getLocalDashboardData(String userId) async {
    return await _localDataSource.getDashboardData(userId);
  }

  /// Guarda datos locales del dashboard
  Future<void> saveLocalDashboardData(DataUserHive data) async {
    await _localDataSource.saveDashboardData(data);
  }

  /// Calcula estadísticas de cursos desde Firestore.
  /// Las consultas de lessons se ejecutan en paralelo (Future.wait) para
  /// evitar el problema N+1 que bloqueaba el dashboard al volver a online.
  Future<Map<String, int>> _calculateCourseStats(String userId) async {
    try {
      final userProgressSnapshot = await _firestore
          .collection('userProgress')
          .where('userId', isEqualTo: userId)
          .get();

      // Agrupar por courseId
      final Map<String, List<QueryDocumentSnapshot>> courseProgress = {};
      for (var doc in userProgressSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final courseId = data['courseId'] as String?;
        if (courseId != null) {
          courseProgress.putIfAbsent(courseId, () => []).add(doc);
        }
      }

      if (courseProgress.isEmpty) {
        return {'total': 0, 'completed': 0, 'inProgress': 0};
      }

      // Consultar todas las lessons en paralelo en lugar de secuencialmente
      final courseIds = courseProgress.keys.toList();
      final lessonsSnapshots = await Future.wait(
        courseIds.map(
          (courseId) => _firestore
              .collection('lessons')
              .where('courseId', isEqualTo: courseId)
              .get(),
        ),
      );

      int completed = 0;
      int inProgress = 0;

      for (var i = 0; i < courseIds.length; i++) {
        final courseId = courseIds[i];
        final progressDocs = courseProgress[courseId]!;
        final totalLessons = lessonsSnapshots[i].docs.length;

        // Verificar si todas las lessons están completadas
        bool allCompleted = progressDocs.every((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String?;
          return status == 'completed';
        });

        bool hasProgress = progressDocs.any((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String?;
          return status == 'in_progress' || status == 'completed';
        });

        if (totalLessons > 0 &&
            progressDocs.length >= totalLessons &&
            allCompleted) {
          completed++;
        } else if (hasProgress) {
          inProgress++;
        }
      }

      return {
        'total': courseProgress.length,
        'completed': completed,
        'inProgress': inProgress,
      };
    } catch (e) {
      debugPrint('Error al calcular estadísticas de cursos: $e');
      return {'total': 0, 'completed': 0, 'inProgress': 0};
    }
  }

  /// Limpia datos locales del dashboard
  Future<void> clearLocalData(String userId) async {
    await _localDataSource.deleteDashboardData(userId);
  }
}

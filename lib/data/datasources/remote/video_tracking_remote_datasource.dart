// lib/data/datasources/remote/video_tracking_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/video_tracking_entity.dart';

/// DataSource remoto para sincronización de tracking de video con Firestore
/// Este es el Nivel 3 de la arquitectura híbrida
class VideoTrackingRemoteDataSource {
  final FirebaseFirestore firestore;
  static const String _collectionName = 'videoProgress';

  VideoTrackingRemoteDataSource({required this.firestore});

  /// Guarda o actualiza el progreso de video en Firestore
  Future<void> saveVideoProgress(VideoTrackingEntity tracking) async {
    final docId = _generateDocId(tracking.userId, tracking.lessonId);
    final docRef = firestore.collection(_collectionName).doc(docId);

    // Construir delta optimizado (solo campos relevantes)
    final data = _buildSyncData(tracking);

    await docRef.set(data, SetOptions(merge: true));
  }

  /// Obtiene el progreso de video desde Firestore
  Future<VideoTrackingEntity?> getVideoProgress(
    String userId,
    String lessonId,
  ) async {
    final docId = _generateDocId(userId, lessonId);
    final docRef = firestore.collection(_collectionName).doc(docId);

    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      return null;
    }

    return _fromFirestore(docSnapshot.data()!, userId, lessonId);
  }

  /// Obtiene todo el progreso de video de un usuario
  Future<List<VideoTrackingEntity>> getUserVideoProgress(String userId) async {
    final querySnapshot =
        await firestore
            .collection(_collectionName)
            .where('userId', isEqualTo: userId)
            .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      final lessonId = data['lessonId'] as String;
      return _fromFirestore(data, userId, lessonId);
    }).toList();
  }

  /// Obtiene progreso de video de un usuario en un curso
  Future<List<VideoTrackingEntity>> getCourseVideoProgress(
    String userId,
    String courseId,
  ) async {
    final querySnapshot =
        await firestore
            .collection(_collectionName)
            .where('userId', isEqualTo: userId)
            .where('courseId', isEqualTo: courseId)
            .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      final lessonId = data['lessonId'] as String;
      return _fromFirestore(data, userId, lessonId);
    }).toList();
  }

  /// Elimina el progreso de video de una lección
  Future<void> deleteVideoProgress(String userId, String lessonId) async {
    final docId = _generateDocId(userId, lessonId);
    await firestore.collection(_collectionName).doc(docId).delete();
  }

  /// Obtiene estadísticas agregadas de progreso de un curso
  Future<Map<String, dynamic>> getCourseAnalytics(String courseId) async {
    final querySnapshot =
        await firestore
            .collection(_collectionName)
            .where('courseId', isEqualTo: courseId)
            .get();

    final totalStudents = querySnapshot.docs.length;
    int totalViewedSeconds = 0;
    int completedLessons = 0;
    final Map<String, int> checkpointAttempts = {};

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      totalViewedSeconds += data['viewedSeconds'] as int? ?? 0;

      if (data['isCompleted'] == true) {
        completedLessons++;
      }

      // Agregar intentos de checkpoints
      final analytics = data['analytics'] as Map<String, dynamic>?;
      if (analytics != null) {
        final attempts =
            analytics['checkpointAttempts'] as Map<String, dynamic>?;
        if (attempts != null) {
          attempts.forEach((checkpointId, count) {
            checkpointAttempts[checkpointId] =
                (checkpointAttempts[checkpointId] ?? 0) + (count as int);
          });
        }
      }
    }

    return {
      'totalStudents': totalStudents,
      'totalViewedSeconds': totalViewedSeconds,
      'completedLessons': completedLessons,
      'averageViewTimePerStudent':
          totalStudents > 0 ? totalViewedSeconds / totalStudents : 0.0,
      'checkpointAttempts': checkpointAttempts,
    };
  }

  /// Genera el ID del documento Firestore
  String _generateDocId(String userId, String lessonId) {
    return '${userId}_$lessonId';
  }

  /// Construye los datos a sincronizar (delta optimizado)
  Map<String, dynamic> _buildSyncData(VideoTrackingEntity tracking) {
    return {
      'userId': tracking.userId,
      'courseId': tracking.courseId,
      'moduleId': tracking.moduleId,
      'lessonId': tracking.lessonId,
      'maxReachedPositionMs': tracking.maxReachedPositionMs,
      'viewedSeconds': tracking.viewedSeconds,
      'completionPercentage': tracking.completionPercentage,
      'checkpointsPassed': tracking.checkpointsPassed,
      'isCompleted': tracking.isCompleted,
      'lastSynced': FieldValue.serverTimestamp(),
      'analytics': {
        'totalViewTimeSeconds': tracking.viewedSeconds,
        'checkpointAttempts': _buildCheckpointAttempts(tracking),
      },
    };
  }

  /// Construye el mapa de intentos de checkpoints
  Map<String, int> _buildCheckpointAttempts(VideoTrackingEntity tracking) {
    // En una implementación completa, esto se calcularía desde los datos de checkpoints
    // Por ahora, retornamos un mapa vacío
    return {};
  }

  /// Convierte desde Firestore a VideoTrackingEntity
  VideoTrackingEntity _fromFirestore(
    Map<String, dynamic> data,
    String userId,
    String lessonId,
  ) {
    return VideoTrackingEntity(
      userId: data['userId'] as String? ?? userId,
      courseId: data['courseId'] as String,
      moduleId: data['moduleId'] as String,
      lessonId: data['lessonId'] as String? ?? lessonId,
      currentPositionMs: 0, // No se sincroniza currentPosition
      lastValidPositionMs: data['lastValidPositionMs'] as int? ?? 0,
      maxReachedPositionMs: data['maxReachedPositionMs'] as int? ?? 0,
      viewedSeconds: data['viewedSeconds'] as int? ?? 0,
      completionPercentage:
          (data['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      totalDurationMs: data['totalDurationMs'] as int? ?? 0,
      checkpointsPassed: List<String>.from(
        data['checkpointsPassed'] as List? ?? [],
      ),
      checkpointsFailed: List<String>.from(
        data['checkpointsFailed'] as List? ?? [],
      ),
      isCompleted: data['isCompleted'] as bool? ?? false,
      lastUpdated:
          data['lastSynced'] is Timestamp
              ? (data['lastSynced'] as Timestamp).toDate()
              : DateTime.now(),
      needsSync: false,
    );
  }

  /// Sincronización por lotes (batch write) para múltiples lecciones
  Future<void> batchSaveVideoProgress(
    List<VideoTrackingEntity> trackingList,
  ) async {
    final batch = firestore.batch();

    for (final tracking in trackingList) {
      final docId = _generateDocId(tracking.userId, tracking.lessonId);
      final docRef = firestore.collection(_collectionName).doc(docId);
      final data = _buildSyncData(tracking);
      batch.set(docRef, data, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Actualiza la colección userProgress con datos de VideoTracking
  /// Esto permite que el progreso de video se refleje en la pantalla de progreso
  Future<void> updateUserProgressWithVideoTracking(
    VideoTrackingEntity tracking,
  ) async {
    final progressId =
        '${tracking.userId}-${tracking.courseId}-${tracking.moduleId}-${tracking.lessonId}';
    final progressRef = firestore.collection('userProgress').doc(progressId);

    final progressData = {
      'userId': tracking.userId,
      'courseId': tracking.courseId,
      'moduleId': tracking.moduleId,
      'lessonId': tracking.lessonId,
      'hasViewedVideo': true,
      'completionPercentage': tracking.completionPercentage,
      'isCompleted': tracking.isCompleted,
      'viewedSeconds': tracking.viewedSeconds,
      'maxReachedPositionMs': tracking.maxReachedPositionMs,
      'lastValidPositionMs': tracking.lastValidPositionMs,
      'checkpointsPassed': tracking.checkpointsPassed,
      'checkpointsFailed': tracking.checkpointsFailed,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    // Si el video está completado, actualizar el estado a inProgress si no está completado
    if (tracking.isCompleted) {
      final progressDoc = await progressRef.get();
      if (progressDoc.exists) {
        final currentStatus = progressDoc.data()?['status'];
        if (currentStatus != 'completed') {
          progressData['status'] = 'inProgress';
        }
      }
    }

    await progressRef.set(progressData, SetOptions(merge: true));
  }
}

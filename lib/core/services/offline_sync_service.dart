// lib/core/services/offline_sync_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/video_tracking_entity.dart';

/// Servicio para manejar sincronización offline-first
/// Responsabilidades:
/// - Mantener cola de operaciones pendientes
/// - Sincronizar cuando hay conexión
/// - Manejar reintentos con backoff
/// - Reconciliar conflictos
class OfflineSyncService {
  final Connectivity _connectivity;
  late final StreamSubscription<ConnectivityResult> _connectivitySubscription;

  // Cola de sincronización (en memoria, se persistirá con Isar)
  final List<SyncQueueItem> _syncQueue = [];

  // Estado
  bool _isProcessing = false;
  bool _isOnline = true;
  Timer? _retryTimer;

  // Callbacks
  final Future<void> Function(SyncQueueItem)? onSyncItem;
  final Future<void> Function()? onConnectivityRestored;
  final Function(String)? onSyncError;
  final Function()? onQueueEmpty;

  OfflineSyncService({
    required Connectivity connectivity,
    this.onSyncItem,
    this.onConnectivityRestored,
    this.onSyncError,
    this.onQueueEmpty,
  }) : _connectivity = connectivity {
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
    _checkInitialConnectivity();
  }

  /// Verifica el estado inicial de conexión
  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    debugPrint('Initial connectivity: ${_isOnline ? "online" : "offline"}');

    if (_isOnline && _syncQueue.isNotEmpty) {
      _processQueue();
    }
    if (_isOnline) {
      _notifyConnectivityRestored();
    }
  }

  Future<void> _notifyConnectivityRestored() async {
    try {
      await onConnectivityRestored?.call();
    } catch (e) {
      debugPrint('Failed to sync after connection restored: $e');
      onSyncError?.call('Failed to sync after connection restored: $e');
    }
  }

  /// Maneja cambios de conectividad
  void _handleConnectivityChange(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (!wasOnline && _isOnline) {
      debugPrint('Connection restored. Processing sync queue...');
      _processQueue();
      _notifyConnectivityRestored();
    } else if (wasOnline && !_isOnline) {
      debugPrint('Connection lost. Operations will be queued.');
    }
  }

  /// Agrega un item a la cola de sincronización
  void enqueue(SyncQueueItem item) {
    _syncQueue.add(item);
    debugPrint(
      'Enqueued sync operation: ${item.operation} for ${item.targetId}',
    );

    if (_isOnline && !_isProcessing) {
      _processQueue();
    }
  }

  /// Procesa la cola de sincronización
  Future<void> _processQueue() async {
    if (_isProcessing || _syncQueue.isEmpty || !_isOnline) return;

    _isProcessing = true;
    debugPrint('Processing sync queue (${_syncQueue.length} items)');

    while (_syncQueue.isNotEmpty && _isOnline) {
      final item = _syncQueue.removeAt(0);

      try {
        await onSyncItem?.call(item);
        debugPrint('Synced successfully: ${item.operation}');
      } catch (e) {
        debugPrint('Sync failed for ${item.operation}: $e');

        // Incrementar retry count
        item.retryCount++;

        // Si no excedió el máximo de reintentos, reencolar
        if (item.retryCount < 5) {
          _syncQueue.insert(0, item); // Reinsertar al inicio

          // Esperar antes de reintentar (exponential backoff)
          final delay = Duration(seconds: _calculateBackoff(item.retryCount));
          await Future.delayed(delay);
        } else {
          // Excedió reintentos, notificar error
          onSyncError?.call(
            'Failed to sync ${item.operation} after 5 attempts: $e',
          );
        }

        // Si hay error, esperar un poco antes de continuar
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    _isProcessing = false;

    if (_syncQueue.isEmpty) {
      onQueueEmpty?.call();
      debugPrint('Sync queue empty');
    }
  }

  /// Calcula el tiempo de espera para backoff exponencial
  int _calculateBackoff(int retryCount) {
    return (1 << retryCount).clamp(1, 30); // 1, 2, 4, 8, 16, 30 max
  }

  /// Fuerza el procesamiento de la cola
  void forceSync() {
    if (_isOnline) {
      _processQueue();
    } else {
      debugPrint('Cannot force sync: offline');
    }
  }

  /// Obtiene el tamaño de la cola
  int get queueSize => _syncQueue.length;

  /// Verifica si está procesando
  bool get isProcessing => _isProcessing;

  /// Verifica si está online
  bool get isOnline => _isOnline;

  /// Limpia la cola (útil para testing o reset)
  void clearQueue() {
    _syncQueue.clear();
    debugPrint('Sync queue cleared');
  }

  /// Reconcilia conflictos entre datos locales y remotos
  /// Estrategia: usar el progreso más avanzado válido
  VideoTrackingEntity reconcileTracking(
    VideoTrackingEntity local,
    VideoTrackingEntity remote,
  ) {
    // Priorizar lastValidPosition más reciente
    final lastValidMs =
        local.lastValidPositionMs > remote.lastValidPositionMs
            ? local.lastValidPositionMs
            : remote.lastValidPositionMs;

    // Priorizar maxReachedPosition más alto
    final maxReachedMs =
        local.maxReachedPositionMs > remote.maxReachedPositionMs
            ? local.maxReachedPositionMs
            : remote.maxReachedPositionMs;

    // Sumar tiempos visualizados (evitar duplicados)
    final viewedSeconds =
        local.viewedSeconds > remote.viewedSeconds
            ? local.viewedSeconds
            : remote.viewedSeconds;

    // Unir checkpoints aprobados
    final allPassed =
        {...local.checkpointsPassed, ...remote.checkpointsPassed}.toList();

    // Usar el último update más reciente
    final lastUpdated =
        local.lastUpdated.isAfter(remote.lastUpdated)
            ? local.lastUpdated
            : remote.lastUpdated;

    // Si alguno está completado, marcar como completado
    final isCompleted = local.isCompleted || remote.isCompleted;

    return VideoTrackingEntity(
      userId: local.userId,
      courseId: local.courseId,
      moduleId: local.moduleId,
      lessonId: local.lessonId,
      currentPositionMs: local.currentPositionMs, // Usar posición actual local
      lastValidPositionMs: lastValidMs,
      maxReachedPositionMs: maxReachedMs,
      viewedSeconds: viewedSeconds,
      completionPercentage:
          local.completionPercentage > remote.completionPercentage
              ? local.completionPercentage
              : remote.completionPercentage,
      totalDurationMs: local.totalDurationMs,
      checkpointsPassed: allPassed,
      checkpointsFailed: local.checkpointsFailed,
      isCompleted: isCompleted,
      lastUpdated: lastUpdated,
      needsSync: true,
    );
  }

  /// Dispose
  void dispose() {
    _connectivitySubscription.cancel();
    _retryTimer?.cancel();
    debugPrint('OfflineSyncService disposed');
  }
}

/// Item en la cola de sincronización
class SyncQueueItem {
  final String id;
  final String
  operation; // 'update_progress', 'checkpoint_passed', 'lesson_completed', 'quiz_submitted'
  final String targetId; // lessonId, checkpointId o quizId
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retryCount;
  bool isProcessing;

  SyncQueueItem({
    required this.id,
    required this.operation,
    required this.targetId,
    required this.payload,
    DateTime? createdAt,
    this.retryCount = 0,
    this.isProcessing = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operation': operation,
      'targetId': targetId,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'isProcessing': isProcessing,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      operation: map['operation'] as String,
      targetId: map['targetId'] as String,
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      createdAt: DateTime.parse(map['createdAt'] as String),
      retryCount: map['retryCount'] as int? ?? 0,
      isProcessing: map['isProcessing'] as bool? ?? false,
    );
  }

  /// Crea un item para actualizar progreso de video
  factory SyncQueueItem.updateVideoProgress(VideoTrackingEntity tracking) {
    return SyncQueueItem(
      id:
          'progress_${tracking.lessonId}_${DateTime.now().millisecondsSinceEpoch}',
      operation: 'update_progress',
      targetId: tracking.lessonId,
      payload: tracking.toMap(),
    );
  }

  /// Crea un item para checkpoint aprobado
  factory SyncQueueItem.checkpointPassed({
    required String lessonId,
    required String checkpointId,
    required int attempts,
  }) {
    return SyncQueueItem(
      id: 'checkpoint_${checkpointId}_${DateTime.now().millisecondsSinceEpoch}',
      operation: 'checkpoint_passed',
      targetId: checkpointId,
      payload: {
        'lessonId': lessonId,
        'checkpointId': checkpointId,
        'attempts': attempts,
        'passedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Crea un item para lección completada
  factory SyncQueueItem.lessonCompleted({
    required String lessonId,
    required Map<String, dynamic> trackingData,
  }) {
    return SyncQueueItem(
      id: 'completed_${lessonId}_${DateTime.now().millisecondsSinceEpoch}',
      operation: 'lesson_completed',
      targetId: lessonId,
      payload: trackingData,
    );
  }

  /// Crea un item para quiz enviado (offline)
  factory SyncQueueItem.quizSubmitted({
    required String quizId,
    required Map<String, dynamic> quizData,
  }) {
    return SyncQueueItem(
      id: 'quiz_${quizId}_${DateTime.now().millisecondsSinceEpoch}',
      operation: 'quiz_submitted',
      targetId: quizId,
      payload: quizData,
    );
  }
}

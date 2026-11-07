// lib/core/services/video_tracking_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/video_tracking_entity.dart';
import '../../domain/entities/checkpoint_entity.dart';
import '../../domain/entities/system_config_entity.dart';

/// Servicio especializado para tracking educativo de videos
/// Responsabilidades:
/// - Calcular tiempo real visualizado
/// - Ignorar tiempo adelantado manualmente
/// - Detectar saltos (skipping)
/// - Controlar checkpoints
/// - Mantener progreso en memoria
/// - Persistir localmente
/// - Sincronizar remotamente
/// - Funcionar offline
class VideoTrackingService {
  // Estado en memoria (Nivel 1)
  VideoTrackingEntity? _currentTracking;
  Duration _currentPosition = Duration.zero;
  Duration _lastPosition = Duration.zero;
  Duration _maxReachedPosition = Duration.zero;
  Duration _lastValidPosition = Duration.zero;
  int _viewedSeconds = 0;
  bool _isPlaying = false;
  DateTime? _lastUpdateTime;
  Timer? _trackingTimer;
  Timer? _syncTimer;

  // Configuración (puede ser dinámica desde Firestore)
  Duration _seekTolerance = const Duration(seconds: 5);
  Duration _trackingInterval = const Duration(seconds: 1);
  Duration _syncInterval = const Duration(seconds: 60);
  double _completionThreshold = 90.0;

  // Callbacks
  final Function(Duration)? onPositionChanged;
  final Function(CheckpointEntity)? onCheckpointReached;
  final Function(VideoTrackingEntity)? onProgressUpdated;
  final Function()? onLessonCompleted;
  final Function(VideoTrackingEntity)? onSyncNeeded;

  // Checkpoints configurados
  final List<CheckpointEntity> checkpoints;
  final Set<String> _passedCheckpoints = {};

  VideoTrackingService({
    this.onPositionChanged,
    this.onCheckpointReached,
    this.onProgressUpdated,
    this.onLessonCompleted,
    this.onSyncNeeded,
    this.checkpoints = const [],
    SystemConfigEntity? config,
  }) {
    if (config != null) {
      _updateConfig(config);
    }
  }

  /// Actualiza la configuración del servicio con valores de Firestore
  void _updateConfig(SystemConfigEntity config) {
    _seekTolerance = Duration(seconds: config.seekToleranceSeconds);
    _trackingInterval = Duration(seconds: config.trackingIntervalSeconds);
    _syncInterval = Duration(seconds: config.syncIntervalSeconds);
    _completionThreshold = config.completionThreshold;
    debugPrint('VideoTrackingService config updated: '
        'seekTolerance=${_seekTolerance.inSeconds}s, '
        'trackingInterval=${_trackingInterval.inSeconds}s, '
        'syncInterval=${_syncInterval.inSeconds}s, '
        'completionThreshold=$_completionThreshold%');
  }

  /// Actualiza la configuración dinámicamente
  void updateConfig(SystemConfigEntity config) {
    _updateConfig(config);
    // Reiniciar timers con nuevos intervalos
    if (_trackingTimer != null) {
      _trackingTimer!.cancel();
      _startTrackingTimer();
    }
    if (_syncTimer != null) {
      _syncTimer!.cancel();
      _startSyncTimer();
    }
  }

  /// Inicializa el tracking para una lección específica
  Future<void> initialize({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
    Duration? resumePosition,
    int totalDurationMs = 0,
    VideoTrackingEntity? existingTracking,
  }) async {
    // Limpiar estado anterior
    dispose();

    final now = DateTime.now();
    final resumeMs = resumePosition?.inMilliseconds ?? 0;

    _currentTracking =
        existingTracking ??
        VideoTrackingEntity(
          userId: userId,
          courseId: courseId,
          moduleId: moduleId,
          lessonId: lessonId,
          currentPositionMs: resumeMs,
          lastValidPositionMs: resumeMs,
          maxReachedPositionMs: resumeMs,
          viewedSeconds: existingTracking?.viewedSeconds ?? 0,
          completionPercentage: existingTracking?.completionPercentage ?? 0.0,
          totalDurationMs: totalDurationMs,
          checkpointsPassed: existingTracking?.checkpointsPassed ?? [],
          checkpointsFailed: existingTracking?.checkpointsFailed ?? [],
          isCompleted: existingTracking?.isCompleted ?? false,
          lastUpdated: now,
          needsSync: false,
        );

    _currentPosition = Duration(milliseconds: resumeMs);
    _lastPosition = _currentPosition;
    _lastValidPosition = _currentPosition;
    _maxReachedPosition = Duration(
      milliseconds: _currentTracking!.maxReachedPositionMs,
    );
    _viewedSeconds = _currentTracking!.viewedSeconds;
    _passedCheckpoints
      ..clear()
      ..addAll(_currentTracking!.checkpointsPassed);
    _lastUpdateTime = now;

    // Iniciar timers
    _startTrackingTimer();
    _startSyncTimer();

    debugPrint(
      'VideoTrackingService initialized for lesson $lessonId at ${_currentPosition.inSeconds}s',
    );
  }

  /// Inicia el timer de tracking (cada segundo)
  void _startTrackingTimer() {
    _trackingTimer = Timer.periodic(_trackingInterval, (_) {
      if (_isPlaying) {
        _updateTracking();
      }
    });
  }

  /// Inicia el timer de sincronización (cada 60 segundos)
  void _startSyncTimer() {
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_isPlaying && _viewedSeconds % 60 == 0) {
        _triggerSync();
      }
    });
  }

  /// Actualiza el tracking cada segundo mientras el video se reproduce
  void _updateTracking() {
    if (_currentTracking == null) return;

    final now = DateTime.now();
    // Solo contar tiempo si el video realmente avanzó
    if (_currentPosition > _lastPosition) {
      _viewedSeconds++;
      _lastValidPosition = _currentPosition;

      // Actualizar maxReachedPosition
      if (_currentPosition > _maxReachedPosition) {
        _maxReachedPosition = _currentPosition;
      }

      // Verificar checkpoints
      _checkForCheckpoints();

      // Verificar completado
      _checkCompletion();
    }

    _lastPosition = _currentPosition;
    _lastUpdateTime = now;

    // Actualizar entidad
    _currentTracking = _currentTracking!.copyWith(
      currentPositionMs: _currentPosition.inMilliseconds,
      lastValidPositionMs: _lastValidPosition.inMilliseconds,
      maxReachedPositionMs: _maxReachedPosition.inMilliseconds,
      viewedSeconds: _viewedSeconds,
      completionPercentage: _calculateCompletionPercentage(),
      lastUpdated: now,
      needsSync: true,
    );

    // Notificar cambios
    onProgressUpdated?.call(_currentTracking!);
    onPositionChanged?.call(_currentPosition);
  }

  /// Verifica si se alcanzó algún checkpoint
  void _checkForCheckpoints() {
    final currentSeconds = _currentPosition.inSeconds;

    for (final checkpoint in checkpoints) {
      if (!_passedCheckpoints.contains(checkpoint.id) &&
          currentSeconds >= checkpoint.triggerPositionSeconds) {
        // Checkpoint alcanzado
        onCheckpointReached?.call(checkpoint);
        debugPrint(
          'Checkpoint reached at ${checkpoint.triggerPositionSeconds}s',
        );
      }
    }
  }

  /// Verifica si la lección está completada (≥90%)
  void _checkCompletion() {
    if (_currentTracking == null) return;

    final completion = _calculateCompletionPercentage();
    if (completion >= _completionThreshold && !_currentTracking!.isCompleted) {
      _currentTracking = _currentTracking!.copyWith(
        isCompleted: true,
        completionPercentage: completion,
        needsSync: true,
      );

      onLessonCompleted?.call();
      _triggerSync(); // Sincronizar inmediatamente al completar
      debugPrint('Lesson completed at $completion%');
    }
  }

  /// Calcula el porcentaje de completado
  double _calculateCompletionPercentage() {
    if (_currentTracking == null || _currentTracking!.totalDurationMs <= 0) {
      return 0.0;
    }
    return (_maxReachedPosition.inMilliseconds /
            _currentTracking!.totalDurationMs *
            100)
        .clamp(0.0, 100.0);
  }

  /// Maneja cambios de posición del video
  void onPositionChange(Duration newPosition) {
    // Si la lección ya está completada, no guardar más datos
    if (_currentTracking != null && _currentTracking!.isCompleted) {
      _currentPosition = newPosition;
      return;
    }

    if (_currentTracking == null) return;

    final delta = newPosition - _lastPosition;
    final timeDelta =
        _lastUpdateTime != null
            ? DateTime.now().difference(_lastUpdateTime!)
            : Duration.zero;

    // Detectar si es un seek manual (salto mayor de lo que el video podría avanzar naturalmente)
    final isManualSeek = delta.inSeconds > timeDelta.inSeconds + 2;

    if (isManualSeek) {
      // Validar seek
      if (!_validateSeek(newPosition)) {
        // Seek inválido: regresar a última posición válida
        debugPrint(
          'Invalid seek blocked: returning to ${_lastValidPosition.inSeconds}s',
        );
        _currentPosition = _lastValidPosition;
        onPositionChanged?.call(_lastValidPosition);
        return;
      }
    }

    _currentPosition = newPosition;
  }

  /// Valida si un seek es permitido
  bool _validateSeek(Duration newPosition) {
    final maxAllowed = _maxReachedPosition + _seekTolerance;
    return newPosition <= maxAllowed;
  }

  /// Marca que el video está reproduciéndose
  void setPlaying(bool playing) {
    _isPlaying = playing;
    if (playing) {
      _lastUpdateTime = DateTime.now();
    } else {
      // Si la lección está completada, no sincronizar
      if (_currentTracking != null && !_currentTracking!.isCompleted) {
        _triggerSync();
      }
    }
  }

  /// Registra que un checkpoint fue aprobado
  void markCheckpointPassed(String checkpointId) {
    if (_currentTracking == null) return;

    // Si la lección ya está completada, no guardar más datos
    if (_currentTracking!.isCompleted) return;

    _passedCheckpoints.add(checkpointId);

    final updatedPassed = List<String>.from(
      _currentTracking!.checkpointsPassed,
    );
    if (!updatedPassed.contains(checkpointId)) {
      updatedPassed.add(checkpointId);
    }

    _currentTracking = _currentTracking!.copyWith(
      checkpointsPassed: updatedPassed,
      lastUpdated: DateTime.now(),
      needsSync: true,
    );

    _triggerSync(); // Sincronizar checkpoint aprobado
  }

  /// Registra que un checkpoint fue fallado
  void markCheckpointFailed(String checkpointId) {
    if (_currentTracking == null) return;

    // Si la lección ya está completada, no guardar más datos
    if (_currentTracking!.isCompleted) return;

    final updatedFailed = List<String>.from(
      _currentTracking!.checkpointsFailed,
    );
    if (!updatedFailed.contains(checkpointId)) {
      updatedFailed.add(checkpointId);
    }

    _currentTracking = _currentTracking!.copyWith(
      checkpointsFailed: updatedFailed,
      lastUpdated: DateTime.now(),
      needsSync: true,
    );

    _triggerSync();
  }

  /// Dispara sincronización
  void _triggerSync() {
    if (_currentTracking != null && _currentTracking!.needsSync) {
      // Llamar al callback para sincronizar con el repositorio
      onSyncNeeded?.call(_currentTracking!);
      // Marcamos como sincronizado después de llamar al callback
      _currentTracking = _currentTracking!.copyWith(needsSync: false);
      debugPrint('Sync triggered for lesson ${_currentTracking!.lessonId}');
    }
  }

  /// Fuerza una sincronización inmediata
  void forceSync() {
    _triggerSync();
  }

  /// Obtiene el estado actual de tracking
  VideoTrackingEntity? get currentTracking => _currentTracking;

  /// Obtiene la posición actual
  Duration get currentPosition => _currentPosition;

  /// Obtiene la última posición válida (para reanudación)
  Duration get lastValidPosition => _lastValidPosition;

  /// Obtiene el tiempo total visualizado
  int get viewedSeconds => _viewedSeconds;

  /// Obtiene el porcentaje de completado
  double get completionPercentage => _calculateCompletionPercentage();

  /// Verifica si la lección está completada
  bool get isCompleted => _currentTracking?.isCompleted ?? false;

  /// Limpia recursos
  void dispose() {
    _trackingTimer?.cancel();
    _syncTimer?.cancel();
    _trackingTimer = null;
    _syncTimer = null;

    // Sincronizar final antes de dispose
    if (_currentTracking != null && _currentTracking!.needsSync) {
      _triggerSync();
    }

    debugPrint('VideoTrackingService disposed');
  }
}

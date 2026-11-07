// lib/domain/entities/system_config_entity.dart

import 'package:equatable/equatable.dart';

/// Entidad para configuración del sistema
/// Permite que el admin modifique valores estáticos del sistema
class SystemConfigEntity extends Equatable {
  // Configuración de Video Tracking
  final int seekToleranceSeconds;
  final int trackingIntervalSeconds;
  final int syncIntervalSeconds;
  final double completionThreshold;

  // Configuración de Quiz
  final int maxQuestionsForTeacher;
  final int maxQuestionsBank;

  // Configuración de Checkpoints
  final int maxCheckpointAttempts;
  final bool enableCheckpoints;

  // Configuración de Sesión
  final int sessionWarningMinutes;
  final int maxSessionDurationMinutes;

  // Configuración de Sincronización
  final int maxSyncRetries;
  final bool enableOfflineMode;

  // Configuración de UI
  final bool enableAnimations;
  final String defaultTheme;

  const SystemConfigEntity({
    this.seekToleranceSeconds = 5,
    this.trackingIntervalSeconds = 1,
    this.syncIntervalSeconds = 60,
    this.completionThreshold = 90.0,
    this.maxQuestionsForTeacher = 5,
    this.maxQuestionsBank = 20,
    this.maxCheckpointAttempts = 3,
    this.enableCheckpoints = true,
    this.sessionWarningMinutes = 5,
    this.maxSessionDurationMinutes = 120,
    this.maxSyncRetries = 5,
    this.enableOfflineMode = true,
    this.enableAnimations = true,
    this.defaultTheme = 'system',
  });

  @override
  List<Object?> get props => [
    seekToleranceSeconds,
    trackingIntervalSeconds,
    syncIntervalSeconds,
    completionThreshold,
    maxQuestionsForTeacher,
    maxQuestionsBank,
    maxCheckpointAttempts,
    enableCheckpoints,
    sessionWarningMinutes,
    maxSessionDurationMinutes,
    maxSyncRetries,
    enableOfflineMode,
    enableAnimations,
    defaultTheme,
  ];

  Map<String, dynamic> toMap() {
    return {
      'seekToleranceSeconds': seekToleranceSeconds,
      'trackingIntervalSeconds': trackingIntervalSeconds,
      'syncIntervalSeconds': syncIntervalSeconds,
      'completionThreshold': completionThreshold,
      'maxQuestionsForTeacher': maxQuestionsForTeacher,
      'maxQuestionsBank': maxQuestionsBank,
      'maxCheckpointAttempts': maxCheckpointAttempts,
      'enableCheckpoints': enableCheckpoints,
      'sessionWarningMinutes': sessionWarningMinutes,
      'maxSessionDurationMinutes': maxSessionDurationMinutes,
      'maxSyncRetries': maxSyncRetries,
      'enableOfflineMode': enableOfflineMode,
      'enableAnimations': enableAnimations,
      'defaultTheme': defaultTheme,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory SystemConfigEntity.fromMap(Map<String, dynamic> map) {
    return SystemConfigEntity(
      seekToleranceSeconds: map['seekToleranceSeconds'] as int? ?? 5,
      trackingIntervalSeconds: map['trackingIntervalSeconds'] as int? ?? 1,
      syncIntervalSeconds: map['syncIntervalSeconds'] as int? ?? 60,
      completionThreshold:
          (map['completionThreshold'] as num?)?.toDouble() ?? 90.0,
      maxQuestionsForTeacher: map['maxQuestionsForTeacher'] as int? ?? 5,
      maxQuestionsBank: map['maxQuestionsBank'] as int? ?? 20,
      maxCheckpointAttempts: map['maxCheckpointAttempts'] as int? ?? 3,
      enableCheckpoints: map['enableCheckpoints'] as bool? ?? true,
      sessionWarningMinutes: map['sessionWarningMinutes'] as int? ?? 5,
      maxSessionDurationMinutes:
          map['maxSessionDurationMinutes'] as int? ?? 120,
      maxSyncRetries: map['maxSyncRetries'] as int? ?? 5,
      enableOfflineMode: map['enableOfflineMode'] as bool? ?? true,
      enableAnimations: map['enableAnimations'] as bool? ?? true,
      defaultTheme: map['defaultTheme'] as String? ?? 'system',
    );
  }

  SystemConfigEntity copyWith({
    int? seekToleranceSeconds,
    int? trackingIntervalSeconds,
    int? syncIntervalSeconds,
    double? completionThreshold,
    int? maxQuestionsForTeacher,
    int? maxQuestionsBank,
    int? maxCheckpointAttempts,
    bool? enableCheckpoints,
    int? sessionWarningMinutes,
    int? maxSessionDurationMinutes,
    int? maxSyncRetries,
    bool? enableOfflineMode,
    bool? enableAnimations,
    String? defaultTheme,
  }) {
    return SystemConfigEntity(
      seekToleranceSeconds: seekToleranceSeconds ?? this.seekToleranceSeconds,
      trackingIntervalSeconds:
          trackingIntervalSeconds ?? this.trackingIntervalSeconds,
      syncIntervalSeconds: syncIntervalSeconds ?? this.syncIntervalSeconds,
      completionThreshold: completionThreshold ?? this.completionThreshold,
      maxQuestionsForTeacher:
          maxQuestionsForTeacher ?? this.maxQuestionsForTeacher,
      maxQuestionsBank: maxQuestionsBank ?? this.maxQuestionsBank,
      maxCheckpointAttempts:
          maxCheckpointAttempts ?? this.maxCheckpointAttempts,
      enableCheckpoints: enableCheckpoints ?? this.enableCheckpoints,
      sessionWarningMinutes:
          sessionWarningMinutes ?? this.sessionWarningMinutes,
      maxSessionDurationMinutes:
          maxSessionDurationMinutes ?? this.maxSessionDurationMinutes,
      maxSyncRetries: maxSyncRetries ?? this.maxSyncRetries,
      enableOfflineMode: enableOfflineMode ?? this.enableOfflineMode,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      defaultTheme: defaultTheme ?? this.defaultTheme,
    );
  }
}

// lib/core/services/checkpoint_service.dart

import 'package:flutter/material.dart';
import '../../domain/entities/checkpoint_entity.dart';

/// Servicio para gestionar checkpoints de aprendizaje
/// Responsabilidades:
/// - Validar respuestas de checkpoints
/// - Registrar intentos
/// - Persistir estado de checkpoints
/// - Proporcionar checkpoints para una lección
class CheckpointService {
  // Cache de checkpoints por lección
  final Map<String, List<CheckpointEntity>> _checkpointsCache = {};

  // Estado local de checkpoints (intentos, aprobados)
  final Map<String, CheckpointEntity> _checkpointState = {};

  /// Obtiene los checkpoints para una lección específica
  List<CheckpointEntity> getCheckpointsForLesson(String lessonId) {
    return _checkpointsCache[lessonId] ?? [];
  }

  /// Configura los checkpoints para una lección
  void setCheckpointsForLesson(
    String lessonId,
    List<CheckpointEntity> checkpoints,
  ) {
    _checkpointsCache[lessonId] = checkpoints;

    // Inicializar estado si no existe
    for (final checkpoint in checkpoints) {
      _checkpointState.putIfAbsent(checkpoint.id, () => checkpoint);
    }

    debugPrint(
      'Configured ${checkpoints.length} checkpoints for lesson $lessonId',
    );
  }

  /// Valida la respuesta de un checkpoint
  CheckpointValidationResult validateAnswer({
    required String checkpointId,
    required int selectedOptionIndex,
  }) {
    final checkpoint = _checkpointState[checkpointId];
    if (checkpoint == null) {
      return CheckpointValidationResult(
        isCorrect: false,
        message: 'Checkpoint no encontrado',
        attempts: 0,
      );
    }

    final isCorrect = selectedOptionIndex == checkpoint.correctOptionIndex;
    final updatedAttempts = checkpoint.attempts + 1;

    // Actualizar estado del checkpoint
    if (isCorrect) {
      _checkpointState[checkpointId] = checkpoint.copyWith(
        attempts: updatedAttempts,
        isPassed: true,
        passedAt: DateTime.now(),
        firstAttemptAt: checkpoint.firstAttemptAt ?? DateTime.now(),
      );

      debugPrint('Checkpoint $checkpointId passed (attempt $updatedAttempts)');

      return CheckpointValidationResult(
        isCorrect: true,
        message: '¡Correcto! Puedes continuar.',
        attempts: updatedAttempts,
      );
    } else {
      _checkpointState[checkpointId] = checkpoint.copyWith(
        attempts: updatedAttempts,
        firstAttemptAt: checkpoint.firstAttemptAt ?? DateTime.now(),
      );

      debugPrint('Checkpoint $checkpointId failed (attempt $updatedAttempts)');

      return CheckpointValidationResult(
        isCorrect: false,
        message: 'Incorrecto. Inténtalo de nuevo.',
        attempts: updatedAttempts,
      );
    }
  }

  /// Obtiene el estado actual de un checkpoint
  CheckpointEntity? getCheckpointState(String checkpointId) {
    return _checkpointState[checkpointId];
  }

  /// Verifica si un checkpoint ya fue aprobado
  bool isCheckpointPassed(String checkpointId) {
    return _checkpointState[checkpointId]?.isPassed ?? false;
  }

  /// Obtiene la cantidad de intentos de un checkpoint
  int getCheckpointAttempts(String checkpointId) {
    return _checkpointState[checkpointId]?.attempts ?? 0;
  }

  /// Restaura el estado de checkpoints desde datos persistidos
  void restoreCheckpointState(List<CheckpointEntity> checkpoints) {
    for (final checkpoint in checkpoints) {
      _checkpointState[checkpoint.id] = checkpoint;
    }
    debugPrint('Restored state for ${checkpoints.length} checkpoints');
  }

  /// Obtiene todos los checkpoints con su estado actual
  List<CheckpointEntity> getAllCheckpointStates() {
    return _checkpointState.values.toList();
  }

  /// Limpia el cache de checkpoints
  void clearCache() {
    _checkpointsCache.clear();
    _checkpointState.clear();
    debugPrint('Checkpoint cache cleared');
  }

  /// Limpia el cache de una lección específica
  void clearLessonCache(String lessonId) {
    _checkpointsCache.remove(lessonId);

    // Remover checkpoints de esta lección del estado
    final lessonCheckpoints = _checkpointsCache[lessonId] ?? [];
    for (final checkpoint in lessonCheckpoints) {
      _checkpointState.remove(checkpoint.id);
    }

    debugPrint('Checkpoint cache cleared for lesson $lessonId');
  }
}

/// Resultado de validación de un checkpoint
class CheckpointValidationResult {
  final bool isCorrect;
  final String message;
  final int attempts;

  CheckpointValidationResult({
    required this.isCorrect,
    required this.message,
    required this.attempts,
  });
}

/// Utilidad para crear checkpoints de ejemplo
class CheckpointFactory {
  /// Crea checkpoints de ejemplo para una lección
  static List<CheckpointEntity> createExampleCheckpoints(String lessonId) {
    return [
      CheckpointEntity(
        id: '${lessonId}_cp_120',
        lessonId: lessonId,
        triggerPositionSeconds: 120,
        question: '¿Cuál es el concepto principal explicado en esta sección?',
        options: [
          'Opción A: Concepto incorrecto',
          'Opción B: Respuesta correcta',
          'Opción C: Otra opción incorrecta',
        ],
        correctOptionIndex: 1,
      ),
      CheckpointEntity(
        id: '${lessonId}_cp_300',
        lessonId: lessonId,
        triggerPositionSeconds: 300,
        question: '¿Qué técnica se demostró en el ejemplo?',
        options: ['Técnica 1', 'Técnica 2 (correcta)', 'Técnica 3'],
        correctOptionIndex: 1,
      ),
      CheckpointEntity(
        id: '${lessonId}_cp_450',
        lessonId: lessonId,
        triggerPositionSeconds: 450,
        question: '¿Cuál es la conclusión principal de esta lección?',
        options: ['Conclusión A', 'Conclusión B', 'Conclusión C (correcta)'],
        correctOptionIndex: 2,
      ),
    ];
  }
}

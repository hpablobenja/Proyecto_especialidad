// lib/data/datasources/local/checkpoint_hive_datasource.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../../models/checkpoint_hive.dart';
import '../../../domain/entities/checkpoint_entity.dart';

/// DataSource local para persistencia de checkpoints usando Hive
class CheckpointHiveDataSource {
  static const String _boxName = 'checkpoints';

  /// Guarda o actualiza un checkpoint
  Future<void> saveCheckpoint(CheckpointEntity checkpoint) async {
    final box = await Hive.openBox<CheckpointHive>(_boxName);
    final hive = CheckpointHive.fromMap(checkpoint.toMap());
    await box.put(hive.key, hive);
  }

  /// Obtiene un checkpoint por ID
  Future<CheckpointHive?> getCheckpoint(String checkpointId) async {
    final box = await Hive.openBox<CheckpointHive>(_boxName);
    return box.get(checkpointId);
  }

  /// Obtiene todos los checkpoints
  Future<List<CheckpointHive>> getAllCheckpoints() async {
    final box = await Hive.openBox<CheckpointHive>(_boxName);
    return box.values.toList();
  }

  /// Obtiene todos los checkpoints de una lección
  Future<List<CheckpointHive>> getLessonCheckpoints(String lessonId) async {
    final box = await Hive.openBox<CheckpointHive>(_boxName);
    return box.values.where((item) => item.lessonId == lessonId).toList();
  }

  /// Obtiene checkpoints aprobados de una lección
  Future<List<CheckpointHive>> getPassedCheckpoints(String lessonId) async {
    final box = await Hive.openBox<CheckpointHive>(_boxName);
    return box.values
        .where((item) => item.lessonId == lessonId && item.isPassed)
        .toList();
  }

  /// Obtiene checkpoints fallados de una lección
  Future<List<CheckpointHive>> getFailedCheckpoints(String lessonId) async {
    final box = await Hive.openBox<CheckpointHive>(_boxName);
    return box.values
        .where(
          (item) =>
              item.lessonId == lessonId && !item.isPassed && item.attempts > 0,
        )
        .toList();
  }

  /// Marca un checkpoint como aprobado
  Future<void> markCheckpointPassed(String checkpointId) async {
    final box = await Hive.openBox<CheckpointHive>(_boxName);
    final existing = box.get(checkpointId);

    if (existing != null) {
      existing.isPassed = true;
      existing.passedAt = DateTime.now();
      await box.put(checkpointId, existing);
    }
  }

  /// Incrementa el contador de intentos de un checkpoint
  Future<void> incrementCheckpointAttempts(String checkpointId) async {
    final box = await Hive.openBox<CheckpointHive>(_boxName);
    final existing = box.get(checkpointId);

    if (existing != null) {
      existing.attempts++;
      if (existing.firstAttemptAt == null) {
        existing.firstAttemptAt = DateTime.now();
      }
      await box.put(checkpointId, existing);
    }
  }

  /// Elimina todos los checkpoints de una lección
  Future<void> deleteLessonCheckpoints(String lessonId) async {
    final box = await Hive.openBox<CheckpointHive>(_boxName);
    final keysToDelete =
        box.keys.where((key) {
          final item = box.get(key);
          return item?.lessonId == lessonId;
        }).toList();

    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// Limpia todos los datos (útil para testing)
  Future<void> clearAll() async {
    final box = await Hive.openBox<CheckpointHive>(_boxName);
    await box.clear();
  }
}

// lib/data/datasources/local/checkpoint_hive_datasource.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/hive_encryption_service.dart';
import '../../models/checkpoint_hive.dart';
import '../../../domain/entities/checkpoint_entity.dart';

/// DataSource local para persistencia de checkpoints usando Hive
class CheckpointHiveDataSource {
  static const String _boxName = HiveEncryptionService.checkpointBox;

  Future<Box<CheckpointHive>> _openBox() {
    return HiveEncryptionService.instance.openBox<CheckpointHive>(_boxName);
  }

  /// Guarda o actualiza un checkpoint
  Future<void> saveCheckpoint(CheckpointEntity checkpoint, String userId) async {
    final box = await _openBox();
    final hive = CheckpointHive.fromMap(checkpoint.toMap(), userId);
    await box.put(hive.key, hive);
  }

  /// Obtiene un checkpoint por ID
  Future<CheckpointHive?> getCheckpoint(String checkpointId, String userId) async {
    final box = await _openBox();
    return box.get('${userId}_$checkpointId');
  }

  /// Obtiene todos los checkpoints de un usuario
  Future<List<CheckpointHive>> getAllCheckpoints(String userId) async {
    final box = await _openBox();
    return box.values.where((item) => item.userId == userId).toList();
  }

  /// Obtiene todos los checkpoints de una lección para un usuario
  Future<List<CheckpointHive>> getLessonCheckpoints(String lessonId, String userId) async {
    final box = await _openBox();
    return box.values.where((item) => item.lessonId == lessonId && item.userId == userId).toList();
  }

  /// Obtiene checkpoints aprobados de una lección para un usuario
  Future<List<CheckpointHive>> getPassedCheckpoints(String lessonId, String userId) async {
    final box = await _openBox();
    return box.values
        .where((item) => item.lessonId == lessonId && item.userId == userId && item.isPassed)
        .toList();
  }

  /// Obtiene checkpoints fallados de una lección para un usuario
  Future<List<CheckpointHive>> getFailedCheckpoints(String lessonId, String userId) async {
    final box = await _openBox();
    return box.values
        .where(
          (item) =>
              item.lessonId == lessonId && item.userId == userId && !item.isPassed && item.attempts > 0,
        )
        .toList();
  }

  /// Marca un checkpoint como aprobado
  Future<void> markCheckpointPassed(String checkpointId, String userId) async {
    final box = await _openBox();
    final key = '${userId}_$checkpointId';
    final existing = box.get(key);

    if (existing != null) {
      existing.isPassed = true;
      existing.passedAt = DateTime.now();
      await box.put(key, existing);
    }
  }

  /// Incrementa el contador de intentos de un checkpoint
  Future<void> incrementCheckpointAttempts(String checkpointId, String userId) async {
    final box = await _openBox();
    final key = '${userId}_$checkpointId';
    final existing = box.get(key);

    if (existing != null) {
      existing.attempts++;
      if (existing.firstAttemptAt == null) {
        existing.firstAttemptAt = DateTime.now();
      }
      await box.put(key, existing);
    }
  }

  /// Elimina todos los checkpoints de una lección para un usuario
  Future<void> deleteLessonCheckpoints(String lessonId, String userId) async {
    final box = await _openBox();
    final keysToDelete =
        box.keys.where((key) {
          final item = box.get(key);
          return item?.lessonId == lessonId && item?.userId == userId;
        }).toList();

    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// Elimina todos los checkpoints de un usuario
  Future<void> clearUserCheckpoints(String userId) async {
    final box = await _openBox();
    final keysToDelete =
        box.keys.where((key) {
          final item = box.get(key);
          return item?.userId == userId;
        }).toList();

    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// Limpia todos los datos (útil para testing)
  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }
}

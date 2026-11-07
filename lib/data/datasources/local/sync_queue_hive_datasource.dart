// lib/data/datasources/local/sync_queue_hive_datasource.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../../models/sync_queue_item_hive.dart';

/// DataSource local para la cola de sincronización usando Hive
class SyncQueueHiveDataSource {
  static const String _boxName = 'syncQueue';

  /// Agrega un item a la cola de sincronización
  Future<void> enqueue(Map<String, dynamic> item) async {
    final box = await Hive.openBox<SyncQueueItemHive>(_boxName);
    final hive = SyncQueueItemHive.fromSyncQueueItem(item);
    await box.put(hive.key, hive);
  }

  /// Obtiene el siguiente item a procesar (el más antiguo no procesado)
  Future<SyncQueueItemHive?> getNextItem() async {
    final box = await Hive.openBox<SyncQueueItemHive>(_boxName);
    final items =
        box.values.where((item) => !item.isProcessing).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return items.isNotEmpty ? items.first : null;
  }

  /// Obtiene todos los items de la cola
  Future<List<SyncQueueItemHive>> getAllItems() async {
    final box = await Hive.openBox<SyncQueueItemHive>(_boxName);
    final items = box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  /// Obtiene todos los items pendientes
  Future<List<SyncQueueItemHive>> getPendingItems() async {
    final box = await Hive.openBox<SyncQueueItemHive>(_boxName);
    final items =
        box.values.where((item) => !item.isProcessing).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return items;
  }

  /// Marca un item como procesado
  Future<void> markAsProcessed(String syncId) async {
    final box = await Hive.openBox<SyncQueueItemHive>(_boxName);
    await box.delete(syncId);
  }

  /// Marca un item como en proceso
  Future<void> markAsProcessing(String syncId) async {
    final box = await Hive.openBox<SyncQueueItemHive>(_boxName);
    final existing = box.get(syncId);

    if (existing != null) {
      existing.isProcessing = true;
      await box.put(syncId, existing);
    }
  }

  /// Incrementa el contador de reintentos de un item
  Future<void> incrementRetryCount(String syncId) async {
    final box = await Hive.openBox<SyncQueueItemHive>(_boxName);
    final existing = box.get(syncId);

    if (existing != null) {
      existing.retryCount++;
      existing.isProcessing = false; // Resetear para reintentar
      await box.put(syncId, existing);
    }
  }

  /// Elimina un item de la cola
  Future<void> removeItem(String syncId) async {
    final box = await Hive.openBox<SyncQueueItemHive>(_boxName);
    await box.delete(syncId);
  }

  /// Obtiene items por operación
  Future<List<SyncQueueItemHive>> getItemsByOperation(String operation) async {
    final box = await Hive.openBox<SyncQueueItemHive>(_boxName);
    return box.values.where((item) => item.operation == operation).toList();
  }

  /// Obtiene el conteo de items pendientes
  Future<int> getPendingCount() async {
    final box = await Hive.openBox<SyncQueueItemHive>(_boxName);
    return box.values.where((item) => !item.isProcessing).length;
  }

  /// Limpia items antiguos (más de 7 días)
  Future<void> clearOldItems() async {
    final box = await Hive.openBox<SyncQueueItemHive>(_boxName);
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

    final keysToDelete =
        box.keys.where((key) {
          final item = box.get(key);
          return item?.createdAt.isBefore(cutoffDate) ?? false;
        }).toList();

    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// Resetea items que quedaron en estado de procesamiento (por crash)
  Future<void> resetStuckItems() async {
    final box = await Hive.openBox<SyncQueueItemHive>(_boxName);
    final stuckItems = box.values.where((item) => item.isProcessing).toList();

    for (final item in stuckItems) {
      item.isProcessing = false;
      await box.put(item.key, item);
    }
  }

  /// Limpia todos los datos (útil para testing)
  Future<void> clearAll() async {
    final box = await Hive.openBox<SyncQueueItemHive>(_boxName);
    await box.clear();
  }
}

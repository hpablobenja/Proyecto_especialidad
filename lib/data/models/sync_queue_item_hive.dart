// lib/data/models/sync_queue_item_hive.dart

import 'dart:convert';
import 'package:hive/hive.dart';

part 'sync_queue_item_hive.g.dart';

/// Modelo Hive para persistencia local de la cola de sincronización
@HiveType(typeId: 3)
class SyncQueueItemHive {
  @HiveField(0)
  String syncId;

  @HiveField(1)
  String operation;

  @HiveField(2)
  String targetId;

  @HiveField(3)
  String payloadJson;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  int retryCount;

  @HiveField(6)
  bool isProcessing;

  SyncQueueItemHive({
    required this.syncId,
    required this.operation,
    required this.targetId,
    required this.payloadJson,
    required this.createdAt,
    this.retryCount = 0,
    this.isProcessing = false,
  });

  /// Convierte desde SyncQueueItem.toMap()
  factory SyncQueueItemHive.fromSyncQueueItem(Map<String, dynamic> itemMap) {
    final payload = itemMap['payload'] as Map<String, dynamic>;

    return SyncQueueItemHive(
      syncId: itemMap['id'] as String,
      operation: itemMap['operation'] as String,
      targetId: itemMap['targetId'] as String,
      payloadJson: _encodePayload(payload),
      createdAt:
          itemMap['createdAt'] is DateTime
              ? itemMap['createdAt'] as DateTime
              : DateTime.parse(itemMap['createdAt'] as String),
      retryCount: itemMap['retryCount'] as int? ?? 0,
      isProcessing: itemMap['isProcessing'] as bool? ?? false,
    );
  }

  /// Convierte a Map
  Map<String, dynamic> toMap() {
    return {
      'id': syncId,
      'operation': operation,
      'targetId': targetId,
      'payload': _decodePayload(payloadJson),
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'isProcessing': isProcessing,
    };
  }

  /// Obtiene el payload decodificado
  Map<String, dynamic> get payload => _decodePayload(payloadJson);

  /// Codifica payload a JSON string
  static String _encodePayload(Map<String, dynamic> payload) {
    return jsonEncode(payload);
  }

  /// Decodifica payload desde JSON string
  static Map<String, dynamic> _decodePayload(String json) {
    return jsonDecode(json) as Map<String, dynamic>;
  }

  /// Genera una clave única para este item
  String get key => syncId;
}

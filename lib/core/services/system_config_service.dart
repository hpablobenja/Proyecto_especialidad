// lib/core/services/system_config_service.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/system_config_entity.dart';

/// Servicio para gestionar la configuración del sistema
/// Permite que el admin modifique valores estáticos del sistema
class SystemConfigService {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'systemConfig';
  static const String _docId = 'default';

  SystemConfigService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Obtiene la configuración actual del sistema
  Future<SystemConfigEntity> getConfig() async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(_docId).get();

      if (doc.exists && doc.data() != null) {
        return SystemConfigEntity.fromMap(doc.data()!);
      } else {
        // Si no existe, crear configuración por defecto
        final defaultConfig = SystemConfigEntity();
        await _firestore
            .collection(_collectionName)
            .doc(_docId)
            .set(defaultConfig.toMap());
        return defaultConfig;
      }
    } catch (e) {
      debugPrint('Error al obtener configuración del sistema: $e');
      // Retornar configuración por defecto en caso de error
      return SystemConfigEntity();
    }
  }

  /// Actualiza la configuración del sistema
  Future<bool> updateConfig(SystemConfigEntity config) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(_docId)
          .set(config.toMap(), SetOptions(merge: true));
      debugPrint('Configuración del sistema actualizada exitosamente');
      return true;
    } catch (e) {
      debugPrint('Error al actualizar configuración del sistema: $e');
      return false;
    }
  }

  /// Restablece la configuración a los valores por defecto
  Future<bool> resetToDefaults() async {
    try {
      final defaultConfig = SystemConfigEntity();
      await _firestore
          .collection(_collectionName)
          .doc(_docId)
          .set(defaultConfig.toMap());
      debugPrint('Configuración restablecida a valores por defecto');
      return true;
    } catch (e) {
      debugPrint('Error al restablecer configuración: $e');
      return false;
    }
  }

  /// Stream para escuchar cambios en la configuración
  Stream<SystemConfigEntity> configStream() {
    return _firestore.collection(_collectionName).doc(_docId).snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        return SystemConfigEntity.fromMap(doc.data()!);
      }
      return SystemConfigEntity();
    });
  }
}

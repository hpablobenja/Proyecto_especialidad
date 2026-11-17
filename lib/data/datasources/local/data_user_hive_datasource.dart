// lib/data/datasources/local/data_user_hive_datasource.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/hive_encryption_service.dart';
import '../../models/data_user_hive.dart';

/// DataSource local para persistencia de datos del dashboard usando Hive
class DataUserHiveDataSource {
  static const String _boxName = HiveEncryptionService.userDataBox;

  Future<Box<DataUserHive>> _openBox() {
    return HiveEncryptionService.instance.openBox<DataUserHive>(_boxName);
  }

  /// Guarda o actualiza los datos del dashboard
  Future<void> saveDashboardData(DataUserHive data) async {
    final box = await _openBox();
    await box.put(data.userId, data);
  }

  /// Obtiene los datos del dashboard para un usuario específico
  Future<DataUserHive?> getDashboardData(String userId) async {
    final box = await _openBox();
    return box.get(userId);
  }

  /// Elimina los datos del dashboard de un usuario
  Future<void> deleteDashboardData(String userId) async {
    final box = await _openBox();
    await box.delete(userId);
  }

  /// Limpia todos los datos (útil para testing o logout)
  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }
}

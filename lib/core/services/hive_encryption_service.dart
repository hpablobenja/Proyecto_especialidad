// lib/core/services/hive_encryption_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Abre cajas Hive cifradas con AES-256 ([HiveAesCipher]).
///
/// La clave de 32 bytes se genera una vez y se guarda en el almacenamiento
/// seguro del dispositivo. Si la caja ya existía sin cifrar, se copia y se
/// vuelve a guardar cifrada.
class HiveEncryptionService {
  HiveEncryptionService._();

  static final HiveEncryptionService instance = HiveEncryptionService._();

  static const String encryptionKeyName = 'hive_aes256_key';
  static const String _migratedPrefix = 'hive_aes256_migrated_';

  /// Datos del usuario (dashboard local).
  static const String userDataBox = 'dashboardData';

  /// Progreso de video.
  static const String progressBox = 'videoProgress';

  /// Progreso de checkpoints.
  static const String checkpointBox = 'checkpoints';

  /// Resultados de cuestionarios.
  static const String quizResultsBox = 'quiz_progress';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  HiveAesCipher? _cipher;
  Future<HiveAesCipher>? _pendingCipher;

  /// Cifrado AES-256 listo para abrir cajas sensibles.
  Future<HiveAesCipher> cipher() {
    final cached = _cipher;
    if (cached != null) return Future.value(cached);

    final pending = _pendingCipher;
    if (pending != null) return pending;

    final loading = _loadCipher();
    _pendingCipher = loading;
    return loading;
  }

  Future<HiveAesCipher> _loadCipher() async {
    try {
      final encoded = await _storage.read(key: encryptionKeyName);
      List<int> key;
      if (encoded == null || encoded.isEmpty) {
        key = Hive.generateSecureKey();
        await _storage.write(
          key: encryptionKeyName,
          value: base64UrlEncode(key),
        );
      } else {
        key = base64Url.decode(encoded);
      }

      if (key.length != 32) {
        throw ArgumentError(
          'La clave Hive debe tener 32 bytes para AES-256.',
        );
      }

      final cipher = HiveAesCipher(key);
      _cipher = cipher;
      return cipher;
    } catch (error) {
      _pendingCipher = null;
      rethrow;
    }
  }

  /// Abre [name] con AES-256. Migra el contenido si la caja estaba en claro.
  Future<Box<T>> openBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }

    final encryptionCipher = await cipher();
    final migratedKey = '$_migratedPrefix$name';
    final migrated = await _storage.read(key: migratedKey) == '1';

    if (!migrated && await Hive.boxExists(name)) {
      final plain = await _tryOpenPlain<T>(name);
      if (plain != null) {
        return _reencrypt<T>(name, plain, encryptionCipher, migratedKey);
      }
    }

    final box = await Hive.openBox<T>(
      name,
      encryptionCipher: encryptionCipher,
    );
    if (!migrated) {
      await _storage.write(key: migratedKey, value: '1');
    }
    return box;
  }

  Future<Box<T>> _reencrypt<T>(
    String name,
    Box<T> plain,
    HiveAesCipher encryptionCipher,
    String migratedKey,
  ) async {
    final snapshot = Map<dynamic, T>.from(plain.toMap());
    await plain.close();
    await Hive.deleteBoxFromDisk(name);

    final encrypted = await Hive.openBox<T>(
      name,
      encryptionCipher: encryptionCipher,
    );
    if (snapshot.isNotEmpty) {
      await encrypted.putAll(snapshot);
    }
    await _storage.write(key: migratedKey, value: '1');
    return encrypted;
  }

  /// Abre una caja previa sin cifrado. Devuelve null si el archivo ya está
  /// cifrado o no se puede leer como texto plano.
  Future<Box<T>?> _tryOpenPlain<T>(String name) async {
    final done = Completer<void>();
    Box<T>? box;
    Object? failure;

    runZonedGuarded(() async {
      try {
        box = await Hive.openBox<T>(name, crashRecovery: false);
      } catch (error) {
        failure = error;
      } finally {
        if (!done.isCompleted) done.complete();
      }
    }, (error, _) {
      failure ??= error;
      if (!done.isCompleted) done.complete();
    });

    await done.future;
    if (box != null) return box;

    // Hive suelta el bloqueo del archivo de forma asíncrona tras un fallo.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    if (failure != null && failure is! HiveError) {
      Error.throwWithStackTrace(
        failure!,
        StackTrace.current,
      );
    }
    return null;
  }

  @visibleForTesting
  void resetForTest() {
    _cipher = null;
    _pendingCipher = null;
  }
}

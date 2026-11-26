// lib/core/services/crashlytics_service.dart

import 'dart:io' show Platform;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Servicio centralizado para gestionar el reporte de errores, métricas y diagnóstico
/// a través de Firebase Crashlytics.
///
/// Implementa buenas prácticas de arquitectura desacoplando la capa de UI y datos
/// de la llamada directa a FirebaseCrashlytics.
class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics;

  CrashlyticsService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  static final CrashlyticsService instance = CrashlyticsService();

  /// Inicializa la configuración de Crashlytics.
  ///
  /// En modo depuración ([kDebugMode]), la colección automática puede desactivarse
  /// o mantenerse condicionalmente según las necesidades de pruebas.
  Future<void> initialize({bool enableInDebug = false}) async {
    try {
      if (kDebugMode && !enableInDebug) {
        // En desarrollo local desactivamos el envío para no contaminar estadísticas reales
        await _crashlytics.setCrashlyticsCollectionEnabled(false);
        debugPrint('[CrashlyticsService] Colección deshabilitada en debug mode.');
      } else {
        await _crashlytics.setCrashlyticsCollectionEnabled(true);
        debugPrint('[CrashlyticsService] Colección habilitada.');
      }

      // Metadata inicial de plataforma y entorno
      await setCustomKey('platform', _resolvePlatform());
      await setCustomKey('debug_mode', kDebugMode);
    } catch (e, stack) {
      debugPrint('[CrashlyticsService] Error al inicializar: $e\n$stack');
    }
  }

  /// Establece o limpia el identificador de usuario para asociar eventos y crashes.
  Future<void> setUserId(String? userId) async {
    try {
      if (userId == null || userId.isEmpty) {
        await _crashlytics.setUserIdentifier('');
        await removeCustomKey('user_role');
      } else {
        await _crashlytics.setUserIdentifier(userId);
      }
    } catch (e) {
      debugPrint('[CrashlyticsService] Error al establecer userId: $e');
    }
  }

  /// Establece contexto del usuario: identificador, rol y versión de la aplicación.
  Future<void> setUserContext({
    required String? userId,
    String? role,
    String? appVersion,
  }) async {
    try {
      await setUserId(userId);
      if (role != null && role.isNotEmpty) {
        await setCustomKey('user_role', role);
      }
      if (appVersion != null && appVersion.isNotEmpty) {
        await setCustomKey('app_version', appVersion);
      }
    } catch (e) {
      debugPrint('[CrashlyticsService] Error al configurar contexto de usuario: $e');
    }
  }

  /// Registra una clave personalizada en el informe de Crashlytics.
  Future<void> setCustomKey(String key, Object value) async {
    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      debugPrint('[CrashlyticsService] Error al registrar custom key ($key): $e');
    }
  }

  /// Remueve o limpia una clave personalizada asignando una cadena vacía.
  Future<void> removeCustomKey(String key) async {
    try {
      await _crashlytics.setCustomKey(key, '');
    } catch (e) {
      debugPrint('[CrashlyticsService] Error al remover custom key ($key): $e');
    }
  }

  /// Registra mensajes en el log de Crashlytics que acompañan a cualquier crash o error reportado.
  Future<void> log(String message) async {
    try {
      debugPrint('[Crashlytics Log] $message');
      await _crashlytics.log(message);
    } catch (e) {
      debugPrint('[CrashlyticsService] Error en log: $e');
    }
  }

  /// Reporta un error manejado o excepción controlada.
  ///
  /// [exception]: Excepción o error capturado.
  /// [stackTrace]: Pila de llamadas asociada.
  /// [reason]: Contexto legible de dónde y por qué ocurrió el error.
  /// [fatal]: Define si la excepción debe catalogarse como crítica o fatal.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    try {
      debugPrint('[Crashlytics recordError] Reason: $reason | Error: $exception');
      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        information: information,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('[CrashlyticsService] Fallo al reportar error: $e');
    }
  }

  /// Captura excepciones de Flutter ([FlutterErrorDetails]).
  void recordFlutterError(FlutterErrorDetails details, {bool fatal = false}) {
    try {
      _crashlytics.recordFlutterError(details, fatal: fatal);
    } catch (e) {
      debugPrint('[CrashlyticsService] Error al registrar FlutterError: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Eventos de diagnóstico de dominio específico (Breadcrumbs)
  // ---------------------------------------------------------------------------

  /// Diagnóstico del flujo de autenticación.
  Future<void> logAuthEvent(String action, {String? email, String? uid, String? role, String? extra}) async {
    final buffer = StringBuffer('AUTH: $action');
    if (uid != null) buffer.write(' | uid: $uid');
    if (role != null) buffer.write(' | role: $role');
    if (email != null) buffer.write(' | email: $email');
    if (extra != null) buffer.write(' | info: $extra');
    await log(buffer.toString());
  }

  /// Diagnóstico para operaciones de Firestore / Base de datos remota.
  Future<void> logFirestoreEvent(String operation, {required String path, String? details}) async {
    final msg = 'FIRESTORE: [$operation] en "$path"${details != null ? " ($details)" : ""}';
    await log(msg);
  }

  /// Diagnóstico para almacenamiento local (Hive, SecureStorage, SharedPreferences).
  Future<void> logStorageEvent(String operation, {required String boxOrKey, String? details}) async {
    final msg = 'LOCAL_STORAGE: [$operation] en "$boxOrKey"${details != null ? " ($details)" : ""}';
    await log(msg);
  }

  /// Diagnóstico para descarga y gestión de contenido multimedia / videos.
  Future<void> logDownloadEvent(String action, {required String resourceId, String? details}) async {
    final msg = 'DOWNLOAD: [$action] recurso: "$resourceId"${details != null ? " ($details)" : ""}';
    await log(msg);
  }

  String _resolvePlatform() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isWindows) return 'windows';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isLinux) return 'linux';
      if (Platform.isFuchsia) return 'fuchsia';
    } catch (_) {
      return 'unknown';
    }
    return 'unknown';
  }
}

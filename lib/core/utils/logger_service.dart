import 'package:flutter/foundation.dart';

class LoggerService {
  /// Registra una excepción con contexto sobre dónde ocurrió.
  /// En el futuro, esto se puede integrar con Crashlytics o Sentry.
  static void logError(String message, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('=========================================');
      print('🚨 ERROR: $message');
      print('Tipo: ${error.runtimeType}');
      print('Detalle: $error');
      if (stackTrace != null) {
        print('Traza: $stackTrace');
      }
      print('=========================================');
    }
    // TODO: Enviar a Crashlytics/Sentry en producción
    // FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
  }

  /// Registra información de interés.
  static void logInfo(String message) {
    if (kDebugMode) {
      print('ℹ️ INFO: $message');
    }
  }

  /// Registra una advertencia.
  static void logWarning(String message) {
    if (kDebugMode) {
      print('⚠️ WARN: $message');
    }
  }
}

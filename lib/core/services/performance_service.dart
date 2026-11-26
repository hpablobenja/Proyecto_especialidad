// lib/core/services/performance_service.dart

import 'dart:io' show Platform;
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Servicio centralizado de Firebase Performance Monitoring.
///
/// Encapsula la lógica de recolección de métricas, traces personalizados,
/// atributos globales y trazabilidad de operaciones críticas.
class PerformanceService {
  final FirebasePerformance _performance;

  PerformanceService({FirebasePerformance? performance})
    : _performance = performance ?? FirebasePerformance.instance;

  static final PerformanceService instance = PerformanceService();

  // Cache de contexto global para inyectar automáticamente en los traces
  String? _currentUserRole;
  String? _appVersion;
  String _platform = 'unknown';

  /// Inicializa la configuración de Performance Monitoring.
  ///
  /// Deshabilita la recolección en modo depuración ([kDebugMode]) a menos que
  /// se fuerce con [enableInDebug: true], previniendo datos ruidosos en Firebase Console.
  Future<void> initialize({
    bool enableInDebug = false,
    String? appVersion,
    String? userRole,
  }) async {
    try {
      _platform = _resolvePlatform();
      _appVersion = appVersion ?? '2.0.1';
      _currentUserRole = userRole;

      final shouldEnable = !kDebugMode || enableInDebug;
      await _performance.setPerformanceCollectionEnabled(shouldEnable);

      debugPrint(
        '[PerformanceService] Inicializado con éxito. '
        'Colección: ${shouldEnable ? "HABILITADA" : "DESHABILITADA (debug)"}. '
        'Plataforma: $_platform, Versión: $_appVersion',
      );
    } catch (e, stack) {
      debugPrint('[PerformanceService] Error en inicialización: $e\n$stack');
    }
  }

  /// Actualiza los atributos globales de usuario (rol, versión de app).
  void setUserContext({String? role, String? appVersion}) {
    if (role != null) _currentUserRole = role;
    if (appVersion != null) _appVersion = appVersion;
  }

  /// Crea e inicia un [Trace] personalizado, inyectando atributos estándar
  /// (plataforma, versión y rol de usuario).
  Future<Trace> startTrace(
    String traceName, {
    Map<String, String>? attributes,
  }) async {
    final trace = _performance.newTrace(traceName);
    await trace.start();

    // Atributos globales automáticos
    _applyGlobalAttributes(trace);

    // Atributos adicionales específicos provistos por quien invoca el trace
    if (attributes != null) {
      attributes.forEach((key, value) {
        if (value.isNotEmpty) {
          trace.putAttribute(key, value);
        }
      });
    }

    return trace;
  }

  /// Detiene de manera segura un trace si está activo.
  Future<void> stopTrace(Trace? trace) async {
    if (trace == null) return;
    try {
      await trace.stop();
    } catch (e) {
      debugPrint('[PerformanceService] Error al detener trace: $e');
    }
  }

  /// Ejecuta una acción asíncrona dentro de un trace automático (start -> stop),
  /// calculando duración y métricas adicionales de forma transparente.
  ///
  /// Maneja excepciones sin interrumpir la propagación del error y garantizando
  /// el cierre del trace en el bloque `finally`.
  Future<T> trackOperation<T>({
    required String traceName,
    required Future<T> Function(Trace trace) operation,
    Map<String, String>? attributes,
    Map<String, int>? initialMetrics,
  }) async {
    final trace = await startTrace(traceName, attributes: attributes);

    if (initialMetrics != null) {
      initialMetrics.forEach((metricName, value) {
        trace.setMetric(metricName, value);
      });
    }

    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation(trace);
      final elapsedMs = stopwatch.elapsed.inMilliseconds;
      trace.setMetric('execution_duration_ms', elapsedMs);
      trace.putAttribute('status', 'success');
      return result;
    } catch (e) {
      final elapsedMs = stopwatch.elapsed.inMilliseconds;
      trace.setMetric('execution_duration_ms', elapsedMs);
      trace.putAttribute('status', 'failure');
      trace.putAttribute('error_type', e.runtimeType.toString());
      rethrow;
    } finally {
      await stopTrace(trace);
    }
  }

  // ===========================================================================
  // MÉTODOS DE TRAZA ESPECÍFICOS PARA EL DOMINIO DE LA APLICACIÓN
  // ===========================================================================

  /// Trace para Inicio de Sesión de usuario.
  Future<T> trackUserLogin<T>({
    required String loginMethod,
    required Future<T> Function(Trace trace) operation,
  }) {
    return trackOperation(
      traceName: 'trace_user_login',
      attributes: {'auth_method': loginMethod},
      operation: operation,
    );
  }

  /// Trace para Carga de Lecciones desde Firestore.
  Future<T> trackLoadLessons<T>({
    required String courseId,
    String? moduleId,
    required Future<T> Function(Trace trace) operation,
  }) {
    return trackOperation(
      traceName: 'trace_load_lessons_firestore',
      attributes: {
        'course_id': courseId,
        if (moduleId != null) 'module_id': moduleId,
      },
      operation: operation,
    );
  }

  /// Trace para Carga de Cuestionarios y preguntas.
  Future<T> trackLoadQuiz<T>({
    required String lessonId,
    required Future<T> Function(Trace trace) operation,
  }) {
    return trackOperation(
      traceName: 'trace_load_quiz',
      attributes: {'lesson_id': lessonId},
      operation: operation,
    );
  }

  /// Trace para Sincronización de Datos con Cloud Firestore.
  Future<T> trackFirestoreSync<T>({
    required String syncType,
    required Future<T> Function(Trace trace) operation,
  }) {
    return trackOperation(
      traceName: 'trace_firestore_sync',
      attributes: {'sync_type': syncType},
      operation: operation,
    );
  }

  /// Trace para Apertura de Contenido Educativo (PDF, documento o módulo).
  Future<T> trackOpenEducationalContent<T>({
    required String contentType,
    required String contentId,
    required Future<T> Function(Trace trace) operation,
  }) {
    return trackOperation(
      traceName: 'trace_open_educational_content',
      attributes: {'content_type': contentType, 'content_id': contentId},
      operation: operation,
    );
  }

  /// Trace para Carga e inicialización de Videos Locales (almacenamiento en disco).
  Future<T> trackLoadLocalVideo<T>({
    required String videoPath,
    required Future<T> Function(Trace trace) operation,
  }) {
    return trackOperation(
      traceName: 'trace_load_local_video',
      attributes: {'has_file': videoPath.isNotEmpty.toString()},
      operation: operation,
    );
  }

  /// Trace para Descarga de Videos o recursos multimedia.
  Future<T> trackVideoDownload<T>({
    required String videoId,
    required Future<T> Function(Trace trace) operation,
  }) {
    return trackOperation(
      traceName: 'trace_video_download',
      attributes: {'video_id': videoId},
      operation: operation,
    );
  }

  // ===========================================================================
  // HELPERS INTERNOS
  // ===========================================================================

  void _applyGlobalAttributes(Trace trace) {
    try {
      trace.putAttribute('platform', _platform);
      if (_appVersion != null && _appVersion!.isNotEmpty) {
        trace.putAttribute('app_version', _appVersion!);
      }
      if (_currentUserRole != null && _currentUserRole!.isNotEmpty) {
        trace.putAttribute('user_role', _currentUserRole!);
      }
    } catch (e) {
      debugPrint('[PerformanceService] Error aplicando atributos globales: $e');
    }
  }

  String _resolvePlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}

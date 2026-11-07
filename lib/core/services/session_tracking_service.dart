import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './../../data/repositories/data_user_repository.dart';
import '../../domain/entities/system_config_entity.dart';

/// Servicio para tracking de tiempo de sesión del usuario
/// Se encarga de iniciar, actualizar y finalizar sesiones automáticamente
class SessionTrackingService {
  static final SessionTrackingService _instance =
      SessionTrackingService._internal();
  factory SessionTrackingService() => _instance;
  SessionTrackingService._internal();

  late final DataUserRepository _dataUserRepository = DataUserRepository();
  Timer? _sessionTimer;
  Timer? _warningTimer;
  bool _isSessionActive = false;
  int _currentSessionMinutes = 0;
  int _totalSessionMinutes = 0;

  // Configuración dinámica
  int _sessionWarningMinutes = 5;
  int _maxSessionDurationMinutes = 120;

  static const String _currentSessionKey = 'current_session_minutes';
  static const String _totalSessionKey = 'total_session_minutes';

  /// Iniciar tracking de sesión
  Future<void> startSessionTracking() async {
    if (_isSessionActive) return;

    // Verificar si el rol es 'maestro'
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('user_role');

    if (userRole != 'maestro') {
      return;
    }

    // Cargar tiempos desde SharedPreferences
    await _loadTimesFromPrefs();

    await _dataUserRepository.startSession();
    _isSessionActive = true;

    // Actualizar tiempo de sesión cada minuto (localmente)
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      _currentSessionMinutes++;
      _totalSessionMinutes++;

      // Guardar en SharedPreferences
      await _saveTimesToPrefs();

      // Verificar si se alcanzó el máximo de tiempo de sesión
      if (_currentSessionMinutes >= _maxSessionDurationMinutes) {
        await stopSessionTracking();
        debugPrint('Sesión finalizada por tiempo máximo alcanzado');
      }

      // No actualizamos en Firestore aquí para evitar llamadas cada minuto.
      // Se actualizará al entrar al Dashboard o al cerrar la sesión.
    });

    // Iniciar timer para advertencia de sesión
    _warningTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final remainingMinutes = _maxSessionDurationMinutes - _currentSessionMinutes;
      if (remainingMinutes == _sessionWarningMinutes && remainingMinutes > 0) {
        debugPrint('Advertencia: $remainingMinutes minutos restantes de sesión');
      }
    });
  }

  /// Detener tracking de sesión
  Future<void> stopSessionTracking() async {
    if (!_isSessionActive) return;

    _sessionTimer?.cancel();
    _sessionTimer = null;
    _warningTimer?.cancel();
    _warningTimer = null;
    await _dataUserRepository.endSession();
    _isSessionActive = false;

    // Resetear sesión actual pero mantener total
    _currentSessionMinutes = 0;
    await _saveTimesToPrefs();
  }

  /// Actualizar la configuración del servicio
  void updateConfig(SystemConfigEntity config) {
    _sessionWarningMinutes = config.sessionWarningMinutes;
    _maxSessionDurationMinutes = config.maxSessionDurationMinutes;
    debugPrint('SessionTrackingService config updated: '
        'sessionWarningMinutes=$_sessionWarningMinutes, '
        'maxSessionDurationMinutes=$_maxSessionDurationMinutes');
  }

  /// Cargar tiempos desde SharedPreferences
  Future<void> _loadTimesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _currentSessionMinutes = prefs.getInt(_currentSessionKey) ?? 0;
    _totalSessionMinutes = prefs.getInt(_totalSessionKey) ?? 0;
  }

  /// Guardar tiempos en SharedPreferences
  Future<void> _saveTimesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentSessionKey, _currentSessionMinutes);
    await prefs.setInt(_totalSessionKey, _totalSessionMinutes);
  }

  /// Obtener tiempo de sesión actual
  int get currentSessionMinutes => _currentSessionMinutes;

  /// Obtener tiempo total
  int get totalSessionMinutes => _totalSessionMinutes;

  /// Verificar si la sesión está activa
  bool get isSessionActive => _isSessionActive;

  /// Dispose del servicio
  void dispose() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _isSessionActive = false;
  }
}

/// Widget wrapper para manejar el ciclo de vida de la sesión
class SessionLifecycleHandler extends StatefulWidget {
  final Widget child;

  const SessionLifecycleHandler({required this.child, super.key});

  @override
  State<SessionLifecycleHandler> createState() =>
      _SessionLifecycleHandlerState();
}

class _SessionLifecycleHandlerState extends State<SessionLifecycleHandler>
    with WidgetsBindingObserver {
  final SessionTrackingService _sessionService = SessionTrackingService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionService.startSessionTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionService.stopSessionTracking();
    _sessionService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App está en primer plano
        _sessionService.startSessionTracking();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App está en segundo plano o cerrándose
        _sessionService.stopSessionTracking();
        break;
      case AppLifecycleState.hidden:
        // App está oculta
        _sessionService.stopSessionTracking();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

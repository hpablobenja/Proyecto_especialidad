import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './../../data/repositories/data_user_repository.dart';

/// Servicio para tracking de tiempo de sesión del usuario
/// Se encarga de iniciar, actualizar y finalizar sesiones automáticamente
class SessionTrackingService {
  static final SessionTrackingService _instance =
      SessionTrackingService._internal();
  factory SessionTrackingService() => _instance;
  SessionTrackingService._internal();

  final DataUserRepository _dataUserRepository = DataUserRepository();
  Timer? _sessionTimer;
  bool _isSessionActive = false;
  int _currentSessionMinutes = 0;
  int _totalSessionMinutes = 0;

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
      
      // No actualizamos en Firestore aquí para evitar llamadas cada minuto.
      // Se actualizará al entrar al Dashboard o al cerrar la sesión.
    });
  }

  /// Detener tracking de sesión
  Future<void> stopSessionTracking() async {
    if (!_isSessionActive) return;

    _sessionTimer?.cancel();
    _sessionTimer = null;
    await _dataUserRepository.endSession();
    _isSessionActive = false;
    
    // Resetear sesión actual pero mantener total
    _currentSessionMinutes = 0;
    await _saveTimesToPrefs();
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

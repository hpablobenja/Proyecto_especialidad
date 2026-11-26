// lib/presentation/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../domain/usecases/auth/update_user_usecase.dart';
import '../../domain/usecases/auth/reset_password_usecase.dart';
import '../../domain/usecases/usecase.dart';
import '../../core/services/session_tracking_service.dart';
import '../../core/services/dashboard_sync_service.dart';
import '../../core/services/quiz_sync_service.dart';
import '../../core/services/video_download_service.dart';
import '../../core/services/local_data_clear_service.dart';
import '../../core/services/crashlytics_service.dart';
import '../../data/datasources/local/video_tracking_hive_datasource.dart';

class AuthProvider extends ChangeNotifier {
  final LoginUsecase loginUsecase;
  final RegisterUsecase registerUsecase;
  final GetCurrentUserUsecase getCurrentUserUsecase;
  final UpdateUserUsecase updateUserUsecase;
  final ResetPasswordUsecase resetPasswordUsecase;

  AuthProvider({
    required this.loginUsecase,
    required this.registerUsecase,
    required this.getCurrentUserUsecase,
    required this.updateUserUsecase,
    required this.resetPasswordUsecase,
    VideoTrackingHiveDataSource? videoTrackingDataSource,
    DashboardSyncService? dashboardSyncService,
    QuizSyncService? quizSyncService,
    VideoDownloadService? videoDownloadService,
    LocalDataClearService? localDataClearService,
    CrashlyticsService? crashlyticsService,
  })  : _videoTrackingDataSource = videoTrackingDataSource,
        _dashboardSyncService = dashboardSyncService,
        _quizSyncService = quizSyncService,
        _videoDownloadService = videoDownloadService,
        _localDataClearService = localDataClearService,
        _crashlyticsService = crashlyticsService ?? CrashlyticsService.instance {
    checkCurrentUser();
  }

  bool _isLoading = true;
  String? _errorMessage;
  UserEntity? _currentUser;

  final _secureStorage = const FlutterSecureStorage();
  final VideoTrackingHiveDataSource? _videoTrackingDataSource;
  final DashboardSyncService? _dashboardSyncService;
  final QuizSyncService? _quizSyncService;
  final VideoDownloadService? _videoDownloadService;
  final LocalDataClearService? _localDataClearService;
  final CrashlyticsService _crashlyticsService;

  String? _previousUserId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserEntity? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await loginUsecase.call(
        LoginParams(email: email, password: password),
      );

      // Limpiar datos del usuario anterior si existe y es diferente
      if (_previousUserId != null && _previousUserId != _currentUser!.uid) {
        await _localDataClearService?.clearUserData(_previousUserId!);
      }

      // Cache credentials for offline login (last 2 users)
      await _cacheUserCredentials(email, password, _currentUser!);

      // Save user role to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', _currentUser!.role);
      await prefs.setString('user_id', _currentUser!.uid);
      debugPrint('Usuario autenticado con role: ${_currentUser!.role}');

      // Sincronizar dashboard en segundo plano si es maestro
      if (_currentUser!.role == 'maestro' && _dashboardSyncService != null) {
        _dashboardSyncService.syncFromFirestore(_currentUser!.uid).catchError((e) {
          debugPrint('Error al sincronizar dashboard al iniciar sesión: $e');
        });
      }

      // Establecer usuario en el servicio de sincronización de quizzes
      _quizSyncService?.setCurrentUser(_currentUser!.uid);

      // Establecer usuario en el servicio de descarga de videos
      _videoDownloadService?.setCurrentUser(_currentUser!.uid);

      _previousUserId = _currentUser!.uid;

      // Registrar contexto de usuario en Crashlytics
      await _crashlyticsService.setUserContext(
        userId: _currentUser!.uid,
        role: _currentUser!.role,
      );
      await _crashlyticsService.logAuthEvent(
        'LOGIN_SUCCESS',
        email: email,
        uid: _currentUser!.uid,
        role: _currentUser!.role,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Try offline login if online login fails
      final offlineUser = await _tryOfflineLogin(email, password);
      if (offlineUser != null) {
        // Limpiar datos del usuario anterior si existe y es diferente
        if (_previousUserId != null && _previousUserId != offlineUser.uid) {
          await _localDataClearService?.clearUserData(_previousUserId!);
        }

        _currentUser = offlineUser;
        _errorMessage = null;

        // Save user role to SharedPreferences for offline user
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', _currentUser!.role);
        await prefs.setString('user_id', _currentUser!.uid);

        // Establecer usuario en el servicio de sincronización de quizzes
        _quizSyncService?.setCurrentUser(_currentUser!.uid);

        // Establecer usuario en el servicio de descarga de videos
        _videoDownloadService?.setCurrentUser(_currentUser!.uid);

        _previousUserId = _currentUser!.uid;

        // Registrar contexto en Crashlytics (modo offline)
        await _crashlyticsService.setUserContext(
          userId: _currentUser!.uid,
          role: _currentUser!.role,
        );
        await _crashlyticsService.logAuthEvent(
          'OFFLINE_LOGIN_SUCCESS',
          email: email,
          uid: _currentUser!.uid,
          role: _currentUser!.role,
        );

        _isLoading = false;
        notifyListeners();
        return true;
      }

      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }
      _errorMessage = errorMsg;

      await _crashlyticsService.logAuthEvent(
        'LOGIN_FAILED',
        email: email,
        extra: errorMsg,
      );
      await _crashlyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Error al iniciar sesión con email: $email',
      );

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _cacheUserCredentials(
    String email,
    String password,
    UserEntity user,
  ) async {
    try {
      // Get existing cached users
      final cachedUsersString = await _secureStorage.read(key: 'cached_users');
      List<dynamic> cachedUsers = [];
      if (cachedUsersString != null) {
        cachedUsers = jsonDecode(cachedUsersString);
      }

      // Remove if user already exists
      cachedUsers.removeWhere((u) => u['email'] == email);

      // Add new user at the beginning
      cachedUsers.insert(0, {
        'email': email,
        'password': password,
        'uid': user.uid,
        'name': user.name,
        'role': user.role,
        'workArea': user.workArea,
        'specialty': user.specialty,
      });

      // Keep only last 2 users
      if (cachedUsers.length > 2) {
        cachedUsers.removeRange(2, cachedUsers.length);
      }

      // Save back to secure storage
      await _secureStorage.write(
        key: 'cached_users',
        value: jsonEncode(cachedUsers),
      );
    } catch (e) {
      // Silently fail - caching is not critical
      debugPrint('Error caching credentials: $e');
    }
  }

  Future<UserEntity?> _tryOfflineLogin(String email, String password) async {
    try {
      final cachedUsersString = await _secureStorage.read(key: 'cached_users');
      if (cachedUsersString == null) return null;

      final cachedUsers = jsonDecode(cachedUsersString) as List<dynamic>;

      for (final userData in cachedUsers) {
        if (userData['email'] == email && userData['password'] == password) {
          return UserEntity(
            uid: userData['uid'],
            email: userData['email'],
            name: userData['name'],
            role: userData['role'],
            workArea: userData['workArea'],
            specialty: userData['specialty'],
          );
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error during offline login: $e');
      return null;
    }
  }

  Future<bool> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
    String? workArea,
    String? specialty,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await registerUsecase.call(
        RegisterParams(
          email: email,
          password: password,
          name: name,
          role: role,
          workArea: workArea,
          specialty: specialty,
        ),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }
      _errorMessage = errorMsg;

      await _crashlyticsService.logAuthEvent(
        'REGISTER_FAILED',
        email: email,
        extra: errorMsg,
      );
      await _crashlyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Error en registro de usuario con email: $email',
      );

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    _currentUser = await getCurrentUserUsecase.call(NoParams());
    if (_currentUser != null) {
      // Limpiar datos del usuario anterior si existe y es diferente
      if (_previousUserId != null && _previousUserId != _currentUser!.uid) {
        await _localDataClearService?.clearUserData(_previousUserId!);
      }

      _quizSyncService?.setCurrentUser(_currentUser!.uid);
      _videoDownloadService?.setCurrentUser(_currentUser!.uid);
      _previousUserId = _currentUser!.uid;

      await _crashlyticsService.setUserContext(
        userId: _currentUser!.uid,
        role: _currentUser!.role,
      );
      await _crashlyticsService.logAuthEvent(
        'SESSION_RESTORED',
        uid: _currentUser!.uid,
        role: _currentUser!.role,
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Stop the session timer before clearing user data
      try {
        await SessionTrackingService().stopSessionTracking();
      } catch (e) {
        debugPrint('Session tracking stop failed: $e');
      }

      // Call the repository's signOut method to clear Firebase auth state
      try {
        await loginUsecase.repository.signOut();
      } catch (e) {
        // If offline, signOut from Firebase will fail, but we still want to clear local state
        debugPrint('Firebase signOut failed (possibly offline): $e');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_role');

      // Limpiar usuario del servicio de sincronización de quizzes
      _quizSyncService?.clearUser();

      // Limpiar usuario del servicio de descarga de videos
      _videoDownloadService?.clearUser();

      await _crashlyticsService.logAuthEvent('SIGNOUT', uid: _currentUser?.uid);
      await _crashlyticsService.setUserId(null);
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión: ${e.toString()}';
      await _crashlyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Error durante signOut',
      );
    } finally {
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearFavoritesState() {
    // Este método será llamado para limpiar el estado de cursos iniciados
    // cuando el usuario se desloguea
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await resetPasswordUsecase.call(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }
      _errorMessage = errorMsg;

      await _crashlyticsService.logAuthEvent(
        'RESET_PASSWORD_FAILED',
        email: email,
        extra: errorMsg,
      );
      await _crashlyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Error al solicitar restablecimiento de contraseña para $email',
      );

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(
    String name,
    String? workArea,
    String? specialty,
  ) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = UserEntity(
        uid: _currentUser!.uid,
        email: _currentUser!.email,
        name: name,
        role: _currentUser!.role,
        workArea: workArea ?? _currentUser!.workArea,
        specialty: specialty ?? _currentUser!.specialty,
      );

      await updateUserUsecase.call(updatedUser);
      _currentUser = updatedUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }
      _errorMessage = errorMsg;

      await _crashlyticsService.recordError(
        e,
        StackTrace.current,
        reason: 'Error al actualizar perfil del usuario ${_currentUser?.uid}',
      );

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

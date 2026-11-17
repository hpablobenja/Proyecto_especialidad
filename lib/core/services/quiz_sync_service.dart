// lib/core/services/quiz_sync_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/quiz_offline_service.dart';

/// Servicio global para sincronizar quizzes offline cuando se restaura la conexión
/// Se inicializa en main.dart y escucha cambios de conectividad a nivel de aplicación
class QuizSyncService {
  static final QuizSyncService _instance = QuizSyncService._internal();
  factory QuizSyncService() => _instance;
  QuizSyncService._internal();

  final QuizOfflineService _quizOfflineService = QuizOfflineService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isInitialized = false;
  bool _isOnline = true;
  String? _currentUserId;

  /// Callback para notificar cuando se sincronizan quizzes
  Function(String userId)? onQuizzesSynced;

  /// Inicializa el servicio
  Future<void> init() async {
    if (_isInitialized) return;
    
    await _quizOfflineService.init();
    
    // Verificar conectividad inicial
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    
    // Escuchar cambios de conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
    
    _isInitialized = true;
    debugPrint('QuizSyncService initialized');
  }

  /// Establece el usuario actual para sincronización
  void setCurrentUser(String userId) {
    _currentUserId = userId;
    debugPrint('QuizSyncService: User set to $userId');
    
    // Si ya está online, intentar sincronizar inmediatamente
    if (_isOnline && _currentUserId != null) {
      _syncPendingQuizzes();
    }
  }

  /// Limpia el usuario actual (logout)
  void clearUser() {
    _currentUserId = null;
    debugPrint('QuizSyncService: User cleared');
  }

  /// Maneja cambios de conectividad
  void _handleConnectivityChange(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (!wasOnline && _isOnline) {
      debugPrint('QuizSyncService: Connection restored, syncing pending quizzes...');
      _syncPendingQuizzes();
    } else if (wasOnline && !_isOnline) {
      debugPrint('QuizSyncService: Connection lost');
    }
  }

  /// Sincroniza quizzes pendientes de sincronización
  Future<void> _syncPendingQuizzes() async {
    if (_currentUserId == null) {
      debugPrint('QuizSyncService: No user set, skipping sync');
      return;
    }

    final pendingQuizzes = _quizOfflineService.getPendingSyncQuizzes(_currentUserId!);
    
    if (pendingQuizzes.isEmpty) {
      debugPrint('QuizSyncService: No pending quizzes to sync');
      return;
    }

    debugPrint('QuizSyncService: Found ${pendingQuizzes.length} pending quizzes to sync');
    int syncedCount = 0;

    for (final quiz in pendingQuizzes) {
      try {
        // Guardar respuestas en quizRespuestas
        final quizRespuestaRef = await _firestore.collection('quizRespuestas').add({
          'userId': quiz.userId,
          'quizId': quiz.quizId,
          'lessonId': quiz.lessonId,
          'moduleId': quiz.moduleId,
          'courseId': quiz.courseId,
          'score': quiz.score,
          'maxScore': quiz.maxScore,
          'answers': quiz.answerDetails.map((a) => a.toMap()).toList(),
          'submittedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('QuizSyncService: Respuestas guardadas en quizRespuestas. Document ID: ${quizRespuestaRef.id}, Quiz ID: ${quiz.quizId}');

        // Actualizar progreso en userProgress
        final progressId =
            '${quiz.userId}-${quiz.courseId}-${quiz.moduleId}-${quiz.lessonId}';
        await _firestore.collection('userProgress').doc(progressId).set({
          'userId': quiz.userId,
          'courseId': quiz.courseId,
          'moduleId': quiz.moduleId,
          'lessonId': quiz.lessonId,
          'hasCompletedQuiz': true,
          'quizScore': quiz.score,
          'maxQuizScore': quiz.maxScore,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Eliminar el quiz local después de sincronizar exitosamente
        await _quizOfflineService.deleteQuizProgress(quiz.userId, quiz.quizId);
        syncedCount++;
        debugPrint('QuizSyncService: Quiz synced and removed from local storage: ${quiz.quizId}');
      } catch (e) {
        debugPrint('QuizSyncService: Error syncing quiz ${quiz.quizId}: $e');
      }
    }

    if (syncedCount > 0 && _currentUserId != null) {
      onQuizzesSynced?.call(_currentUserId!);
    }

    debugPrint('QuizSyncService: Sync completed');
  }

  /// Fuerza una sincronización manual
  Future<void> forceSync() async {
    if (_currentUserId == null) {
      debugPrint('QuizSyncService: No user set, cannot force sync');
      return;
    }
    
    if (!_isOnline) {
      debugPrint('QuizSyncService: Offline, cannot force sync');
      return;
    }
    
    await _syncPendingQuizzes();
  }

  /// Dispose del servicio
  void dispose() {
    _connectivitySubscription?.cancel();
    _isInitialized = false;
    debugPrint('QuizSyncService disposed');
  }
}

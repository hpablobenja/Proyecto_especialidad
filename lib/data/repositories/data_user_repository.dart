import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_user_model.dart';

class DataUserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener datos del usuario actual
  Future<DataUserModel?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId == null) return null;

    final doc = await _firestore.collection('dataUser').doc(userId).get();
    if (!doc.exists) {
      // Crear documento inicial si no existe
      return await _createInitialUserData(userId);
    }

    return DataUserModel.fromFirestore(doc);
  }

  // Stream de datos del usuario
  Stream<DataUserModel?> getUserDataStream() async* {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId == null) {
      yield null;
      return;
    }

    yield* _firestore
        .collection('dataUser')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? DataUserModel.fromFirestore(doc) : null);
  }

  // Crear datos iniciales del usuario
  Future<DataUserModel> _createInitialUserData(String userId) async {
    final initialData = DataUserModel(
      userId: userId,
      currentSessionMinutes: 0,
      totalSessionMinutes: 0,
      sessionStartTime: DateTime.now(),
      lastSessionEnd: DateTime.now(),
      categoryProgress: {
        'Ciencias Sociales': 0.0,
        'Ciencias Naturales': 0.0,
        'Comunicación y Lenguaje': 0.0,
        'Alternativa': 0.0,
        'Otro(Especificar)': 0.0,
      },
      overallProgress: 0.0,
      unlockedAchievements: [],
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('dataUser').doc(userId).set(initialData.toMap());
    return initialData;
  }

  // Iniciar sesión (registrar tiempo de inicio)
  Future<void> startSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId == null) return;

    // Esperar a que FirebaseAuth inicialice el usuario antes de escribir en Firestore
    // para evitar el error de PERMISSION_DENIED en el arranque de la app.
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.authStateChanges().firstWhere((user) => user != null, orElse: () => null);
      if (FirebaseAuth.instance.currentUser == null) return; // Sigue deslogueado
    }

    try {
      final doc = await _firestore.collection('dataUser').doc(userId).get();
      if (doc.exists) {
        final userData = DataUserModel.fromFirestore(doc);
        if (userData.sessionStartTime != null) {
          // Si había una sesión activa que no se cerró correctamente,
          // recuperamos los minutos acumulados y los sumamos al total.
          final recoveredMinutes = userData.currentSessionMinutes;
          final newTotal = userData.totalSessionMinutes + recoveredMinutes;
          await _firestore.collection('dataUser').doc(userId).update({
            'totalSessionMinutes': newTotal,
            'currentSessionMinutes': 0,
            'sessionStartTime': null,
          });
        }
      } else {
        // Crear datos iniciales si no existe
        await _createInitialUserData(userId);
      }

      await _firestore.collection('dataUser').doc(userId).set({
        'userId': userId,
        'sessionStartTime': FieldValue.serverTimestamp(),
        'currentSessionMinutes': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error al iniciar sesión en dataUser: $e");
    }
  }

  // Finalizar sesión (actualizar tiempos)
  Future<void> endSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId == null) return;

    final doc = await _firestore.collection('dataUser').doc(userId).get();
    if (!doc.exists) return;

    final userData = DataUserModel.fromFirestore(doc);
    final sessionStartTime = userData.sessionStartTime;
    
    if (sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(sessionStartTime).inMinutes;
      final newTotalMinutes = userData.totalSessionMinutes + sessionDuration;

      await _firestore.collection('dataUser').doc(userId).update({
        'currentSessionMinutes': 0,
        'totalSessionMinutes': newTotalMinutes,
        'sessionStartTime': null,
        'lastSessionEnd': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Actualizar tiempo de sesión actual (llamar periódicamente)
  Future<void> updateCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId == null) return;

    final doc = await _firestore.collection('dataUser').doc(userId).get();
    
    DateTime? sessionStartTime;
    if (doc.exists) {
      final userData = DataUserModel.fromFirestore(doc);
      sessionStartTime = userData.sessionStartTime;
    }
    
    if (sessionStartTime != null) {
      final currentDuration = DateTime.now().difference(sessionStartTime).inMinutes;
      
      await _firestore.collection('dataUser').doc(userId).set({
        'currentSessionMinutes': currentDuration,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Calcular y actualizar progreso por categoría
  Future<void> updateCategoryProgress(String category, double progress) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId == null) return;

    final doc = await _firestore.collection('dataUser').doc(userId).get();
    
    Map<String, double> updatedProgress;
    if (doc.exists) {
      final userData = DataUserModel.fromFirestore(doc);
      updatedProgress = Map<String, double>.from(userData.categoryProgress);
    } else {
      // Crear datos iniciales si no existe el documento
      updatedProgress = {
        'Ciencias Sociales': 0.0,
        'Ciencias Naturales': 0.0,
        'Comunicación y Lenguaje': 0.0,
        'Alternativa': 0.0,
        'Otro(Especificar)': 0.0,
      };
    }
    
    updatedProgress[category] = progress;

    // Calcular progreso general basado en el promedio de categorías
    final totalProgress = updatedProgress.values.reduce((a, b) => a + b);
    final averageProgress = totalProgress / updatedProgress.length;

    await _firestore.collection('dataUser').doc(userId).set({
      'categoryProgress': updatedProgress,
      'overallProgress': averageProgress,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Recalcular progreso general basado en todas las categorías
  Future<void> recalculateOverallProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId == null) return;

    final doc = await _firestore.collection('dataUser').doc(userId).get();
    
    Map<String, double> categoryProgress;
    if (doc.exists) {
      final userData = DataUserModel.fromFirestore(doc);
      categoryProgress = userData.categoryProgress;
    } else {
      categoryProgress = {
        'Ciencias Sociales': 0.0,
        'Ciencias Naturales': 0.0,
        'Comunicación y Lenguaje': 0.0,
        'Alternativa': 0.0,
        'Otro(Especificar)': 0.0,
      };
    }

    final totalProgress = categoryProgress.values.reduce((a, b) => a + b);
    final averageProgress = totalProgress / categoryProgress.length;

    await _firestore.collection('dataUser').doc(userId).set({
      'overallProgress': averageProgress,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Desbloquear logro
  Future<void> unlockAchievement(String achievementId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId == null) return;

    final doc = await _firestore.collection('dataUser').doc(userId).get();
    
    List<String> unlockedAchievements;
    if (doc.exists) {
      final userData = DataUserModel.fromFirestore(doc);
      unlockedAchievements = userData.unlockedAchievements;
    } else {
      unlockedAchievements = [];
    }

    if (!unlockedAchievements.contains(achievementId)) {
      final updatedAchievements = List<String>.from(unlockedAchievements);
      updatedAchievements.add(achievementId);

      await _firestore.collection('dataUser').doc(userId).set({
        'unlockedAchievements': updatedAchievements,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Verificar y desbloquear logros automáticamente
  Future<void> checkAndUnlockAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId == null) return;

    final doc = await _firestore.collection('dataUser').doc(userId).get();
    if (!doc.exists) return;

    final userData = DataUserModel.fromFirestore(doc);
    final achievementsToUnlock = <String>[];

    // Logro: Primer curso completado (10+ horas de estudio)
    if (userData.totalSessionMinutes >= 600 && !userData.unlockedAchievements.contains('10_hours_study')) {
      achievementsToUnlock.add('10_hours_study');
    }

    // Logro: 5 cursos completados (se verificará desde otra parte)
    // Logro: 10 horas de estudio (ya verificado arriba)

    // Desbloquear logros
    for (final achievement in achievementsToUnlock) {
      await unlockAchievement(achievement);
    }
  }
}

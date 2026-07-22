// lib/presentation/providers/favorites_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/data_user_repository.dart';
import '../../data/models/course_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _startedCourseIds = {};
  String? _currentUserId;
  final DataUserRepository _dataUserRepository = DataUserRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> get startedCourseIds =>
      _startedCourseIds.toList(growable: false);

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) throw Exception('User not logged in');
    return userId;
  }

  Future<void> load() async {
    try {
      final userId = await _getUserId();
      
      // Si el usuario cambió, limpiar y recargar
      if (_currentUserId != userId) {
        _startedCourseIds.clear();
        _currentUserId = userId;
      }
      
      // Cargar cursos iniciados desde Firestore
      final userCoursesSnapshot = await _firestore
          .collection('user_courses')
          .where('userId', isEqualTo: userId)
          .get();
      
      _startedCourseIds.clear();
      for (final doc in userCoursesSnapshot.docs) {
        final courseId = doc.data()['courseId'] as String?;
        if (courseId != null) {
          _startedCourseIds.add(courseId);
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  // Limpiar el estado cuando el usuario se desloguea
  void clear() {
    _startedCourseIds.clear();
    _currentUserId = null;
    notifyListeners();
  }

  Future<void> markCourseStarted(String courseId) async {
    try {
      final userId = await _getUserId();
      
      // Verificar si el rol es 'maestro'
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role');
      
      if (userRole != 'maestro') {
        return;
      }

      // Verificar si ya existe el curso para este usuario
      final existingCourse = await _firestore
          .collection('user_courses')
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .get();
      
      if (existingCourse.docs.isEmpty) {
        // Guardar en Firestore para persistencia
        await _firestore.collection('user_courses').add({
          'userId': userId,
          'courseId': courseId,
          'status': 'in_progress',
          'startedAt': FieldValue.serverTimestamp(),
        });
        
        _startedCourseIds.add(courseId);
        notifyListeners();
        
        // Actualizar progreso por categoría en dataUser
        await _updateCategoryProgressForCourse(courseId);
      }
    } catch (e) {
      print('Error marking course started: $e');
    }
  }

  Future<void> _updateCategoryProgressForCourse(String courseId) async {
    try {
      // Obtener información del curso
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) return;
      
      final courseData = courseDoc.data();
      final category = courseData?['targetAudience'] as String?;
      
      if (category == null) return;
      
      // Obtener todos los cursos de esa categoría
      final categoryCourses = await _firestore
          .collection('courses')
          .where('targetAudience', isEqualTo: category)
          .get();
      
      final totalCoursesInCategory = categoryCourses.docs.length;
      
      // Obtener cursos iniciados del usuario en esa categoría
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) return;
      
      final userCoursesSnapshot = await _firestore
          .collection('user_courses')
          .where('userId', isEqualTo: userId)
          .get();
      
      final userCourseIds = userCoursesSnapshot.docs
          .map((doc) => doc.data()['courseId'] as String)
          .toSet();
      
      // Obtener cursos de la categoría que el usuario ha iniciado
      final categoryCourseIds = categoryCourses.docs.map((doc) => doc.id).toSet();
      final startedInCategory = categoryCourseIds.intersection(userCourseIds);
      
      // Calcular progreso (cursos iniciados / total cursos en categoría)
      final progress = totalCoursesInCategory > 0 
          ? (startedInCategory.length / totalCoursesInCategory) * 100 
          : 0.0;
      
      // Actualizar en dataUser
      await _dataUserRepository.updateCategoryProgress(category, progress);
      
      // Recalcular progreso general
      await _dataUserRepository.recalculateOverallProgress();
      
      // Verificar logros
      await _dataUserRepository.checkAndUnlockAchievements();
    } catch (e) {
      print('Error al actualizar progreso por categoría: $e');
    }
  }

  bool isCourseStarted(String courseId) => _startedCourseIds.contains(courseId);
}

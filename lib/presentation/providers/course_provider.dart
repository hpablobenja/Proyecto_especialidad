// lib/presentation/providers/course_provider.dart

import 'package:flutter/material.dart';

import '../../domain/entities/course_entity.dart';
import '../../domain/usecases/courses/get_courses_usecase.dart';
import '../../domain/usecases/courses/create_course_usecase.dart';
import '../../domain/usecases/usecase.dart';

class CourseProvider extends ChangeNotifier {
  final GetCoursesUsecase getCoursesUsecase;
  final CreateCourseUsecase createCourseUsecase;

  CourseProvider({
    required this.getCoursesUsecase,
    required this.createCourseUsecase,
  });

  bool _isLoading = false;
  String? _errorMessage;
  List<CourseEntity> _courses = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CourseEntity> get courses => _courses;

  Future<void> loadCourses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _courses = await getCoursesUsecase.call(NoParams());
    } catch (e) {
      _errorMessage = 'No se pudieron cargar los cursos. $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCourse(String title, String description, {String targetAudience = 'General'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await createCourseUsecase.call(
        CreateCourseParams(
          title: title, 
          description: description,
          targetAudience: targetAudience,
        ),
      );
      _courses = List.of(_courses)..add(created);
      return true;
    } catch (e) {
      _errorMessage = 'Error al crear el curso. $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// lib/presentation/providers/content_provider.dart

import 'package:flutter/material.dart';

import '../../domain/entities/course_entity.dart';
import '../../domain/usecases/content/list_courses_usecase.dart'
    as content_list;
import '../../domain/usecases/content/create_course_usecase.dart'
    as content_create_course;
import '../../domain/usecases/content/update_course_usecase.dart'
    as content_update_course;
import '../../domain/usecases/content/delete_course_usecase.dart'
    as content_delete_course;
import '../../domain/usecases/usecase.dart';

class ContentProvider extends ChangeNotifier {
  final content_list.ListCoursesUsecase listCoursesUsecase;
  final content_create_course.CreateCourseUsecase createCourseUsecase;
  final content_update_course.UpdateCourseUsecase updateCourseUsecase;
  final content_delete_course.DeleteCourseUsecase deleteCourseUsecase;

  ContentProvider({
    required this.listCoursesUsecase,
    required this.createCourseUsecase,
    required this.updateCourseUsecase,
    required this.deleteCourseUsecase,
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
      final result = await listCoursesUsecase.call(NoParams());
      _courses = result;
    } catch (e) {
      _errorMessage = 'No se pudieron cargar los cursos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CourseEntity?> createCourse(CourseEntity course) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final created = await createCourseUsecase.call(course);
      _courses = [..._courses, created];
      return created;
    } catch (e) {
      _errorMessage = 'No se pudo crear el curso: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CourseEntity?> updateCourse(CourseEntity course) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await updateCourseUsecase.call(course);
      _courses = _courses.map((c) => c.id == updated.id ? updated : c).toList();
      return updated;
    } catch (e) {
      _errorMessage = 'No se pudo actualizar el curso: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await deleteCourseUsecase.call(
        content_delete_course.DeleteCourseParams(courseId),
      );
      _courses = _courses.where((c) => c.id != courseId).toList();
      return true;
    } catch (e) {
      _errorMessage = 'No se pudo eliminar el curso: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

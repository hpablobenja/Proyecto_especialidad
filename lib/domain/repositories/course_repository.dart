// lib/domain/repositories/course_repository.dart

import '../entities/course_entity.dart';

abstract class CourseRepository {
  Future<List<CourseEntity>> getCourses();
  Future<CourseEntity> createCourse(CourseEntity course);
  Future<CourseEntity> updateCourse(CourseEntity course);
  Future<bool> updateCourseStatus(String courseId, String status);
  // Aquí se agregarían los métodos para editar, eliminar, buscar, etc.
}

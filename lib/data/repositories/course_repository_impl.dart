// lib/data/repositories/course_repository_impl.dart

import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/remote/course_remote_datasource.dart';
import '../models/course_model.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource remoteDataSource;

  CourseRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CourseEntity>> getCourses() async {
    final courseModels = await remoteDataSource.getCourses();
    return courseModels; // La lista de CourseModel es compatible con List<CourseEntity>
  }

  @override
  Future<CourseEntity> createCourse(CourseEntity course) async {
    final courseModel = CourseModel(
      id: course.id,
      title: course.title,
      description: course.description,
      targetAudience: course.targetAudience,
      status: course.status,
    );
    final newCourseModel = await remoteDataSource.createCourse(courseModel);
    return newCourseModel;
  }

  @override
  Future<CourseEntity> updateCourse(CourseEntity course) async {
    final courseModel = CourseModel(
      id: course.id,
      title: course.title,
      description: course.description,
      targetAudience: course.targetAudience,
      status: course.status,
    );
    final updatedCourseModel = await remoteDataSource.updateCourse(courseModel);
    return updatedCourseModel;
  }

  @override
  Future<bool> updateCourseStatus(String courseId, String status) async {
    return await remoteDataSource.updateCourseStatus(courseId, status);
  }
}

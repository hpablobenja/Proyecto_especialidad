// lib/data/datasources/remote/course_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/crashlytics_service.dart';
import '../../models/course_model.dart';

abstract class CourseRemoteDataSource {
  Future<List<CourseModel>> getCourses();
  Future<CourseModel> createCourse(CourseModel course);
  Future<CourseModel> updateCourse(CourseModel course);
  Future<bool> updateCourseStatus(String courseId, String status);
  // Futuras implementaciones: editar, eliminar, buscar, etc.
}

class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  final FirebaseFirestore firestore;
  final CrashlyticsService _crashlyticsService;

  CourseRemoteDataSourceImpl(this.firestore, {CrashlyticsService? crashlyticsService})
      : _crashlyticsService = crashlyticsService ?? CrashlyticsService.instance;

  @override
  Future<List<CourseModel>> getCourses() async {
    try {
      await _crashlyticsService.logFirestoreEvent('GET_ALL', path: 'courses');
      final querySnapshot = await firestore.collection('courses').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return CourseModel(
          id: doc.id,
          title: (data['title'] ?? '') as String,
          description: (data['description'] ?? '') as String,
          targetAudience:
              (data['targetAudience'] ?? 'Ciencias Naturales') as String,
          status: (data['status'] ?? 'draft') as String,
        );
      }).toList();
    } catch (e, stack) {
      await _crashlyticsService.recordError(
        e,
        stack,
        reason: 'Error al obtener lista de cursos desde Firestore',
      );
      rethrow;
    }
  }

  @override
  Future<CourseModel> createCourse(CourseModel course) async {
    try {
      await _crashlyticsService.logFirestoreEvent('CREATE', path: 'courses', details: course.title);
      final docRef = firestore.collection('courses').doc();
      final newCourse = course.copyWith(id: docRef.id);
      await docRef.set(newCourse.toMap());
      return newCourse;
    } catch (e, stack) {
      await _crashlyticsService.recordError(
        e,
        stack,
        reason: 'Error al crear curso ${course.title} en Firestore',
      );
      rethrow;
    }
  }

  @override
  Future<CourseModel> updateCourse(CourseModel course) async {
    try {
      await _crashlyticsService.logFirestoreEvent('UPDATE', path: 'courses/${course.id}');
      await firestore.collection('courses').doc(course.id).update(course.toMap());
      return course;
    } catch (e, stack) {
      await _crashlyticsService.recordError(
        e,
        stack,
        reason: 'Error al actualizar curso ${course.id} en Firestore',
      );
      rethrow;
    }
  }

  @override
  Future<bool> updateCourseStatus(String courseId, String status) async {
    try {
      await _crashlyticsService.logFirestoreEvent(
        'UPDATE_STATUS',
        path: 'courses/$courseId',
        details: 'status: $status',
      );
      await firestore.collection('courses').doc(courseId).update({
        'status': status,
      });
      return true;
    } catch (e, stack) {
      await _crashlyticsService.recordError(
        e,
        stack,
        reason: 'Error al cambiar estado del curso $courseId a $status',
      );
      return false;
    }
  }
}

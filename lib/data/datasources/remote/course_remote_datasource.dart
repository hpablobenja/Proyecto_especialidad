// lib/data/datasources/remote/course_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/course_model.dart';

abstract class CourseRemoteDataSource {
  Future<List<CourseModel>> getCourses();
  Future<CourseModel> createCourse(CourseModel course);
  // Futuras implementaciones: editar, eliminar, buscar, etc.
}

class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  final FirebaseFirestore firestore;

  CourseRemoteDataSourceImpl(this.firestore);

  @override
  Future<List<CourseModel>> getCourses() async {
    final querySnapshot = await firestore.collection('courses').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return CourseModel(
        id: doc.id,
        title: (data['title'] ?? '') as String,
        description: (data['description'] ?? '') as String,
        targetAudience: (data['targetAudience'] ?? 'Inicial') as String,
      );
    }).toList();
  }

  @override
  Future<CourseModel> createCourse(CourseModel course) async {
    final docRef = firestore.collection('courses').doc();
    final newCourse = course.copyWith(id: docRef.id);
    await docRef.set(newCourse.toMap());
    return newCourse;
  }
}

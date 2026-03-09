// lib/data/datasources/remote/content_remote_datasource.dart

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../domain/entities/course_entity.dart';
import '../../../domain/entities/module_entity.dart';
import '../../../domain/entities/lesson_entity.dart';
import '../../../domain/entities/media_resource.dart';
import '../../../domain/entities/comment_entity.dart';

abstract class ContentRemoteDataSource {
  Future<List<CourseEntity>> listCourses();
  Future<CourseEntity> createCourse(CourseEntity course);
  Future<CourseEntity> updateCourse(CourseEntity course);
  Future<void> deleteCourse(String courseId);

  Future<List<ModuleEntity>> listModules(String courseId);
  Future<ModuleEntity> createModule(ModuleEntity module);
  Future<void> updateModule(ModuleEntity module);
  Future<void> deleteModule(String courseId, String moduleId);
  Future<void> reorderModules(String courseId, List<String> orderedModuleIds);

  Future<List<LessonEntity>> listLessons(String courseId, String moduleId);
  Future<LessonEntity> createLesson(LessonEntity lesson);
  Future<void> updateLesson(LessonEntity lesson);
  Future<void> deleteLesson(String courseId, String moduleId, String lessonId);
  Future<void> reorderLessons(String courseId, String moduleId, List<String> orderedLessonIds);

  Future<MediaResource> uploadMedia({
    required String courseId,
    required String? moduleId,
    required String? lessonId,
    required MediaUploadRequest request,
  });
  Future<void> deleteMedia({
    required String courseId,
    required String? moduleId,
    required String? lessonId,
    required String mediaId,
  });

  // Comments
  Future<List<CommentEntity>> listComments({
    required String courseId,
    required String moduleId,
    required String lessonId,
  });
  Future<CommentEntity> addComment(CommentEntity comment);
  Future<void> deleteComment({
    required String courseId,
    required String moduleId,
    required String lessonId,
    required String commentId,
  });
}

class ContentRemoteDataSourceImpl implements ContentRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  ContentRemoteDataSourceImpl(this.firestore, this.storage);

  CollectionReference<Map<String, dynamic>> get _coursesCol => firestore.collection('courses');
  CollectionReference<Map<String, dynamic>> _modulesCol(String courseId) =>
      _coursesCol.doc(courseId).collection('modules');
  CollectionReference<Map<String, dynamic>> get _rootLessonsCol =>
      firestore.collection('lecciones');
  CollectionReference<Map<String, dynamic>> _commentsCol(String courseId, String moduleId, String lessonId) =>
      _rootLessonsCol.doc(lessonId).collection('comments');

  Map<String, dynamic> _courseToMap(CourseEntity c) => {
        'title': c.title,
        'description': c.description,
        'targetAudience': c.targetAudience,
      };

  CourseEntity _courseFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return CourseEntity(
      id: doc.id,
      title: (d['title'] ?? '') as String,
      description: (d['description'] ?? '') as String,
      targetAudience: (d['targetAudience'] ?? 'Inicial') as String,
    );
  }

  Map<String, dynamic> _commentToMap(CommentEntity c) => {
        'courseId': c.courseId,
        'moduleId': c.moduleId,
        'lessonId': c.lessonId,
        'userId': c.userId,
        'userName': c.userName,
        'text': c.text,
        'createdAt': Timestamp.fromDate(c.createdAt),
        'updatedAt': c.updatedAt != null ? Timestamp.fromDate(c.updatedAt!) : null,
      };

  CommentEntity _commentFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return CommentEntity(
      id: doc.id,
      courseId: (d['courseId'] ?? '') as String,
      moduleId: (d['moduleId'] ?? '') as String,
      lessonId: (d['lessonId'] ?? '') as String,
      userId: (d['userId'] ?? '') as String,
      userName: (d['userName'] ?? '') as String,
      text: (d['text'] ?? '') as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> _moduleToMap(ModuleEntity m) => {
        'courseId': m.courseId,
        'title': m.title,
        'description': m.description,
        'orderIndex': m.orderIndex,
      };

  ModuleEntity _moduleFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ModuleEntity(
      id: doc.id,
      courseId: (d['courseId'] ?? '') as String,
      title: (d['title'] ?? '') as String,
      description: d['description'] as String?,
      orderIndex: (d['orderIndex'] ?? 0) as int,
    );
  }

  Map<String, dynamic> _mediaToMap(MediaResource m) => {
        'id': m.id,
        'url': m.url,
        'filename': m.filename,
        'mimeType': m.mimeType,
        'sizeBytes': m.sizeBytes,
        'durationSeconds': m.duration?.inSeconds,
        'metadata': m.metadata,
      };

  MediaResource _mediaFromMap(Map<String, dynamic> d) => MediaResource(
        id: (d['id'] ?? '') as String,
        url: (d['url'] ?? '') as String,
        filename: (d['filename'] ?? '') as String,
        mimeType: (d['mimeType'] ?? '') as String,
        sizeBytes: (d['sizeBytes'] ?? 0) as int,
        duration:
            d['durationSeconds'] != null ? Duration(seconds: (d['durationSeconds'] as num).toInt()) : null,
        metadata: (d['metadata'] as Map?)?.cast<String, dynamic>(),
      );

  Map<String, dynamic> _lessonToMap(LessonEntity l) => {
        'courseId': l.courseId,
        'moduleId': l.moduleId,
        'title': l.title,
        'contentDelta': l.contentDelta,
        'objectives': l.objectives,
        'media': l.media.map(_mediaToMap).toList(),
        'downloadableResources': l.downloadableResources.map(_mediaToMap).toList(),
        'strategies': l.strategies,
        'orderIndex': l.orderIndex,
        'dripUnlockAt': l.dripUnlockAt,
      };

  LessonEntity _lessonFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final mediaList = (d['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final resList = (d['downloadableResources'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final strategiesList = (d['strategies'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final strategies = strategiesList.map((s) => s.cast<String, String>()).toList();
    return LessonEntity(
      id: doc.id,
      courseId: (d['courseId'] ?? '') as String,
      moduleId: (d['moduleId'] ?? '') as String,
      title: (d['title'] ?? '') as String,
      contentDelta: (d['contentDelta'] as List?)?.cast<dynamic>(),
      objectives: d['objectives'] as String?,
      media: mediaList.map(_mediaFromMap).toList(),
      downloadableResources: resList.map(_mediaFromMap).toList(),
      strategies: strategies,
      orderIndex: (d['orderIndex'] ?? 0) as int,
      dripUnlockAt: (d['dripUnlockAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Future<CourseEntity> createCourse(CourseEntity course) async {
    final doc = await _coursesCol.add(_courseToMap(course));
    final snap = await doc.get();
    return _courseFromDoc(snap);
  }

  @override
  Future<List<ModuleEntity>> listModules(String courseId) async {
    final qs = await _modulesCol(courseId).orderBy('orderIndex').get();
    return qs.docs.map(_moduleFromDoc).toList();
  }

  @override
  Future<ModuleEntity> createModule(ModuleEntity module) async {
    final col = _modulesCol(module.courseId);
    final doc = await col.add(_moduleToMap(module));
    final snap = await doc.get();
    return _moduleFromDoc(snap);
  }

  @override
  Future<LessonEntity> createLesson(LessonEntity lesson) async {
    final doc = await _rootLessonsCol.add(_lessonToMap(lesson));
    final snap = await doc.get();
    return _lessonFromDoc(snap);
  }

  @override
  Future<List<LessonEntity>> listLessons(String courseId, String moduleId) async {
    final qs = await _rootLessonsCol
        .where('courseId', isEqualTo: courseId)
        .where('moduleId', isEqualTo: moduleId)
        .get();
    final list = qs.docs.map(_lessonFromDoc).toList();
    list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  @override
  Future<void> deleteCourse(String courseId) async {
    await _coursesCol.doc(courseId).delete();
    // TODO: Consider cascading delete of modules/lessons (requires recursive deletion)
  }

  @override
  Future<void> deleteLesson(String courseId, String moduleId, String lessonId) async {
    await _rootLessonsCol.doc(lessonId).delete();
  }

  @override
  Future<void> deleteMedia({
    required String courseId,
    required String? moduleId,
    required String? lessonId,
    required String mediaId,
  }) async {
    // mediaId is the full storage path assigned on upload
    await storage.ref(mediaId).delete();
  }

  @override
  Future<void> deleteModule(String courseId, String moduleId) async {
    await _modulesCol(courseId).doc(moduleId).delete();
  }

  @override
  Future<List<CourseEntity>> listCourses() async {
    final qs = await _coursesCol.orderBy('title').get();
    return qs.docs.map(_courseFromDoc).toList();
  }

  @override
  Future<void> reorderLessons(String courseId, String moduleId, List<String> orderedLessonIds) async {
    final batch = firestore.batch();
    for (var i = 0; i < orderedLessonIds.length; i++) {
      final id = orderedLessonIds[i];
      final ref = _rootLessonsCol.doc(id);
      batch.update(ref, {'orderIndex': i});
    }
    await batch.commit();
  }

  @override
  Future<void> reorderModules(String courseId, List<String> orderedModuleIds) async {
    final batch = firestore.batch();
    for (var i = 0; i < orderedModuleIds.length; i++) {
      final id = orderedModuleIds[i];
      final ref = _modulesCol(courseId).doc(id);
      batch.update(ref, {'orderIndex': i});
    }
    await batch.commit();
  }

  @override
  Future<CourseEntity> updateCourse(CourseEntity course) async {
    await _coursesCol.doc(course.id).update(_courseToMap(course));
    final snap = await _coursesCol.doc(course.id).get();
    return _courseFromDoc(snap);
  }

  @override
  Future<void> updateLesson(LessonEntity lesson) async {
    await _rootLessonsCol.doc(lesson.id).update(_lessonToMap(lesson));
  }

  @override
  Future<void> updateModule(ModuleEntity module) async {
    await _modulesCol(module.courseId).doc(module.id).update(_moduleToMap(module));
  }

  @override
  Future<MediaResource> uploadMedia({
    required String courseId,
    required String? moduleId,
    required String? lessonId,
    required MediaUploadRequest request,
  }) async {
    final safeModule = moduleId ?? '_root';
    final safeLesson = lessonId ?? '_root';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${request.filename}';
    final path = 'content/$courseId/$safeModule/$safeLesson/$fileName';
    final ref = storage.ref(path);
    final meta = SettableMetadata(contentType: request.mimeType);
    final task = await ref.putData(
      Uint8List.fromList(request.bytes),
      meta,
    );
    final url = await task.ref.getDownloadURL();
    return MediaResource(
      id: path, // use storage path as id for easier deletion
      url: url,
      filename: request.filename,
      mimeType: request.mimeType,
      sizeBytes: request.bytes.length,
    );
  }

  // ---------------- Comments ----------------
  @override
  Future<List<CommentEntity>> listComments({
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    final qs = await _commentsCol(courseId, moduleId, lessonId)
        .orderBy('createdAt', descending: true)
        .get();
    return qs.docs.map(_commentFromDoc).toList();
  }

  @override
  Future<CommentEntity> addComment(CommentEntity comment) async {
    final text = comment.text.trim();
    if (text.isEmpty || text.length > 500) {
      throw ArgumentError('El comentario debe tener entre 1 y 500 caracteres');
    }
    final now = DateTime.now();
    final toStore = CommentEntity(
      id: '',
      courseId: comment.courseId,
      moduleId: comment.moduleId,
      lessonId: comment.lessonId,
      userId: comment.userId,
      userName: comment.userName,
      text: text,
      createdAt: comment.createdAt,
      updatedAt: now,
    );
    final data = _commentToMap(toStore);
    final col = _commentsCol(comment.courseId, comment.moduleId, comment.lessonId);
    final doc = await col.add(data);
    final snap = await doc.get();
    return _commentFromDoc(snap);
  }

  @override
  Future<void> deleteComment({
    required String courseId,
    required String moduleId,
    required String lessonId,
    required String commentId,
  }) async {
    await _commentsCol(courseId, moduleId, lessonId).doc(commentId).delete();
  }
}

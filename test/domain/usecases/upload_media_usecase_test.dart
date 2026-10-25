import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/domain/entities/course_entity.dart';
import 'package:redmaestra1/domain/entities/module_entity.dart';
import 'package:redmaestra1/domain/entities/lesson_entity.dart';
import 'package:redmaestra1/domain/entities/media_resource.dart';
import 'package:redmaestra1/domain/entities/comment_entity.dart';
import 'package:redmaestra1/domain/repositories/content_repository.dart';
import 'package:redmaestra1/domain/usecases/content/upload_media_usecase.dart';

class MockContentRepository implements ContentRepository {
  MediaResource? mediaToReturn;
  Exception? errorToThrow;
  String? lastCourseId;
  String? lastModuleId;
  String? lastLessonId;
  MediaUploadRequest? lastRequest;

  @override
  Future<List<CourseEntity>> listCourses() async => [];

  @override
  Future<CourseEntity> createCourse(CourseEntity course) async => course;

  @override
  Future<CourseEntity> updateCourse(CourseEntity course) async => course;

  @override
  Future<void> deleteCourse(String courseId) async {}

  @override
  Future<List<ModuleEntity>> listModules(String courseId) async => [];

  @override
  Future<ModuleEntity> createModule(ModuleEntity module) async => module;

  @override
  Future<void> updateModule(ModuleEntity module) async {}

  @override
  Future<void> deleteModule(String courseId, String moduleId) async {}

  @override
  Future<void> reorderModules(String courseId, List<String> orderedModuleIds) async {}

  @override
  Future<List<LessonEntity>> listLessons(String courseId, String moduleId) async => [];

  @override
  Future<LessonEntity> createLesson(LessonEntity lesson) async => lesson;

  @override
  Future<void> updateLesson(LessonEntity lesson) async {}

  @override
  Future<void> deleteLesson(String courseId, String moduleId, String lessonId) async {}

  @override
  Future<void> reorderLessons(String courseId, String moduleId, List<String> orderedLessonIds) async {}

  @override
  Future<MediaResource> uploadMedia({required String courseId, required String? moduleId, required String? lessonId, required MediaUploadRequest request}) async {
    lastCourseId = courseId;
    lastModuleId = moduleId;
    lastLessonId = lessonId;
    lastRequest = request;
    
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return mediaToReturn ?? MediaResource(
      id: 'media_1',
      url: 'https://example.com/file',
      filename: request.filename,
      mimeType: request.mimeType,
      sizeBytes: request.bytes.length,
    );
  }

  @override
  Future<void> deleteMedia({required String courseId, required String? moduleId, required String? lessonId, required String mediaId}) async {}

  @override
  Future<List<CommentEntity>> listComments({required String courseId, required String moduleId, required String lessonId}) async => [];

  @override
  Future<CommentEntity> addComment(CommentEntity comment) async => comment;

  @override
  Future<void> deleteComment({required String courseId, required String moduleId, required String lessonId, required String commentId}) async {}
}

void main() {
  group('UploadMediaUsecase Tests', () {
    late UploadMediaUsecase usecase;
    late MockContentRepository mockRepository;

    setUp(() {
      mockRepository = MockContentRepository();
      usecase = UploadMediaUsecase(mockRepository);
    });

    test('UploadMediaUsecase calls repository with correct courseId', () async {
      final params = UploadMediaParams(
        courseId: 'course_1',
        request: MediaUploadRequest(
          filename: 'test.pdf',
          mimeType: 'application/pdf',
          bytes: [1, 2, 3],
        ),
      );

      await usecase(params);

      expect(mockRepository.lastCourseId, 'course_1');
    });

    test('UploadMediaUsecase calls repository with correct moduleId', () async {
      final params = UploadMediaParams(
        courseId: 'course_1',
        moduleId: 'module_1',
        request: MediaUploadRequest(
          filename: 'test.pdf',
          mimeType: 'application/pdf',
          bytes: [1, 2, 3],
        ),
      );

      await usecase(params);

      expect(mockRepository.lastModuleId, 'module_1');
    });

    test('UploadMediaUsecase calls repository with correct lessonId', () async {
      final params = UploadMediaParams(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        request: MediaUploadRequest(
          filename: 'test.pdf',
          mimeType: 'application/pdf',
          bytes: [1, 2, 3],
        ),
      );

      await usecase(params);

      expect(mockRepository.lastLessonId, 'lesson_1');
    });

    test('UploadMediaUsecase calls repository with correct request', () async {
      final request = MediaUploadRequest(
        filename: 'test.pdf',
        mimeType: 'application/pdf',
        bytes: [1, 2, 3],
      );
      final params = UploadMediaParams(
        courseId: 'course_1',
        request: request,
      );

      await usecase(params);

      expect(mockRepository.lastRequest?.filename, 'test.pdf');
      expect(mockRepository.lastRequest?.mimeType, 'application/pdf');
      expect(mockRepository.lastRequest?.bytes, [1, 2, 3]);
    });

    test('UploadMediaUsecase returns media from repository', () async {
      final testMedia = MediaResource(
        id: 'media_123',
        url: 'https://example.com/file.pdf',
        filename: 'test.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 1024,
      );
      mockRepository.mediaToReturn = testMedia;
      final params = UploadMediaParams(
        courseId: 'course_1',
        request: MediaUploadRequest(
          filename: 'test.pdf',
          mimeType: 'application/pdf',
          bytes: [1, 2, 3],
        ),
      );

      final result = await usecase(params);

      expect(result.id, 'media_123');
      expect(result.url, 'https://example.com/file.pdf');
    });

    test('UploadMediaUsecase throws exception when repository throws', () async {
      mockRepository.errorToThrow = Exception('Upload failed');
      final params = UploadMediaParams(
        courseId: 'course_1',
        request: MediaUploadRequest(
          filename: 'test.pdf',
          mimeType: 'application/pdf',
          bytes: [1, 2, 3],
        ),
      );

      expect(() => usecase(params), throwsException);
    });

    test('UploadMediaUsecase handles null moduleId', () async {
      final params = UploadMediaParams(
        courseId: 'course_1',
        request: MediaUploadRequest(
          filename: 'test.pdf',
          mimeType: 'application/pdf',
          bytes: [1, 2, 3],
        ),
      );

      await usecase(params);

      expect(mockRepository.lastModuleId, null);
    });

    test('UploadMediaUsecase handles null lessonId', () async {
      final params = UploadMediaParams(
        courseId: 'course_1',
        moduleId: 'module_1',
        request: MediaUploadRequest(
          filename: 'test.pdf',
          mimeType: 'application/pdf',
          bytes: [1, 2, 3],
        ),
      );

      await usecase(params);

      expect(mockRepository.lastLessonId, null);
    });

    test('UploadMediaUsecase handles different mime types', () async {
      final params = UploadMediaParams(
        courseId: 'course_1',
        request: MediaUploadRequest(
          filename: 'video.mp4',
          mimeType: 'video/mp4',
          bytes: [1, 2, 3],
        ),
      );

      await usecase(params);

      expect(mockRepository.lastRequest?.mimeType, 'video/mp4');
    });

    test('UploadMediaParams creates correctly', () {
      final request = MediaUploadRequest(
        filename: 'test.pdf',
        mimeType: 'application/pdf',
        bytes: [1, 2, 3],
      );
      final params = UploadMediaParams(
        courseId: 'course_1',
        moduleId: 'module_1',
        lessonId: 'lesson_1',
        request: request,
      );

      expect(params.courseId, 'course_1');
      expect(params.moduleId, 'module_1');
      expect(params.lessonId, 'lesson_1');
      expect(params.request, request);
    });

    test('UploadMediaParams with null optional fields', () {
      final request = MediaUploadRequest(
        filename: 'test.pdf',
        mimeType: 'application/pdf',
        bytes: [1, 2, 3],
      );
      final params = UploadMediaParams(
        courseId: 'course_1',
        request: request,
      );

      expect(params.moduleId, null);
      expect(params.lessonId, null);
    });
  });
}

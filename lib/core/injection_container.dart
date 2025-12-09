// lib/core/injection_container.dart

import 'package:get_it/get_it.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../data/datasources/remote/auth_remote_datasource.dart';
import '../data/datasources/remote/course_remote_datasource.dart';
import '../data/datasources/remote/content_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/course_repository_impl.dart';
import '../data/repositories/content_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/course_repository.dart';
import '../domain/repositories/content_repository.dart';
import '../domain/usecases/auth/login_usecase.dart';
import '../domain/usecases/auth/register_usecase.dart';
import '../domain/usecases/auth/get_current_user_usecase.dart';
import '../domain/usecases/auth/update_user_usecase.dart';
import '../domain/usecases/courses/get_courses_usecase.dart';
import '../domain/usecases/courses/create_course_usecase.dart';
import '../domain/usecases/courses/get_course_progress_usecase.dart';
import '../domain/usecases/reports/generate_pdf_report_usecase.dart';
import '../domain/usecases/reports/generate_all_users_report_usecase.dart';
import '../domain/usecases/content/list_courses_usecase.dart' as content_list;
import '../domain/usecases/content/list_modules_usecase.dart' as content_list_modules;
import '../domain/usecases/content/list_lessons_usecase.dart' as content_list_lessons;
import '../domain/usecases/content/create_course_usecase.dart' as content_create;
import '../domain/usecases/content/update_course_usecase.dart' as content_update;
import '../domain/usecases/content/delete_course_usecase.dart' as content_delete_course;
import '../domain/usecases/content/create_module_usecase.dart' as content_create_module;
import '../domain/usecases/content/update_module_usecase.dart' as content_update_module;
import '../domain/usecases/content/delete_module_usecase.dart' as content_delete_module;
import '../domain/usecases/content/reorder_modules_usecase.dart' as content_reorder_modules;
import '../domain/usecases/content/create_lesson_usecase.dart' as content_create_lesson;
import '../domain/usecases/content/update_lesson_usecase.dart' as content_update_lesson;
import '../domain/usecases/content/delete_lesson_usecase.dart' as content_delete_lesson;
import '../domain/usecases/content/reorder_lessons_usecase.dart' as content_reorder_lessons;
import '../domain/usecases/content/upload_media_usecase.dart' as content_upload_media;
import '../domain/usecases/content/delete_media_usecase.dart' as content_delete_media;
import '../domain/usecases/content/list_comments_usecase.dart' as content_list_comments;
import '../domain/usecases/content/add_comment_usecase.dart' as content_add_comment;
import '../domain/usecases/content/delete_comment_usecase.dart' as content_delete_comment;
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/course_provider.dart';
import '../presentation/providers/progress_provider.dart';
import '../presentation/providers/content_provider.dart';
import '../presentation/providers/admin_content_provider.dart';
import '../presentation/providers/comments_provider.dart';

// sl = Service Locator
final sl = GetIt.instance;

void init() {
  // ----------------------- External Libraries -----------------------
  // Registra las instancias de las bibliotecas externas (Firebase)
  // Se registran primero ya que son dependencias de las capas de datos.
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  // Inicializa las dependencias por funcionalidad para mayor modularidad.
  _initAuth();
  _initCourses();
  _initContent();
}

void _initAuth() {
  // Provider
  sl.registerFactory<AuthProvider>(
    () => AuthProvider(
      loginUsecase: sl<LoginUsecase>(),
      registerUsecase: sl<RegisterUsecase>(),
      getCurrentUserUsecase: sl<GetCurrentUserUsecase>(),
      updateUserUsecase: sl<UpdateUserUsecase>(),
    ),
  );

  // Comments provider
  sl.registerFactory<CommentsProvider>(
    () => CommentsProvider(
      listCommentsUsecase: sl<content_list_comments.ListCommentsUsecase>(),
      addCommentUsecase: sl<content_add_comment.AddCommentUsecase>(),
      deleteCommentUsecase: sl<content_delete_comment.DeleteCommentUsecase>(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton<LoginUsecase>(
    () => LoginUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<RegisterUsecase>(
    () => RegisterUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetCurrentUserUsecase>(
    () => GetCurrentUserUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<UpdateUserUsecase>(
    () => UpdateUserUsecase(sl<AuthRepository>()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
  );

  // Data Source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<FirebaseAuth>(), sl<FirebaseFirestore>()),
  );
}

void _initCourses() {
  // Provider
  sl.registerFactory<CourseProvider>(
    () => CourseProvider(
      getCoursesUsecase: sl<GetCoursesUsecase>(),
      createCourseUsecase: sl<CreateCourseUsecase>(),
    ),
  );
  sl.registerFactory<ProgressProvider>(
    () => ProgressProvider(
      getCourseProgressUsecase: sl<GetCourseProgressUsecase>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );

  // Use Case
  sl.registerLazySingleton<GetCoursesUsecase>(
    () => GetCoursesUsecase(sl<CourseRepository>()),
  );
  sl.registerLazySingleton<CreateCourseUsecase>(
    () => CreateCourseUsecase(sl<CourseRepository>()),
  );
  sl.registerLazySingleton<GetCourseProgressUsecase>(
    () => GetCourseProgressUsecase(sl<CourseRepository>()),
  );
  sl.registerLazySingleton<GeneratePdfReportUsecase>(
    () => GeneratePdfReportUsecase(sl<CourseRepository>(), firestore: sl<FirebaseFirestore>()),
  );

  sl.registerLazySingleton<GenerateAllUsersReportUsecase>(
    () => GenerateAllUsersReportUsecase(sl<CourseRepository>(), firestore: sl<FirebaseFirestore>()),
  );

  // Repository
  sl.registerLazySingleton<CourseRepository>(
    () => CourseRepositoryImpl(sl<CourseRemoteDataSource>()),
  );

  // Data Source
  sl.registerLazySingleton<CourseRemoteDataSource>(
    () => CourseRemoteDataSourceImpl(sl<FirebaseFirestore>()),
  );
}

void _initContent() {
  // Provider (gestiona contenido CRUD y listados desde capa content)
  sl.registerFactory<ContentProvider>(
    () => ContentProvider(
      listCoursesUsecase: sl<content_list.ListCoursesUsecase>(),
      createCourseUsecase: sl<content_create.CreateCourseUsecase>(),
      updateCourseUsecase: sl<content_update.UpdateCourseUsecase>(),
      deleteCourseUsecase: sl<content_delete_course.DeleteCourseUsecase>(),
    ),
  );

  // Admin content provider (gestiona módulos, lecciones y media)
  sl.registerFactory<AdminContentProvider>(
    () => AdminContentProvider(
      listModulesUsecase: sl<content_list_modules.ListModulesUsecase>(),
      listLessonsUsecase: sl<content_list_lessons.ListLessonsUsecase>(),
      createModuleUsecase: sl<content_create_module.CreateModuleUsecase>(),
      updateModuleUsecase: sl<content_update_module.UpdateModuleUsecase>(),
      deleteModuleUsecase: sl<content_delete_module.DeleteModuleUsecase>(),
      reorderModulesUsecase: sl<content_reorder_modules.ReorderModulesUsecase>(),
      createLessonUsecase: sl<content_create_lesson.CreateLessonUsecase>(),
      updateLessonUsecase: sl<content_update_lesson.UpdateLessonUsecase>(),
      deleteLessonUsecase: sl<content_delete_lesson.DeleteLessonUsecase>(),
      reorderLessonsUsecase: sl<content_reorder_lessons.ReorderLessonsUsecase>(),
      uploadMediaUsecase: sl<content_upload_media.UploadMediaUsecase>(),
      deleteMediaUsecase: sl<content_delete_media.DeleteMediaUsecase>(),
    ),
  );

  // Use Cases (content)
  sl.registerLazySingleton<content_list.ListCoursesUsecase>(
    () => content_list.ListCoursesUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_create.CreateCourseUsecase>(
    () => content_create.CreateCourseUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_update.UpdateCourseUsecase>(
    () => content_update.UpdateCourseUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_list_modules.ListModulesUsecase>(
    () => content_list_modules.ListModulesUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_list_lessons.ListLessonsUsecase>(
    () => content_list_lessons.ListLessonsUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_delete_course.DeleteCourseUsecase>(
    () => content_delete_course.DeleteCourseUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_create_module.CreateModuleUsecase>(
    () => content_create_module.CreateModuleUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_update_module.UpdateModuleUsecase>(
    () => content_update_module.UpdateModuleUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_delete_module.DeleteModuleUsecase>(
    () => content_delete_module.DeleteModuleUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_reorder_modules.ReorderModulesUsecase>(
    () => content_reorder_modules.ReorderModulesUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_create_lesson.CreateLessonUsecase>(
    () => content_create_lesson.CreateLessonUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_update_lesson.UpdateLessonUsecase>(
    () => content_update_lesson.UpdateLessonUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_delete_lesson.DeleteLessonUsecase>(
    () => content_delete_lesson.DeleteLessonUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_reorder_lessons.ReorderLessonsUsecase>(
    () => content_reorder_lessons.ReorderLessonsUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_upload_media.UploadMediaUsecase>(
    () => content_upload_media.UploadMediaUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_delete_media.DeleteMediaUsecase>(
    () => content_delete_media.DeleteMediaUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_list_comments.ListCommentsUsecase>(
    () => content_list_comments.ListCommentsUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_add_comment.AddCommentUsecase>(
    () => content_add_comment.AddCommentUsecase(sl<ContentRepository>()),
  );
  sl.registerLazySingleton<content_delete_comment.DeleteCommentUsecase>(
    () => content_delete_comment.DeleteCommentUsecase(sl<ContentRepository>()),
  );

  // Repository
  sl.registerLazySingleton<ContentRepository>(
    () => ContentRepositoryImpl(sl<ContentRemoteDataSource>()),
  );

  // Data Source
  sl.registerLazySingleton<ContentRemoteDataSource>(
    () => ContentRemoteDataSourceImpl(sl<FirebaseFirestore>(), sl<FirebaseStorage>()),
  );
}


// lib/core/di/riverpod_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Data Sources
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/course_remote_datasource.dart';
import '../../data/datasources/remote/content_remote_datasource.dart';

// Repositories
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/course_repository.dart';
import '../../domain/repositories/content_repository.dart';

// Use Cases
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../domain/usecases/auth/update_user_usecase.dart';
import '../../domain/usecases/auth/reset_password_usecase.dart';
import '../../domain/usecases/courses/get_courses_usecase.dart';
import '../../domain/usecases/courses/create_course_usecase.dart';
import '../../domain/usecases/courses/get_course_progress_usecase.dart';
import '../../domain/usecases/reports/generate_pdf_report_usecase.dart';
import '../../domain/usecases/reports/generate_all_users_report_usecase.dart';
import '../../domain/usecases/content/list_courses_usecase.dart'
    as content_list;
import '../../domain/usecases/content/list_modules_usecase.dart'
    as content_list_modules;
import '../../domain/usecases/content/list_lessons_usecase.dart'
    as content_list_lessons;
import '../../domain/usecases/content/create_course_usecase.dart'
    as content_create;
import '../../domain/usecases/content/update_course_usecase.dart'
    as content_update;
import '../../domain/usecases/content/delete_course_usecase.dart'
    as content_delete_course;
import '../../domain/usecases/content/create_module_usecase.dart'
    as content_create_module;
import '../../domain/usecases/content/update_module_usecase.dart'
    as content_update_module;
import '../../domain/usecases/content/delete_module_usecase.dart'
    as content_delete_module;
import '../../domain/usecases/content/reorder_modules_usecase.dart'
    as content_reorder_modules;
import '../../domain/usecases/content/create_lesson_usecase.dart'
    as content_create_lesson;
import '../../domain/usecases/content/update_lesson_usecase.dart'
    as content_update_lesson;
import '../../domain/usecases/content/delete_lesson_usecase.dart'
    as content_delete_lesson;
import '../../domain/usecases/content/reorder_lessons_usecase.dart'
    as content_reorder_lessons;
import '../../domain/usecases/content/upload_media_usecase.dart'
    as content_upload_media;
import '../../domain/usecases/content/delete_media_usecase.dart'
    as content_delete_media;
import '../../domain/usecases/content/list_comments_usecase.dart'
    as content_list_comments;
import '../../domain/usecases/content/add_comment_usecase.dart'
    as content_add_comment;
import '../../domain/usecases/content/delete_comment_usecase.dart'
    as content_delete_comment;

// Presentation Providers
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/course_provider.dart';
import '../../presentation/providers/progress_provider.dart';
import '../../presentation/providers/content_provider.dart';
import '../../presentation/providers/admin_content_provider.dart';
import '../../presentation/providers/comments_provider.dart';
import '../../presentation/providers/theme_provider.dart';
import '../../presentation/providers/dashboard_provider.dart';
import '../../presentation/providers/connectivity_provider.dart';
import '../../core/services/pdf_generator_service.dart';
import '../../core/services/offline_cache_service.dart';

// ----------------------- External Libraries Providers -----------------------
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

// ----------------------- App Services Providers -----------------------
final pdfGeneratorServiceProvider = Provider<PdfGeneratorService>((ref) {
  return PdfGeneratorService();
});

final offlineCacheServiceProvider = Provider<OfflineCacheService>((ref) {
  return OfflineCacheService();
});

// ----------------------- Data Sources Providers -----------------------
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

final courseRemoteDataSourceProvider = Provider<CourseRemoteDataSource>((ref) {
  return CourseRemoteDataSourceImpl(ref.watch(firestoreProvider));
});

final contentRemoteDataSourceProvider = Provider<ContentRemoteDataSource>((
  ref,
) {
  return ContentRemoteDataSourceImpl(
    ref.watch(firestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

// ----------------------- Repositories Providers -----------------------
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepositoryImpl(ref.watch(courseRemoteDataSourceProvider));
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepositoryImpl(ref.watch(contentRemoteDataSourceProvider));
});

// ----------------------- Use Cases Providers -----------------------

// Auth Use Cases
final loginUsecaseProvider = Provider<LoginUsecase>((ref) {
  return LoginUsecase(ref.watch(authRepositoryProvider));
});

final registerUsecaseProvider = Provider<RegisterUsecase>((ref) {
  return RegisterUsecase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUsecaseProvider = Provider<GetCurrentUserUsecase>((ref) {
  return GetCurrentUserUsecase(ref.watch(authRepositoryProvider));
});

final updateUserUsecaseProvider = Provider<UpdateUserUsecase>((ref) {
  return UpdateUserUsecase(ref.watch(authRepositoryProvider));
});

final resetPasswordUsecaseProvider = Provider<ResetPasswordUsecase>((ref) {
  return ResetPasswordUsecase(ref.watch(authRepositoryProvider));
});

// Course Use Cases
final getCoursesUsecaseProvider = Provider<GetCoursesUsecase>((ref) {
  return GetCoursesUsecase(ref.watch(courseRepositoryProvider));
});

final createCourseUsecaseProvider = Provider<CreateCourseUsecase>((ref) {
  return CreateCourseUsecase(ref.watch(courseRepositoryProvider));
});

final getCourseProgressUsecaseProvider = Provider<GetCourseProgressUsecase>((
  ref,
) {
  return GetCourseProgressUsecase(ref.watch(courseRepositoryProvider));
});

final generatePdfReportUsecaseProvider = Provider<GeneratePdfReportUsecase>((
  ref,
) {
  return GeneratePdfReportUsecase(
    ref.watch(courseRepositoryProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final generateAllUsersReportUsecaseProvider =
    Provider<GenerateAllUsersReportUsecase>((ref) {
      return GenerateAllUsersReportUsecase(
        ref.watch(courseRepositoryProvider),
        firestore: ref.watch(firestoreProvider),
      );
    });

// Content Use Cases
final listCoursesUsecaseProvider = Provider<content_list.ListCoursesUsecase>((
  ref,
) {
  return content_list.ListCoursesUsecase(ref.watch(contentRepositoryProvider));
});

final createContentCourseUsecaseProvider =
    Provider<content_create.CreateCourseUsecase>((ref) {
      return content_create.CreateCourseUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final updateCourseUsecaseProvider =
    Provider<content_update.UpdateCourseUsecase>((ref) {
      return content_update.UpdateCourseUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final deleteCourseUsecaseProvider =
    Provider<content_delete_course.DeleteCourseUsecase>((ref) {
      return content_delete_course.DeleteCourseUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final listModulesUsecaseProvider =
    Provider<content_list_modules.ListModulesUsecase>((ref) {
      return content_list_modules.ListModulesUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final listLessonsUsecaseProvider =
    Provider<content_list_lessons.ListLessonsUsecase>((ref) {
      return content_list_lessons.ListLessonsUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final createModuleUsecaseProvider =
    Provider<content_create_module.CreateModuleUsecase>((ref) {
      return content_create_module.CreateModuleUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final updateModuleUsecaseProvider =
    Provider<content_update_module.UpdateModuleUsecase>((ref) {
      return content_update_module.UpdateModuleUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final deleteModuleUsecaseProvider =
    Provider<content_delete_module.DeleteModuleUsecase>((ref) {
      return content_delete_module.DeleteModuleUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final reorderModulesUsecaseProvider =
    Provider<content_reorder_modules.ReorderModulesUsecase>((ref) {
      return content_reorder_modules.ReorderModulesUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final createLessonUsecaseProvider =
    Provider<content_create_lesson.CreateLessonUsecase>((ref) {
      return content_create_lesson.CreateLessonUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final updateLessonUsecaseProvider =
    Provider<content_update_lesson.UpdateLessonUsecase>((ref) {
      return content_update_lesson.UpdateLessonUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final deleteLessonUsecaseProvider =
    Provider<content_delete_lesson.DeleteLessonUsecase>((ref) {
      return content_delete_lesson.DeleteLessonUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final reorderLessonsUsecaseProvider =
    Provider<content_reorder_lessons.ReorderLessonsUsecase>((ref) {
      return content_reorder_lessons.ReorderLessonsUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final uploadMediaUsecaseProvider =
    Provider<content_upload_media.UploadMediaUsecase>((ref) {
      return content_upload_media.UploadMediaUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final deleteMediaUsecaseProvider =
    Provider<content_delete_media.DeleteMediaUsecase>((ref) {
      return content_delete_media.DeleteMediaUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final listCommentsUsecaseProvider =
    Provider<content_list_comments.ListCommentsUsecase>((ref) {
      return content_list_comments.ListCommentsUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final addCommentUsecaseProvider =
    Provider<content_add_comment.AddCommentUsecase>((ref) {
      return content_add_comment.AddCommentUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

final deleteCommentUsecaseProvider =
    Provider<content_delete_comment.DeleteCommentUsecase>((ref) {
      return content_delete_comment.DeleteCommentUsecase(
        ref.watch(contentRepositoryProvider),
      );
    });

// ----------------------- ChangeNotifier Providers -----------------------

final authStateProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  ref.keepAlive();
  return AuthProvider(
    loginUsecase: ref.read(loginUsecaseProvider),
    registerUsecase: ref.read(registerUsecaseProvider),
    getCurrentUserUsecase: ref.read(getCurrentUserUsecaseProvider),
    updateUserUsecase: ref.read(updateUserUsecaseProvider),
    resetPasswordUsecase: ref.read(resetPasswordUsecaseProvider),
  );
});

final commentsStateProvider = ChangeNotifierProvider<CommentsProvider>((ref) {
  ref.keepAlive();
  return CommentsProvider(
    listCommentsUsecase: ref.read(listCommentsUsecaseProvider),
    addCommentUsecase: ref.read(addCommentUsecaseProvider),
    deleteCommentUsecase: ref.read(deleteCommentUsecaseProvider),
  );
});

final courseStateProvider = ChangeNotifierProvider<CourseProvider>((ref) {
  ref.keepAlive();
  return CourseProvider(
    getCoursesUsecase: ref.read(getCoursesUsecaseProvider),
    createCourseUsecase: ref.read(createCourseUsecaseProvider),
  );
});

final progressStateProvider = ChangeNotifierProvider<ProgressProvider>((ref) {
  ref.keepAlive();
  return ProgressProvider(
    getCourseProgressUsecase: ref.read(getCourseProgressUsecaseProvider),
    firestore: ref.read(firestoreProvider),
  );
});

final contentStateProvider = ChangeNotifierProvider<ContentProvider>((ref) {
  ref.keepAlive();
  return ContentProvider(
    listCoursesUsecase: ref.read(listCoursesUsecaseProvider),
    createCourseUsecase: ref.read(createContentCourseUsecaseProvider),
    updateCourseUsecase: ref.read(updateCourseUsecaseProvider),
    deleteCourseUsecase: ref.read(deleteCourseUsecaseProvider),
  );
});

final adminContentStateProvider = ChangeNotifierProvider<AdminContentProvider>((
  ref,
) {
  ref.keepAlive();
  return AdminContentProvider(
    listModulesUsecase: ref.read(listModulesUsecaseProvider),
    listLessonsUsecase: ref.read(listLessonsUsecaseProvider),
    createModuleUsecase: ref.read(createModuleUsecaseProvider),
    updateModuleUsecase: ref.read(updateModuleUsecaseProvider),
    deleteModuleUsecase: ref.read(deleteModuleUsecaseProvider),
    reorderModulesUsecase: ref.read(reorderModulesUsecaseProvider),
    createLessonUsecase: ref.read(createLessonUsecaseProvider),
    updateLessonUsecase: ref.read(updateLessonUsecaseProvider),
    deleteLessonUsecase: ref.read(deleteLessonUsecaseProvider),
    reorderLessonsUsecase: ref.read(reorderLessonsUsecaseProvider),
    uploadMediaUsecase: ref.read(uploadMediaUsecaseProvider),
    deleteMediaUsecase: ref.read(deleteMediaUsecaseProvider),
  );
});

final themeStateProvider = ChangeNotifierProvider<ThemeProvider>((ref) {
  ref.keepAlive();
  return ThemeProvider();
});

final favoritesStateProvider = ChangeNotifierProvider<FavoritesProvider>((ref) {
  ref.keepAlive();
  return FavoritesProvider()..load();
});

final connectivityStateProvider = ChangeNotifierProvider<ConnectivityProvider>((
  ref,
) {
  ref.keepAlive();
  return ConnectivityProvider();
});

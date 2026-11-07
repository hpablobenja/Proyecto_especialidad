// lib/presentation/providers/admin_content_provider.dart

import 'package:flutter/material.dart';

import '../../domain/entities/module_entity.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/media_resource.dart';
import '../../domain/usecases/content/list_modules_usecase.dart'
    as uc_list_modules;
import '../../domain/usecases/content/list_lessons_usecase.dart'
    as uc_list_lessons;
import '../../domain/usecases/content/create_module_usecase.dart'
    as uc_create_module;
import '../../domain/usecases/content/update_module_usecase.dart'
    as uc_update_module;
import '../../domain/usecases/content/delete_module_usecase.dart'
    as uc_delete_module;
import '../../domain/usecases/content/reorder_modules_usecase.dart'
    as uc_reorder_modules;
import '../../domain/usecases/content/create_lesson_usecase.dart'
    as uc_create_lesson;
import '../../domain/usecases/content/update_lesson_usecase.dart'
    as uc_update_lesson;
import '../../domain/usecases/content/delete_lesson_usecase.dart'
    as uc_delete_lesson;
import '../../domain/usecases/content/reorder_lessons_usecase.dart'
    as uc_reorder_lessons;
import '../../domain/usecases/content/upload_media_usecase.dart'
    as uc_upload_media;
import '../../domain/usecases/content/delete_media_usecase.dart'
    as uc_delete_media;

class AdminContentProvider extends ChangeNotifier {
  final uc_list_modules.ListModulesUsecase listModulesUsecase;
  final uc_list_lessons.ListLessonsUsecase listLessonsUsecase;
  final uc_create_module.CreateModuleUsecase createModuleUsecase;
  final uc_update_module.UpdateModuleUsecase updateModuleUsecase;
  final uc_delete_module.DeleteModuleUsecase deleteModuleUsecase;
  final uc_reorder_modules.ReorderModulesUsecase reorderModulesUsecase;

  final uc_create_lesson.CreateLessonUsecase createLessonUsecase;
  final uc_update_lesson.UpdateLessonUsecase updateLessonUsecase;
  final uc_delete_lesson.DeleteLessonUsecase deleteLessonUsecase;
  final uc_reorder_lessons.ReorderLessonsUsecase reorderLessonsUsecase;

  final uc_upload_media.UploadMediaUsecase uploadMediaUsecase;
  final uc_delete_media.DeleteMediaUsecase deleteMediaUsecase;

  AdminContentProvider({
    required this.listModulesUsecase,
    required this.listLessonsUsecase,
    required this.createModuleUsecase,
    required this.updateModuleUsecase,
    required this.deleteModuleUsecase,
    required this.reorderModulesUsecase,
    required this.createLessonUsecase,
    required this.updateLessonUsecase,
    required this.deleteLessonUsecase,
    required this.reorderLessonsUsecase,
    required this.uploadMediaUsecase,
    required this.deleteMediaUsecase,
  });

  bool _isBusy = false;
  String? _error;

  bool get isBusy => _isBusy;
  String? get error => _error;

  void _setBusy(bool v) {
    _isBusy = v;
    notifyListeners();
  }

  // ---------------- Fetching ----------------
  Future<List<ModuleEntity>> fetchModules(String courseId) async {
    _setBusy(true);
    _setError(null);
    try {
      final modules = await listModulesUsecase.call(courseId);
      return modules;
    } catch (e) {
      _setError('Error al listar módulos: $e');
      return [];
    } finally {
      _setBusy(false);
    }
  }

  Future<List<LessonEntity>> fetchLessons({
    required String courseId,
    required String moduleId,
  }) async {
    _setBusy(true);
    _setError(null);
    try {
      final lessons = await listLessonsUsecase.call(
        courseId: courseId,
        moduleId: moduleId,
      );
      return lessons;
    } catch (e) {
      _setError('Error al listar lecciones: $e');
      return [];
    } finally {
      _setBusy(false);
    }
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }

  // ---------------- Modules ----------------
  Future<ModuleEntity?> createModule(ModuleEntity module) async {
    _setBusy(true);
    _setError(null);
    try {
      // Validation: max 2 modules per course is a UI/data concern; enforce elsewhere if needed
      final created = await createModuleUsecase.call(module);
      return created;
    } catch (e) {
      _setError('Error al crear módulo: $e');
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> updateModule(ModuleEntity module) async {
    _setBusy(true);
    _setError(null);
    try {
      await updateModuleUsecase.call(module);
      return true;
    } catch (e) {
      _setError('Error al actualizar módulo: $e');
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> deleteModule({
    required String courseId,
    required String moduleId,
  }) async {
    _setBusy(true);
    _setError(null);
    try {
      await deleteModuleUsecase.call(
        uc_delete_module.DeleteModuleParams(
          courseId: courseId,
          moduleId: moduleId,
        ),
      );
      return true;
    } catch (e) {
      _setError('Error al eliminar módulo: $e');
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> reorderModules(
    String courseId,
    List<String> orderedModuleIds,
  ) async {
    _setBusy(true);
    _setError(null);
    try {
      await reorderModulesUsecase.call(
        uc_reorder_modules.ReorderModulesParams(
          courseId: courseId,
          orderedModuleIds: orderedModuleIds,
        ),
      );
      return true;
    } catch (e) {
      _setError('Error al reordenar módulos: $e');
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ---------------- Lessons ----------------
  Future<LessonEntity?> createLesson(LessonEntity lesson) async {
    _setBusy(true);
    _setError(null);
    try {
      // Validation: max 3 lessons per module and <= 5 minutes should be validated at UI before calling this
      final created = await createLessonUsecase.call(lesson);
      return created;
    } catch (e) {
      _setError('Error al crear lección: $e');
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> updateLesson(LessonEntity lesson) async {
    _setBusy(true);
    _setError(null);
    try {
      await updateLessonUsecase.call(lesson);
      return true;
    } catch (e) {
      _setError('Error al actualizar lección: $e');
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> deleteLesson({
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    _setBusy(true);
    _setError(null);
    try {
      await deleteLessonUsecase.call(
        uc_delete_lesson.DeleteLessonParams(
          courseId: courseId,
          moduleId: moduleId,
          lessonId: lessonId,
        ),
      );
      return true;
    } catch (e) {
      _setError('Error al eliminar lección: $e');
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> reorderLessons(
    String courseId,
    String moduleId,
    List<String> orderedLessonIds,
  ) async {
    _setBusy(true);
    _setError(null);
    try {
      await reorderLessonsUsecase.call(
        uc_reorder_lessons.ReorderLessonsParams(
          courseId: courseId,
          moduleId: moduleId,
          orderedLessonIds: orderedLessonIds,
        ),
      );
      return true;
    } catch (e) {
      _setError('Error al reordenar lecciones: $e');
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ---------------- Media ----------------
  Future<MediaResource?> uploadMedia({
    required String courseId,
    String? moduleId,
    String? lessonId,
    required MediaUploadRequest request,
  }) async {
    _setBusy(true);
    _setError(null);
    try {
      // Basic validations by mimeType and size should be ensured at UI
      final media = await uploadMediaUsecase.call(
        uc_upload_media.UploadMediaParams(
          courseId: courseId,
          moduleId: moduleId,
          lessonId: lessonId,
          request: request,
        ),
      );
      return media;
    } catch (e) {
      _setError('Error al subir archivo: $e');
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> deleteMedia({
    required String courseId,
    String? moduleId,
    String? lessonId,
    required String mediaId,
  }) async {
    _setBusy(true);
    _setError(null);
    try {
      await deleteMediaUsecase.call(
        uc_delete_media.DeleteMediaParams(
          courseId: courseId,
          moduleId: moduleId,
          lessonId: lessonId,
          mediaId: mediaId,
        ),
      );
      return true;
    } catch (e) {
      _setError('Error al eliminar archivo: $e');
      return false;
    } finally {
      _setBusy(false);
    }
  }
}

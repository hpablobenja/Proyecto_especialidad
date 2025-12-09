// lib/presentation/screens/admin/course_content_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/admin_content_provider.dart';
import '../../providers/comments_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/youtube_video_manager.dart';
import 'quiz_management_screen.dart';
import '../../../domain/entities/module_entity.dart';
import '../../../domain/entities/lesson_entity.dart';
import '../../../domain/entities/media_resource.dart';

class CourseContentScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  const CourseContentScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<CourseContentScreen> createState() => _CourseContentScreenState();
}

class _CourseContentScreenState extends State<CourseContentScreen> {
  bool _loading = true;
  String? _error;
  List<ModuleEntity> _modules = [];
  final Map<String, List<LessonEntity>> _lessonsByModule = {};

  @override
  void initState() {
    super.initState();
    // Evita notifyListeners() durante la fase de build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadModules();
    });
  }

  Future<void> _editLesson(ModuleEntity module, LessonEntity lesson) async {
    final titleCtrl = TextEditingController(text: lesson.title);
    final objCtrl = TextEditingController(text: lesson.objectives ?? '');
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Editar lección'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Ingrese un título'
                                : null,
                  ),
                  TextFormField(
                    controller: objCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Objetivos (opcional)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate())
                    Navigator.pop(context, true);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (ok != true) return;

    try {
      final admin = Provider.of<AdminContentProvider>(context, listen: false);
      final updated = LessonEntity(
        id: lesson.id,
        courseId: lesson.courseId,
        moduleId: lesson.moduleId,
        title: titleCtrl.text.trim(),
        contentDelta: lesson.contentDelta,
        objectives: objCtrl.text.trim().isEmpty ? null : objCtrl.text.trim(),
        media: lesson.media,
        downloadableResources: lesson.downloadableResources,
        orderIndex: lesson.orderIndex,
        dripUnlockAt: lesson.dripUnlockAt,
      );
      final success = await admin.updateLesson(updated);
      if (success) {
        await _loadLessons(module.id);
      } else if (admin.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(admin.error!),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar lección: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _deleteLesson(ModuleEntity module, LessonEntity lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar lección'),
            content: Text('¿Eliminar "${lesson.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    try {
      final admin = Provider.of<AdminContentProvider>(context, listen: false);
      final ok = await admin.deleteLesson(
        courseId: widget.courseId,
        moduleId: module.id,
        lessonId: lesson.id,
      );
      if (ok) {
        await _loadLessons(module.id);
      } else if (admin.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(admin.error!),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar lección: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _editModule(ModuleEntity module) async {
    final titleCtrl = TextEditingController(text: module.title);
    final descCtrl = TextEditingController(text: module.description ?? '');
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Editar módulo'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Ingrese un título'
                                : null,
                  ),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate())
                    Navigator.pop(context, true);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    if (ok != true) return;

    try {
      final admin = Provider.of<AdminContentProvider>(context, listen: false);
      final updated = ModuleEntity(
        id: module.id,
        courseId: module.courseId,
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        orderIndex: module.orderIndex,
      );
      final success = await admin.updateModule(updated);
      if (success) {
        // Replace in list
        setState(() {
          _modules =
              _modules.map((m) => m.id == updated.id ? updated : m).toList();
        });
      } else if (admin.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(admin.error!),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar módulo: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _deleteModule(ModuleEntity module) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar módulo'),
            content: Text('¿Eliminar "${module.title}" y sus lecciones?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    try {
      final admin = Provider.of<AdminContentProvider>(context, listen: false);
      final ok = await admin.deleteModule(
        courseId: widget.courseId,
        moduleId: module.id,
      );
      if (ok) {
        setState(() {
          _modules = _modules.where((m) => m.id != module.id).toList();
          _lessonsByModule.remove(module.id);
        });
      } else if (admin.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(admin.error!),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar módulo: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _manageStrategies({
    required ModuleEntity module,
    required LessonEntity lesson,
  }) async {
    final strategies = List<Map<String, String>>.from(lesson.strategies);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Estrategias: ${lesson.title}'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (strategies.isEmpty)
                      const Text('No hay estrategias definidas.')
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: strategies.length,
                          itemBuilder: (context, index) {
                            final s = strategies[index];
                            return ListTile(
                              title: Text(s['title'] ?? ''),
                              subtitle: Text(
                                s['description'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final result = await _editStrategyDialog(
                                        context,
                                        title: s['title'],
                                        description: s['description'],
                                      );
                                      if (result != null) {
                                        setState(() {
                                          strategies[index] = result;
                                        });
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      setState(() {
                                        strategies.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await _editStrategyDialog(context);
                        if (result != null) {
                          setState(() {
                            strategies.add(result);
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Estrategia'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final admin = Provider.of<AdminContentProvider>(
                        context,
                        listen: false,
                      );
                      final updated = LessonEntity(
                        id: lesson.id,
                        courseId: lesson.courseId,
                        moduleId: lesson.moduleId,
                        title: lesson.title,
                        contentDelta: lesson.contentDelta,
                        objectives: lesson.objectives,
                        media: lesson.media,
                        downloadableResources: lesson.downloadableResources,
                        strategies: strategies,
                        orderIndex: lesson.orderIndex,
                        dripUnlockAt: lesson.dripUnlockAt,
                      );
                      final success = await admin.updateLesson(updated);
                      if (success) {
                        await _loadLessons(module.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Estrategias actualizadas'),
                          ),
                        );
                      } else if (admin.error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(admin.error!),
                            backgroundColor: AppColors.errorColor,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar estrategias: $e'),
                          backgroundColor: AppColors.errorColor,
                        ),
                      );
                    }
                  },
                  child: const Text('Guardar Cambios'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, String>?> _editStrategyDialog(
    BuildContext context, {
    String? title,
    String? description,
  }) async {
    final titleCtrl = TextEditingController(text: title);
    final descCtrl = TextEditingController(text: description);
    final formKey = GlobalKey<FormState>();

    return showDialog<Map<String, String>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              title == null ? 'Nueva Estrategia' : 'Editar Estrategia',
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Requerido'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    maxLines: 5,
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Requerido'
                                : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, {
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                    });
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  Future<void> _attachVideoToLesson({
    required ModuleEntity module,
    required LessonEntity lesson,
  }) async {
    final urlCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String? videoIdFromUrl(String url) {
      final u = url.trim();
      final patterns = <RegExp>[
        RegExp(r'^https?:\/\/(?:www\.)?youtu\.be\/([A-Za-z0-9_-]{11})'),
        RegExp(
          r'^https?:\/\/(?:www\.)?youtube\.com\/watch\?v=([A-Za-z0-9_-]{11})',
        ),
        RegExp(
          r'^https?:\/\/(?:www\.)?youtube\.com\/embed\/([A-Za-z0-9_-]{11})',
        ),
        RegExp(
          r'^https?:\/\/(?:www\.)?youtube\.com\/shorts\/([A-Za-z0-9_-]{11})',
        ),
      ];
      for (final p in patterns) {
        final m = p.firstMatch(u);
        if (m != null) return m.group(1);
      }
      // Fallback: try to parse any v= param
      final uri = Uri.tryParse(u);
      final v = uri?.queryParameters['v'];
      if (v != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(v)) return v;
      return null;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Agregar video de YouTube'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL de YouTube',
                  hintText: 'https://youtu.be/XXXXXXXXXXX',
                ),
                validator: (v) {
                  final id = v == null ? null : videoIdFromUrl(v);
                  if (id == null) return 'Ingrese una URL válida de YouTube';
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate())
                    Navigator.pop(context, true);
                },
                child: const Text('Adjuntar'),
              ),
            ],
          ),
    );

    if (ok != true) return;

    final id = videoIdFromUrl(urlCtrl.text);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('URL de YouTube no válida'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    try {
      final media = MediaResource(
        id: 'youtube:$id',
        url: 'https://www.youtube.com/watch?v=$id',
        filename: 'YouTube $id',
        mimeType: 'video/youtube',
        sizeBytes: 0,
        duration: null,
        metadata: {'provider': 'youtube', 'videoId': id},
      );

      final admin = Provider.of<AdminContentProvider>(context, listen: false);
      final updated = LessonEntity(
        id: lesson.id,
        courseId: lesson.courseId,
        moduleId: lesson.moduleId,
        title: lesson.title,
        contentDelta: lesson.contentDelta,
        objectives: lesson.objectives,
        media: [...lesson.media, media],
        downloadableResources: lesson.downloadableResources,
        orderIndex: lesson.orderIndex,
        dripUnlockAt: lesson.dripUnlockAt,
      );

      final success = await admin.updateLesson(updated);
      if (success) {
        await _loadLessons(module.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enlace de YouTube agregado correctamente'),
          ),
        );
      } else {
        final msg = admin.error ?? 'No se pudo guardar la lección con el video';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.errorColor),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al adjuntar video: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _loadModules() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final admin = Provider.of<AdminContentProvider>(context, listen: false);
      final mods = await admin.fetchModules(widget.courseId);
      setState(() {
        _modules = mods;
      });
    } catch (e) {
      setState(() => _error = 'No se pudieron cargar los módulos: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadLessons(String moduleId) async {
    try {
      final admin = Provider.of<AdminContentProvider>(context, listen: false);
      final list = await admin.fetchLessons(
        courseId: widget.courseId,
        moduleId: moduleId,
      );
      setState(() {
        _lessonsByModule[moduleId] = list;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron cargar las lecciones: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _onLessonUpdated(LessonEntity updatedLesson, {BuildContext? dialogContext}) async {
    try {
      final admin = Provider.of<AdminContentProvider>(context, listen: false);
      final success = await admin.updateLesson(updatedLesson);
      if (success) {
        await _loadLessons(updatedLesson.moduleId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lección actualizada correctamente')),
        );
        // Cerrar el diálogo si se proporcionó el contexto
        if (dialogContext != null && dialogContext.mounted) {
          Navigator.of(dialogContext).pop();
        }
      } else if (admin.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(admin.error!),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar lección: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _addModule() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Nuevo módulo'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título del módulo',
                    ),
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Ingrese un título'
                                : null,
                  ),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate())
                    Navigator.pop(context, true);
                },
                child: const Text('Crear'),
              ),
            ],
          ),
    );

    if (ok != true) return;

    try {
      final admin = Provider.of<AdminContentProvider>(context, listen: false);
      final module = ModuleEntity(
        id: '',
        courseId: widget.courseId,
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        orderIndex: _modules.length,
      );
      final created = await admin.createModule(module);
      if (created != null) {
        setState(() => _modules = [..._modules, created]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear módulo: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _addLesson(ModuleEntity module) async {
    final titleCtrl = TextEditingController();
    final objCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Nueva lección'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título de la lección',
                    ),
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Ingrese un título'
                                : null,
                  ),
                  TextFormField(
                    controller: objCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Objetivos (opcional)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate())
                    Navigator.pop(context, true);
                },
                child: const Text('Crear'),
              ),
            ],
          ),
    );

    if (ok != true) return;

    try {
      final admin = Provider.of<AdminContentProvider>(context, listen: false);
      final current = _lessonsByModule[module.id] ?? [];
      final lesson = LessonEntity(
        id: '',
        courseId: widget.courseId,
        moduleId: module.id,
        title: titleCtrl.text.trim(),
        contentDelta: null,
        objectives: objCtrl.text.trim().isEmpty ? null : objCtrl.text.trim(),
        media: const [],
        downloadableResources: const [],
        orderIndex: current.length,
        dripUnlockAt: null,
      );
      final created = await admin.createLesson(lesson);
      if (created != null) {
        setState(() {
          _lessonsByModule[module.id] = [...current, created];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear lección: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contenido: ${widget.courseTitle}')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addModule,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo módulo'),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(
                  _error!,
                  style: TextStyle(color: AppColors.errorColor),
                ),
              )
              : _modules.isEmpty
              ? const Center(
                child: Text('No hay módulos. Crea el primero con el botón +'),
              )
              : ListView.builder(
                itemCount: _modules.length,
                itemBuilder: (context, index) {
                  final m = _modules[index];
                  final lessons = _lessonsByModule[m.id];
                  return ExpansionTile(
                    leading: const Icon(Icons.folder_open),
                    title: Text(m.title),
                    subtitle:
                        m.description != null ? Text(m.description!) : null,
                    onExpansionChanged: (expanded) {
                      if (expanded && lessons == null) {
                        _loadLessons(m.id);
                      }
                    },
                    children: [
                      // Module actions row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Editar módulo',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editModule(m),
                            ),
                            IconButton(
                              tooltip: 'Eliminar módulo',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteModule(m),
                            ),
                          ],
                        ),
                      ),
                      if (lessons == null)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: LinearProgressIndicator(),
                        )
                      else if (lessons.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Sin lecciones aún.'),
                        )
                      else
                        ...lessons.map(
                          (l) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Ícono + título en una fila
                                  Row(
                                    children: [
                                      const Icon(Icons.play_lesson_outlined),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (l.objectives != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        l.objectives!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  // Botones debajo del título
                                  Wrap(
                                    spacing: 4,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      IconButton(
                                        tooltip: 'Editar lección',
                                        onPressed: () => _editLesson(m, l),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip: 'Eliminar lección',
                                        onPressed: () => _deleteLesson(m, l),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                      IconButton(
                                        tooltip: 'Gestionar videos',
                                        onPressed:
                                            () => _openVideoManager(
                                              module: m,
                                              lesson: l,
                                            ),
                                        icon: const Icon(Icons.video_library),
                                      ),
                                      IconButton(
                                        tooltip: 'Comentarios',
                                        onPressed:
                                            () => _openComments(
                                              module: m,
                                              lesson: l,
                                            ),
                                        icon: const Icon(
                                          Icons.comment_outlined,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Gestionar cuestionario',
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => QuizManagementScreen(
                                                    lesson: l,
                                                  ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.quiz),
                                      ),
                                      IconButton(
                                        tooltip: 'Gestionar estrategias',
                                        onPressed:
                                            () => _manageStrategies(
                                              module: m,
                                              lesson: l,
                                            ),
                                        icon: const Icon(
                                          Icons.lightbulb_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            right: 16.0,
                            bottom: 12,
                          ),
                          child: OutlinedButton.icon(
                            onPressed: () => _addLesson(m),
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar lección'),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }

  void _openVideoManager({
    required ModuleEntity module,
    required LessonEntity lesson,
  }) async {
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.video_library,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Gestión de Videos - ${lesson.title}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: YouTubeVideoManager(
                      lesson: lesson,
                      onLessonUpdated: (updatedLesson) => _onLessonUpdated(updatedLesson, dialogContext: dialogContext),
                      isAdmin: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _openComments({
    required ModuleEntity module,
    required LessonEntity lesson,
  }) async {
    final comments = Provider.of<CommentsProvider>(context, listen: false);
    await comments.load(
      courseId: widget.courseId,
      moduleId: module.id,
      lessonId: lesson.id,
    );

    final textCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Helper to add comment
    Future<void> _submit() async {
      if (!formKey.currentState!.validate()) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Inicia sesión para comentar'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }
      final ok = await comments.add(
        courseId: widget.courseId,
        moduleId: module.id,
        lessonId: lesson.id,
        userId: user.uid,
        userName: user.email,
        text: textCtrl.text,
      );
      if (ok) {
        textCtrl.clear();
      } else if (comments.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(comments.error!),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8,
                    ),
                    child: Text(
                      'Comentarios • ${lesson.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: Consumer<CommentsProvider>(
                      builder: (context, cp, _) {
                        if (cp.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (cp.items.isEmpty) {
                          return const Center(
                            child: Text('Sé el primero en comentar.'),
                          );
                        }
                        return ListView.separated(
                          itemCount: cp.items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final c = cp.items[i];
                            return ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(
                                c.userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(c.text),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final ok = await cp.remove(
                                    courseId: c.courseId,
                                    moduleId: c.moduleId,
                                    lessonId: c.lessonId,
                                    commentId: c.id,
                                  );
                                  if (!ok && cp.error != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(cp.error!),
                                        backgroundColor: AppColors.errorColor,
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Form(
                      key: formKey,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: textCtrl,
                              maxLength: 500,
                              decoration: const InputDecoration(
                                hintText: 'Escribe un comentario (máx. 500)…',
                                counterText: '',
                              ),
                              validator: (v) {
                                final t = (v ?? '').trim();
                                if (t.isEmpty) return 'Escribe algo';
                                if (t.length > 500)
                                  return 'Máximo 500 caracteres';
                                return null;
                              },
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

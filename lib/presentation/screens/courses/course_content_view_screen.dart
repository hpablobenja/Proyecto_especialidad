// lib/presentation/screens/courses/course_content_view_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/module_entity.dart';
import '../../../domain/entities/lesson_entity.dart';
import '../../../core/di/riverpod_providers.dart';
import '../../../core/services/offline_cache_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/no_internet_message.dart';
import '../courses/lesson_options_screen.dart';
import '../../../core/constants/app_colors.dart';

class CourseContentViewScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String courseTitle;

  const CourseContentViewScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  ConsumerState<CourseContentViewScreen> createState() =>
      _CourseContentViewScreenState();
}

class _CourseContentViewScreenState
    extends ConsumerState<CourseContentViewScreen> {
  bool _loading = true;
  String? _error;
  List<ModuleEntity> _modules = [];
  final Map<String, List<LessonEntity>> _lessonsByModule = {};
  OfflineCacheService get _cacheService =>
      ref.read(offlineCacheServiceProvider);

  String? _youtubeIdFromLesson(LessonEntity lesson) {
    // Find a youtube media or fallback to first media
    final mediaList = lesson.media;
    if (mediaList.isEmpty) return null;
    final ytMedia = mediaList.firstWhere(
      (m) => m.mimeType == 'video/youtube',
      orElse: () => mediaList.first,
    );

    // Prefer metadata.videoId if present
    final meta = ytMedia.metadata;
    final metaId = meta is Map<String, dynamic> ? meta['videoId'] : null;
    final idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');
    if (metaId is String && metaId.isNotEmpty && idPattern.hasMatch(metaId)) {
      return metaId;
    }

    // Parse from URL
    final url = ytMedia.url;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final v = uri.queryParameters['v'];
    if (v != null && idPattern.hasMatch(v)) return v;
    final path = uri.pathSegments;
    if (path.isNotEmpty) {
      if ((uri.host.contains('youtu.be') ||
              path.first == 'embed' ||
              path.first == 'shorts') &&
          idPattern.hasMatch(path.last)) {
        return path.last;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadModules();
    });
  }

  Future<void> _loadModules() async {
    // Check if online
    final connectivity = ref.read(connectivityStateProvider);
    if (!connectivity.isOnline) {
      // Try to load cached data
      final cachedModules = await _cacheService.getCachedModules(
        widget.courseId,
      );
      final cachedLesson = await _cacheService.getLastLesson();

      if (cachedModules.isNotEmpty) {
        // Cargar todas las lessons cacheadas para cada módulo
        final Map<String, List<LessonEntity>> cachedLessonsMap = {};
        for (final mod in cachedModules) {
          final modLessons = await _cacheService.getCachedLessons(mod.id);
          if (modLessons.isNotEmpty) {
            cachedLessonsMap[mod.id] = modLessons;
          }
        }

        // Si alguna lección suelta pertenecía al curso y no estaba en el mapa, añadirla
        if (cachedLesson != null &&
            cachedLesson.courseId == widget.courseId &&
            !cachedLessonsMap.containsKey(cachedLesson.moduleId)) {
          cachedLessonsMap[cachedLesson.moduleId] = [cachedLesson];
        }

        setState(() {
          _modules = cachedModules;
          _lessonsByModule.addAll(cachedLessonsMap);
          _loading = false;
          _error = null;
        });
      } else if (cachedLesson != null &&
          cachedLesson.courseId == widget.courseId) {
        setState(() {
          _modules = [
            ModuleEntity(
              id: cachedLesson.moduleId,
              courseId: cachedLesson.courseId,
              title: 'Módulo Guardado',
              description: 'Contenido disponible offline',
              orderIndex: 0,
            ),
          ];
          _lessonsByModule[cachedLesson.moduleId] = [cachedLesson];
          _loading = false;
          _error = null;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'offline';
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final admin = ref.read(adminContentStateProvider);
      final mods = await admin.fetchModules(widget.courseId);
      setState(() => _modules = mods);

      // Cache modules for offline access
      await _cacheService.cacheModules(widget.courseId, mods);
    } catch (e) {
      setState(() => _error = 'No se pudieron cargar los módulos: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadLessons(String moduleId) async {
    final connectivity = ref.read(connectivityStateProvider);
    if (!connectivity.isOnline) {
      final cachedList = await _cacheService.getCachedLessons(moduleId);
      if (cachedList.isNotEmpty) {
        setState(() {
          _lessonsByModule[moduleId] = cachedList;
        });
      }
      return;
    }

    try {
      final admin = ref.read(adminContentStateProvider);
      final list = await admin.fetchLessons(
        courseId: widget.courseId,
        moduleId: moduleId,
      );
      // Ordenar lessons por orderIndex
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      setState(() {
        _lessonsByModule[moduleId] = list;
      });
      // Guardar automáticamente lessons del módulo en local
      await _cacheService.cacheLessonsForModule(moduleId, list);
      if (list.isNotEmpty) {
        await _cacheService.cacheLastLesson(list.first);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron cargar las lecciones: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = ref.watch(authStateProvider);
    final isMaestro = authProvider.currentUser?.role == 'maestro';

    return Scaffold(
      appBar: AppBar(title: Text('Microformación: ${widget.courseTitle}')),
      // Only show drawer if NOT maestro
      drawer: isMaestro ? null : const AppDrawer(),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error == 'offline'
              ? const NoInternetMessage()
              : _error != null
              ? Center(
                child: Text(
                  _error!,
                  style: TextStyle(color: AppColors.errorColor),
                ),
              )
              : _modules.isEmpty
              ? const Center(child: Text('Aún no hay contenido disponible.'))
              : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
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
                      if (lessons == null)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: LinearProgressIndicator(),
                        )
                      else if (lessons.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Sin lecciones en este módulo.'),
                        )
                      else
                        ...lessons.asMap().entries.map((entry) {
                          final index = entry.key;
                          final l = entry.value;
                          final ytId = _youtubeIdFromLesson(l);
                          final thumbUrl =
                              ytId != null
                                  ? 'https://img.youtube.com/vi/' +
                                      ytId +
                                      '/hqdefault.jpg'
                                  : null;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryColor,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              l.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (thumbUrl != null) ...[
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (_) => LessonOptionsScreen(
                                                lesson: l,
                                              ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: Image.network(
                                              thumbUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    size: 32,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black45,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            child: const Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                if (l.objectives != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      l.objectives!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              // Cache lesson for offline access
                              _cacheService.cacheLastLesson(l);

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => LessonOptionsScreen(lesson: l),
                                ),
                              );
                            },
                          );
                        }),
                    ],
                  );
                },
              ),
    );
  }
}

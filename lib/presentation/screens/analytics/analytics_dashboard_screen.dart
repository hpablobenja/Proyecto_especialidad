// lib/presentation/screens/analytics/analytics_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/video_tracking_entity.dart';
import '../../providers/video_tracking_provider.dart';
import '../../../core/di/riverpod_providers.dart';

/// Dashboard de analítica educativa para mostrar métricas de progreso de video
class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _courseStats;
  List<VideoTrackingEntity>? _userProgress;
  String? _selectedCourseId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> _lessonTitles = {}; // lessonId -> title
  Map<String, String> _moduleTitles = {}; // moduleId -> title
  Map<String, String> _courseTitles = {}; // courseId -> title

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final auth = ref.read(authStateProvider);
    final user = auth.currentUser;

    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final repository = ref.read(videoTrackingRepositoryProvider);

      // Obtener progreso del usuario (el repositorio ya carga de Firebase si no hay datos locales)
      final progress = await repository.getUserVideoProgress(user.uid);

      // Si no hay datos locales, intentar cargar directamente de Firebase
      if (progress.isEmpty) {
        try {
          final remoteDataSource = ref.read(
            videoTrackingRemoteDataSourceProvider,
          );
          final remoteProgress = await remoteDataSource.getUserVideoProgress(
            user.uid,
          );

          if (remoteProgress.isNotEmpty) {
            // Sincronizar datos remotos con local
            for (final tracking in remoteProgress) {
              await repository.saveVideoProgress(tracking);
            }

            // Recargar desde local ahora que se sincronizaron
            final syncedProgress = await repository.getUserVideoProgress(
              user.uid,
            );
            await _loadTitles(syncedProgress);
            _calculateStats(syncedProgress);
            return;
          }
        } catch (e) {
          debugPrint('Error cargando desde Firebase: $e');
        }
      }

      // Cargar títulos de cursos, módulos y lecciones
      await _loadTitles(progress);

      _calculateStats(progress);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando analítica: $e')));
      }
    }
  }

  void _calculateStats(List<VideoTrackingEntity> progress) {
    // Obtener estadísticas del primer curso (o el seleccionado)
    Map<String, dynamic>? stats;
    if (progress.isNotEmpty) {
      final courseId = _selectedCourseId ?? progress.first.courseId;
      final courseProgress =
          progress.where((item) => item.courseId == courseId).toList();
      final completedLessons =
          courseProgress.where((item) => item.isCompleted).length;
      final totalViewedSeconds = courseProgress.fold<int>(
        0,
        (total, item) => total + item.viewedSeconds,
      );
      final averageCompletion =
          courseProgress.isEmpty
              ? 0.0
              : courseProgress.fold<double>(
                    0,
                    (total, item) => total + item.completionPercentage,
                  ) /
                  courseProgress.length;

      stats = {
        'totalLessons': courseProgress.length,
        'completedLessons': completedLessons,
        'totalViewedSeconds': totalViewedSeconds,
        'averageCompletionPercentage': averageCompletion,
      };
    }

    if (mounted) {
      setState(() {
        _userProgress = progress;
        _courseStats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTitles(List<VideoTrackingEntity> progress) async {
    // Obtener IDs únicos de cursos, módulos y lecciones
    final courseIds = progress.map((p) => p.courseId).where((id) => id.isNotEmpty).toSet().toList();
    final lessonIds = progress.map((p) => p.lessonId).where((id) => id.isNotEmpty).toSet().toList();

    // Cargar títulos de cursos
    final courseFutures = courseIds.map((courseId) async {
      try {
        final doc = await _firestore.collection('courses').doc(courseId).get();
        if (doc.exists) {
          _courseTitles[courseId] =
              doc.data()?['title'] as String? ?? 'Sin título';
        }
      } catch (_) {}
    });

    // Cargar títulos de módulos buscando en la subcolección de su respectivo curso
    final moduleFutures = progress.map((p) async {
      if (p.moduleId.isEmpty || _moduleTitles.containsKey(p.moduleId)) return;
      try {
        if (p.courseId.isNotEmpty) {
          final subDoc = await _firestore
              .collection('courses')
              .doc(p.courseId)
              .collection('modules')
              .doc(p.moduleId)
              .get();
          if (subDoc.exists) {
            _moduleTitles[p.moduleId] =
                subDoc.data()?['title'] as String? ?? 'Sin título';
            return;
          }
        }
        // Fallback a colección raíz
        final rootDoc = await _firestore.collection('modules').doc(p.moduleId).get();
        if (rootDoc.exists) {
          _moduleTitles[p.moduleId] =
              rootDoc.data()?['title'] as String? ?? 'Sin título';
        }
      } catch (_) {}
    });

    // Cargar títulos de lecciones
    final lessonFutures = lessonIds.map((lessonId) async {
      try {
        final doc = await _firestore.collection('lessons').doc(lessonId).get();
        if (doc.exists) {
          _lessonTitles[lessonId] =
              doc.data()?['title'] as String? ?? 'Sin título';
        }
      } catch (_) {}
    });

    await Future.wait([...courseFutures, ...moduleFutures, ...lessonFutures]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analítica Educativa')),
        body: const Center(child: Text('Inicia sesión para ver tu progreso')),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analítica Educativa')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analítica Educativa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body:
          _courseStats == null
              ? const Center(
                child: Text('No hay datos de progreso disponibles'),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCard(),
                    const SizedBox(height: 16),
                    _buildCompletionChart(),
                    const SizedBox(height: 16),
                    _buildCheckpointsCard(),
                    const SizedBox(height: 16),
                    _buildLessonsProgressList(),
                  ],
                ),
              ),
    );
  }

  Widget _buildOverviewCard() {
    final totalLessons = _courseStats!['totalLessons'] as int;
    final completedLessons = _courseStats!['completedLessons'] as int;
    final totalViewedSeconds = _courseStats!['totalViewedSeconds'] as int;
    final averageCompletion =
        _courseStats!['averageCompletionPercentage'] as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen General',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Lecciones',
                  '$completedLessons/$totalLessons',
                  Icons.book,
                ),
                _buildStatItem(
                  'Tiempo Total',
                  _formatDuration(totalViewedSeconds),
                  Icons.access_time,
                ),
                _buildStatItem(
                  'Promedio',
                  '${averageCompletion.toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildCompletionChart() {
    final completedLessons = _courseStats!['completedLessons'] as int;
    final totalLessons = _courseStats!['totalLessons'] as int;
    final completionRate =
        totalLessons > 0 ? completedLessons / totalLessons : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasa de Completación',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: completionRate * 100,
                      title: '${(completionRate * 100).toStringAsFixed(1)}%',
                      color: Theme.of(context).colorScheme.primary,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: (1 - completionRate) * 100,
                      title:
                          '${((1 - completionRate) * 100).toStringAsFixed(1)}%',
                      color: const Color.fromARGB(255, 191, 231, 239),
                      radius: 50,
                    ),
                  ],
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckpointsCard() {
    if (_userProgress == null || _userProgress!.isEmpty) {
      return const SizedBox.shrink();
    }

    int totalPassed = 0;
    int totalFailed = 0;

    for (final progress in _userProgress!) {
      totalPassed += progress.checkpointsPassed.length;
      totalFailed += progress.checkpointsFailed.length;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Checkpoints', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCheckpointStat('Aprobados', totalPassed, Colors.green),
                _buildCheckpointStat('Fallados', totalFailed, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckpointStat(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget _buildLessonsProgressList() {
    if (_userProgress == null || _userProgress!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progreso por Lección',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._userProgress!.map(
              (progress) => _buildLessonProgressItem(progress),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonProgressItem(VideoTrackingEntity progress) {
    final lessonTitle =
        _lessonTitles[progress.lessonId] ?? 'Lección ${progress.lessonId}';
    final moduleTitle =
        _moduleTitles[progress.moduleId] ?? 'Módulo ${progress.moduleId}';
    final courseTitle =
        _courseTitles[progress.courseId] ?? 'Curso ${progress.courseId}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lessonTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$courseTitle > $moduleTitle',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${progress.completionPercentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: progress.isCompleted ? Colors.green : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.completionPercentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress.isCompleted
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Tiempo: ${_formatDuration(progress.viewedSeconds)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Pos: ${_formatDuration(progress.lastValidPositionMs ~/ 1000)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Checkpoints: ${progress.checkpointsPassed.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}

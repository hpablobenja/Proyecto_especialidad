import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/models/data_user_model.dart';
import '../../../data/repositories/data_user_repository.dart';
import '../../../core/di/riverpod_providers.dart';
import '../../../domain/usecases/courses/get_course_progress_usecase.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  final DataUserRepository _dataUserRepository = DataUserRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _userDataSubscription;
  StreamSubscription? _userProgressSubscription;

  DataUserModel? _userData;
  int _totalCourses = 0;
  int _completedCourses = 0;
  int _inProgressCourses = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    _userProgressSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final userRole = prefs.getString('user_role');

    // Solo cargar datos si el rol es 'maestro'
    if (userId == null || userRole != 'maestro') {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Forzar recarga de datos al entrar
    setState(() {
      _isLoading = true;
    });

    // Actualizar tiempo de sesión al ingresar a la pantalla
    await _dataUserRepository.updateCurrentSession();

    // Asegurar que el documento del usuario existe antes de escuchar
    await _dataUserRepository.getUserData();

    // Escuchar cambios en dataUser en tiempo real (tiempos de sesión)
    _userDataSubscription = _dataUserRepository.getUserDataStream().listen((
      userData,
    ) {
      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    });

    // Escuchar cambios en userProgress para calcular cursos y progreso
    _userProgressSubscription = _firestore
        .collection('userProgress')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            _calculateProgressFromUserProgress(snapshot);
          }
        });
  }

  Future<void> _calculateProgressFromUserProgress(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    // Agrupar progreso por courseId
    final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    courseProgress = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final courseId = data['courseId'] as String?;
      if (courseId != null) {
        courseProgress.putIfAbsent(courseId, () => []).add(doc);
      }
    }

    int completed = 0;
    int inProgress = 0;

    // Calcular categorías y progreso
    final Map<String, int> categoryProgress = {};
    final Map<String, int> categoryTotals = {};

    // Obtener información de cursos en paralelo
    final courseIds = courseProgress.keys.toList();
    final courseDocs = await Future.wait(
      courseIds.map(
        (courseId) => _firestore.collection('courses').doc(courseId).get(),
      ),
    );

    for (var i = 0; i < courseDocs.length; i++) {
      final courseDoc = courseDocs[i];
      final courseId = courseIds[i];
      final progressDocs = courseProgress[courseId]!;

      if (courseDoc.exists) {
        final courseData = courseDoc.data();
        final category = courseData?['targetAudience'] as String? ?? 'Otro';
        categoryTotals[category] = (categoryTotals[category] ?? 0) + 1;

        // Obtener el total de lecciones de este curso
        final lessonsSnapshot =
            await _firestore
                .collection('lecciones')
                .where('courseId', isEqualTo: courseId)
                .get();
        final totalLessons = lessonsSnapshot.docs.length;

        // Verificar si todas las lecciones registradas están completadas
        bool allRecordedCompleted = progressDocs.every((doc) {
          final data = doc.data();
          final status = data['status'] as String?;
          return status == 'completed';
        });

        bool hasProgress = progressDocs.any((doc) {
          final data = doc.data();
          final status = data['status'] as String?;
          return status == 'in_progress' || status == 'completed';
        });

        // El curso está completado solo si tiene lecciones, y el usuario ha completado todas.
        bool isFullyCompleted = false;
        if (totalLessons > 0 &&
            progressDocs.length >= totalLessons &&
            allRecordedCompleted) {
          isFullyCompleted = true;
        }

        if (isFullyCompleted) {
          completed++;
          categoryProgress[category] = (categoryProgress[category] ?? 0) + 1;
        } else if (hasProgress) {
          inProgress++;
        }
      }
    }

    // Actualizar progreso por categoría en dataUser
    for (var category in categoryTotals.keys) {
      final progress =
          categoryTotals[category]! > 0
              ? ((categoryProgress[category] ?? 0) /
                      categoryTotals[category]!) *
                  100
              : 0.0;
      await _dataUserRepository.updateCategoryProgress(category, progress);
    }

    if (mounted) {
      setState(() {
        _totalCourses = courseProgress.length;
        _completedCourses = completed;
        _inProgressCourses = inProgress;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateAchievements() {
    final achievements = <Map<String, dynamic>>[];
    if (_userData == null) return achievements;

    // Logro: Primer curso completado
    achievements.add({
      'title': 'Primer Curso Completado',
      'description': 'Completaste tu primer curso',
      'icon': Icons.star,
      'color': Colors.amber,
      'unlocked': _completedCourses >= 1,
    });

    // Logro: 5 cursos completados
    achievements.add({
      'title': 'Estudiante Dedicado',
      'description': 'Completaste 5 cursos',
      'icon': Icons.workspace_premium,
      'color': Colors.purple,
      'unlocked': _completedCourses >= 5,
    });

    // Logro: 10 horas de estudio
    achievements.add({
      'title': '10 Horas de Estudio',
      'description': 'Acumulaste 10 horas de capacitación',
      'icon': Icons.access_time,
      'color': Colors.blue,
      'unlocked': _userData!.totalSessionMinutes >= 600,
    });

    return achievements;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryColor, AppColors.accentColor],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mi Dashboard',
                    style: AppStyles.headline1.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Progreso y logros de tu aprendizaje',
                    style: AppStyles.bodyText1.copyWith(
                      color: Colors.white.withAlpha((0.9 * 255).round()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta de progreso general
                  _buildProgressCard(),
                  const SizedBox(height: 16),
                  // Métricas principales
                  _buildMetricsGrid(),
                  const SizedBox(height: 20),
                  // Barras de progreso por categoría
                  _buildCategoryProgress(),
                  const SizedBox(height: 16),
                  // Logros
                  _buildAchievementsSection(),
                  const SizedBox(height: 16),
                  // Horas de capacitación
                  _buildHoursCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progreso General',
                  style: AppStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_userData?.overallProgress.toStringAsFixed(1) ?? '0.0'}%',
                  style: AppStyles.headlineMedium.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_userData?.overallProgress ?? 0) / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(_userData?.overallProgress ?? 0),
                ),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Cursos Totales', _totalCourses.toString()),
                _buildStatItem('Completados', _completedCourses.toString()),
                _buildStatItem('En Progreso', _inProgressCourses.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Flexible(
      child: Column(
        children: [
          Text(
            value,
            style: AppStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppStyles.bodyText1.copyWith(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final achievements = _generateAchievements();
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate aspect ratio based on screen width
        final crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
        final width = 120;
        final childAspectRatio = width / 100;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            _buildMetricCard(
              'Sesión Actual',
              _userData?.currentSessionFormatted ?? '0m',
              Icons.access_time,
              Colors.blue,
            ),
            _buildMetricCard(
              'Tiempo Total',
              _userData?.totalSessionFormatted ?? '0m',
              Icons.schedule,
              Colors.green,
            ),
            _buildMetricCard(
              'Cursos Activos',
              '$_inProgressCourses',
              Icons.play_circle,
              Colors.orange,
            ),
            _buildMetricCard(
              'Logros Desbloqueados',
              '${achievements.where((a) => a['unlocked']).length}',
              Icons.emoji_events,
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                style: AppStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Flexible(
              child: Text(
                title,
                style: AppStyles.bodyText1.copyWith(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgress() {
    final categoryProgress = _userData?.categoryProgress ?? {};
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progreso por Categoría',
              style: AppStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryItem(
              'Ciencias Sociales',
              categoryProgress['Ciencias Sociales'] ?? 0.0,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildCategoryItem(
              'Ciencias Naturales',
              categoryProgress['Ciencias Naturales'] ?? 0.0,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildCategoryItem(
              'Comunicación y Lenguaje',
              categoryProgress['Comunicación y Lenguaje'] ?? 0.0,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildCategoryItem(
              'Alternativa',
              categoryProgress['Alternativa'] ?? 0.0,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: AppStyles.bodyText1.copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              '${progress.toStringAsFixed(0)}%',
              style: AppStyles.bodyText1.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    final achievements = _generateAchievements();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Logros',
                  style: AppStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${achievements.where((a) => a['unlocked']).length}/${achievements.length}',
                  style: AppStyles.bodyText1.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (achievements.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Completa cursos para desbloquear logros',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  return _buildAchievementItem(achievement);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(Map<String, dynamic> achievement) {
    final isUnlocked = achievement['unlocked'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isUnlocked
                  ? achievement['color'].withAlpha((0.1 * 255).round())
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUnlocked ? achievement['color'] : Colors.grey[300]!,
            width: isUnlocked ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUnlocked ? achievement['color'] : Colors.grey[400],
                shape: BoxShape.circle,
              ),
              child: Icon(achievement['icon'], color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement['title'],
                    style: AppStyles.bodyText1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement['description'],
                    style: AppStyles.bodyText1.copyWith(
                      fontSize: 12,
                      color: isUnlocked ? Colors.grey[700] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (isUnlocked)
              const Icon(Icons.check_circle, color: Colors.green, size: 24)
            else
              Icon(Icons.lock, color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withAlpha((0.1 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule,
                color: AppColors.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiempo en Sesión',
                    style: AppStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Actual: ${_userData?.currentSessionFormatted ?? '0m'} | Total: ${_userData?.totalSessionFormatted ?? '0m'}',
                    style: AppStyles.bodyText1.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 75) return Colors.green;
    if (progress >= 50) return Colors.blue;
    if (progress >= 25) return Colors.orange;
    return Colors.red;
  }
}

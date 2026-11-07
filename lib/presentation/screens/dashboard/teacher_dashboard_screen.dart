import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/models/data_user_hive.dart';
import '../../../data/repositories/data_user_repository.dart';
import '../../../core/services/dashboard_sync_service.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen>
    with WidgetsBindingObserver {
  final DataUserRepository _dataUserRepository = DataUserRepository();
  final DashboardSyncService _dashboardSyncService = DashboardSyncService();
  StreamSubscription? _userDataSubscription;
  StreamSubscription? _userProgressSubscription;
  Timer? _sessionTimer;
  // Evita que múltiples sincronizaciones concurrentes se ejecuten a la vez
  bool _syncInProgress = false;
  // Debounce para el listener de datos del usuario
  Timer? _userDataDebounce;

  DataUserHive? _localData;
  int _totalCourses = 0;
  int _completedCourses = 0;
  int _inProgressCourses = 0;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userDataSubscription?.cancel();
    _userProgressSubscription?.cancel();
    _sessionTimer?.cancel();
    _userDataDebounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App está en primer plano, recalcular tiempo y reiniciar timer
        if (_localData != null && _localData!.sessionStartTime != null) {
          final currentDuration =
              DateTime.now()
                  .difference(_localData!.sessionStartTime!)
                  .inMinutes;
          setState(() {
            _localData = DataUserHive(
              userId: _localData!.userId,
              currentSessionMinutes: currentDuration,
              totalSessionMinutes: _localData!.totalSessionMinutes,
              sessionStartTime: _localData!.sessionStartTime,
              lastSessionEnd: _localData!.lastSessionEnd,
              categoryProgress: _localData!.categoryProgress,
              overallProgress: _localData!.overallProgress,
              unlockedAchievements: _localData!.unlockedAchievements,
              updatedAt: _localData!.updatedAt,
              totalCourses: _localData!.totalCourses,
              completedCourses: _localData!.completedCourses,
              inProgressCourses: _localData!.inProgressCourses,
            );
          });
          _startSessionTimer();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App está en segundo plano o cerrándose, detener timer
        _sessionTimer?.cancel();
        break;
    }
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

    // Cargar datos locales primero
    final localData = await _dashboardSyncService.getLocalDashboardData(userId);
    if (localData != null) {
      // Recalcular tiempo actual basándose en sessionStartTime
      DataUserHive updatedData = localData;
      if (localData.sessionStartTime != null) {
        final currentDuration =
            DateTime.now().difference(localData.sessionStartTime!).inMinutes;
        updatedData = DataUserHive(
          userId: localData.userId,
          currentSessionMinutes: currentDuration,
          totalSessionMinutes: localData.totalSessionMinutes,
          sessionStartTime: localData.sessionStartTime,
          lastSessionEnd: localData.lastSessionEnd,
          categoryProgress: localData.categoryProgress,
          overallProgress: localData.overallProgress,
          unlockedAchievements: localData.unlockedAchievements,
          updatedAt: localData.updatedAt,
          totalCourses: localData.totalCourses,
          completedCourses: localData.completedCourses,
          inProgressCourses: localData.inProgressCourses,
        );
        // Guardar el tiempo actualizado localmente
        await _dashboardSyncService.saveLocalDashboardData(updatedData);
      }

      setState(() {
        _localData = updatedData;
        _totalCourses = updatedData.totalCourses;
        _completedCourses = updatedData.completedCourses;
        _inProgressCourses = updatedData.inProgressCourses;
        _isLoading = false;
      });

      // Sincronizar desde Firestore en segundo plano sin bloquear la UI
      _syncFromFirestore(userId).catchError(
        (e) => debugPrint('Error en sync background: $e'),
      );
    } else {
      // Si no hay datos locales, sincronizar desde Firestore (primera carga)
      await _syncFromFirestore(userId);
    }

    // Escuchar cambios en dataUser en tiempo real para actualizar tiempos de sesión.
    // Se usa debounce de 2 segundos para evitar escrituras y setState en ráfaga
    // cuando Firestore emite múltiples snapshots al recuperar la conexión.
    _userDataSubscription = _dataUserRepository.getUserDataStream().listen((
      userData,
    ) {
      if (mounted) {
        // Cancelar debounce previo y esperar 2 s antes de procesar
        _userDataDebounce?.cancel();
        _userDataDebounce = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            _updateLocalSessionTimes(userId, userData);
          }
        });
      }
    });

    // Iniciar timer para actualizar tiempos cada minuto
    _startSessionTimer();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();

    // Actualizar inmediatamente al iniciar (tick 0) para no esperar 1 minuto
    _tickSessionTimer();

    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      _tickSessionTimer();
    });
  }

  /// Calcula el tiempo de sesión actual y actualiza el estado local.
  /// Se llama al iniciar el timer y cada minuto posterior.
  Future<void> _tickSessionTimer() async {
    if (_localData == null || _localData!.sessionStartTime == null) return;

    // Calcular tiempo actual localmente sin escribir a Firebase
    final currentDuration =
        DateTime.now().difference(_localData!.sessionStartTime!).inMinutes;

    if (mounted) {
      setState(() {
        _localData = DataUserHive(
          userId: _localData!.userId,
          currentSessionMinutes: currentDuration,
          totalSessionMinutes: _localData!.totalSessionMinutes,
          sessionStartTime: _localData!.sessionStartTime,
          lastSessionEnd: _localData!.lastSessionEnd,
          categoryProgress: _localData!.categoryProgress,
          overallProgress: _localData!.overallProgress,
          unlockedAchievements: _localData!.unlockedAchievements,
          updatedAt: _localData!.updatedAt,
          totalCourses: _localData!.totalCourses,
          completedCourses: _localData!.completedCourses,
          inProgressCourses: _localData!.inProgressCourses,
        );
      });

      // Guardar solo localmente
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null) {
        await _dashboardSyncService.saveLocalDashboardData(_localData!);
      }
    }
  }

  Future<void> _syncFromFirestore(String userId) async {
    // Evitar sincronizaciones concurrentes
    if (_syncInProgress) {
      debugPrint('Sync ya en progreso, omitiendo nueva solicitud');
      return;
    }
    _syncInProgress = true;

    if (mounted) {
      setState(() {
        _isSyncing = true;
      });
    }

    try {
      // Obtener datos locales y de Firestore para comparar
      final localData =
          await _dashboardSyncService.getLocalDashboardData(userId);
      final firestoreData = await _dataUserRepository.getUserData();

      if (localData != null && firestoreData != null) {
        // Comparar tiempos: si local es mayor, sincronizar hacia Firestore
        final localTotalMinutes =
            localData.totalSessionMinutes + localData.currentSessionMinutes;
        final firestoreTotalMinutes =
            firestoreData.totalSessionMinutes +
            firestoreData.currentSessionMinutes;

        if (localTotalMinutes > firestoreTotalMinutes) {
          // Local tiene datos más recientes, sincronizar hacia Firestore
          await _dashboardSyncService.syncToFirestore(userId);
          debugPrint(
            'Sincronizado hacia Firestore: local ($localTotalMinutes min) > Firestore ($firestoreTotalMinutes min)',
          );
        } else if (firestoreTotalMinutes > localTotalMinutes) {
          // Firestore tiene datos más recientes, sincronizar desde Firestore
          await _dashboardSyncService.syncFromFirestore(userId);
          debugPrint(
            'Sincronizado desde Firestore: Firestore ($firestoreTotalMinutes min) > local ($localTotalMinutes min)',
          );
        } else {
          // Datos iguales, solo recargar estadísticas de cursos
          await _dashboardSyncService.syncFromFirestore(userId);
          debugPrint('Datos iguales, recargando estadísticas de cursos');
        }

        // Recargar datos locales después de sincronizar
        final updatedLocalData =
            await _dashboardSyncService.getLocalDashboardData(userId);
        if (updatedLocalData != null && mounted) {
          setState(() {
            _localData = updatedLocalData;
            _totalCourses = updatedLocalData.totalCourses;
            _completedCourses = updatedLocalData.completedCourses;
            _inProgressCourses = updatedLocalData.inProgressCourses;
            _isLoading = false;
          });
        }
      } else {
        // Si no hay datos locales, sincronizar desde Firestore
        final success = await _dashboardSyncService.syncFromFirestore(userId);
        if (success) {
          final newLocalData =
              await _dashboardSyncService.getLocalDashboardData(userId);
          if (newLocalData != null && mounted) {
            setState(() {
              _localData = newLocalData;
              _totalCourses = newLocalData.totalCourses;
              _completedCourses = newLocalData.completedCourses;
              _inProgressCourses = newLocalData.inProgressCourses;
              _isLoading = false;
            });
          }
        }
      }
    } finally {
      _syncInProgress = false;
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _updateLocalSessionTimes(String userId, dynamic userData) async {
    if (_localData == null) return;

    // Recalcular currentSessionMinutes localmente desde sessionStartTime.
    // No usamos userData.currentSessionMinutes porque Firestore lo resetea a 0
    // al iniciar sesión y solo lo actualiza al cerrarla; usar ese valor
    // provocaría que el indicador de "Sesión Actual" siempre muestre 0.
    final DateTime? startTime = userData.sessionStartTime as DateTime?;
    final int currentMins =
        startTime != null
            ? DateTime.now().difference(startTime).inMinutes
            : (_localData!.sessionStartTime != null
                ? DateTime.now()
                    .difference(_localData!.sessionStartTime!)
                    .inMinutes
                : _localData!.currentSessionMinutes);

    // totalSessionMinutes de Firestore contiene solo sesiones anteriores
    // (endSession suma la duración al total y pone currentSessionMinutes = 0).
    // No duplicamos sumando currentSessionMinutes aquí; eso lo hace
    // totalSessionFormatted en DataUserHive.
    final int totalMins = userData.totalSessionMinutes as int;

    final updatedData = DataUserHive(
      userId: _localData!.userId,
      currentSessionMinutes: currentMins,
      totalSessionMinutes: totalMins,
      sessionStartTime: startTime ?? _localData!.sessionStartTime,
      lastSessionEnd: userData.lastSessionEnd ?? _localData!.lastSessionEnd,
      categoryProgress:
          userData.categoryProgress ?? _localData!.categoryProgress,
      overallProgress: userData.overallProgress ?? _localData!.overallProgress,
      unlockedAchievements:
          userData.unlockedAchievements ?? _localData!.unlockedAchievements,
      updatedAt: userData.updatedAt ?? _localData!.updatedAt,
      totalCourses: _localData!.totalCourses,
      completedCourses: _localData!.completedCourses,
      inProgressCourses: _localData!.inProgressCourses,
    );

    await _dashboardSyncService.saveLocalDashboardData(updatedData);

    if (mounted) {
      setState(() {
        _localData = updatedData;
      });
    }
  }

  List<Map<String, dynamic>> _generateAchievements() {
    final achievements = <Map<String, dynamic>>[];
    if (_localData == null) return achievements;

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
      'unlocked': _localData!.totalSessionMinutes >= 600,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mi Dashboard',
                          style: AppStyles.headline1.copyWith(
                            color: Colors.white,
                            fontSize: 28,
                          ),
                        ),
                      ),
                      IconButton(
                        icon:
                            _isSyncing
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Icon(Icons.sync, color: Colors.white),
                        onPressed:
                            _isSyncing
                                ? null
                                : () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final userId = prefs.getString('user_id');
                                  if (userId != null) {
                                    await _syncFromFirestore(userId);
                                  }
                                },
                      ),
                    ],
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
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: const Color(0x0A000000),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A000000),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  Text(
                    '${_localData?.overallProgress.toStringAsFixed(1) ?? '0.0'}%',
                    style: AppStyles.headlineMedium.copyWith(
                      color: const Color(0xFF917CDC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_localData?.overallProgress ?? 0) / 100,
                  backgroundColor: const Color(0xFFF1F4F8),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(_localData?.overallProgress ?? 0),
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
              fontWeight: FontWeight.w600,
              color: const Color(0xFF917CDC),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppStyles.bodyText1.copyWith(
              fontSize: 12,
              color: const Color(0xFF4A5568),
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
              _localData?.currentSessionFormatted ?? '0m',
              Icons.access_time,
              Colors.blue,
            ),
            _buildMetricCard(
              'Tiempo Total',
              _localData?.totalSessionFormatted ?? '0m',
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
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A000000),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                    fontWeight: FontWeight.w600,
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
                    color: const Color(0xFF4A5568),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryProgress() {
    final categoryProgress = _localData?.categoryProgress ?? {};
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A000000),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progreso por Categoría',
                style: AppStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
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
              style: AppStyles.bodyText1.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2D3748),
              ),
            ),
            Text(
              '${progress.toStringAsFixed(0)}%',
              style: AppStyles.bodyText1.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: const Color(0xFFF1F4F8),
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
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A000000),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  Text(
                    '${achievements.where((a) => a['unlocked']).length}/${achievements.length}',
                    style: AppStyles.bodyText1.copyWith(
                      color: const Color(0xFF4A5568),
                    ),
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
                      style: TextStyle(color: Color(0xFF4A5568)),
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
                  : const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked ? achievement['color'] : const Color(0xFFE2E8F0),
            width: isUnlocked ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isUnlocked ? achievement['color'] : const Color(0xFFCBD5E1),
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
                      fontWeight: FontWeight.w600,
                      color:
                          isUnlocked
                              ? const Color(0xFF2D3748)
                              : const Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement['description'],
                    style: AppStyles.bodyText1.copyWith(
                      fontSize: 12,
                      color:
                          isUnlocked
                              ? const Color(0xFF4A5568)
                              : const Color(0xFFA0AEC0),
                    ),
                  ),
                ],
              ),
            ),
            if (isUnlocked)
              const Icon(Icons.check_circle, color: Colors.green, size: 24)
            else
              const Icon(Icons.lock, color: Color(0xFFA0AEC0), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A000000),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF917CDC).withAlpha((0.1 * 255).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.schedule,
                  color: const Color(0xFF917CDC),
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
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Actual: ${_localData?.currentSessionFormatted ?? '0m'} | Total: ${_localData?.totalSessionFormatted ?? '0m'}',
                      style: AppStyles.bodyText1.copyWith(
                        color: const Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

// lib/presentation/screens/admin/admin_reports_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:screenshot/screenshot.dart';

import '../../../core/di/riverpod_providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/usecases/reports/generate_all_users_report_usecase.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  bool _isGenerating = false;
  bool _isLoadingStats = true;
  bool _isLoadingTeachers = true;
  final ScreenshotController _screenshotController = ScreenshotController();
  
  // Filtro de maestro
  String? _selectedTeacherId;
  List<Map<String, String?>> _teachers = [];
  bool _showIndividualReport = false;
  
  // Estadísticas generales
  int _totalUsers = 0;
  int _usersWithProgress = 0;
  int _totalLessonsCompleted = 0;
  final Map<String, int> _lessonsByStatus = {'Completado': 0, 'En Curso': 0, 'No Iniciado': 0};
  final Map<String, int> _usersByWorkArea = {'Urbano': 0, 'Rural': 0};
  final Map<String, int> _usersBySpecialty = {};
  final Map<String, int> _lessonsByCourse = {};
  final Map<String, String> _courseNames = {};
  double _completionRate = 0.0;
  int _activeUsersLast7Days = 0;
  
  // Estadísticas individuales del maestro seleccionado
  int _teacherTotalLessons = 0;
  int _teacherCompletedLessons = 0;
  int _teacherInProgressLessons = 0;
  int _teacherNotStartedLessons = 0;
  double _teacherProgressPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
    _loadStatistics();
    _loadCourseNames();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoadingTeachers = true;
    });

    try {
      final firestore = ref.read(firestoreProvider);
      final usersSnapshot = await firestore.collection('users').get();
      final teachers = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'maestro')
          .map((doc) {
            final data = doc.data();
            return <String, String?>{
              'uid': doc.id,
              'name': data['name'] as String? ?? 'Sin nombre',
              'email': data['email'] as String? ?? '',
              'workArea': data['workArea'] as String?,
              'specialty': data['specialty'] as String?,
            };
          })
          .toList();
      
      // Ordenar alfabéticamente por nombre
      teachers.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      
      setState(() {
        _teachers = teachers;
        _isLoadingTeachers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTeachers = false;
      });
    }
  }

  Future<void> _loadCourseNames() async {
    try {
      final firestore = ref.read(firestoreProvider);
      final coursesSnapshot = await firestore.collection('courses').get();

      _courseNames.clear();
      for (var doc in coursesSnapshot.docs) {
        _courseNames[doc.id] = doc.data()['title'] as String? ?? 'Curso sin nombre';
      }
    } catch (_) {
      // Si falla, continuamos con IDs vacíos
    }
  }

  Future<void> _loadTeacherStatistics(String teacherId) async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final firestore = ref.read(firestoreProvider);
      
      // Obtener progreso del maestro específico
      final progressSnapshot = await firestore
          .collection('userProgress')
          .where('userId', isEqualTo: teacherId)
          .get();
      
      _teacherTotalLessons = progressSnapshot.docs.length;
      _teacherCompletedLessons = 0;
      _teacherInProgressLessons = 0;
      _teacherNotStartedLessons = 0;
      
      for (var doc in progressSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'No Iniciado';
        
        if (status == 'completed') {
          _teacherCompletedLessons++;
        } else if (status == 'inProgress') {
          _teacherInProgressLessons++;
        } else {
          _teacherNotStartedLessons++;
        }
      }
      
      // Calcular porcentaje de progreso
      if (_teacherTotalLessons > 0) {
        _teacherProgressPercentage = (_teacherCompletedLessons / _teacherTotalLessons) * 100;
      }
      
      setState(() {
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final firestore = ref.read(firestoreProvider);
      
      // Obtener todos los usuarios
      final usersSnapshot = await firestore.collection('users').get();
      final users = usersSnapshot.docs.where((doc) => doc.data()['role'] == 'maestro').toList();
      _totalUsers = users.length;
      
      // Contar por área de trabajo
      _usersByWorkArea.clear();
      for (var doc in users) {
        final workArea = doc.data()['workArea'] as String?;
        if (workArea != null) {
          _usersByWorkArea[workArea] = (_usersByWorkArea[workArea] ?? 0) + 1;
        }
      }
      
      // Contar por especialidad
      _usersBySpecialty.clear();
      for (var doc in users) {
        final specialty = doc.data()['specialty'] as String?;
        if (specialty != null && specialty.isNotEmpty) {
          _usersBySpecialty[specialty] = (_usersBySpecialty[specialty] ?? 0) + 1;
        }
      }
      
      // Obtener progreso de usuarios
      final progressSnapshot = await firestore.collection('userProgress').get();
      _usersWithProgress = progressSnapshot.docs.length;
      
      // Calcular usuarios activos en los últimos 7 días
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      _activeUsersLast7Days = progressSnapshot.docs.where((doc) {
        final updatedAt = doc.data()['updatedAt'] as Timestamp?;
        if (updatedAt != null) {
          return updatedAt.toDate().isAfter(sevenDaysAgo);
        }
        return false;
      }).length;
      
      // Contar lecciones por estado y por curso
      _lessonsByStatus.clear();
      _lessonsByCourse.clear();
      for (var doc in progressSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'No Iniciado';
        final courseId = data['courseId'] as String?;
        
        // Mapear el status de Firestore a las claves del mapa
        String mappedStatus;
        switch (status) {
          case 'completed':
            mappedStatus = 'Completado';
            break;
          case 'inProgress':
            mappedStatus = 'En Curso';
            break;
          default:
            mappedStatus = 'No Iniciado';
        }
        
        if (_lessonsByStatus.containsKey(mappedStatus)) {
          _lessonsByStatus[mappedStatus] = (_lessonsByStatus[mappedStatus] ?? 0) + 1;
        }
        
        if (courseId != null) {
          _lessonsByCourse[courseId] = (_lessonsByCourse[courseId] ?? 0) + 1;
        }
        
        if (status == 'completed') {
          _totalLessonsCompleted++;
        }
      }
      
      // Calcular tasa de finalización
      if (_lessonsByStatus.isNotEmpty) {
        final totalLessons = _lessonsByStatus.values.reduce((a, b) => a + b);
        if (totalLessons > 0) {
          _completionRate = (_lessonsByStatus['Completado'] ?? 0) / totalLessons * 100;
        } else {
          _completionRate = 0.0;
        }
      } else {
        _completionRate = 0.0;
      }
      
      // Si no hay datos, inicializar en 0
      if (_lessonsByStatus.isEmpty) {
        _lessonsByStatus['Completado'] = 0;
        _lessonsByStatus['En Curso'] = 0;
        _lessonsByStatus['No Iniciado'] = 0;
      }
      
      setState(() {
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  void _onTeacherChanged(String? teacherId) {
    setState(() {
      _selectedTeacherId = teacherId;
      _showIndividualReport = teacherId != null;
    });
    
    if (teacherId != null) {
      _loadTeacherStatistics(teacherId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes y Estadísticas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de maestro
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtrar por Maestro',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingTeachers)
                      const CircularProgressIndicator()
                    else if (_teachers.isEmpty)
                      const Text('No hay maestros disponibles')
                    else
                      DropdownButtonFormField<String>(
                      initialValue: _selectedTeacherId,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar maestro',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_search),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Ver estadísticas generales'),
                        ),
                        ..._teachers.map((teacher) {
                          return DropdownMenuItem<String>(
                            value: teacher['uid'] as String,
                            child: Text(teacher['name'] as String),
                          );
                        }),
                      ],
                      onChanged: _onTeacherChanged,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_showIndividualReport)
              _buildIndividualTeacherReport()
            else
              _buildGeneralReport(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas Generales',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'Visualización del progreso de todos los maestros en las microformaciones.',
        ),
        const SizedBox(height: 24),

        if (_isLoadingStats)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando estadísticas...'),
              ],
            ),
          )
        else
          Screenshot(
            controller: _screenshotController,
            child: _buildStatisticsCharts(),
          ),
        
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 24),

        Text(
          'Generar Reporte PDF',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'Descarga un reporte PDF completo con las estadísticas y gráficas.',
        ),
        const SizedBox(height: 24),

        if (_isGenerating)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando reporte...'),
              ],
            ),
          )
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Descargar reporte con gráficas'),
            onPressed: () => _generateReportWithCharts(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIndividualTeacherReport() {
    final selectedTeacher = _teachers.firstWhere(
      (t) => t['uid'] == _selectedTeacherId,
      orElse: () => <String, String?>{'uid': '', 'name': 'Maestro no encontrado', 'email': '', 'workArea': ''},
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _onTeacherChanged(null),
            ),
            Expanded(
              child: Text(
                'Reporte de: ${selectedTeacher['name'] ?? 'Maestro'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (selectedTeacher['email'] != null)
          Text(
            'Email: ${selectedTeacher['email']}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        if (selectedTeacher['workArea'] != null)
          Text(
            'Área: ${selectedTeacher['workArea']}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        const SizedBox(height: 24),

        if (_isLoadingStats)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando estadísticas del maestro...'),
              ],
            ),
          )
        else
          _buildTeacherStatisticsCharts(),
        
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 24),

        Text(
          'Generar Reporte PDF Individual',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'Descarga un reporte PDF individual con las estadísticas del maestro.',
        ),
        const SizedBox(height: 24),

        if (_isGenerating)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generando reporte...'),
              ],
            ),
          )
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Descargar reporte individual'),
            onPressed: () => _generateIndividualReport(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatisticsCharts() {
    final topCourseValues = _lessonsByCourse.values.toList()..sort((a, b) => b.compareTo(a));
    final maxCourseLessons = topCourseValues.isEmpty
        ? 0
        : topCourseValues.take(5).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        // Tarjetas de estadísticas - Primera fila
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Total Usuarios', _totalUsers.toString(), Icons.people),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Con Progreso', _usersWithProgress.toString(), Icons.trending_up),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Lecciones Completadas', _totalLessonsCompleted.toString(), Icons.check_circle),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Tarjetas de estadísticas - Segunda fila
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Tasa Finalización', '${_completionRate.toStringAsFixed(1)}%', Icons.percent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Activos (7 días)', _activeUsersLast7Days.toString(), Icons.calendar_today),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Especialidades', _usersBySpecialty.length.toString(), Icons.school),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Gráfica de distribución de participación de maestros
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Participación de Maestros en Microformaciones',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Proporción de maestros con lecciones iniciadas o completadas frente a sin actividad.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Builder(
                    builder: (context) {
                      final withProgress = _usersWithProgress;
                      final withoutProgress = (_totalUsers - _usersWithProgress) > 0
                          ? (_totalUsers - _usersWithProgress)
                          : 0;

                      return PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(
                              value: withProgress.toDouble(),
                              title: withProgress > 0 ? '$withProgress' : '',
                              color: AppColors.primaryBlue,
                              radius: 50,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            PieChartSectionData(
                              value: withoutProgress.toDouble(),
                              title: withoutProgress > 0 ? '$withoutProgress' : '',
                              color: Colors.blueGrey.shade300,
                              radius: 50,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegend('Con Progreso', AppColors.primaryBlue),
                    _buildLegend('Sin Actividad', Colors.blueGrey.shade300),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Gráfica de barras para área de trabajo
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuarios por Área de Trabajo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: ([_usersByWorkArea['Urbano'] ?? 0, _usersByWorkArea['Rural'] ?? 0]
                              .reduce((a, b) => a > b ? a : b) + 5)
                          .toDouble(),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: (_usersByWorkArea['Urbano'] ?? 0).toDouble(),
                              color: AppColors.primaryColor,
                              width: 20,
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: (_usersByWorkArea['Rural'] ?? 0).toDouble(),
                              color: Colors.green,
                              width: 20,
                            ),
                          ],
                        ),
                      ],
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final label = value == 0 ? 'Urbano' : 'Rural';
                              return Text(
                                label,
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const Text('');
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Gráfica de barras para distribución por especialidad
        if (_usersBySpecialty.isNotEmpty)
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usuarios por Especialidad',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _usersBySpecialty.values.reduce((a, b) => a > b ? a : b).toDouble() + 2,
                        barGroups: List.generate(
                          _usersBySpecialty.keys.length,
                          (index) {
                            final key = _usersBySpecialty.keys.elementAt(index);
                            final value = _usersBySpecialty[key] ?? 0;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: value.toDouble(),
                                  color: Colors.primaries[index % Colors.primaries.length],
                                  width: 20,
                                ),
                              ],
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < _usersBySpecialty.keys.length) {
                                  final key = _usersBySpecialty.keys.elementAt(index);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      key.length > 10 ? '${key.substring(0, 10)}...' : key,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const Text('');
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),

        // Gráfica de barras para lecciones por curso (top 5)
        if (_lessonsByCourse.isNotEmpty)
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lecciones por Curso (Top 5)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxCourseLessons.toDouble() + 2,
                        barGroups: List.generate(
                          _lessonsByCourse.keys.length > 5 ? 5 : _lessonsByCourse.keys.length,
                          (index) {
                            final sortedEntries = _lessonsByCourse.entries.toList()
                              ..sort((a, b) => b.value.compareTo(a.value));
                            final entry = sortedEntries[index];
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.toDouble(),
                                  color: Colors.teal,
                                  width: 20,
                                ),
                              ],
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < 5) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const Text('');
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Leyenda de cursos
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < 5 && i < _lessonsByCourse.keys.length; i++)
                      _buildCourseLegend(i),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCourseLegend(int index) {
    final sortedEntries = _lessonsByCourse.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (index >= sortedEntries.length) return const SizedBox.shrink();
    
    final courseId = sortedEntries[index].key;
    final courseName = _courseNames[courseId] ?? 'Curso desconocido';
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          courseName.length > 20 ? '${courseName.substring(0, 20)}...' : courseName,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTeacherStatisticsCharts() {
    return Column(
      children: [
        // Tarjetas de estadísticas del maestro
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Total Lecciones', _teacherTotalLessons.toString(), Icons.book),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Completadas', _teacherCompletedLessons.toString(), Icons.check_circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Progreso', '${_teacherProgressPercentage.toStringAsFixed(1)}%', Icons.trending_up),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Gráfica de pie para estado de lecciones del maestro
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de Lecciones del Maestro',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: _teacherCompletedLessons.toDouble(),
                          title: '$_teacherCompletedLessons',
                          color: AppColors.successColor,
                          radius: 50,
                        ),
                        PieChartSectionData(
                          value: _teacherInProgressLessons.toDouble(),
                          title: '$_teacherInProgressLessons',
                          color: Colors.orange,
                          radius: 50,
                        ),
                        PieChartSectionData(
                          value: _teacherNotStartedLessons.toDouble(),
                          title: '$_teacherNotStartedLessons',
                          color: Colors.grey,
                          radius: 50,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegend('Completado', AppColors.successColor),
                    _buildLegend('En Curso', Colors.orange),
                    _buildLegend('No Iniciado', Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateIndividualReport(BuildContext context) async {
    if (_selectedTeacherId == null) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    final auth = ref.read(authStateProvider);
    if (auth.currentUser?.role != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para realizar esta acción.'),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final usecase = ref.read(generateAllUsersReportUsecaseProvider);
      final filePath = await usecase.call(_selectedTeacherId);

      if (!mounted) return;

      setState(() {
        _isGenerating = false;
      });

      await OpenFilex.open(filePath);

      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            'Reporte individual generado y abierto exitosamente.\nGuardado en: $filePath',
          ),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isGenerating = false;
      });

      messenger?.showSnackBar(
        SnackBar(
          content: Text('Error al generar el reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateReportWithCharts(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final auth = ref.read(authStateProvider);
    if (auth.currentUser?.role != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para realizar esta acción.'),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final usecase = ref.read(generateAllUsersReportUsecaseProvider);
      final filePath = await usecase.call(NoParams());

      if (!mounted) return;

      setState(() {
        _isGenerating = false;
      });

      await OpenFilex.open(filePath);

      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            'Reporte generado y abierto exitosamente.\nGuardado en: $filePath',
          ),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isGenerating = false;
      });

      messenger?.showSnackBar(
        SnackBar(
          content: Text('Error al generar el reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

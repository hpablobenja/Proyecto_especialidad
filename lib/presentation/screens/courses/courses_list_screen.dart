import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/course_provider.dart';
import '../../widgets/course_card.dart';
import '../../widgets/app_drawer.dart';

class CoursesListScreen extends StatefulWidget {
  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  String _selectedAudience = 'Todos';
  final List<String> _audiences = [
    'Todos',
    'Inicial',
    'Primaria',
    'Secundaria',
    'Alternativa',
    'Otro(Especificar)',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedFilter();
    // Cargar los cursos una sola vez al entrar a la pantalla
    Future.microtask(() => context.read<CourseProvider>().loadCourses());
  }

  Future<void> _loadSavedFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFilter = prefs.getString('selected_audience_filter');
    if (savedFilter != null && _audiences.contains(savedFilter)) {
      setState(() {
        _selectedAudience = savedFilter;
      });
    }
  }

  Future<void> _saveFilter(String filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_audience_filter', filter);
  }

  Future<void> _onRefresh() async {
    await context.read<CourseProvider>().loadCourses();
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    for (var c in courseProvider.courses) {
      print('Course: ${c.title}, audience: ${c.targetAudience}');
    }

    final filteredCourses =
        _selectedAudience == 'Todos'
            ? courseProvider.courses
            : courseProvider.courses
                .where(
                  (c) =>
                      c.targetAudience.trim().toLowerCase() ==
                      _selectedAudience.trim().toLowerCase(),
                )
                .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Microformaciones')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Chip-based filter instead of dropdown
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                  child: Text(
                    'Filtrar por público:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        _audiences.map((audience) {
                          final isSelected = _selectedAudience == audience;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(audience),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedAudience = audience;
                                });
                                _saveFilter(audience);
                              },
                              selectedColor: Colors.green.shade100,
                              checkmarkColor: Colors.green.shade700,
                              labelStyle: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.green.shade900
                                        : Colors.black87,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                              backgroundColor: Colors.grey.shade200,
                              elevation: isSelected ? 2 : 0,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child:
                  courseProvider.isLoading
                      ? ListView(
                        children: const [
                          SizedBox(height: 300),
                          Center(child: CircularProgressIndicator()),
                        ],
                      )
                      : filteredCourses.isEmpty
                      ? ListView(
                        children: const [
                          SizedBox(height: 300),
                          Center(
                            child: Text('No hay microformaciones disponibles.'),
                          ),
                        ],
                      )
                      : ListView.builder(
                        itemCount: filteredCourses.length,
                        itemBuilder: (context, index) {
                          final course = filteredCourses[index];
                          return CourseCard(course: course);
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

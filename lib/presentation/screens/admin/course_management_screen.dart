// lib/presentation/screens/admin/course_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../providers/course_provider.dart';
import '../../../domain/usecases/courses/create_course_usecase.dart'; // Importar el use case
import '../../widgets/app_drawer.dart';
import '../../providers/content_provider.dart';
import 'course_content_screen.dart';
import '../../../domain/entities/course_entity.dart';

class CourseManagementScreen extends StatefulWidget {
  @override
  _CourseManagementScreenState createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedTargetAudience = 'Ciencias Naturales';
  final List<String> _targetAudiences = [
    'Ciencias Sociales',
    'Ciencias Naturales',
    'Comunicación y Lenguaje',
    'Alternativa',
    'Otro(Especificar)',
  ];

  void _createCourse() async {
    if (_formKey.currentState!.validate()) {
      // Accede al use case de creación a través del inyector de dependencias
      // En una aplicación real, el provider manejaría esta lógica.
      // Para este ejemplo, lo hacemos directamente para mantener la simplicidad.
      final createCourseUsecase =
          Provider.of<CourseProvider>(
            context,
            listen: false,
          ).createCourseUsecase;

      try {
        await createCourseUsecase.call(
          CreateCourseParams(
            title: _titleController.text,
            description: _descriptionController.text,
            targetAudience: _selectedTargetAudience,
          ),
        );
        // Muestra una notificación de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microformación creada exitosamente.'),
            backgroundColor: AppColors.successColor,
          ),
        );
        // Limpia el formulario
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedTargetAudience = 'Inicial';
        });
        // Recarga la lista de cursos para reflejar el cambio
        Provider.of<CourseProvider>(context, listen: false).loadCourses();
        // Recarga ContentProvider para actualizar la UI automáticamente
        Provider.of<ContentProvider>(context, listen: false).loadCourses();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la microformación: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Cargar cursos existentes para gestionarlos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ContentProvider>(context, listen: false).loadCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestionar Cursos',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Crear Nueva Microformación',
                style: AppStyles.headline1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título del Curso',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese un título.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción del Curso',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese una descripción.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTargetAudience,
                decoration: InputDecoration(
                  labelText: 'Público Objetivo',
                  border: OutlineInputBorder(),
                ),
                items:
                    _targetAudiences.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedTargetAudience = newValue!;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _createCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(Icons.add),
                label: Text(
                  'Crear Microformación',
                  style: AppStyles.buttonText,
                ),
              ),

              const SizedBox(height: 32),
              Text(
                'Microformaciones existentes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Consumer<ContentProvider>(
                builder: (context, content, _) {
                  if (content.isLoading && content.courses.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (content.errorMessage != null) {
                    return Text(
                      content.errorMessage!,
                      style: TextStyle(color: AppColors.errorColor),
                    );
                  }
                  if (content.courses.isEmpty) {
                    return const Text('No hay microformaciones aún.');
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: content.courses.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final c = content.courses[index];
                      return ListTile(
                        leading: const Icon(Icons.menu_book_outlined),
                        title: Text(
                          c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          c.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _editCourse(context, c);
                                break;
                              case 'delete':
                                _deleteCourse(context, c);
                                break;
                              case 'manage':
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => CourseContentScreen(
                                          courseId: c.id,
                                          courseTitle: c.title,
                                        ),
                                  ),
                                );
                                break;
                            }
                          },
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'manage',
                                  child: ListTile(
                                    leading: Icon(Icons.folder_open),
                                    title: Text('Gestionar contenido'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Editar curso'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete_outline),
                                    title: Text('Eliminar curso'),
                                  ),
                                ),
                              ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editCourse(BuildContext context, CourseEntity course) async {
    final titleCtrl = TextEditingController(text: course.title);
    final descCtrl = TextEditingController(text: course.description);
    String selectedAudience =
        course.targetAudience.isEmpty
            ? 'Otro(Especificar)'
            : course.targetAudience;
    // Ensure the selected audience is in the list, otherwise default to 'Otro(Especificar)'
    if (!_targetAudiences.contains(selectedAudience)) {
      selectedAudience = 'Otro(Especificar)';
    }

    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Editar curso'),
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
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                        ),
                        minLines: 2,
                        maxLines: 5,
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedAudience,
                        decoration: InputDecoration(
                          labelText: 'Público Objetivo',
                        ),
                        items:
                            _targetAudiences.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedAudience = newValue!;
                          });
                        },
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
              );
            },
          ),
    );

    if (ok != true) return;

    final updated = CourseEntity(
      id: course.id,
      title: titleCtrl.text.trim(),
      description: descCtrl.text.trim(),
      targetAudience: selectedAudience,
    );

    final contentProvider = Provider.of<ContentProvider>(
      context,
      listen: false,
    );
    final res = await contentProvider.updateCourse(updated);
    if (res == null && contentProvider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(contentProvider.errorMessage!)));
    }
  }

  Future<void> _deleteCourse(BuildContext context, CourseEntity course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar curso'),
            content: Text(
              '¿Eliminar "${course.title}"? Esta acción no se puede deshacer.',
            ),
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

    final contentProvider = Provider.of<ContentProvider>(
      context,
      listen: false,
    );
    final ok = await contentProvider.deleteCourse(course.id);
    if (!ok && contentProvider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(contentProvider.errorMessage!)));
    }
  }
}

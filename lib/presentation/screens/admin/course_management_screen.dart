// lib/presentation/screens/admin/course_management_screen.dart

import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/di/riverpod_providers.dart';
import '../../../data/models/lesson_import_model.dart';
import '../../../data/models/quiz_import_model.dart';
import '../../../domain/usecases/courses/create_course_usecase.dart'; // Importar el use case
import '../../../core/services/excel_import_service.dart';
import '../../widgets/app_drawer.dart';
import 'course_content_screen.dart';
import '../../../domain/entities/course_entity.dart';
import '../../../data/repositories/notification_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/validation_utils.dart';

class CourseManagementScreen extends ConsumerStatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  ConsumerState<CourseManagementScreen> createState() =>
      _CourseManagementScreenState();
}

class _CourseManagementScreenState
    extends ConsumerState<CourseManagementScreen> {
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
  String _statusFilter = 'all'; // 'all', 'published', 'draft'

  void _createCourse() async {
    if (_formKey.currentState!.validate()) {
      // Accede al use case de creación a través del inyector de dependencias
      // En una aplicación real, el provider manejaría esta lógica.
      // Para este ejemplo, lo hacemos directamente para mantener la simplicidad.
      final createCourseUsecase = ref.read(createCourseUsecaseProvider);

      try {
        await createCourseUsecase.call(
          CreateCourseParams(
            title: _titleController.text,
            description: _descriptionController.text,
            targetAudience: _selectedTargetAudience,
          ),
        );

        // Muestra una notificación de éxito
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Microformación creada como borrador. Completa el contenido antes de publicarla.',
              ),
              backgroundColor: AppColors.successColor,
            ),
          );
        }
        // Limpia el formulario
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedTargetAudience = 'Ciencias Naturales';
        });
        // Recarga la lista de cursos para reflejar el cambio
        ref.read(courseStateProvider).loadCourses();
        // Recarga ContentProvider para actualizar la UI automáticamente
        ref.read(contentStateProvider).loadCourses();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear la microformación: $e'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Cargar cursos existentes para gestionarlos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contentStateProvider).loadCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentStateProvider);
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
                decoration: const InputDecoration(
                  labelText: 'Título del Curso',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) => ValidationUtils.validateRequiredTextWithLetters(
                      value,
                      fieldName: 'El título del curso',
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción del Curso',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator:
                    (value) => ValidationUtils.validateRequiredTextWithLetters(
                      value,
                      fieldName: 'La descripción del curso',
                    ),
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
              Column(
                children: [
                  // Botón Crear Microformación ocupando toda la fila
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createCourse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(
                        'Crear Microformación',
                        style: AppStyles.buttonText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12, height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _importFromExcel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(Icons.file_upload),
                          label: Text(
                            'Importar Excel',
                            style: AppStyles.buttonText.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _downloadTemplate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(Icons.download),
                          label: Text(
                            'Descargar Plantilla',
                            style: AppStyles.buttonText.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Microformaciones',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${content.courses.length} en total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Filtro rápido de estado
              Builder(
                builder: (context) {
                  final publishedCount =
                      content.courses
                          .where((c) => c.status == 'published')
                          .length;
                  final draftCount =
                      content.courses
                          .where((c) => c.status != 'published')
                          .length;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text('Todos (${content.courses.length})'),
                          selected: _statusFilter == 'all',
                          selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                          checkmarkColor: AppColors.primaryBlue,
                          labelStyle: TextStyle(
                            fontWeight:
                                _statusFilter == 'all'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                _statusFilter == 'all'
                                    ? AppColors.primaryBlue
                                    : null,
                          ),
                          onSelected:
                              (_) => setState(() => _statusFilter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          avatar: const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          label: Text('Publicados ($publishedCount)'),
                          selected: _statusFilter == 'published',
                          selectedColor: Colors.green.withOpacity(0.2),
                          checkmarkColor: Colors.green.shade800,
                          labelStyle: TextStyle(
                            fontWeight:
                                _statusFilter == 'published'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                _statusFilter == 'published'
                                    ? Colors.green.shade900
                                    : null,
                          ),
                          onSelected:
                              (_) =>
                                  setState(() => _statusFilter = 'published'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          avatar: const Icon(
                            Icons.edit_note,
                            size: 16,
                            color: Colors.orange,
                          ),
                          label: Text('Borradores ($draftCount)'),
                          selected: _statusFilter == 'draft',
                          selectedColor: Colors.orange.withOpacity(0.2),
                          checkmarkColor: Colors.orange.shade800,
                          labelStyle: TextStyle(
                            fontWeight:
                                _statusFilter == 'draft'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                _statusFilter == 'draft'
                                    ? Colors.orange.shade900
                                    : null,
                          ),
                          onSelected:
                              (_) => setState(() => _statusFilter = 'draft'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (content.isLoading && content.courses.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (content.errorMessage != null)
                Text(
                  content.errorMessage!,
                  style: TextStyle(color: AppColors.errorColor),
                )
              else if (content.courses.isEmpty)
                const Text('No hay microformaciones aún.')
              else
                Builder(
                  builder: (context) {
                    final filteredCourses =
                        content.courses.where((c) {
                          if (_statusFilter == 'published')
                            return c.status == 'published';
                          if (_statusFilter == 'draft')
                            return c.status != 'published';
                          return true;
                        }).toList();

                    if (filteredCourses.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            _statusFilter == 'published'
                                ? 'No hay cursos publicados todavía.'
                                : 'No hay cursos en borrador.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredCourses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final c = filteredCourses[index];
                        final isPublished = c.status == 'published';
                        final isDraft = !isPublished;

                        return Card(
                          elevation: isPublished ? 2 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color:
                                  isPublished
                                      ? Colors.green.withOpacity(0.5)
                                      : Colors.orange.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors:
                                    isPublished
                                        ? [
                                          Colors.green.withOpacity(0.04),
                                          Colors.white,
                                        ]
                                        : [
                                          Colors.orange.withOpacity(0.04),
                                          Colors.white,
                                        ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            isPublished
                                                ? Colors.green.withOpacity(0.12)
                                                : Colors.orange.withOpacity(
                                                  0.12,
                                                ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isPublished
                                            ? Icons.check_circle
                                            : Icons.edit_note,
                                        color:
                                            isPublished
                                                ? Colors.green.shade700
                                                : Colors.orange.shade800,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            c.description,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
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
                                          case 'publish':
                                            _publishCourse(context, c);
                                            break;
                                          case 'unpublish':
                                            _unpublishCourse(context, c);
                                            break;
                                        }
                                      },
                                      itemBuilder:
                                          (context) => [
                                            const PopupMenuItem(
                                              value: 'manage',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.folder_open,
                                                ),
                                                title: Text(
                                                  'Gestionar contenido',
                                                ),
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.edit_outlined,
                                                ),
                                                title: Text('Editar curso'),
                                              ),
                                            ),
                                            if (isDraft)
                                              const PopupMenuItem(
                                                value: 'publish',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.publish,
                                                    color: Colors.green,
                                                  ),
                                                  title: Text(
                                                    'Publicar curso',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (isPublished)
                                              const PopupMenuItem(
                                                value: 'unpublish',
                                                child: ListTile(
                                                  leading: Icon(
                                                    Icons.unpublished,
                                                    color: Colors.orange,
                                                  ),
                                                  title: Text(
                                                    'Despublicar curso',
                                                    style: TextStyle(
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                ),
                                                title: Text(
                                                  'Eliminar curso',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isPublished
                                                ? Colors.green.withOpacity(0.15)
                                                : Colors.orange.withOpacity(
                                                  0.15,
                                                ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              isPublished
                                                  ? Colors.green.shade400
                                                  : Colors.orange.shade400,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isPublished
                                                ? Icons.check_circle
                                                : Icons.pending_outlined,
                                            size: 14,
                                            color:
                                                isPublished
                                                    ? Colors.green.shade800
                                                    : Colors.orange.shade900,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            isPublished
                                                ? 'PUBLICADO'
                                                : 'BORRADOR',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  isPublished
                                                      ? Colors.green.shade900
                                                      : Colors.orange.shade900,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (c.targetAudience.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          c.targetAudience,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
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
                                ValidationUtils.validateRequiredTextWithLetters(
                                  v,
                                  fieldName: 'El título',
                                ),
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
                                ValidationUtils.validateRequiredTextWithLetters(
                                  v,
                                  fieldName: 'La descripción',
                                ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedAudience,
                        decoration: const InputDecoration(
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
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context, true);
                      }
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

    final contentProvider = ref.read(contentStateProvider);
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

    final contentProvider = ref.read(contentStateProvider);
    final ok = await contentProvider.deleteCourse(course.id);
    if (!ok && contentProvider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(contentProvider.errorMessage!)));
    }
  }

  Future<void> _publishCourse(BuildContext context, CourseEntity course) async {
    // Validar que el curso tenga contenido completo antes de publicar
    final firestore = FirebaseFirestore.instance;

    try {
      final missingRequirements = <String>[];

      // 1. Validar curso (título y descripción con letras)
      final hasLettersInCourseTitle = RegExp(
        r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]',
      ).hasMatch(course.title.trim());
      if (course.title.trim().isEmpty || !hasLettersInCourseTitle) {
        missingRequirements.add(
          '• Curso: El título es obligatorio y debe contener letras.',
        );
      }
      final hasLettersInCourseDesc = RegExp(
        r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]',
      ).hasMatch(course.description.trim());
      if (course.description.trim().isEmpty || !hasLettersInCourseDesc) {
        missingRequirements.add(
          '• Curso: La descripción es obligatoria y debe contener letras.',
        );
      }

      // 2. Obtener módulos del curso
      var modulesSnapshot =
          await firestore
              .collection('courses')
              .doc(course.id)
              .collection('modules')
              .get();

      if (modulesSnapshot.docs.isEmpty) {
        modulesSnapshot =
            await firestore
                .collection('modules')
                .where('courseId', isEqualTo: course.id)
                .get();
      }

      if (modulesSnapshot.docs.isEmpty) {
        missingRequirements.add(
          '• Módulos: El curso no tiene módulos creados. Debe crear al menos un módulo.',
        );
      }

      for (var moduleDoc in modulesSnapshot.docs) {
        final moduleId = moduleDoc.id;
        final moduleData = moduleDoc.data();
        final modTitle = (moduleData['title'] as String? ?? '').trim();
        final modDesc = (moduleData['description'] as String? ?? '').trim();

        final modName = modTitle.isNotEmpty ? modTitle : 'Módulo';

        // Validar título y descripción del módulo
        if (modTitle.isEmpty ||
            !RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]').hasMatch(modTitle)) {
          missingRequirements.add(
            '• Módulo "$modName": El título es obligatorio y debe contener letras.',
          );
        }
        if (modDesc.isEmpty ||
            !RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]').hasMatch(modDesc)) {
          missingRequirements.add(
            '• Módulo "$modName": La descripción es obligatoria y debe contener letras.',
          );
        }

        // Obtener lecciones del módulo
        var lessonsSnapshot =
            await firestore
                .collection('lessons')
                .where('courseId', isEqualTo: course.id)
                .where('moduleId', isEqualTo: moduleId)
                .get();

        if (lessonsSnapshot.docs.isEmpty) {
          lessonsSnapshot =
              await firestore
                  .collection('courses')
                  .doc(course.id)
                  .collection('modules')
                  .doc(moduleId)
                  .collection('lessons')
                  .get();
        }

        if (lessonsSnapshot.docs.isEmpty) {
          lessonsSnapshot =
              await firestore
                  .collection('lessons')
                  .where('courseId', isEqualTo: course.id)
                  .where('moduleId', isEqualTo: moduleId)
                  .get();
        }

        if (lessonsSnapshot.docs.isEmpty) {
          missingRequirements.add(
            '• Módulo "$modName": No tiene lecciones creadas.',
          );
          continue;
        }

        // Verificar cada lección
        for (var lessonDoc in lessonsSnapshot.docs) {
          final lessonData = lessonDoc.data();
          final lessonTitle = (lessonData['title'] as String? ?? '').trim();
          final lessonObj = (lessonData['objectives'] as String? ?? '').trim();
          final lessonLabel =
              lessonTitle.isNotEmpty ? lessonTitle : 'Lección sin título';

          // Título de la lección
          if (lessonTitle.isEmpty ||
              !RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]').hasMatch(lessonTitle)) {
            missingRequirements.add(
              '• Módulo "$modName" ➔ Lección "$lessonLabel": El título es obligatorio y debe contener letras.',
            );
          }

          // Objetivos de la lección
          if (lessonObj.isEmpty ||
              !RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]').hasMatch(lessonObj)) {
            missingRequirements.add(
              '• Módulo "$modName" ➔ Lección "$lessonLabel": Los objetivos son obligatorios y deben contener letras.',
            );
          }

          // Video
          final media = lessonData['media'] as List<dynamic>? ?? [];
          final hasVideo = media.isNotEmpty;
          if (!hasVideo) {
            missingRequirements.add(
              '• Módulo "$modName" ➔ Lección "$lessonLabel": Falta agregar video.',
            );
          } else {
            // Verificar si algún video supera los 16 minutos (960 segundos)
            for (var m in media) {
              if (m is Map) {
                final durationSecs =
                    (m['durationSeconds'] as num?)?.toInt() ??
                    (m['metadata'] is Map
                        ? ((m['metadata']['durationSeconds'] as num?)?.toInt())
                        : null);
                if (durationSecs != null && durationSecs > 16 * 60) {
                  final mins = (durationSecs / 60).floor();
                  final secs = durationSecs % 60;
                  missingRequirements.add(
                    '• Módulo "$modName" ➔ Lección "$lessonLabel": El video supera los 16 minutos permitidos ($mins:${secs.toString().padLeft(2, '0')} min).',
                  );
                }
              }
            }
          }

          // Cuestionario
          final quizSnapshot =
              await firestore
                  .collection('quizzes')
                  .where('lessonId', isEqualTo: lessonDoc.id)
                  .get();

          if (quizSnapshot.docs.isEmpty) {
            missingRequirements.add(
              '• Módulo "$modName" ➔ Lección "$lessonLabel": Falta crear cuestionario.',
            );
          }

          // Estrategias
          final rawStrategies =
              lessonData['strategies'] as List<dynamic>? ?? [];
          if (rawStrategies.isEmpty) {
            missingRequirements.add(
              '• Módulo "$modName" ➔ Lección "$lessonLabel": Falta crear estrategias.',
            );
          }
        }
      }

      // Si falta algo, mostrar ventana flotante con los pendientes
      if (missingRequirements.isNotEmpty) {
        if (!context.mounted) return;
        await showDialog(
          context: context,
          builder:
              (dialogCtx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Requisitos pendientes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No se puede publicar el curso porque faltan los siguientes elementos requeridos:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...missingRequirements.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Text(
                              item,
                              style: const TextStyle(fontSize: 13, height: 1.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        );
        return;
      }

      // Confirmar publicación
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Publicar curso'),
              content: Text(
                '¿Estás seguro de publicar "${course.title}"? Una vez publicado, será visible para todos los maestros.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Publicar'),
                ),
              ],
            ),
      );

      if (confirm != true) return;

      // Actualizar estado a published
      final repository = ref.read(courseRepositoryProvider);
      final success = await repository.updateCourseStatus(
        course.id,
        'published',
      );

      if (success) {
        // Crear notificaciones para todos los usuarios maestros
        final notificationRepository = NotificationRepository();
        final usersSnapshot = await firestore.collection('users').get();
        for (var userDoc in usersSnapshot.docs) {
          if (userDoc.data()['role'] == 'maestro') {
            final existingNotification =
                await firestore
                    .collection('notifications')
                    .where('userId', isEqualTo: userDoc.id)
                    .where('courseId', isEqualTo: course.id)
                    .where('type', isEqualTo: 'new_course')
                    .get();

            if (existingNotification.docs.isEmpty) {
              await notificationRepository.createNotification(
                userId: userDoc.id,
                title: '🎓 Nuevo Curso Disponible',
                body: 'Se ha publicado un nuevo curso: ${course.title}',
                type: 'new_course',
                courseId: course.id,
              );
            }
          }
        }

        ref.read(contentStateProvider).loadCourses();
        ref.read(courseStateProvider).loadCourses();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Curso publicado exitosamente.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al publicar el curso.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _unpublishCourse(
    BuildContext context,
    CourseEntity course,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Despublicar curso'),
            content: Text(
              '¿Estás seguro de despublicar "${course.title}"? Ya no será visible para los maestros.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Despublicar'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final repository = ref.read(courseRepositoryProvider);
      final success = await repository.updateCourseStatus(course.id, 'draft');

      if (success) {
        ref.read(contentStateProvider).loadCourses();
        ref.read(courseStateProvider).loadCourses();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Curso despublicado exitosamente.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al despublicar el curso.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String? _extractYouTubeVideoId(String url) {
    final u = url.trim();
    final patterns = <RegExp>[
      RegExp(r'^https?:\/\/(?:www\.)?youtu\.be\/([A-Za-z0-9_-]{11})'),
      RegExp(r'^https?:\/\/(?:www\.)?youtube\.com\/watch\?v=([A-Za-z0-9_-]{11})'),
      RegExp(r'^https?:\/\/(?:www\.)?youtube\.com\/embed\/([A-Za-z0-9_-]{11})'),
      RegExp(r'^https?:\/\/(?:www\.)?youtube\.com\/shorts\/([A-Za-z0-9_-]{11})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(u);
      if (m != null) return m.group(1);
    }
    final uri = Uri.tryParse(u);
    if (uri != null) {
      final v = uri.queryParameters['v'];
      if (v != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(v)) return v;
    }
    return null;
  }

  Future<void> _importFromExcel() async {
    final excelService = ExcelImportService();
    final firestore = FirebaseFirestore.instance;

    try {
      // Mostrar diálogo de carga
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Leyendo archivo Excel...'),
                    ],
                  ),
                ),
              ),
            ),
      );

      final result = await excelService.importFromExcel();

      // Cerrar diálogo de carga
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (result == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se seleccionó ningún archivo'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (result.hasErrors) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Errores en la importación'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: result.errors.map((e) => Text('• $e')).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
          );
        }
        return;
      }

      if (result.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El archivo Excel no contiene datos válidos'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Mostrar resumen de lo que se va a importar
      final confirmImport = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Confirmar importación'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Se importarán:'),
                  const SizedBox(height: 8),
                  Text('• ${result.courses.length} curso(s)'),
                  Text('• ${result.modules.length} módulo(s)'),
                  Text('• ${result.lessons.length} lección(es)'),
                  if (result.strategies.isNotEmpty)
                    Text('• ${result.strategies.length} estrategia(s)'),
                  if (result.quizzes.isNotEmpty)
                    Text('• ${result.quizzes.length} cuestionario(s)'),
                  if (result.questions.isNotEmpty)
                    Text('• ${result.questions.length} pregunta(s)'),
                  const SizedBox(height: 16),
                  const Text(
                    '¿Desea continuar?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Importar'),
                ),
              ],
            ),
      );

      if (confirmImport != true) return;

      // Mostrar diálogo de progreso
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Guardando en base de datos...'),
                    ],
                  ),
                ),
              ),
            ),
      );

      // 1. Organizar estrategias por ID de lección
      final strategiesByLessonId = <String, List<Map<String, String>>>{};
      for (final strat in result.strategies) {
        final lessonKey = strat.lessonId.trim();
        if (lessonKey.isNotEmpty) {
          strategiesByLessonId.putIfAbsent(lessonKey, () => []).add({
            'title': strat.title.trim(),
            'description': strat.description.trim(),
          });
        }
      }

      // 2. Procesar cursos
      final courseIdMap = <String, String>{};
      for (final courseImport in result.courses) {
        final courseRef = await firestore.collection('courses').add({
          'title': courseImport.title.trim(),
          'description': courseImport.description.trim(),
          'targetAudience': courseImport.targetAudience,
          'status': courseImport.status,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (courseImport.id.isNotEmpty) {
          courseIdMap[courseImport.id.trim()] = courseRef.id;
        }
      }

      // Fallback para cursos únicos si no viniera ID
      String? defaultCourseFirestoreId;
      if (courseIdMap.length == 1) {
        defaultCourseFirestoreId = courseIdMap.values.first;
      }

      // 3. Procesar módulos (únicamente en la subcolección courses/{courseId}/modules)
      final moduleIdMap = <String, String>{};
      for (final moduleImport in result.modules) {
        final rawCourseId = moduleImport.courseId.trim();
        final realCourseId =
            courseIdMap[rawCourseId] ?? defaultCourseFirestoreId ?? rawCourseId;

        final moduleData = {
          'courseId': realCourseId,
          'title': moduleImport.title.trim(),
          'description': moduleImport.description?.trim(),
          'orderIndex': moduleImport.orderIndex,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Guardar únicamente en la subcolección courses/{courseId}/modules
        final moduleRef = await firestore
            .collection('courses')
            .doc(realCourseId)
            .collection('modules')
            .add(moduleData);

        if (moduleImport.id.isNotEmpty) {
          moduleIdMap[moduleImport.id.trim()] = moduleRef.id;
        }
      }

      String? defaultModuleFirestoreId;
      if (moduleIdMap.length == 1) {
        defaultModuleFirestoreId = moduleIdMap.values.first;
      }

      // 4. Procesar lecciones
      final lessonIdMap = <String, String>{};
      for (final lessonImport in result.lessons) {
        final rawCourseId = lessonImport.courseId.trim();
        final rawModuleId = lessonImport.moduleId.trim();

        final realCourseId =
            courseIdMap[rawCourseId] ?? defaultCourseFirestoreId ?? rawCourseId;
        final realModuleId =
            moduleIdMap[rawModuleId] ?? defaultModuleFirestoreId ?? rawModuleId;

        // Extraer estrategias: primero de la pestaña 'Estrategias'
        List<Map<String, String>> strategies = [];
        if (lessonImport.id.isNotEmpty && strategiesByLessonId.containsKey(lessonImport.id.trim())) {
          strategies.addAll(strategiesByLessonId[lessonImport.id.trim()]!);
        }

        // Si no habían en la pestaña Estrategias, intentar parsear del campo de la lección (JSON o texto)
        if (strategies.isEmpty &&
            lessonImport.strategies != null &&
            lessonImport.strategies!.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(lessonImport.strategies!.trim());
            if (decoded is List) {
              for (final item in decoded) {
                if (item is Map) {
                  final t = (item['title'] ?? item['titulo'] ?? '').toString().trim();
                  final d = (item['description'] ?? item['descripcion'] ?? '').toString().trim();
                  if (t.isNotEmpty || d.isNotEmpty) {
                    strategies.add({'title': t, 'description': d});
                  }
                }
              }
            }
          } catch (_) {
            // Si no es JSON válido, agregarlo como una sola estrategia
            strategies.add({
              'title': 'Estrategia',
              'description': lessonImport.strategies!.trim(),
            });
          }
        }

        // Construir MediaResource para el video
        final mediaList = <Map<String, dynamic>>[];
        final videoUrl = lessonImport.videoUrl?.trim();
        if (videoUrl != null && videoUrl.isNotEmpty) {
          final videoId = _extractYouTubeVideoId(videoUrl);
          final String mediaId = videoId != null ? 'youtube:$videoId' : 'video_${DateTime.now().millisecondsSinceEpoch}';
          final String canonicalUrl = videoId != null ? 'https://www.youtube.com/watch?v=$videoId' : videoUrl;
          final String mimeType = (lessonImport.videoType?.toLowerCase().contains('youtube') ?? false) || videoId != null
              ? 'video/youtube'
              : (lessonImport.videoType ?? 'video/youtube');

          mediaList.add({
            'id': mediaId,
            'url': canonicalUrl,
            'filename': videoId != null ? 'YouTube $videoId' : lessonImport.title,
            'mimeType': mimeType,
            'sizeBytes': 0,
            'durationSeconds': 0,
            'metadata': {
              'provider': 'youtube',
              if (videoId != null) 'videoId': videoId,
              'durationSeconds': 0,
            },
          });
        }

        final lessonData = {
          'courseId': realCourseId,
          'moduleId': realModuleId,
          'title': lessonImport.title.trim(),
          'objectives': lessonImport.objectives?.trim(),
          'media': mediaList,
          'strategies': strategies,
          'orderIndex': lessonImport.orderIndex,
          'checkpoints': <Map<String, dynamic>>[],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Guardar en la colección 'lessons' raíz
        final lessonRef = firestore.collection('lessons').doc();
        lessonData['id'] = lessonRef.id;
        await lessonRef.set(lessonData);

        if (lessonImport.id.isNotEmpty) {
          lessonIdMap[lessonImport.id.trim()] = lessonRef.id;
        }
      }

      // 5. Procesar Cuestionarios, Preguntas y Respuestas en la colección raíz 'quizzes'
      int importedQuizzesCount = 0;
      if (result.quizzes.isNotEmpty) {
        // Normalizar y agrupar respuestas por questionId en minúsculas y sin espacios
        final answersByQuestion = <String, List<AnswerImportModel>>{};
        for (final ans in result.answers) {
          final qKey = ans.questionId.trim().toLowerCase();
          if (qKey.isNotEmpty) {
            answersByQuestion.putIfAbsent(qKey, () => []).add(ans);
          }
        }

        // Normalizar y agrupar preguntas por quizId
        final questionsByQuiz = <String, List<QuestionImportModel>>{};
        for (final q in result.questions) {
          final quizKey = q.quizId.trim().toLowerCase();
          if (quizKey.isNotEmpty) {
            questionsByQuiz.putIfAbsent(quizKey, () => []).add(q);
          }
        }

        // Map auxiliar para buscar lecciones importadas sin distinción de mayúsculas
        final cleanLessonIdMap = <String, String>{};
        lessonIdMap.forEach((k, v) => cleanLessonIdMap[k.toLowerCase()] = v);

        for (final quizImport in result.quizzes) {
          final rawLessonId = quizImport.lessonId.trim();
          final realLessonId = cleanLessonIdMap[rawLessonId.toLowerCase()] ??
              lessonIdMap[rawLessonId] ??
              (lessonIdMap.isNotEmpty ? lessonIdMap.values.first : rawLessonId);

          // Obtener courseId y moduleId de la lección
          String quizCourseId = '';
          String quizModuleId = '';

          final matchedLesson = result.lessons.firstWhere(
            (l) => l.id.trim().toLowerCase() == rawLessonId.toLowerCase(),
            orElse: () => result.lessons.isNotEmpty ? result.lessons.first : LessonImportModel(
              id: '',
              courseId: '',
              moduleId: '',
              title: '',
              orderIndex: 0,
            ),
          );

          if (matchedLesson.id.isNotEmpty) {
            final rawCourse = matchedLesson.courseId.trim();
            final rawMod = matchedLesson.moduleId.trim();
            quizCourseId = courseIdMap[rawCourse] ?? defaultCourseFirestoreId ?? rawCourse;
            quizModuleId = moduleIdMap[rawMod] ?? defaultModuleFirestoreId ?? rawMod;
          }

          if (quizCourseId.isEmpty && defaultCourseFirestoreId != null) {
            quizCourseId = defaultCourseFirestoreId!;
          }
          if (quizModuleId.isEmpty && defaultModuleFirestoreId != null) {
            quizModuleId = defaultModuleFirestoreId!;
          }

          final quizKey = quizImport.id.trim().toLowerCase();
          final quizQuestionsModels = questionsByQuiz[quizKey] ??
              (questionsByQuiz.length == 1 ? questionsByQuiz.values.first : <QuestionImportModel>[]);

          final questionsEntities = <Map<String, dynamic>>[];

          for (final qModel in quizQuestionsModels) {
            final qKey = qModel.id.trim().toLowerCase();
            final answers = answersByQuestion[qKey] ?? [];
            final options = <String>[];
            int correctIndex = 0;

            for (int i = 0; i < answers.length; i++) {
              options.add(answers[i].text.trim());
              if (answers[i].isCorrect) {
                correctIndex = i;
              }
            }

            if (options.isEmpty) {
              options.addAll(['Opción A', 'Opción B', 'Opción C']);
            }

            questionsEntities.add({
              'id': qModel.id.isNotEmpty ? qModel.id : DateTime.now().millisecondsSinceEpoch.toString(),
              'text': qModel.text.trim(),
              'options': options,
              'correctAnswerIndex': correctIndex,
            });
          }

          // Guardar en la colección raíz 'quizzes'
          // Estructura requerida por QuizEntity y por firestore.rules
          final quizDocRef = firestore.collection('quizzes').doc();
          await quizDocRef.set({
            'id': quizDocRef.id,
            'lessonId': realLessonId,
            'courseId': quizCourseId,
            'moduleId': quizModuleId,
            'title': quizImport.title.isNotEmpty ? quizImport.title.trim() : 'Evaluación',
            'questions': questionsEntities,
            'createdAt': FieldValue.serverTimestamp(),
          });
          importedQuizzesCount++;
        }
      }

      // Cerrar diálogo de progreso
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Recargar cursos
      ref.read(contentStateProvider).loadCourses();
      ref.read(courseStateProvider).loadCourses();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Importación exitosa: ${result.courses.length} cursos, ${result.modules.length} módulos, ${result.lessons.length} lecciones, $importedQuizzesCount cuestionario(s)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Cerrar cualquier diálogo abierto
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al importar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      // Cargar el archivo desde assets
      final byteData = await rootBundle.load(
        'assets/templates/plantilla_cursos.xlsx',
      );
      final bytes = byteData.buffer.asUint8List();

      // Obtener directorio de documentos del usuario
      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/plantilla_cursos.xlsx';

      // Guardar el archivo
      final file = File(outputPath);
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plantilla guardada en: $outputPath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar plantilla: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

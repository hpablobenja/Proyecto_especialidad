// lib/presentation/screens/admin/quiz_management_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/lesson_entity.dart';
import '../../../domain/entities/quiz_entity.dart';
import '../../../domain/entities/question_entity.dart';
import '../../../core/constants/app_colors.dart';

class QuizManagementScreen extends StatefulWidget {
  final LessonEntity lesson;

  const QuizManagementScreen({super.key, required this.lesson});

  @override
  State<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends State<QuizManagementScreen> {
  QuizEntity? _quiz;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final quizDoc = await firestore
          .collection('courses')
          .doc(widget.lesson.courseId)
          .collection('modules')
          .doc(widget.lesson.moduleId)
          .collection('lessons')
          .doc(widget.lesson.id)
          .collection('quiz')
          .limit(1)
          .get();

      if (quizDoc.docs.isNotEmpty) {
        final quizData = quizDoc.docs.first.data();
        final questionsData = quizData['questions'] as List? ?? [];
        
        final questions = questionsData
            .map((q) => QuestionEntity.fromMap(q as Map<String, dynamic>))
            .toList();

        setState(() {
          _quiz = QuizEntity(
            id: quizDoc.docs.first.id,
            lessonId: widget.lesson.id,
            courseId: widget.lesson.courseId,
            moduleId: widget.lesson.moduleId,
            questions: questions,
          );
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el cuestionario: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveQuiz(QuizEntity quiz) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final quizRef = firestore
          .collection('courses')
          .doc(widget.lesson.courseId)
          .collection('modules')
          .doc(widget.lesson.moduleId)
          .collection('lessons')
          .doc(widget.lesson.id)
          .collection('quiz')
          .doc(quiz.id);

      await quizRef.set(quiz.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuestionario guardado correctamente'),
          backgroundColor: AppColors.successColor,
        ),
      );
      await _loadQuiz();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el cuestionario: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _deleteQuiz() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cuestionario'),
        content: const Text('¿Estás seguro de que deseas eliminar este cuestionario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('courses')
          .doc(widget.lesson.courseId)
          .collection('modules')
          .doc(widget.lesson.moduleId)
          .collection('lessons')
          .doc(widget.lesson.id)
          .collection('quiz')
          .doc(_quiz!.id)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuestionario eliminado correctamente'),
          backgroundColor: AppColors.successColor,
        ),
      );
      setState(() {
        _quiz = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar el cuestionario: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cuestionario: ${widget.lesson.title}'),
        actions: [
          if (_quiz != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteQuiz,
              tooltip: 'Eliminar cuestionario',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : _quiz == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No hay cuestionario para esta lección',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Crea un cuestionario con máximo 5 preguntas',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _showCreateQuizDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Crear Cuestionario'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildQuizEditor(),
    );
  }

  Widget _buildQuizEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppColors.primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Máximo 5 preguntas. Cada pregunta debe tener 3 opciones de respuesta.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Preguntas (${_quiz!.questions.length}/5)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_quiz!.questions.length < 5)
                ElevatedButton.icon(
                  onPressed: () => _showAddQuestionDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Pregunta'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_quiz!.questions.length, (index) {
            return _QuestionEditorCard(
              questionNumber: index + 1,
              question: _quiz!.questions[index],
              onEdit: () => _showEditQuestionDialog(index),
              onDelete: () => _deleteQuestion(index),
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _saveQuiz(_quiz!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Guardar Cuestionario', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateQuizDialog() {
    final quiz = QuizEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      lessonId: widget.lesson.id,
      courseId: widget.lesson.courseId,
      moduleId: widget.lesson.moduleId,
      questions: [],
    );
    setState(() {
      _quiz = quiz;
    });
    _showAddQuestionDialog();
  }

  void _showAddQuestionDialog() {
    _showQuestionDialog();
  }

  void _showEditQuestionDialog(int index) {
    _showQuestionDialog(questionIndex: index);
  }

  void _showQuestionDialog({int? questionIndex}) {
    final isEditing = questionIndex != null;
    final question = isEditing ? _quiz!.questions[questionIndex] : null;

    final questionTextCtrl = TextEditingController(text: question?.text ?? '');
    final option1Ctrl = TextEditingController(text: question?.options[0] ?? '');
    final option2Ctrl = TextEditingController(text: question?.options[1] ?? '');
    final option3Ctrl = TextEditingController(text: question?.options[2] ?? '');
    int? correctAnswer = question?.correctAnswerIndex;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar Pregunta' : 'Nueva Pregunta'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: questionTextCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Pregunta',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese la pregunta' : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Opciones de respuesta (selecciona la correcta):',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<int>(
                    title: TextFormField(
                      controller: option1Ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Opción 1',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese la opción' : null,
                    ),
                    value: 0,
                    groupValue: correctAnswer,
                    onChanged: (v) => setDialogState(() => correctAnswer = v),
                  ),
                  RadioListTile<int>(
                    title: TextFormField(
                      controller: option2Ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Opción 2',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese la opción' : null,
                    ),
                    value: 1,
                    groupValue: correctAnswer,
                    onChanged: (v) => setDialogState(() => correctAnswer = v),
                  ),
                  RadioListTile<int>(
                    title: TextFormField(
                      controller: option3Ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Opción 3',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingrese la opción' : null,
                    ),
                    value: 2,
                    groupValue: correctAnswer,
                    onChanged: (v) => setDialogState(() => correctAnswer = v),
                  ),
                  if (correctAnswer == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Selecciona la respuesta correcta',
                        style: TextStyle(color: AppColors.errorColor, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate() && correctAnswer != null) {
                  final newQuestion = QuestionEntity(
                    id: question?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    text: questionTextCtrl.text.trim(),
                    options: [
                      option1Ctrl.text.trim(),
                      option2Ctrl.text.trim(),
                      option3Ctrl.text.trim(),
                    ],
                    correctAnswerIndex: correctAnswer!,
                  );

                  setState(() {
                    if (isEditing) {
                      _quiz = QuizEntity(
                        id: _quiz!.id,
                        lessonId: _quiz!.lessonId,
                        courseId: _quiz!.courseId,
                        moduleId: _quiz!.moduleId,
                        questions: List.from(_quiz!.questions)
                          ..[questionIndex] = newQuestion,
                      );
                    } else {
                      if (_quiz!.questions.length < 5) {
                        _quiz = QuizEntity(
                          id: _quiz!.id,
                          lessonId: _quiz!.lessonId,
                          courseId: _quiz!.courseId,
                          moduleId: _quiz!.moduleId,
                          questions: [..._quiz!.questions, newQuestion],
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Máximo 5 preguntas permitidas'),
                            backgroundColor: AppColors.errorColor,
                          ),
                        );
                        return;
                      }
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Guardar' : 'Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteQuestion(int index) {
    setState(() {
      _quiz = QuizEntity(
        id: _quiz!.id,
        lessonId: _quiz!.lessonId,
        courseId: _quiz!.courseId,
        moduleId: _quiz!.moduleId,
        questions: List.from(_quiz!.questions)..removeAt(index),
      );
    });
  }
}

class _QuestionEditorCard extends StatelessWidget {
  final int questionNumber;
  final QuestionEntity question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionEditorCard({
    required this.questionNumber,
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Pregunta $questionNumber',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: AppColors.errorColor),
                  onPressed: onDelete,
                  tooltip: 'Eliminar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(question.text, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            ...List.generate(question.options.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      index == question.correctAnswerIndex ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 16,
                      color: index == question.correctAnswerIndex ? AppColors.successColor : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(question.options[index])),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}


// lib/presentation/screens/courses/quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/lesson_entity.dart';
import '../../../domain/entities/quiz_entity.dart';
import '../../../domain/entities/question_entity.dart';
import '../../providers/progress_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class QuizScreen extends StatefulWidget {
  final LessonEntity lesson;

  const QuizScreen({super.key, required this.lesson});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  QuizEntity? _quiz;
  bool _loading = true;
  String? _error;
  final Map<int, int?> _selectedAnswers = {}; // questionIndex -> selectedOptionIndex
  bool _isSubmitting = false;
  bool _showResults = false;
  int _score = 0;

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

      if (quizDoc.docs.isEmpty) {
        setState(() {
          _error = 'No hay cuestionario disponible para esta lección.';
          _loading = false;
        });
        return;
      }

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
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el cuestionario: $e';
        _loading = false;
      });
    }
  }

  Future<void> _submitQuiz() async {
    if (_quiz == null) return;

    // Verificar que todas las preguntas estén respondidas
    for (int i = 0; i < _quiz!.questions.length; i++) {
      if (_selectedAnswers[i] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor responde todas las preguntas.'),
            backgroundColor: AppColors.errorColor,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    // Calcular puntaje
    int correct = 0;
    for (int i = 0; i < _quiz!.questions.length; i++) {
      if (_selectedAnswers[i] == _quiz!.questions[i].correctAnswerIndex) {
        correct++;
      }
    }

    setState(() {
      _score = correct;
      _showResults = true;
      _isSubmitting = false;
    });

    // Marcar lección como completada
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    if (auth.currentUser != null) {
      await progress.markLessonCompleted(
        userId: auth.currentUser!.uid,
        courseId: widget.lesson.courseId,
        moduleId: widget.lesson.moduleId,
        lessonId: widget.lesson.id,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cuestionario completado. Puntaje: $_score/${_quiz!.questions.length}',
        ),
        backgroundColor: AppColors.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: Center(
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_quiz == null || _quiz!.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: const Center(
          child: Text('No hay preguntas disponibles.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: _showResults
          ? _buildResults()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.quiz, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Responde las siguientes preguntas. Máximo ${_quiz!.questions.length} preguntas.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(_quiz!.questions.length, (index) {
                    final question = _quiz!.questions[index];
                    return _QuestionCard(
                      questionNumber: index + 1,
                      question: question,
                      selectedAnswer: _selectedAnswers[index],
                      onAnswerSelected: (answerIndex) {
                        setState(() {
                          _selectedAnswers[index] = answerIndex;
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Enviar Cuestionario',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildResults() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: _score == _quiz!.questions.length
                ? AppColors.successColor.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    _score == _quiz!.questions.length
                        ? Icons.check_circle
                        : Icons.info,
                    size: 64,
                    color: _score == _quiz!.questions.length
                        ? AppColors.successColor
                        : Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Resultado del Cuestionario',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Puntaje: $_score/${_quiz!.questions.length}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _score == _quiz!.questions.length
                              ? AppColors.successColor
                              : Colors.orange,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Revisión de Respuestas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_quiz!.questions.length, (index) {
            final question = _quiz!.questions[index];
            final selected = _selectedAnswers[index];
            final isCorrect = selected == question.correctAnswerIndex;
            return _ResultQuestionCard(
              questionNumber: index + 1,
              question: question,
              selectedAnswer: selected,
              isCorrect: isCorrect,
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Volver', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int questionNumber;
  final QuestionEntity question;
  final int? selectedAnswer;
  final Function(int) onAnswerSelected;

  const _QuestionCard({
    required this.questionNumber,
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pregunta $questionNumber',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              question.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ...List.generate(question.options.length, (index) {
              final isSelected = selectedAnswer == index;
              return RadioListTile<int>(
                title: Text(question.options[index]),
                value: index,
                groupValue: selectedAnswer,
                onChanged: (_) => onAnswerSelected(index),
                activeColor: Theme.of(context).primaryColor,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ResultQuestionCard extends StatelessWidget {
  final int questionNumber;
  final QuestionEntity question;
  final int? selectedAnswer;
  final bool isCorrect;

  const _ResultQuestionCard({
    required this.questionNumber,
    required this.question,
    required this.selectedAnswer,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isCorrect
          ? AppColors.successColor.withOpacity(0.1)
          : AppColors.errorColor.withOpacity(0.1),
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
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? AppColors.successColor : AppColors.errorColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              question.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            ...List.generate(question.options.length, (index) {
              final isCorrectAnswer = index == question.correctAnswerIndex;
              Color? backgroundColor;
              IconData? icon;
              Color? iconColor;

              if (isCorrectAnswer) {
                backgroundColor = AppColors.successColor.withOpacity(0.2);
                icon = Icons.check_circle;
                iconColor = AppColors.successColor;
              } else if (selectedAnswer == index && !isCorrect) {
                backgroundColor = AppColors.errorColor.withOpacity(0.2);
                icon = Icons.cancel;
                iconColor = AppColors.errorColor;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCorrectAnswer
                        ? AppColors.successColor
                        : (selectedAnswer == index ? AppColors.errorColor : Colors.grey[300]!),
                    width: isCorrectAnswer || selectedAnswer == index ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        question.options[index],
                        style: TextStyle(
                          fontWeight: isCorrectAnswer ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isCorrectAnswer)
                      Text(
                        'Correcta',
                        style: TextStyle(
                          color: AppColors.successColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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


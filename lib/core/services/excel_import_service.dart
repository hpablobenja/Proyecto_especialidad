// lib/core/services/excel_import_service.dart

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/course_import_model.dart';
import '../../data/models/module_import_model.dart';
import '../../data/models/lesson_import_model.dart';
import '../../data/models/strategy_import_model.dart';
import '../../data/models/quiz_import_model.dart';
import '../utils/logger_service.dart';

class ExcelImportResult {
  final List<CourseImportModel> courses;
  final List<ModuleImportModel> modules;
  final List<LessonImportModel> lessons;
  final List<StrategyImportModel> strategies;
  final List<QuizImportModel> quizzes;
  final List<QuestionImportModel> questions;
  final List<AnswerImportModel> answers;
  final List<String> errors;

  ExcelImportResult({
    required this.courses,
    required this.modules,
    required this.lessons,
    this.strategies = const [],
    this.quizzes = const [],
    this.questions = const [],
    this.answers = const [],
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isEmpty =>
      courses.isEmpty &&
      modules.isEmpty &&
      lessons.isEmpty &&
      strategies.isEmpty &&
      quizzes.isEmpty;
}

class ExcelImportService {
  static const List<String> coursesSheetNames = ['Cursos', 'Curso'];
  static const List<String> modulesSheetNames = ['Modulos', 'Módulos', 'Modulo', 'Módulo'];
  static const List<String> lessonsSheetNames = ['Lecciones', 'Lección', 'Leccion'];
  static const List<String> strategiesSheetNames = ['Estrategias', 'Estrategia'];
  static const List<String> quizzesSheetNames = ['Cuestionarios', 'Cuestionario', 'Quizzes', 'Quiz'];
  static const List<String> questionsSheetNames = ['Preguntas', 'Pregunta'];
  static const List<String> answersSheetNames = ['Respuestas', 'Respuesta'];

  Future<ExcelImportResult?> importFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final filePath = result.files.single.path;
      if (filePath == null) return null;

      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final courses = <CourseImportModel>[];
      final modules = <ModuleImportModel>[];
      final lessons = <LessonImportModel>[];
      final strategies = <StrategyImportModel>[];
      final quizzes = <QuizImportModel>[];
      final questions = <QuestionImportModel>[];
      final answers = <AnswerImportModel>[];
      final errors = <String>[];

      // Helper para buscar pestañas de forma flexible
      Sheet? findSheet(List<String> names) {
        for (final tableKey in excel.tables.keys) {
          final cleanKey = _cleanSheetName(tableKey);
          for (final name in names) {
            if (cleanKey == _cleanSheetName(name)) {
              return excel.tables[tableKey];
            }
          }
        }
        return null;
      }

      // Procesar Cursos
      final courseSheet = findSheet(coursesSheetNames);
      if (courseSheet != null) {
        courses.addAll(_parseCoursesSheet(courseSheet));
      } else {
        errors.add('No se encontró la pestaña "Cursos"');
      }

      // Procesar Módulos
      final moduleSheet = findSheet(modulesSheetNames);
      if (moduleSheet != null) {
        modules.addAll(_parseModulesSheet(moduleSheet));
      } else {
        errors.add('No se encontró la pestaña "Modulos"');
      }

      // Procesar Lecciones
      final lessonSheet = findSheet(lessonsSheetNames);
      if (lessonSheet != null) {
        lessons.addAll(_parseLessonsSheet(lessonSheet));
      } else {
        errors.add('No se encontró la pestaña "Lecciones"');
      }

      // Procesar Estrategias (opcional o complementaria)
      final strategySheet = findSheet(strategiesSheetNames);
      if (strategySheet != null) {
        strategies.addAll(_parseStrategiesSheet(strategySheet));
      }

      // Procesar Cuestionarios
      final quizSheet = findSheet(quizzesSheetNames);
      if (quizSheet != null) {
        quizzes.addAll(_parseQuizzesSheet(quizSheet));
      }

      // Procesar Preguntas
      final questionSheet = findSheet(questionsSheetNames);
      if (questionSheet != null) {
        questions.addAll(_parseQuestionsSheet(questionSheet));
      }

      // Procesar Respuestas
      final answerSheet = findSheet(answersSheetNames);
      if (answerSheet != null) {
        answers.addAll(_parseAnswersSheet(answerSheet));
      }

      return ExcelImportResult(
        courses: courses,
        modules: modules,
        lessons: lessons,
        strategies: strategies,
        quizzes: quizzes,
        questions: questions,
        answers: answers,
        errors: errors,
      );
    } catch (e) {
      LoggerService.logError('Error al importar Excel', e);
      return ExcelImportResult(
        courses: [],
        modules: [],
        lessons: [],
        errors: ['Error al leer el archivo: $e'],
      );
    }
  }

  static String _cleanSheetName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  bool _isRowEmpty(List<dynamic> row) {
    if (row.isEmpty) return true;
    return !row.any((cell) {
      if (cell == null) return false;
      try {
        final dynamic val = cell.value;
        if (val != null) {
          return val.toString().trim().isNotEmpty;
        }
      } catch (_) {}
      return cell.toString().trim().isNotEmpty;
    });
  }

  List<CourseImportModel> _parseCoursesSheet(Sheet sheet) {
    final courses = <CourseImportModel>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (_isRowEmpty(row)) continue;

      try {
        final course = CourseImportModel.fromExcelRow(row);
        if (course.title.trim().isEmpty) continue;
        courses.add(course);
      } catch (e) {
        LoggerService.logError('Error al parsear curso en fila ${i + 1}', e);
      }
    }
    return courses;
  }

  List<ModuleImportModel> _parseModulesSheet(Sheet sheet) {
    final modules = <ModuleImportModel>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (_isRowEmpty(row)) continue;

      try {
        final module = ModuleImportModel.fromExcelRow(row);
        if (module.title.trim().isEmpty) continue;
        modules.add(module);
      } catch (e) {
        LoggerService.logError('Error al parsear módulo en fila ${i + 1}', e);
      }
    }
    return modules;
  }

  List<LessonImportModel> _parseLessonsSheet(Sheet sheet) {
    final lessons = <LessonImportModel>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (_isRowEmpty(row)) continue;

      try {
        final lesson = LessonImportModel.fromExcelRow(row);
        if (lesson.title.trim().isEmpty) continue;
        lessons.add(lesson);
      } catch (e) {
        LoggerService.logError('Error al parsear lección en fila ${i + 1}', e);
      }
    }
    return lessons;
  }

  List<StrategyImportModel> _parseStrategiesSheet(Sheet sheet) {
    final strategies = <StrategyImportModel>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (_isRowEmpty(row)) continue;

      try {
        final strategy = StrategyImportModel.fromExcelRow(row);
        if (strategy.lessonId.trim().isEmpty || strategy.title.trim().isEmpty) {
          continue;
        }
        strategies.add(strategy);
      } catch (e) {
        LoggerService.logError('Error al parsear estrategia en fila ${i + 1}', e);
      }
    }
    return strategies;
  }

  List<QuizImportModel> _parseQuizzesSheet(Sheet sheet) {
    final quizzes = <QuizImportModel>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (_isRowEmpty(row)) continue;

      try {
        final quiz = QuizImportModel.fromExcelRow(row);
        if (quiz.id.trim().isEmpty && quiz.lessonId.trim().isEmpty) continue;
        quizzes.add(quiz);
      } catch (e) {
        LoggerService.logError('Error al parsear cuestionario en fila ${i + 1}', e);
      }
    }
    return quizzes;
  }

  List<QuestionImportModel> _parseQuestionsSheet(Sheet sheet) {
    final questions = <QuestionImportModel>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (_isRowEmpty(row)) continue;

      try {
        final question = QuestionImportModel.fromExcelRow(row);
        if (question.id.trim().isEmpty || question.text.trim().isEmpty) continue;
        questions.add(question);
      } catch (e) {
        LoggerService.logError('Error al parsear pregunta en fila ${i + 1}', e);
      }
    }
    return questions;
  }

  List<AnswerImportModel> _parseAnswersSheet(Sheet sheet) {
    final answers = <AnswerImportModel>[];
    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (_isRowEmpty(row)) continue;

      try {
        final answer = AnswerImportModel.fromExcelRow(row);
        if (answer.questionId.trim().isEmpty || answer.text.trim().isEmpty) continue;
        answers.add(answer);
      } catch (e) {
        LoggerService.logError('Error al parsear respuesta en fila ${i + 1}', e);
      }
    }
    return answers;
  }

  static void _appendTextRow(Sheet sheet, List<String> values) {
    sheet.appendRow(values.map((value) => TextCellValue(value)).toList());
  }

  /// Genera una plantilla de Excel alineada con EstructuraExcel.md
  static Future<String?> generateTemplate() async {
    try {
      final excel = Excel.createExcel();

      // Pestaña Cursos
      final coursesSheet = excel['Cursos'];
      _appendTextRow(coursesSheet, [
        'ID',
        'Título',
        'Descripción',
        'Público Objetivo',
        'Estado',
      ]);
      _appendTextRow(coursesSheet, [
        'curso_bio_001',
        'Biología General: Fundamentos de la Vida',
        'Curso introductorio a la biología celular y ecología.',
        'Ciencias Naturales',
        'draft',
      ]);

      // Pestaña Modulos
      final modulesSheet = excel['Modulos'];
      _appendTextRow(modulesSheet, [
        'ID',
        'ID Curso',
        'Título',
        'Descripción',
        'Orden',
      ]);
      _appendTextRow(modulesSheet, [
        'modulo_bio_001',
        'curso_bio_001',
        'Módulo 1: La Célula y su Entorno',
        'Estudio de las partes de la célula y su funcionamiento.',
        '1',
      ]);

      // Pestaña Lecciones
      final lessonsSheet = excel['Lecciones'];
      _appendTextRow(lessonsSheet, [
        'ID',
        'ID Curso',
        'ID Módulo',
        'Título',
        'Objetivos',
        'URL Video',
        'Tipo Video',
        'Orden',
      ]);
      _appendTextRow(lessonsSheet, [
        'leccion_bio_001',
        'curso_bio_001',
        'modulo_bio_001',
        'La fotosíntesis y la energía celular',
        'Comprender el proceso fotosintético en plantas.',
        'https://www.youtube.com/watch?v=KbLw6cB52vQ',
        'youtube',
        '1',
      ]);

      // Pestaña Estrategias
      final strategiesSheet = excel['Estrategias'];
      _appendTextRow(strategiesSheet, [
        'ID',
        'ID Lección',
        'Título',
        'Descripción',
      ]);
      _appendTextRow(strategiesSheet, [
        'estrategia_001',
        'leccion_bio_001',
        'Sopa de letras de organelos',
        'Encontrar 10 términos clave sobre la célula vegetal.',
      ]);

      // Pestaña Cuestionarios
      final quizzesSheet = excel['Cuestionarios'];
      _appendTextRow(quizzesSheet, [
        'ID',
        'ID Lección',
        'Título',
      ]);
      _appendTextRow(quizzesSheet, [
        'quiz_001',
        'leccion_bio_001',
        'Evaluación de Fotosíntesis',
      ]);

      // Pestaña Preguntas
      final questionsSheet = excel['Preguntas'];
      _appendTextRow(questionsSheet, [
        'ID',
        'ID Cuestionario',
        'Pregunta',
      ]);
      _appendTextRow(questionsSheet, [
        'pregunta_001',
        'quiz_001',
        '¿En qué orgánulo celular ocurre la fotosíntesis?',
      ]);

      // Pestaña Respuestas
      final answersSheet = excel['Respuestas'];
      _appendTextRow(answersSheet, [
        'ID Pregunta',
        'Opción',
        'Texto',
        'Es Correcta',
      ]);
      _appendTextRow(answersSheet, [
        'pregunta_001',
        'A',
        'Cloroplasto',
        'TRUE',
      ]);
      _appendTextRow(answersSheet, [
        'pregunta_001',
        'B',
        'Mitocondria',
        'FALSE',
      ]);
      _appendTextRow(answersSheet, [
        'pregunta_001',
        'C',
        'Ribosoma',
        'FALSE',
      ]);

      // Guardar el archivo
      final fileBytes = excel.encode();
      if (fileBytes == null) return null;

      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/plantilla_cursos.xlsx';

      final file = File(outputPath);
      await file.writeAsBytes(fileBytes);

      return outputPath;
    } catch (e) {
      LoggerService.logError('Error al generar plantilla de Excel', e);
      return null;
    }
  }
}

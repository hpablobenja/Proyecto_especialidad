// lib/data/models/quiz_import_model.dart

class QuizImportModel {
  final String id;
  final String lessonId;
  final String title;

  QuizImportModel({
    required this.id,
    required this.lessonId,
    required this.title,
  });

  factory QuizImportModel.fromExcelRow(List<dynamic> row) {
    return QuizImportModel(
      id: _getCellValueAt(row, 0) ?? '',
      lessonId: _getCellValueAt(row, 1) ?? '',
      title: _getCellValueAt(row, 2) ?? '',
    );
  }

  static String? _getCellValueAt(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return null;
    return _getCellValue(row[index]);
  }

  static String? _getCellValue(dynamic cell) {
    if (cell == null) return null;
    try {
      final dynamic value = cell.value;
      if (value != null) {
        return value.toString().trim();
      }
    } catch (_) {}

    final cellStr = cell.toString().trim();
    if (cellStr.startsWith('Data(')) {
      final firstComma = cellStr.indexOf(',');
      if (firstComma > 5) {
        return cellStr.substring(5, firstComma).trim();
      }
    }
    return cellStr;
  }
}

class QuestionImportModel {
  final String id;
  final String quizId;
  final String text;

  QuestionImportModel({
    required this.id,
    required this.quizId,
    required this.text,
  });

  factory QuestionImportModel.fromExcelRow(List<dynamic> row) {
    return QuestionImportModel(
      id: _getCellValueAt(row, 0) ?? '',
      quizId: _getCellValueAt(row, 1) ?? '',
      text: _getCellValueAt(row, 2) ?? '',
    );
  }

  static String? _getCellValueAt(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return null;
    return _getCellValue(row[index]);
  }

  static String? _getCellValue(dynamic cell) {
    if (cell == null) return null;
    try {
      final dynamic value = cell.value;
      if (value != null) {
        return value.toString().trim();
      }
    } catch (_) {}

    final cellStr = cell.toString().trim();
    if (cellStr.startsWith('Data(')) {
      final firstComma = cellStr.indexOf(',');
      if (firstComma > 5) {
        return cellStr.substring(5, firstComma).trim();
      }
    }
    return cellStr;
  }
}

class AnswerImportModel {
  final String questionId;
  final String option;
  final String text;
  final bool isCorrect;

  AnswerImportModel({
    required this.questionId,
    required this.option,
    required this.text,
    required this.isCorrect,
  });

  factory AnswerImportModel.fromExcelRow(List<dynamic> row) {
    final rawIsCorrect = _getCellValueAt(row, 3)?.toLowerCase() ?? 'false';
    final isCorrect = rawIsCorrect == 'true' ||
        rawIsCorrect == '1' ||
        rawIsCorrect == 'verdadero' ||
        rawIsCorrect == 'si' ||
        rawIsCorrect == 's';

    return AnswerImportModel(
      questionId: _getCellValueAt(row, 0) ?? '',
      option: _getCellValueAt(row, 1) ?? '',
      text: _getCellValueAt(row, 2) ?? '',
      isCorrect: isCorrect,
    );
  }

  static String? _getCellValueAt(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return null;
    return _getCellValue(row[index]);
  }

  static String? _getCellValue(dynamic cell) {
    if (cell == null) return null;
    try {
      final dynamic value = cell.value;
      if (value != null) {
        return value.toString().trim();
      }
    } catch (_) {}

    final cellStr = cell.toString().trim();
    if (cellStr.startsWith('Data(')) {
      final firstComma = cellStr.indexOf(',');
      if (firstComma > 5) {
        return cellStr.substring(5, firstComma).trim();
      }
    }
    return cellStr;
  }
}


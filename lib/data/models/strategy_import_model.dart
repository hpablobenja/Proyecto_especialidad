// lib/data/models/strategy_import_model.dart

class StrategyImportModel {
  final String id;
  final String lessonId;
  final String title;
  final String description;

  StrategyImportModel({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.description,
  });

  factory StrategyImportModel.fromExcelRow(List<dynamic> row) {
    return StrategyImportModel(
      id: _getCellValueAt(row, 0) ?? '',
      lessonId: _getCellValueAt(row, 1) ?? '',
      title: _getCellValueAt(row, 2) ?? '',
      description: _getCellValueAt(row, 3) ?? '',
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


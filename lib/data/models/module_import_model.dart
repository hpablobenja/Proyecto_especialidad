// lib/data/models/module_import_model.dart

class ModuleImportModel {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int orderIndex;

  ModuleImportModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.orderIndex,
  });

  factory ModuleImportModel.fromExcelRow(List<dynamic> row) {
    return ModuleImportModel(
      id: _getCellValueAt(row, 0) ?? '',
      courseId: _getCellValueAt(row, 1) ?? '',
      title: _getCellValueAt(row, 2) ?? '',
      description: _getCellValueAt(row, 3),
      orderIndex: int.tryParse(_getCellValueAt(row, 4) ?? '1') ?? 1,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'orderIndex': orderIndex,
    };
  }
}

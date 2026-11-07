// lib/data/models/lesson_import_model.dart

class LessonImportModel {
  final String id;
  final String courseId;
  final String moduleId;
  final String title;
  final String? objectives;
  final String? videoUrl;
  final String? videoType;
  final String? strategies;
  final int orderIndex;

  LessonImportModel({
    required this.id,
    required this.courseId,
    required this.moduleId,
    required this.title,
    this.objectives,
    this.videoUrl,
    this.videoType,
    this.strategies,
    required this.orderIndex,
  });

  factory LessonImportModel.fromExcelRow(List<dynamic> row) {
    // Si la plantilla tiene 8 columnas (ID, ID Curso, ID Módulo, Título, Objetivos, URL Video, Tipo Video, Orden):
    // 0: ID
    // 1: ID Curso
    // 2: ID Módulo
    // 3: Título
    // 4: Objetivos
    // 5: URL Video
    // 6: Tipo Video
    // 7: Orden (o Estrategias si fuera formato de 9 columnas)
    
    final id = _getCellValueAt(row, 0) ?? '';
    final courseId = _getCellValueAt(row, 1) ?? '';
    final moduleId = _getCellValueAt(row, 2) ?? '';
    final title = _getCellValueAt(row, 3) ?? '';
    final objectives = _getCellValueAt(row, 4);
    final videoUrl = _getCellValueAt(row, 5);
    final videoType = _getCellValueAt(row, 6);

    String? strategies;
    int order = 1;

    // Detectar si la fila tiene 8 o 9 columnas
    if (row.length >= 9) {
      strategies = _getCellValueAt(row, 7);
      order = int.tryParse(_getCellValueAt(row, 8) ?? '1') ?? 1;
    } else {
      order = int.tryParse(_getCellValueAt(row, 7) ?? '1') ?? 1;
    }

    return LessonImportModel(
      id: id,
      courseId: courseId,
      moduleId: moduleId,
      title: title,
      objectives: objectives,
      videoUrl: videoUrl,
      videoType: videoType,
      strategies: strategies,
      orderIndex: order,
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
      'moduleId': moduleId,
      'title': title,
      'objectives': objectives,
      'videoUrl': videoUrl,
      'videoType': videoType,
      'strategies': strategies,
      'orderIndex': orderIndex,
    };
  }
}

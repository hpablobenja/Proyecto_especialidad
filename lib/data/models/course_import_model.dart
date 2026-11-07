// lib/data/models/course_import_model.dart

class CourseImportModel {
  final String id;
  final String title;
  final String description;
  final String targetAudience;
  final String status;

  static const List<String> validTargetAudiences = [
    'Ciencias Sociales',
    'Ciencias Naturales',
    'Comunicación y Lenguaje',
    'Alternativa',
    'Otro(Especificar)',
  ];

  CourseImportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAudience,
    this.status = 'draft',
  });

  factory CourseImportModel.fromExcelRow(List<dynamic> row) {
    final id = _getCellValueAt(row, 0) ?? '';
    final title = _getCellValueAt(row, 1) ?? '';
    final description = _getCellValueAt(row, 2) ?? '';
    
    // El público objetivo está en la columna 3 (índice 3: ID=0, Título=1, Descripción=2, Público Objetivo=3, Estado=4)
    String rawAudience = _getCellValueAt(row, 3) ?? '';
    String rawStatus = _getCellValueAt(row, 4) ?? 'draft';

    // Si por alguna razón la columna 3 contiene 'draft' o 'published', entonces vino invertido o corrido
    if ((rawAudience.toLowerCase() == 'draft' || rawAudience.toLowerCase() == 'published') &&
        _getCellValueAt(row, 4) != null) {
      rawStatus = rawAudience;
      rawAudience = _getCellValueAt(row, 4) ?? '';
    }

    final targetAudience = _normalizeTargetAudience(rawAudience);
    final status = rawStatus.toLowerCase() == 'published' ? 'published' : 'draft';

    return CourseImportModel(
      id: id,
      title: title,
      description: description,
      targetAudience: targetAudience,
      status: status,
    );
  }

  static String _normalizeTargetAudience(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return 'Ciencias Naturales';

    final lower = _removeDiacritics(cleaned.toLowerCase());

    if (lower.contains('social')) return 'Ciencias Sociales';
    if (lower.contains('natural')) return 'Ciencias Naturales';
    if (lower.contains('comunicaci') || lower.contains('lenguaje')) return 'Comunicación y Lenguaje';
    if (lower.contains('alternativa')) return 'Alternativa';
    if (lower.contains('otro')) return 'Otro(Especificar)';

    for (final audience in validTargetAudiences) {
      if (_removeDiacritics(audience.toLowerCase()) == lower) {
        return audience;
      }
    }

    return cleaned;
  }

  static String _removeDiacritics(String str) {
    const withDia = 'áéíóúüñÁÉÍÓÚÜÑ';
    const withoutDia = 'aeiouunAEIOUUN';
    var result = str;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
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
      'title': title,
      'description': description,
      'targetAudience': targetAudience,
      'status': status,
    };
  }
}

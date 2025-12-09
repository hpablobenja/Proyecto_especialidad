import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../domain/entities/lesson_entity.dart';

class PdfGeneratorService {
  Future<String> generateLessonPdf(LessonEntity lesson) async {
    final pdf = pw.Document();

    // Cargar fuente para soportar caracteres especiales si es necesario
    // Por ahora usaremos la fuente por defecto

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                lesson.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            if (lesson.objectives != null && lesson.objectives!.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text(
                'Objetivos',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(lesson.objectives!),
            ],
            pw.SizedBox(height: 20),
            pw.Text(
              'Contenido',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(_parseContent(lesson.contentDelta)),
            if (lesson.strategies.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text(
                'Estrategias',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              ...lesson.strategies.map((strategy) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        strategy['title'] ?? 'Sin título',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(strategy['description'] ?? ''),
                    ],
                  ),
                );
              }).toList(),
            ],
          ];
        },
      ),
    );

    // Save to documents directory for offline access
    final directory = await getApplicationDocumentsDirectory();
    final documentsPath = '${directory.path}/documentos';
    final documentsDir = Directory(documentsPath);
    
    // Create directory if it doesn't exist
    if (!await documentsDir.exists()) {
      await documentsDir.create(recursive: true);
    }
    
    final file = File('$documentsPath/leccion_${lesson.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Try to open the file, but don't fail if it can't be opened
    try {
      await OpenFilex.open(file.path);
    } catch (e) {
      // Silently fail - file is saved even if it can't be opened
    }
    
    return file.path;
  }

  String _parseContent(List<dynamic>? contentDelta) {
    if (contentDelta == null) return '';
    String text = '';
    try {
      for (var op in contentDelta) {
        if (op is Map && op.containsKey('insert')) {
          final insert = op['insert'];
          if (insert is String) {
            text += insert;
          }
        }
      }
    } catch (e) {
      text = 'Error al procesar contenido';
    }
    return text;
  }
}

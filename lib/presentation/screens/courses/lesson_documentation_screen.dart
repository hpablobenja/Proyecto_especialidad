// lib/presentation/screens/courses/lesson_documentation_screen.dart

import 'package:flutter/material.dart';

import '../../../domain/entities/lesson_entity.dart';
import '../../../core/services/pdf_generator_service.dart';
import '../../../core/services/offline_cache_service.dart';

class LessonDocumentationScreen extends StatefulWidget {
  final LessonEntity lesson;

  const LessonDocumentationScreen({super.key, required this.lesson});

  @override
  State<LessonDocumentationScreen> createState() =>
      _LessonDocumentationScreenState();
}

class _LessonDocumentationScreenState extends State<LessonDocumentationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Cache lesson for offline access when viewing documentation
    _cacheLesson();
  }

  Future<void> _cacheLesson() async {
    try {
      final cacheService = OfflineCacheService();
      await cacheService.cacheLastLesson(widget.lesson);
    } catch (e) {
      // Silently fail - caching is not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    final strategies = widget.lesson.strategies;
    final hasStrategies = strategies.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lesson.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Descargar PDF',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generando PDF...')),
              );
              try {
                final pdfService = PdfGeneratorService();
                final filePath = await pdfService.generateLessonPdf(widget.lesson);
                
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('PDF guardado en: $filePath'),
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'OK',
                      onPressed: () {},
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al generar PDF: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body:
          hasStrategies
              ? Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: strategies.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final strategy = strategies[index];
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strategy['title'] ?? 'Sin título',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const Divider(height: 32),
                                  Text(
                                    strategy['description'] ?? '',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(height: 1.6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                          onPressed:
                              _currentPage > 0
                                  ? () {
                                    _pageController.previousPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                  : null,
                        ),
                        Text(
                          'Estrategia ${_currentPage + 1} de ${strategies.length}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed:
                              _currentPage < strategies.length - 1
                                  ? () {
                                    _pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ],
              )
              : Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No hay estrategias documentadas para esta lección.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
    );
  }
}

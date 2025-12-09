// lib/presentation/screens/admin/admin_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/injection_container.dart' as di;
import '../../../domain/usecases/reports/generate_all_users_report_usecase.dart';
import '../../providers/auth_provider.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _isGenerating = false;

  Future<void> _generateAllUsersReport(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para generar reportes.')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final usecase = di.sl<GenerateAllUsersReportUsecase>();
      final filePath = await usecase.call(NoParams());
      
      if (!mounted) return;
      
      setState(() {
        _isGenerating = false;
      });

      // Abrir el PDF automáticamente
      await OpenFilex.open(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte generado y abierto exitosamente.\nGuardado en: $filePath'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar el reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generar Reportes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reportes de Progreso',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Genera un reporte PDF completo con el progreso de todos los usuarios en las microformaciones.',
            ),
            const SizedBox(height: 24),
            
            if (_isGenerating)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generando reporte...'),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generar reporte de todos los usuarios'),
                onPressed: () => _generateAllUsersReport(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            Text(
              'Información del Reporte',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '• El reporte incluye el progreso de todos los usuarios maestros\n'
              '• Se muestra el estado de cada lección (Completado, En Curso, No Iniciado)\n'
              '• El archivo PDF se guarda automáticamente en la carpeta de documentos\n'
              '• Incluye estadísticas generales de uso',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

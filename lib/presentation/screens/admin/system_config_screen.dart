// lib/presentation/screens/admin/system_config_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/system_config_service.dart';
import '../../../core/services/local_data_clear_service.dart';
import '../../../domain/entities/system_config_entity.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/riverpod_providers.dart';

class SystemConfigScreen extends ConsumerStatefulWidget {
  const SystemConfigScreen({super.key});

  @override
  ConsumerState<SystemConfigScreen> createState() => _SystemConfigScreenState();
}

class _SystemConfigScreenState extends ConsumerState<SystemConfigScreen> {
  final SystemConfigService _configService = SystemConfigService();
  final LocalDataClearService _dataClearService = LocalDataClearService();
  SystemConfigEntity? _config;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isClearingData = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
    });

    final config = await _configService.getConfig();

    setState(() {
      _config = config;
      _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;

    setState(() {
      _isSaving = true;
    });

    final success = await _configService.updateConfig(_config!);

    setState(() {
      _isSaving = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Configuración guardada exitosamente'
              : 'Error al guardar configuración',
        ),
        backgroundColor:
            success ? AppColors.successColor : AppColors.errorColor,
      ),
    );
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Restablecer configuración'),
            content: const Text(
              '¿Estás seguro de restablecer todos los valores a los predeterminados?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Restablecer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() {
        _isSaving = true;
      });

      final success = await _configService.resetToDefaults();

      if (success) {
        await _loadConfig();
      }

      setState(() {
        _isSaving = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Configuración restablecida' : 'Error al restablecer',
          ),
          backgroundColor:
              success ? AppColors.successColor : AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _clearAllLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Borrar datos locales'),
            content: const Text(
              '¿Estás seguro de borrar todos los datos locales del sistema?\n\nEsto incluye:\n• Progreso de videos\n• Checkpoints\n• Cola de sincronización\n• Quizzes offline\n\nEsta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Borrar todo',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() {
        _isClearingData = true;
      });

      final success = await _dataClearService.clearAllLocalData();

      setState(() {
        _isClearingData = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Datos locales borrados exitosamente'
                : 'Error al borrar datos locales',
          ),
          backgroundColor:
              success ? AppColors.successColor : AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final user = auth.currentUser;
    final isAdmin = (user?.role ?? '').toLowerCase() == 'admin';

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuración del Sistema')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Acceso denegado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Solo los administradores pueden acceder a esta configuración',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuración del Sistema')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_config == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuración del Sistema')),
        body: const Center(child: Text('Error al cargar configuración')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Sistema'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restablecer valores por defecto',
            onPressed: _resetToDefaults,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Configuración de Video Tracking'),
            _buildIntField(
              'Tolerancia de búsqueda (segundos)',
              _config!.seekToleranceSeconds,
              (value) =>
                  _config = _config!.copyWith(seekToleranceSeconds: value),
              min: 1,
              max: 30,
            ),
            _buildIntField(
              'Intervalo de tracking (segundos)',
              _config!.trackingIntervalSeconds,
              (value) =>
                  _config = _config!.copyWith(trackingIntervalSeconds: value),
              min: 1,
              max: 10,
            ),
            _buildIntField(
              'Intervalo de sincronización (segundos)',
              _config!.syncIntervalSeconds,
              (value) =>
                  _config = _config!.copyWith(syncIntervalSeconds: value),
              min: 10,
              max: 300,
            ),
            _buildDoubleField(
              'Umbral de completación (%)',
              _config!.completionThreshold,
              (value) =>
                  _config = _config!.copyWith(completionThreshold: value),
              min: 50,
              max: 100,
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Configuración de Quiz'),
            _buildIntField(
              'Máximo preguntas para maestros',
              _config!.maxQuestionsForTeacher,
              (value) =>
                  _config = _config!.copyWith(maxQuestionsForTeacher: value),
              min: 1,
              max: 20,
            ),
            _buildIntField(
              'Máximo preguntas en banco',
              _config!.maxQuestionsBank,
              (value) => _config = _config!.copyWith(maxQuestionsBank: value),
              min: 5,
              max: 50,
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Configuración de Checkpoints'),
            _buildBoolField(
              'Habilitar checkpoints',
              _config!.enableCheckpoints,
              (value) => _config = _config!.copyWith(enableCheckpoints: value),
            ),
            _buildIntField(
              'Máximo intentos de checkpoint',
              _config!.maxCheckpointAttempts,
              (value) =>
                  _config = _config!.copyWith(maxCheckpointAttempts: value),
              min: 1,
              max: 10,
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Configuración de Sesión'),
            _buildIntField(
              'Advertencia de sesión (minutos)',
              _config!.sessionWarningMinutes,
              (value) =>
                  _config = _config!.copyWith(sessionWarningMinutes: value),
              min: 1,
              max: 30,
            ),
            _buildIntField(
              'Duración máxima de sesión (minutos)',
              _config!.maxSessionDurationMinutes,
              (value) =>
                  _config = _config!.copyWith(maxSessionDurationMinutes: value),
              min: 30,
              max: 480,
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Configuración de Sincronización'),
            _buildIntField(
              'Máximo reintentos de sincronización',
              _config!.maxSyncRetries,
              (value) => _config = _config!.copyWith(maxSyncRetries: value),
              min: 1,
              max: 10,
            ),
            _buildBoolField(
              'Habilitar modo offline',
              _config!.enableOfflineMode,
              (value) => _config = _config!.copyWith(enableOfflineMode: value),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Configuración de UI'),
            _buildBoolField(
              'Habilitar animaciones',
              _config!.enableAnimations,
              (value) => _config = _config!.copyWith(enableAnimations: value),
            ),
            _buildDropdownField(
              'Tema por defecto',
              _config!.defaultTheme,
              ['system', 'light', 'dark'],
              (value) => _config = _config!.copyWith(defaultTheme: value),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveConfig,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          'Guardar Configuración',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: OutlinedButton.icon(
                onPressed: _isClearingData ? null : _clearAllLocalData,
                icon: _isClearingData
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      )
                    : const Icon(Icons.delete_outline, size: 18),
                label: Text(
                  _isClearingData ? 'Borrando...' : 'Borrar datos locales',
                  style: const TextStyle(fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  minimumSize: const Size(200, 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildIntField(
    String label,
    int value,
    Function(int) onChanged, {
    int min = 0,
    int max = 1000,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        initialValue: value.toString(),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixText: '($min - $max)',
        ),
        keyboardType: TextInputType.number,
        onChanged: (text) {
          final intValue = int.tryParse(text);
          if (intValue != null && intValue >= min && intValue <= max) {
            onChanged(intValue);
          }
        },
      ),
    );
  }

  Widget _buildDoubleField(
    String label,
    double value,
    Function(double) onChanged, {
    double min = 0,
    double max = 1000,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        initialValue: value.toString(),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixText: '($min - $max)',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (text) {
          final doubleValue = double.tryParse(text);
          if (doubleValue != null && doubleValue >= min && doubleValue <= max) {
            onChanged(doubleValue);
          }
        },
      ),
    );
  }

  Widget _buildBoolField(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: SwitchListTile(
        title: Text(label),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items:
            options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

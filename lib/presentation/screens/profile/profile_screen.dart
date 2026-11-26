// lib/presentation/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/di/riverpod_providers.dart';
import '../../../core/services/system_config_service.dart';
import '../../../core/services/local_data_clear_service.dart';
import '../../../core/services/crashlytics_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final SystemConfigService _configService = SystemConfigService();
  final LocalDataClearService _dataClearService = LocalDataClearService();
  bool _enableLocalDataClear = false;
  bool _isLoadingConfig = true;
  bool _isClearingData = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _configService.getConfig();
    debugPrint(
      'Configuración cargada: enableLocalDataClearForTeachers = ${config.enableLocalDataClearForTeachers}',
    );
    if (mounted) {
      setState(() {
        _enableLocalDataClear = config.enableLocalDataClearForTeachers;
        _isLoadingConfig = false;
      });
    }
  }

  Future<void> _clearLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Borrar datos locales'),
            content: const Text(
              '¿Estás seguro de borrar todos tus datos locales?\n\nEsto incluye:\n• Progreso de videos\n• Checkpoints\n• Cola de sincronización\n• Quizzes offline\n\nEsta acción no se puede deshacer.',
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
    final authProvider = ref.watch(authStateProvider);
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Perfil'),
          backgroundColor: AppColors.primaryColor,
          centerTitle: true,
        ),
        body: const Center(
          child: Text('No se pudo cargar la información del usuario.'),
        ),
      );
    }

    return Scaffold(
      appBar:
          user.role.toLowerCase() != 'maestro'
              ? CustomAppBar(title: 'Mi Perfil')
              : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF1E3A8A),
                child: const Icon(Icons.person, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                user.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(
                    label: Text(
                      user.role,
                      style: AppStyles.buttonText.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor:
                        user.role == 'admin'
                            ? Colors.red
                            : const Color(0xFF917CDC),
                  ),
                  if (user.workArea != null && user.workArea!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        user.workArea!,
                        style: AppStyles.buttonText.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: Colors.teal,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x0A000000),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.person,
                          color: Color(0xFF917CDC),
                        ),
                        title: const Text(
                          'Nombre Completo',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        subtitle: Text(
                          user.name,
                          style: const TextStyle(color: Color(0xFF4A5568)),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.email,
                          color: Color(0xFF917CDC),
                        ),
                        title: const Text(
                          'Correo Electrónico',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        subtitle: Text(
                          user.email,
                          style: const TextStyle(color: Color(0xFF4A5568)),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.work,
                          color: Color(0xFF917CDC),
                        ),
                        title: const Text(
                          'Especialidad',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        subtitle: Text(
                          user.specialty ?? 'No especificada',
                          style: const TextStyle(color: Color(0xFF4A5568)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Editar Perfil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF917CDC),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed:
                    authProvider.isLoading
                        ? null
                        : () async {
                          // Show confirmation dialog
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Cerrar Sesión'),
                                  content: const Text(
                                    '¿Estás seguro de que deseas cerrar sesión?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(context).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text('Cerrar Sesión'),
                                    ),
                                  ],
                                ),
                          );

                          if (confirm != true) return;

                          try {
                            // Clear favorites provider before logging out
                            ref.read(favoritesStateProvider).clear();
                            // Wait for signOut to complete
                            await ref.read(authStateProvider).signOut();

                            // Use root navigator to escape nested navigator in MainShell
                            if (context.mounted) {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al cerrar sesión: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                icon:
                    authProvider.isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.logout),
                label: Text(
                  authProvider.isLoading
                      ? 'Cerrando sesión...'
                      : 'Cerrar Sesión',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Agregar logs antes del crash para asegurar que se envíe
                  await CrashlyticsService.instance.log('Test crash iniciado desde pantalla de perfil');
                  await CrashlyticsService.instance.setCustomKey('test_crash_source', 'profile_screen');
                  await CrashlyticsService.instance.setCustomKey('test_timestamp', DateTime.now().toIso8601String());
                  // Pequeña pausa para permitir que los logs se envíen
                  await Future.delayed(const Duration(milliseconds: 500));
                  // Forzar el crash
                  FirebaseCrashlytics.instance.crash();
                },
                child: const Text('Test Crash'),
              ),
              const SizedBox(height: 20),

              // Botón para borrar datos locales (solo para maestros cuando está habilitado por admin)
              if (user.role.toLowerCase() == 'maestro' &&
                  !_isLoadingConfig &&
                  _enableLocalDataClear)
                ElevatedButton.icon(
                  onPressed: _isClearingData ? null : _clearLocalData,
                  icon:
                      _isClearingData
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Icon(Icons.delete_outline),
                  label: Text(
                    _isClearingData ? 'Borrando...' : 'Borrar datos locales',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

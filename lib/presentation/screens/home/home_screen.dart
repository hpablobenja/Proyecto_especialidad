// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/riverpod_providers.dart';
import '../shell/main_shell.dart';
import '../admin/admin_dashboard_screen.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authProvider = ref.watch(authStateProvider);

    // Muestra una pantalla de carga si el usuario no ha sido cargado aún
    if (authProvider.currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Decide qué pantalla mostrar basándose en el rol del usuario
    return authProvider.currentUser!.role == 'admin'
        ? AdminDashboardScreen()
        : _HomeScaffold(child: MainShell());
  }
}

class _HomeScaffold extends StatelessWidget {
  final Widget child;

  const _HomeScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

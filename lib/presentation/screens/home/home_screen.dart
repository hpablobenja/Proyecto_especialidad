// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../shell/main_shell.dart';
import '../admin/admin_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Muestra una pantalla de carga si el usuario no ha sido cargado aún
    if (authProvider.currentUser == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
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

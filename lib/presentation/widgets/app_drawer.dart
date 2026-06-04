// lib/presentation/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/riverpod_providers.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/courses/my_progress_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/course_management_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../screens/courses/courses_list_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.currentUser;

    final isAdmin = (user?.role ?? '').toLowerCase() == 'admin';

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            UserAccountsDrawerHeader(
              accountName: Text(user?.role.toUpperCase() ?? ''),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: AppColors.primaryColor,
                  size: 36,
                ),
              ),
              decoration: BoxDecoration(color: AppColors.primaryColor),
            ),
            // Contenido del menú
            if (isAdmin) ...[
              // Menú restringido para Administrador
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Perfil'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => ProfileScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_customize),
                title: const Text('Panel de Administración'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AdminDashboardScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.manage_accounts),
                title: const Text('Gestionar cursos'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CourseManagementScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Generar reportes'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminReportsScreen(),
                    ),
                  );
                },
              ),
            ] else ...[
              // Menú estándar para no administradores (sin cambios)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Mi perfil'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => ProfileScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book),
                title: const Text('Cursos'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => CoursesListScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Mi progreso y reportes'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => MyProgressScreen()));
                },
              ),
            ],

            const Spacer(),
            const Divider(height: 1),

            // Cerrar sesión
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authStateProvider).signOut();
                // Ir al login y limpiar la pila
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

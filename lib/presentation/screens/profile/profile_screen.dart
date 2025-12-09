// lib/presentation/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_app_bar.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Mi Perfil'),
          backgroundColor: AppColors.primaryColor,
          centerTitle: true,
        ),
        body: Center(
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
                backgroundColor: AppColors.primaryColor,
                child: Icon(Icons.person, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                user.name,
                style: AppStyles.headline1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(
                  user.role.toUpperCase(),
                  style: AppStyles.buttonText.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                backgroundColor:
                    user.role == 'admin' ? Colors.red : AppColors.accentColor,
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: Icon(Icons.person, color: AppColors.primaryColor),
                title: Text('Nombre Completo'),
                subtitle: Text(user.name),
              ),
              ListTile(
                leading: Icon(Icons.email, color: AppColors.primaryColor),
                title: Text('Correo Electrónico'),
                subtitle: Text(user.email),
              ),
              ListTile(
                leading: Icon(Icons.security, color: AppColors.primaryColor),
                title: Text('ID de Usuario'),
                subtitle: Text(user.uid),
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
                icon: Icon(Icons.edit),
                label: Text('Editar Perfil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
                            // Wait for signOut to complete
                            await authProvider.signOut();

                            // Only navigate after signOut completes successfully
                            if (!mounted) return;

                            // Use root navigator to escape nested navigator in MainShell
                            Navigator.of(context, rootNavigator: true)
                                .pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          } catch (e) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al cerrar sesión: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
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
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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

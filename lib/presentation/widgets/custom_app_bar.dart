// lib/presentation/widgets/custom_app_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/riverpod_providers.dart';
import '../screens/auth/login_screen.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final Color? titleColor;

  const CustomAppBar({Key? key, required this.title, this.titleColor})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: Text(title, style: TextStyle(color: titleColor ?? Colors.white)),
      backgroundColor: AppColors.primaryColor,
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: Colors.white),
          onPressed: () async {
            // Limpiar el estado de cursos iniciados antes de desloguear
            ref.read(favoritesStateProvider).clear();
            await ref.read(authStateProvider).signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

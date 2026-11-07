// lib/presentation/widgets/connectivity_redirect.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/riverpod_providers.dart';
import '../screens/home/home_screen.dart';

/// Navigator raíz de [MaterialApp]. Permite volver a Formaciones
/// desde cualquier ruta apilada encima del shell.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Puente hacia el shell: cierra rutas anidadas y abre la pestaña Formaciones.
class ConnectivityRedirect {
  static void Function()? resetToFormaciones;

  static void goToFormaciones(WidgetRef ref) {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;

    nav.popUntil((route) => route.isFirst);

    final reset = resetToFormaciones;
    if (reset != null) {
      reset();
    } else {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen()),
        (route) => false,
      );
    }

    final connectivity = ref.read(connectivityStateProvider);
    if (connectivity.isOnline) {
      ref.read(courseStateProvider).loadCourses();
    }
  }
}

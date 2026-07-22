// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/di/riverpod_providers.dart';
import 'core/services/notification_service.dart';
import 'core/services/session_tracking_service.dart';
import 'core/services/session_timer_service.dart';
import 'presentation/widgets/background_image.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  // Asegura que los widgets de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa el servicio de notificaciones (preparado para Firebase Console en el futuro)
  await NotificationService().initialize();

  runApp(
    const ProviderScope(
      child: SessionLifecycleHandler(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeStateProvider);
    final auth = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'RedMaestra - Microformaciones',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        return BackgroundImage(excludeLogin: true, child: child!);
      },
      home: auth.isLoading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : (auth.isLoggedIn && (auth.currentUser?.role ?? '').isNotEmpty)
              ? HomeScreen()
              : LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}

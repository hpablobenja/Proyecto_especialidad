// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/di/riverpod_providers.dart';
import 'core/services/notification_service.dart';
import 'core/services/session_tracking_service.dart';
import 'core/services/quiz_offline_service.dart';
import 'core/services/quiz_sync_service.dart';
import 'core/services/video_download_service.dart';
import 'data/models/video_progress_hive.dart';
import 'data/models/checkpoint_hive.dart';
import 'data/models/sync_queue_item_hive.dart';
import 'data/models/quiz_progress_hive.dart';
import 'data/models/downloaded_video_hive.dart';
import 'data/models/data_user_hive.dart';
import 'presentation/widgets/background_image.dart';
import 'presentation/widgets/connectivity_redirect.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  // Asegura que los widgets de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa Hive para persistencia local de tracking
  await Hive.initFlutter();

  // Registrar adaptadores Hive
  Hive.registerAdapter(VideoProgressHiveAdapter());
  Hive.registerAdapter(CheckpointHiveAdapter());
  Hive.registerAdapter(SyncQueueItemHiveAdapter());
  Hive.registerAdapter(QuizProgressHiveAdapter());
  Hive.registerAdapter(QuizAnswerDetailAdapter());
  Hive.registerAdapter(DownloadedVideoHiveAdapter());
  Hive.registerAdapter(DataUserHiveAdapter());

  // Inicializa el servicio de notificaciones sin bloquear el inicio de la app
  NotificationService().initialize().catchError((e) {
    debugPrint('Error inicializando notificaciones: $e');
  });

  // Inicializa el servicio offline de quiz
  final quizOfflineService = QuizOfflineService();
  await quizOfflineService.init().catchError((e) {
    debugPrint('Error inicializando quiz offline service: $e');
  });

  // Inicializa el servicio global de sincronización de quizzes
  final quizSyncService = QuizSyncService();
  await quizSyncService.init().catchError((e) {
    debugPrint('Error inicializando quiz sync service: $e');
  });

  // Inicializa el servicio de descargas de video de fondo sin bloquear el inicio de la app
  VideoDownloadService().init().catchError((e) {
    debugPrint('Error inicializando video download service: $e');
  });

  runApp(const ProviderScope(child: SessionLifecycleHandler(child: MyApp())));
}

// Clave global para mostrar SnackBars desde cualquier lugar (incluyendo transiciones de autenticación)
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeStateProvider);
    final auth = ref.watch(authStateProvider);

    // Inicializar configuración de sesión
    ref.listen(sessionTrackingConfigProvider, (previous, next) {
      // Configuración cargada silenciosamente
    });

    ref.listen(connectivityStateProvider, (previous, next) {
      if (previous == null || previous.redirectToken == next.redirectToken) {
        return;
      }

      final auth = ref.read(authStateProvider);
      final role = (auth.currentUser?.role ?? '').toLowerCase();
      if (!auth.isLoggedIn || role.isEmpty || role == 'admin') return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ConnectivityRedirect.goToFormaciones(ref);
      });
    });

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'RedMaestra - Microformaciones',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return BackgroundImage(excludeLogin: true, child: child!);
      },
      home:
          auth.isLoading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
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

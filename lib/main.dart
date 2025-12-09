// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'presentation/widgets/background_image.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/course_provider.dart';
import 'presentation/providers/progress_provider.dart';
import 'presentation/providers/content_provider.dart';
import 'presentation/providers/admin_content_provider.dart';
import 'presentation/providers/comments_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/favorites_provider.dart';
import 'presentation/providers/connectivity_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  // Asegura que los widgets de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configura la inyección de dependencias
  di.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => di.sl<AuthProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<CourseProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<ProgressProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<ContentProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<AdminContentProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<CommentsProvider>()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()..load()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'RedMaestra - Microformaciones',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              return BackgroundImage(child: child!, excludeLogin: true);
            },
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.isLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return auth.isLoggedIn ? HomeScreen() : LoginScreen();
              },
            ),
            routes: {
              '/login': (context) => LoginScreen(),
              '/home': (context) => HomeScreen(),
            },
          );
        },
      ),
    );
  }
}

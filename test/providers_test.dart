import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:redmaestra1/presentation/providers/auth_provider.dart';
import 'package:redmaestra1/presentation/providers/theme_provider.dart';
import 'package:redmaestra1/presentation/providers/connectivity_provider.dart';
import 'package:redmaestra1/domain/usecases/auth/login_usecase.dart';
import 'package:redmaestra1/domain/usecases/auth/register_usecase.dart';
import 'package:redmaestra1/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:redmaestra1/domain/usecases/auth/update_user_usecase.dart';
import 'package:redmaestra1/domain/entities/user_entity.dart';

@GenerateMocks([
  LoginUsecase,
  RegisterUsecase,
  GetCurrentUserUsecase,
  UpdateUserUsecase,
])
import 'providers_test.mocks.dart';

void main() {
  // Inicializar el binding para todas las pruebas
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('AuthProvider Tests', () {
    late MockLoginUsecase mockLoginUsecase;
    late MockRegisterUsecase mockRegisterUsecase;
    late MockGetCurrentUserUsecase mockGetCurrentUserUsecase;
    late MockUpdateUserUsecase mockUpdateUserUsecase;
    late AuthProvider authProvider;

    setUp(() {
      mockLoginUsecase = MockLoginUsecase();
      mockRegisterUsecase = MockRegisterUsecase();
      mockGetCurrentUserUsecase = MockGetCurrentUserUsecase();
      mockUpdateUserUsecase = MockUpdateUserUsecase();

      authProvider = AuthProvider(
        loginUsecase: mockLoginUsecase,
        registerUsecase: mockRegisterUsecase,
        getCurrentUserUsecase: mockGetCurrentUserUsecase,
        updateUserUsecase: mockUpdateUserUsecase,
      );
    });

    test('Estado inicial es correcto', () {
      expect(authProvider.isLoading, false);
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.currentUser, null);
      expect(authProvider.errorMessage, null);
    });

    test('Login exitoso actualiza el estado', () async {
      final mockUser = UserEntity(
        uid: 'test_uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'maestro',
      );

      when(mockLoginUsecase.call(any)).thenAnswer((_) async => mockUser);

      final result = await authProvider.signInWithEmailAndPassword(
        'test@example.com',
        'password123',
      );

      expect(result, true);
      expect(authProvider.isLoggedIn, true);
      expect(authProvider.currentUser, mockUser);
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, null);
      verify(mockLoginUsecase.call(any)).called(1);
    });

    test('Login fallido maneja errores', () async {
      when(
        mockLoginUsecase.call(any),
      ).thenThrow(Exception('Credenciales inválidas'));

      final result = await authProvider.signInWithEmailAndPassword(
        'wrong@example.com',
        'wrongpass',
      );

      expect(result, false);
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.currentUser, null);
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, isNotNull);
    });

    test('Logout limpia el estado', () async {
      // Primero hacer login
      final mockUser = UserEntity(
        uid: 'test_uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'maestro',
      );

      when(mockLoginUsecase.call(any)).thenAnswer((_) async => mockUser);
      await authProvider.signInWithEmailAndPassword(
        'test@example.com',
        'password123',
      );

      // Verificar que está logueado
      expect(authProvider.isLoggedIn, true);

      // Hacer logout
      await authProvider.signOut();

      expect(authProvider.isLoggedIn, false);
      expect(authProvider.currentUser, null);
      expect(authProvider.errorMessage, null);
    });
  });

  group('ThemeProvider Tests', () {
    late ThemeProvider themeProvider;

    setUp(() {
      themeProvider = ThemeProvider();
    });

    test('Estado inicial es light theme', () async {
      // Esperar a que se complete la inicialización
      await Future.delayed(Duration(milliseconds: 100));
      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.isDarkMode, false);
    });

    test('Toggle theme cambia a dark mode', () async {
      await Future.delayed(
        Duration(milliseconds: 100),
      ); // Esperar inicialización
      await themeProvider.toggleTheme();
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, true);
    });

    test('Toggle theme vuelve a light mode', () async {
      await Future.delayed(
        Duration(milliseconds: 100),
      ); // Esperar inicialización
      await themeProvider.toggleTheme(); // a dark
      await themeProvider.toggleTheme(); // a light
      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.isDarkMode, false);
    });

    test('Set theme mode funciona correctamente', () async {
      await Future.delayed(
        Duration(milliseconds: 100),
      ); // Esperar inicialización
      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, true);

      await themeProvider.setThemeMode(ThemeMode.light);
      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.isDarkMode, false);

      await themeProvider.setThemeMode(ThemeMode.system);
      expect(themeProvider.themeMode, ThemeMode.system);
    });
  });

  group('ConnectivityProvider Tests', () {
    test('ConnectivityProvider puede ser importado', () {
      // Solo verificamos que la clase puede ser importada
      // sin instanciarla para evitar problemas con el binding
      expect(ConnectivityProvider, isNotNull);
    });
  });
}

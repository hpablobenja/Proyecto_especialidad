import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:redmaestra1/core/di/riverpod_providers.dart';
import 'package:redmaestra1/presentation/providers/auth_provider.dart';
import 'package:redmaestra1/presentation/screens/auth/login_screen.dart';
import 'package:redmaestra1/domain/entities/user_entity.dart';

import 'providers_test.mocks.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('LoginScreen Widget Tests', () {
    late MockLoginUsecase mockLoginUsecase;
    late MockRegisterUsecase mockRegisterUsecase;
    late MockGetCurrentUserUsecase mockGetCurrentUserUsecase;
    late MockUpdateUserUsecase mockUpdateUserUsecase;
    late MockResetPasswordUsecase mockResetPasswordUsecase;
    late AuthProvider authProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});

      mockLoginUsecase = MockLoginUsecase();
      mockRegisterUsecase = MockRegisterUsecase();
      mockGetCurrentUserUsecase = MockGetCurrentUserUsecase();
      mockUpdateUserUsecase = MockUpdateUserUsecase();
      mockResetPasswordUsecase = MockResetPasswordUsecase();

      when(mockGetCurrentUserUsecase.call(any)).thenAnswer((_) async => null);

      authProvider = AuthProvider(
        loginUsecase: mockLoginUsecase,
        registerUsecase: mockRegisterUsecase,
        getCurrentUserUsecase: mockGetCurrentUserUsecase,
        updateUserUsecase: mockUpdateUserUsecase,
        resetPasswordUsecase: mockResetPasswordUsecase,
      );
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [authStateProvider.overrideWith((ref) => authProvider)],
        child: MaterialApp(home: LoginScreen()),
      );
    }

    testWidgets('LoginScreen muestra el formulario correctamente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Iniciar Sesión'), findsOneWidget);
    });

    testWidgets('LoginScreen permite ingresar texto', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('LoginScreen responde al tap del botón', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Defer login completion to avoid navigating to HomeScreen (requires Firebase).
      final loginCompleter = Completer<UserEntity>();
      when(mockLoginUsecase.call(any)).thenAnswer((_) => loginCompleter.future);

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(mockLoginUsecase.call(any)).called(1);
    });

    testWidgets('LoginScreen maneja errores de login', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      when(mockLoginUsecase.call(any)).thenThrow(Exception('Error de login'));

      await tester.enterText(
        find.byType(TextFormField).first,
        'wrong@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'wrongpass');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      verify(mockLoginUsecase.call(any)).called(1);
    });
  });
}

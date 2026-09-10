import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:redmaestra1/core/di/riverpod_providers.dart';
import 'package:redmaestra1/presentation/providers/auth_provider.dart';
import 'package:redmaestra1/presentation/screens/auth/login_screen.dart';
import 'package:redmaestra1/domain/usecases/auth/login_usecase.dart';
import 'package:redmaestra1/domain/usecases/auth/register_usecase.dart';
import 'package:redmaestra1/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:redmaestra1/domain/usecases/auth/update_user_usecase.dart';
import 'package:redmaestra1/domain/usecases/auth/reset_password_usecase.dart';
import 'package:redmaestra1/domain/entities/user_entity.dart';

@GenerateMocks([
  LoginUsecase,
  RegisterUsecase,
  GetCurrentUserUsecase,
  UpdateUserUsecase,
  ResetPasswordUsecase,
])
import 'login_screen_test_simple.mocks.dart';

class MockResetPasswordUsecase extends Mock implements ResetPasswordUsecase {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('LoginScreen Widget Tests', () {
    late MockLoginUsecase mockLoginUsecase;
    late MockRegisterUsecase mockRegisterUsecase;
    late MockGetCurrentUserUsecase mockGetCurrentUserUsecase;
    late MockUpdateUserUsecase mockUpdateUserUsecase;
    late MockResetPasswordUsecase mockResetPasswordUsecase;
    late AuthProvider authProvider;

    setUp(() {
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

      final mockUser = UserEntity(
        uid: 'test_uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'maestro',
      );

      when(mockLoginUsecase.call(any)).thenAnswer((_) async => mockUser);

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

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

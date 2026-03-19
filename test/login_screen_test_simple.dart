// test/login_screen_test_simple.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:redmaestra1/presentation/providers/auth_provider.dart';
import 'package:redmaestra1/presentation/screens/auth/login_screen.dart';
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
import 'login_screen_test_simple.dart';
import 'login_screen_test_simple.mocks.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('LoginScreen Widget Tests', () {
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

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: LoginScreen(),
        ),
      );
    }

    testWidgets('LoginScreen muestra el formulario correctamente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Verificar elementos básicos
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Iniciar Sesión'), findsOneWidget);
    });

    testWidgets('LoginScreen permite ingresar texto', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Ingresar texto en los campos
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.pump();

      // Verificar que el texto se ingresó
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('LoginScreen responde al tap del botón', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Configurar mock para respuesta exitosa
      final mockUser = UserEntity(
        uid: 'test_uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'maestro',
      );

      when(mockLoginUsecase.call(any)).thenAnswer((_) async => mockUser);

      // Ingresar credenciales y presionar botón
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Verificar que se llamó al usecase
      verify(mockLoginUsecase.call(any)).called(1);
    });

    testWidgets('LoginScreen maneja errores de login', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Configurar mock para lanzar error
      when(mockLoginUsecase.call(any)).thenThrow(Exception('Error de login'));

      // Ingresar credenciales y presionar botón
      await tester.enterText(
        find.byType(TextFormField).first,
        'wrong@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'wrongpass');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Verificar que se intentó el login
      verify(mockLoginUsecase.call(any)).called(1);
    });
  });
}

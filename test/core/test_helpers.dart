import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper class for test utilities
class TestHelpers {
  /// Crea un widget envuelto en MaterialApp para pruebas
  static Widget createMaterialAppWidget(Widget child) {
    return MaterialApp(home: child);
  }

  /// Crea un widget envuelto en Scaffold para pruebas
  static Widget createScaffoldWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  /// Espera a que todos los futures se completen
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  /// Encuentra un widget por texto y verifica que existe
  static void findText(String text, {bool shouldFind = true}) {
    if (shouldFind) {
      expect(find.text(text), findsOneWidget);
    } else {
      expect(find.text(text), findsNothing);
    }
  }

  /// Encuentra un widget por tipo y verifica que existe
  static void findWidgetOfType(Type type, {bool shouldFind = true}) {
    if (shouldFind) {
      expect(find.byType(type), findsOneWidget);
    } else {
      expect(find.byType(type), findsNothing);
    }
  }

  /// Simula un tap en un widget con texto específico
  static Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pump();
  }

  /// Simula un tap en un widget por tipo
  static Future<void> tapWidgetByType(WidgetTester tester, Type type) async {
    await tester.tap(find.byType(type));
    await tester.pump();
  }

  /// Ingresa texto en un TextFormField
  static Future<void> enterText(
    WidgetTester tester,
    String text, {
    int index = 0,
  }) async {
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(index), text);
    await tester.pump();
  }

  /// Verifica que un CircularProgressIndicator está presente
  static void verifyLoadingIndicator({bool shouldBeLoading = true}) {
    if (shouldBeLoading) {
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    } else {
      expect(find.byType(CircularProgressIndicator), findsNothing);
    }
  }

  /// Verifica que un mensaje de error está presente
  static void verifyErrorMessage(String message) {
    expect(find.text(message), findsOneWidget);
  }

  /// Espera un período específico de tiempo (para pruebas asíncronas)
  static Future<void> wait(Duration duration) async {
    await Future.delayed(duration);
  }

  /// Verifica que un widget con key específica existe
  static void findWidgetByKey(Key key, {bool shouldFind = true}) {
    if (shouldFind) {
      expect(find.byKey(key), findsOneWidget);
    } else {
      expect(find.byKey(key), findsNothing);
    }
  }

  /// Simula scroll en un widget scrollable
  static Future<void> scroll(
    WidgetTester tester, {
    double offset = 300,
    Finder? finder,
  }) {
    final targetFinder = finder ?? find.byType(Scrollable);
    return tester.fling(targetFinder, const Offset(0, -300), offset);
  }
}

/// Clase base para pruebas de widgets
abstract class WidgetTestBase {
  late WidgetTester tester;

  Future<void> setUp(WidgetTester tester) async {
    this.tester = tester;
    await setUpTest();
  }

  Future<void> setUpTest() async {
    // Override en subclases si es necesario
  }

  Future<void> tearDownTest() async {
    // Override en subclases si es necesario
  }
}

/// Clase base para pruebas de providers
abstract class ProviderTestBase {
  Future<void> setUp() async {
    await setUpTest();
  }

  Future<void> setUpTest() async {
    // Override en subclases si es necesario
  }

  Future<void> tearDownTest() async {
    // Override en subclases si es necesario
  }
}

/// Constantes para pruebas
class TestConstants {
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'password123';
  static const String testUid = 'test_uid_123';
  static const String testRole = 'maestro';
  static const String testDisplayName = 'Test User';

  static const String invalidEmail = 'invalid-email';
  static const String wrongPassword = 'wrongpassword';
  static const String emptyString = '';

  static const Duration shortWait = Duration(milliseconds: 100);
  static const Duration mediumWait = Duration(milliseconds: 500);
  static const Duration longWait = Duration(seconds: 1);
}

/// Mensajes de error comunes para pruebas
class TestErrorMessages {
  static const String emailRequired = 'Por favor ingresa un correo electrónico';
  static const String emailInvalid =
      'Por favor ingresa un correo electrónico válido';
  static const String passwordRequired = 'Por favor ingresa una contraseña';
  static const String passwordTooShort =
      'La contraseña debe tener al menos 6 caracteres';
  static const String loginFailed = 'Usuario o contraseña incorrectos';
  static const String networkError = 'Error de conexión';
  static const String genericError = 'Ha ocurrido un error';
}
